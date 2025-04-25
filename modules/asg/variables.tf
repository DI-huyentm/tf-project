variable "ami_id" {}
variable "instance_type" {}
variable "key_name" {}
variable "security_group_id" {}
variable "public_subnet_ids" { type = list(string) }
variable "target_group_arn" {}
variable "desired_capacity" {}
variable "min_size" {}
variable "max_size" {}
# modules/asg/outputs.tf
output "asg_name" { value = aws_autoscaling_group.this.name }
