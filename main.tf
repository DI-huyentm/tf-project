terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.95.0"
    }
  }
}

provider "aws" {
  # Configuration options
}

module "vpc" {
  source   = "./modules/vpc"
  vpc_name = "tf-vpc"
  vpc_cidr = "192.168.0.0/16"
  public_subnets = [
    { cidr = "192.168.1.0/24", az = "us-east-1a", name = "tf-public-subnet-1" },
    { cidr = "192.168.2.0/24", az = "us-east-1b", name = "tf-public-subnet-2" }
  ]
  isolated_subnets = [
    { cidr = "192.168.3.0/24", az = "us-east-1a", name = "tf-isolated-subnet-1" },
    { cidr = "192.168.4.0/24", az = "us-east-1b", name = "tf-isolated-subnet-2" }
  ]
}
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP/HTTPS"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
module "alb" {
  source            = "./modules/alb"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_id = aws_security_group.alb_sg.id
}
module "asg" {
  source            = "./modules/asg"
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  key_name          = var.key_name
  security_group_id = aws_security_group.alb_sg.id
  public_subnet_ids = module.vpc.public_subnet_ids
  target_group_arn  = module.alb.target_group_arn
  desired_capacity  = 1
  min_size          = 1
  max_size          = 2
}
