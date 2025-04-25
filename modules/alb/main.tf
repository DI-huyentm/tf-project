# Target group cho ASG dùng chung
# resource "aws_lb_target_group" "this" {
#   name        = "tf-target-group"
#   port        = 80
#   protocol    = "HTTP"
#   vpc_id      = var.vpc_id
#   target_type = "instance"
#   health_check {
#     protocol = "HTTPS"
#     path     = "/"
#   }
# }

resource "aws_lb_target_group" "this" {
  name        = "tf-target-group"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
    protocol = "HTTPS"
    path     = "/"
  }
}
# Certificate tự ký (self-signed)
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "tls_self_signed_cert" "cert" {
  private_key_pem = tls_private_key.key.private_key_pem

  subject {
    common_name  = "example.com"
    organization = "TF"
  }

  validity_period_hours = 8760
  is_ca_certificate     = false

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]
}


resource "aws_acm_certificate" "this" {
  private_key       = tls_private_key.key.private_key_pem
  certificate_body  = tls_self_signed_cert.cert.cert_pem
  certificate_chain = tls_self_signed_cert.cert.cert_pem
}
# Application Load Balancer
resource "aws_lb" "this" {
  name               = "tf-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.security_group_id]
}
# Listener HTTP → redirect HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
# Listener HTTPS → forward đến Target Group
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.this.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
