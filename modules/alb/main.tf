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
  name = "tf-target-group"
  port = 443
  # port 443 cua con ec2 trong target group
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "instance"
  # vi trong target group nay la nhung con ec2 ne de type la instance. Nhung type khac: vi du: lambda
  health_check {
    # gui lien tuc nhung goi tin https co path la /, de xem nhung con instance trong target group con song khong
    # neu 200 -> hoat dong binh thuong, neu 400, 500 -> unhealthy
    protocol = "HTTPS"
    path     = "/"
  }
}
# Certificate tự ký (self-signed)

# gen ra 1 cai private key
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# gen ra 1 cai cert tu ki bang cai private key vua tao
resource "tls_self_signed_cert" "cert" {
  private_key_pem = tls_private_key.key.private_key_pem

  subject {
    common_name  = "tranhuyen.com"
    organization = "NAB"
  }

  validity_period_hours = 8760
  # expired hours
  is_ca_certificate = false
  # to chuc uy tin ki cho?

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
    # server authenticate: thang server verify minh
  ]
}

# import cert vao acm (quan ly cert tap trung)
resource "aws_acm_certificate" "this" {
  private_key      = tls_private_key.key.private_key_pem
  certificate_body = tls_self_signed_cert.cert.cert_pem
}
# Application Load Balancer
resource "aws_lb" "this" {
  name     = "tf-alb"
  internal = false
  # deploy o subnet public
  load_balancer_type = "application"
  # co 4 loai LB: ALB la loai cho layer 7 (tang ung dung), Network LB (cho tang giao van), Gateway LB (cho tang Ip), Classic LB (do co, cho tang 4 + 7)
  subnets         = var.public_subnet_ids
  security_groups = [var.security_group_id]
}
# Listener HTTP → redirect HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  # khi con alb lang nghe duoc nhung request http qua cong 80 (cua alb), thi no se redirect nhung request nay sang cong 443
  # tu cong 443 cua alb -> nem sang cong 443 cua ec2 trong target group
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
  # giao thuc ssl nay se phai thoa man chinh sach ma thang nao dat ra, thi ten cua security policy nay la "ELBSecurityPolicy-2016-08"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  # nhet cert vao 443 nay, khi mo cong 443, bat buoc phai nhet cai cert nay vao cong 443
  certificate_arn = aws_acm_certificate.this.arn
  # alb nem "foraward" traffic cho target group
  # target group se chia deu traffic cho cac con ec2 ben trong
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
