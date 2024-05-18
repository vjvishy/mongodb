terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49"
    }
    ssh = {
      source = "loafoe/ssh"
    }
  }
  required_version = "~> 1.8.3"
}