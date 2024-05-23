data "terraform_remote_state" "aws_resources" {
  backend = "local"
 
  config = {
    path = "../aws-resources/terraform.tfstate"
  }
}

# Get AWS Region information
provider "aws" {
  region = data.terraform_remote_state.aws_resources.outputs.region
}


module "db_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/web"

  name        = "db-sg-${data.terraform_remote_state.aws_resources.outputs.project_name}-${data.terraform_remote_state.aws_resources.outputs.environment}"
  description = "Security group for Database with TCP ports open within VPC"
  vpc_id      = data.terraform_remote_state.aws_resources.outputs.vpc_id

  #ingress_cidr_blocks = module.vpc.public_subnets_cidr_blocks
  ingress_cidr_blocks = [data.terraform_remote_state.aws_resources.outputs.vpc_cidr_block]
  #ingress_cidr_blocks = ["0.0.0.0"]
  
  ingress_with_cidr_blocks  = [
    {
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }, 
    {
      from_port = 22
      to_port   = 27017
      protocol  = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }, 
  ]

  tags = data.terraform_remote_state.aws_resources.outputs.resource_tags
}

module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"

  key_name            = var.ec2_key_pair_name
  create_private_key  = true
}


module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  bucket = "s3-bucket-${data.terraform_remote_state.aws_resources.outputs.project_name}-${data.terraform_remote_state.aws_resources.outputs.environment}"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "my-bucket" {

  depends_on = [module.s3-bucket]

  bucket = module.s3-bucket.s3_bucket_id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.1"

  depends_on = [module.key_pair]

  name                        = var.db_instance_name
  instance_type               = var.db_instance_type
  ami                         = var.mongodb_ami_id
  subnet_id                   = data.terraform_remote_state.aws_resources.outputs.vpc_public_subnets[0]
  vpc_security_group_ids      = [module.db_security_group.security_group_id]
  associate_public_ip_address = true
  key_name                    = var.ec2_key_pair_name

  tags = data.terraform_remote_state.aws_resources.outputs.resource_tags
}

resource "local_file" "aws_credentials" {
  content  = "[default]\n aws_access_key_id = ${var.aws_access_key_id}\n aws_secret_access_key = ${var.aws_secret_access_key}\n region = ${data.terraform_remote_state.aws_resources.outputs.region}"
  filename = "${path.module}/credentials"
}

resource "local_file" "create_user" {
  content  = "db.createUser({\n  user:'${var.mongodb_username}',\n  pwd:'${var.mongodb_password}',\n  roles: [{ role: 'userAdminAnyDatabase', db: 'admin' }]});\ndb.grantRolesToUser('myUserAdmin',['readWriteAnyDatabase'])"
  filename = "${path.module}/create_user.js"
}

resource "ssh_resource" "create_mongodb_user" {
  depends_on = [module.ec2_instance]
  
  when = "create"

  host          = "${module.ec2_instance.public_ip}"
  user          = "ubuntu"
  private_key   = module.key_pair.private_key_openssh

  timeout     = "5m"
  retry_delay = "5s"

  file {
    source = "${path.module}/create_user.js"
    destination = "/home/ubuntu/create_user.js"
    permissions = "0775"
  }

  commands = [
    "sudo systemctl restart mongod",
    "mkdir -p ~/.aws",
    "mongosh '127.0.0.1:27017/admin' create_user.js"
  ]
}

resource "ssh_resource" "update_mongodb_config" {
  depends_on = [module.ec2_instance, ssh_resource.create_mongodb_user]
  
  when = "create"

  host          = "${module.ec2_instance.public_ip}"
  user          = "ubuntu"
  private_key   = module.key_pair.private_key_openssh

  timeout     = "5m"
  retry_delay = "5s"

  file {
    source = "${path.module}/update_mongodb_config.sh"
    destination = "/home/ubuntu/update_mongodb_config.sh"
    permissions = "0775"
  }

  commands = [
    "./update_mongodb_config.sh ${module.ec2_instance.public_dns}"
  ]
}

resource "ssh_resource" "create_aws_credentials" {
  depends_on = [module.ec2_instance, ssh_resource.update_mongodb_config]
  
  when = "create"

  host          = "${module.ec2_instance.public_ip}"
  user          = "ubuntu"
  private_key   = module.key_pair.private_key_openssh

  timeout     = "5m"
  retry_delay = "5s"

  file {
    source = "${path.module}/credentials"
    destination = "/home/ubuntu/.aws/credentials"
    permissions = "0775"
  }

  commands = [
    "sudo apt install unzip -y",
    "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'",
    "unzip awscliv2.zip",
    "sudo ./aws/install"
  ]
}

resource "ssh_resource" "setup_mongodb_backup" {
  depends_on = [module.ec2_instance, ssh_resource.create_aws_credentials]
  
  when = "create"

  host          = "${module.ec2_instance.public_ip}"
  user          = "ubuntu"
  private_key   = module.key_pair.private_key_openssh

  timeout     = "5m"
  retry_delay = "5s"

  file {
    source = "${path.module}/backup_mongodb.sh"
    destination = "/home/ubuntu/backup_mongodb.sh"
    permissions = "0775"
  }

  commands = [
    "crontab -l | { cat; echo '*/30 * * * * /home/ubuntu/backup_mongodb.sh ${module.ec2_instance.public_dns} ${var.mongodb_name} ${module.s3-bucket.s3_bucket_id} > /home/ubuntu/backup_mongodb.log'; } | crontab -"
  ]
}
