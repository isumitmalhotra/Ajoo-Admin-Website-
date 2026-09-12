/**
 * The load balancer, and the two things about it that are not defaults.
 *
 * The plan chose an ALB over App Runner for a reason worth repeating here,
 * because the reason is also the configuration: Socket.io needs real
 * WebSockets, and the API holds in-process state — the rate limiter, the SEO
 * cache, the scheduler and Socket.io all assume one process. So:
 *
 *   1. the idle timeout is raised, because a WebSocket that sends nothing for
 *      sixty seconds is a healthy WebSocket and the default would cut it;
 *   2. stickiness is on, so that the day there is a second task a socket keeps
 *      talking to the process that owns its state.
 *
 * Stickiness is set now rather than "when we scale", because the day somebody
 * raises desired_count is not the day they will remember this file.
 */

resource "aws_lb" "main" {
  name               = "${local.name}-alb"
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.alb.id]

  # A negotiation can sit quiet for minutes while a guest thinks. 300s is five
  # times the default and still far below the platform's own socket timeouts.
  idle_timeout = 300

  enable_deletion_protection = var.env == "prod"
  drop_invalid_header_fields = true

  tags = { Name = "${local.name}-alb" }
}

resource "aws_lb_target_group" "api" {
  name        = "${local.name}-api"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip" # Fargate with awsvpc networking registers by IP
  vpc_id      = aws_vpc.main.id

  /**
   * /health, not /.
   *
   * The backend's own Dockerfile HEALTHCHECK hits /health precisely because it
   * answers without touching the database — so a database blip restarts
   * nothing. The load balancer uses the same endpoint for the same reason: an
   * ALB that drains every task during a brief RDS failover turns a blip into
   * an outage.
   */
  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  # See the file header. Twelve hours, so a socket survives a long session.
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 43200
    enabled         = true
  }

  # Let an in-flight request finish rather than cutting it at deploy time.
  deregistration_delay = 30

  tags = { Name = "${local.name}-api" }
}

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  /**
   * 301, permanent.
   *
   * A guest who types the hostname without a scheme should arrive, not time
   * out — and the redirect is permanent because this API will not serve plain
   * HTTP again. 308 would preserve the method, but every client here follows a
   * 301 on GET and re-issues POSTs to the HTTPS base URL anyway.
   */
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  # The validated certificate when DNS is ours to manage, the raw one when the
  # zone lives elsewhere and somebody added the record by hand.
  certificate_arn = var.manage_dns ? aws_acm_certificate_validation.api[0].certificate_arn : aws_acm_certificate.api.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

output "alb_dns_name" {
  description = "Point api.aajoohomes.com at this (ALIAS in Route 53, CNAME elsewhere)."
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Needed for a Route 53 ALIAS record."
  value       = aws_lb.main.zone_id
}
