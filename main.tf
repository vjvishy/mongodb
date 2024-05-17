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
  
  ingress_with_cidr_blocks  = [
    {
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = data.terraform_remote_state.aws_resources.outputs.resource_tags
}

module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"

  key_name            = var.ec2_key_pair_name
  create_private_key  = true
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

