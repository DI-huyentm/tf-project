resource "aws_launch_template" "this" {
  name_prefix   = "tf-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  # card mang la co dia chi ip, tat ca traffic tu ben ngoai hoac tu trong ra thi di qua card mang. Muon monitor cac goi tin, la monitor cai card mang
  # card mang co the co nhieu dia chi ip, co dia chi MAC/IPv4(public/private)
  # network interface chinh la cai card mang
  network_interfaces {
    # gan cho card mang nay 1 dia chi ip public
    associate_public_ip_address = true
    #firewall, sg se gan cho card mang. vi 1 may tinh can co 1 card mang de day traffic ra ngoai or vao trong.
    # sg nam o card mang, khong phai nam o firewall
    security_groups = [var.security_group_id]
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
