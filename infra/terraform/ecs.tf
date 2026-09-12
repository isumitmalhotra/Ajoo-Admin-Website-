/**
 * The API service. One task, on purpose.
 *
 * The plan's §3 is explicit and it is not a placeholder: the rate limiter, the
 * SEO cache, the scheduler and Socket.io all hold state in the process. Two
 * tasks means two rate limiters counting half the requests each, two caches
 * disagreeing, the scheduler firing twice, and sockets split across processes
 * that cannot see each other's rooms. Redis is what fixes that, and it is a
 * growth decision rather than a launch one.
 *
 * So desired_count is 1 and the deployment percentages below are what make a
 * deploy work at that size.
 */

resource "aws_ecs_cluster" "main" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = local.name }
}

/**
 * Fargate only, no Spot.
 *
 * Spot is roughly 70% cheaper and can be reclaimed with two minutes' notice.
 * At one task that is not a cost saving, it is a scheduled outage.
 */
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aajoo/${var.env}/api"
  retention_in_days = 30

  tags = { Name = "${local.name}-api" }
}

variable "api_image_tag" {
  description = "A commit SHA. Never 'latest' — see the ECR comment on immutable tags."
  type        = string
  default     = "bootstrap"
}

variable "api_cpu" {
  description = "256 = 0.25 vCPU. The API is I/O bound; this is the Render free tier several times over."
  type        = number
  default     = 512
}

variable "api_memory" {
  description = "MiB. 1024 is the smallest that pairs with 512 CPU."
  type        = number
  default     = 1024
}

locals {
  # Parameters Terraform created, plus the ones an operator supplied, plus
  # whichever optional ones actually exist. Anything absent is simply not
  # injected — a name pointing at nothing makes a task fail to start with an
  # error that names the ARN and not the variable.
  ssm_prefix = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/aajoo/${var.env}"

  api_secrets = [
    for n in concat(
      ["DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD"],
      tolist(local.operator_supplied),
      local.present_optional,
    ) : { name = n, valueFrom = "${local.ssm_prefix}/${n}" }
  ]
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${local.name}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.api_cpu
  memory                   = var.api_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64" # Graviton: same price, more of it
  }

  container_definitions = jsonencode([{
    name      = "api"
    image     = "${local.ecr_urls["api"]}:${var.api_image_tag}"
    essential = true

    portMappings = [{ containerPort = 8080, protocol = "tcp" }]

    # Non-secret, and knowable here.
    environment = [
      { name = "NODE_ENV", value = "production" },
      { name = "PORT", value = "8080" },
    ]

    secrets = local.api_secrets

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.api.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "api"
      }
    }

    /**
     * The image already carries a HEALTHCHECK that hits /health without
     * touching the database. Repeating it here means ECS replaces a task that
     * has stopped answering even before the load balancer drains it.
     */
    healthCheck = {
      command     = ["CMD-SHELL", "node -e \"require('http').get('http://127.0.0.1:8080/health',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))\""]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 30
    }
  }])

  tags = { Name = "${local.name}-api" }
}

resource "aws_ecs_service" "api" {
  name            = "${local.name}-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  enable_execute_command = var.enable_ecs_exec

  network_configuration {
    subnets = aws_subnet.public[*].id
    # Public subnet, public IP, and no NAT gateway. What keeps this private is
    # the security group: inbound from the ALB only. See network.tf.
    assign_public_ip = true
    security_groups  = [aws_security_group.tasks.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 8080
  }

  /**
   * 100/200: start the new task BEFORE stopping the old one.
   *
   * At desired_count 1 the alternative (minimum_healthy_percent 0) is a deploy
   * with a hole in it — the old task stops, the new one pulls an image, and
   * the API is down for however long that takes. 200 costs one extra task for
   * a minute or two per deploy.
   */
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # The load balancer needs the listener to exist before it can register.
  depends_on = [aws_lb_listener.https]

  lifecycle {
    # The pipeline updates the task definition on every deploy; Terraform
    # should not drag it back to whatever it last applied.
    ignore_changes = [task_definition, desired_count]
  }

  tags = { Name = "${local.name}-api" }
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.api.name
}

output "api_log_group" {
  value = aws_cloudwatch_log_group.api.name
}
