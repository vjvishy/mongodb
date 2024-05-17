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


