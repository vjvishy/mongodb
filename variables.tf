variable "aws_access_key_id" {
    description = "AWS Access Key Id"
    type        = string
    default     = "AKIAQ3EGUX4SKRAQP6EL" 
}

variable "aws_secret_access_key" {
    description = "AWS Secret Access Key"
    type        = string
    default     = "k/wGjpexJtXlyJMTeAyPJ37z7erz8+aA8wOQbuik" 
}

# EC2 Instance Key-Pair Name
variable "ec2_key_pair_name" {
    description = "EC2 Instance Key-Pair Name"
    type        = string
    default     = "mongodb" 
}

# MongoDB instance name
variable "db_instance_name" {
    description = "Name of the DB EC2 instance"
    type        = string
    default     = "db"
}

#MongoDB EC2 instance type
variable "db_instance_type" {
    description = "AWS EC2 instance type to provision"
    type        = string
    default     = "t2.medium"
}

#MongoDB EC2 AMI Id
variable "mongodb_ami_id" {
    description = "AMI Id of the MongoDB server"
    type        = string
    default     = "ami-09fc2e89035bdc541"
}

#MongoDB Database Name
variable "mongodb_name" {
    description = "MongoDB Database Name"
    type        = string
    default     = "admin"
}

#MongoDB Database Username
variable "mongodb_username" {
    description = "MongoDB Database UserName"
    type        = string
    default     = "myUserAdmin"
}

#MongoDB Database Password
variable "mongodb_password" {
    description = "MongoDB Database Password"
    type        = string
    default     = "abc123"
}

