/**
 * Moving the data, from inside the VPC.
 *
 * ── Why this is a Fargate task and not a script on somebody's laptop ────────
 * RDS is in private subnets with `publicly_accessible = false`, and its
 * security group admits port 3306 from the tasks group and from nothing else.
 * There is no bastion and deliberately no NAT gateway. So there is exactly one
 * place in the world that can write to this database: a task on the tasks
 * security group.
 *
 * That constraint turns out to be the right answer anyway. The alternative —
 * dump to a laptop, restore from the laptop — puts a file containing every
 * guest's KYC, every host's bank account and every booking on a personal
 * machine, in a downloads folder, for ever. This way the data goes source →
 * container → RDS and never lands anywhere a person can forget about.
 *
 * The task has a public IP (public subnet), so it can reach the current
 * managed MySQL over the internet, and it is inside the VPC, so it can reach
 * RDS privately. Both ends, one hop, no file.
 *
 * ── Why it defaults to OFF ──────────────────────────────────────────────────
 * This task definition can read the entire production database and write over
 * another one. It should exist for the hours of the cutover and then stop
 * existing. `enable_data_migration = true` in tfvars for the window, back to
 * false afterwards, and the definition is deregistered.
 */

variable "enable_data_migration" {
  description = <<-EOT
    Create the one-off data-copy task definition and its parameters.

    True only during the cutover window. It grants read of the SOURCE database
    credentials and write to the target; leaving it on afterwards leaves a
    standing way to overwrite production from a single API call.
  EOT
  type        = bool
  default     = false
}

variable "migration_cpu" {
  description = "A dump-and-load is I/O bound, but gzip and sed are not free."
  type        = number
  default     = 1024
}

variable "migration_memory" {
  description = "MiB. mysqldump streams, so this is not sized by database size."
  type        = number
  default     = 2048
}

locals {
  migration_count = var.enable_data_migration ? 1 : 0

  /**
   * The SOURCE credentials are supplied the same way every other secret is —
   * infra/scripts/put-parameters.sh, from a file on the operator's machine —
   * under a separate path so they can be deleted in one command when the
   * cutover is done:
   *
   *   aws ssm delete-parameters --names \
   *     /aajoo/prod/migration/SOURCE_HOST ... (etc)
   */
  migration_source_names = [
    "SOURCE_HOST", "SOURCE_PORT", "SOURCE_USER", "SOURCE_PASSWORD", "SOURCE_DB",
  ]

  migration_ssm_prefix = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/aajoo/${var.env}/migration"
}

resource "aws_cloudwatch_log_group" "migration" {
  count = local.migration_count

  name              = "/aajoo/${var.env}/migration"
  retention_in_days = 30

  tags = { Name = "${local.name}-migration" }
}

/**
 * The task execution role can read /aajoo/<env>/* already, which covers the
 * migration path. This policy exists only because the source parameters sit
 * under a different sub-path, and being explicit about it is the point: the
 * grant that lets a container read the OLD database's password should be
 * visible in a file, not inherited by a wildcard nobody re-reads.
 */
resource "aws_iam_role_policy" "migration_secrets" {
  count = local.migration_count

  name = "migration-source-secrets"
  role = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameters", "ssm:GetParameter"]
      Resource = "${local.migration_ssm_prefix}/*"
    }]
  })
}

resource "aws_ecs_task_definition" "migration" {
  count = local.migration_count

  family                   = "${local.name}-migration"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.migration_cpu
  memory                   = var.migration_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    # X86_64 regardless of var.cpu_architecture: this pulls a stock MySQL
    # image, not one we build, and the tag below is the x86 manifest.
    cpu_architecture = "X86_64"
  }

  container_definitions = jsonencode([{
    name = "migration"

    /**
     * AWS's public mirror of the official image, not Docker Hub.
     *
     * Docker Hub rate-limits anonymous pulls per source IP. A Fargate task has
     * a fresh public IP each time, which usually gets away with it — and
     * "usually" is not a property you want in the one hour when the platform
     * is frozen and waiting for this container to start.
     */
    image     = "public.ecr.aws/docker/library/mysql:8.0"
    essential = true

    # No command here on purpose. Every run supplies its own through
    # `--overrides`, so the thing being executed is visible in the command that
    # launched it and in CloudTrail, rather than buried in a revision.
    entryPoint = ["/bin/sh", "-c"]
    command    = ["echo 'This task does nothing without an override. See infra/scripts/migrate-data.sh'; exit 64"]

    environment = [
      { name = "TARGET_HOST", value = aws_db_instance.main.address },
      { name = "TARGET_PORT", value = tostring(aws_db_instance.main.port) },
      { name = "TARGET_DB", value = var.db_name },
      { name = "TARGET_USER", value = var.db_username },
    ]

    secrets = concat(
      [{ name = "TARGET_PASSWORD", valueFrom = "${local.ssm_prefix}/DB_PASSWORD" }],
      [for n in local.migration_source_names : {
        name = n, valueFrom = "${local.migration_ssm_prefix}/${n}"
      }],
    )

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.migration[0].name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "migration"
      }
    }
  }])

  tags = { Name = "${local.name}-migration" }
}

output "migration_task_family" {
  description = "Empty until enable_data_migration = true."
  value       = local.migration_count > 0 ? aws_ecs_task_definition.migration[0].family : ""
}
