/**
 * The website: the SPA and the SEO renderer, as one container.
 *
 * This was the single biggest risk in the September comparison and it is
 * already solved in the repo. Vercel's `api/seo-render.ts` rewrites every HTML
 * request to inject title, description, canonical and JSON-LD, and serving
 * `dist/` as plain static files would hand every crawler the shell's hardcoded
 * head. The frontend Dockerfile ships the SPA *and* `scripts/seoRenderServe.mjs`
 * as one image — the same server the SEO acceptance tests run against. So there
 * is no Lambda@Edge, no CloudFront Function, and no rewrite to maintain: it is
 * another Fargate service behind the same load balancer.
 *
 * THE BUILD-TIME TRAP, which is Day 3's first line in the plan: `VITE_*` values
 * are inlined by Vite at build time. Pointing the website at the new API is a
 * REBUILD, not an environment change, and an image built against the old API
 * URL will keep calling Render no matter what the task definition says.
 */

resource "aws_lb_target_group" "web" {
  name        = "${local.name}-web"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    # The renderer answers "/" for every path; a dedicated health path would be
    # a second thing to keep alive. A 200 on the root is the same signal.
    path                = "/"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = { Name = "${local.name}-web" }
}

/**
 * Only CloudFront may reach the website, and this is what enforces it.
 *
 * Without this rule the ALB would serve the site directly to anyone who found
 * its hostname — bypassing the CDN, the cache and anything ever put in front of
 * it, and giving crawlers a second origin serving the same pages under a
 * different name. The secret is generated here and handed to CloudFront as a
 * custom header; the rule matches on it rather than on Host, so the origin
 * hostname alone is not enough to get in.
 */
resource "random_password" "cloudfront_origin_secret" {
  length  = 40
  special = false
}

resource "aws_lb_listener_rule" "web" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 20

  condition {
    http_header {
      http_header_name = "X-Origin-Verify"
      values           = [random_password.cloudfront_origin_secret.result]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_cloudwatch_log_group" "web" {
  name              = "/aajoo/${var.env}/web"
  retention_in_days = 30
  tags              = { Name = "${local.name}-web" }
}

variable "web_image_tag" {
  description = "A commit SHA, and one built against the new API URL. See the file header."
  type        = string
  default     = "bootstrap"
}

resource "aws_ecs_task_definition" "web" {
  family                   = "${local.name}-web"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([{
    name      = "web"
    image     = "${local.ecr_urls["web"]}:${var.web_image_tag}"
    essential = true

    portMappings = [{ containerPort = 8080, protocol = "tcp" }]

    /**
     * No secrets here, and that is correct.
     *
     * Everything this container needs at RUNTIME is already inside the bundle,
     * because Vite inlined it. Adding SSM parameters would imply they could
     * change something, and they cannot.
     */
    environment = [
      { name = "NODE_ENV", value = "production" },
      { name = "PORT", value = "8080" },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.web.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "web"
      }
    }
  }])

  tags = { Name = "${local.name}-web" }
}

/**
 * Two tasks, unlike the API.
 *
 * The renderer holds nothing between requests — it reads the URL, fetches what
 * the page needs and returns HTML — so there is no in-process state to split
 * and no reason to run a single point of failure. It is also the service a
 * guest actually looks at.
 */
resource "aws_ecs_service" "web" {
  name            = "${local.name}-web"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  enable_execute_command = var.enable_ecs_exec

  network_configuration {
    subnets          = aws_subnet.public[*].id
    assign_public_ip = true
    security_groups  = [aws_security_group.tasks.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web.arn
    container_name   = "web"
    container_port   = 8080
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener.https]

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = { Name = "${local.name}-web" }
}
