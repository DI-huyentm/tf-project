resource "aws_launch_template" "this" {
  name_prefix   = "tf-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.security_group_id]
  }
}
resource "aws_autoscaling_group" "this" {
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = var.public_subnet_ids
  target_group_arns   = [var.target_group_arn]
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "tf-asg-instance"
    propagate_at_launch = true
  }
}
