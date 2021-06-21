resource "aws_elb" "cluster-two-lb" {
  name               = "${var.prefix}-cluster-two-lb"
  availability_zones = aws_instance.ubuntu_vms[*].availability_zone

  listener {
    instance_port     = 80
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:80"
    interval            = 30
  }

  instances                   = [
    aws_instance.ubuntu_vms[4].id
  ]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "${var.prefix}-cluster-two-lb"
  }
}

resource "aws_route53_record" "cluster-two" {
  zone_id = data.aws_route53_zone.rancher.zone_id
  name    = "two.${data.aws_route53_zone.rancher.name}"
  type    = "CNAME"
  ttl     = "5"

  records        = ["${aws_elb.cluster-two-lb.dns_name}."]
}