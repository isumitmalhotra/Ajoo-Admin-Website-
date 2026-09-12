/**
 * Two roles, and the difference between them matters.
 *
 *   execution role   what ECS ITSELF uses to start the task: pull the image,
 *                    read the parameters it is told to inject, write logs
 *   task role        what the APPLICATION uses once it is running
 *
 * Conflating them is the common shortcut and it hands the running container
 * the power to read every parameter in the account. The application here needs
 * neither — it talks to Cloudinary, Razorpay and the database over the network,
 * not to the AWS API — so its task role is deliberately empty.
 */

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ── What ECS uses to start a task ──────────────────────────────────────────
resource "aws_iam_role" "task_execution" {
  name = "${local.name}-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${local.name}-task-execution" }
}

resource "aws_iam_role_policy_attachment" "task_execution_managed" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

/**
 * Parameters under THIS environment's path, and nothing else.
 *
 * The managed policy above covers ECR and logs; it does not cover SSM, and the
 * usual fix is to bolt on AmazonSSMReadOnlyAccess, which grants every parameter
 * in the account. Scoped to `/aajoo/<env>/*` instead, so a second environment's
 * secrets are out of reach even from this one's task starter.
 */
resource "aws_iam_role_policy" "task_execution_ssm" {
  name = "read-app-parameters"
  role = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameters", "ssm:GetParameter"]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/aajoo/${var.env}/*"
      },
      {
        # SecureStrings are encrypted with the account's default SSM key, and
        # decrypting them needs this. Confined to SSM's own use of the key.
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      },
    ]
  })
}

# ── What the application itself gets ───────────────────────────────────────
/**
 * Empty, and that is the design.
 *
 * The API's integrations are all HTTP to third parties. If something later
 * genuinely needs AWS — an S3 bucket for invoices, say — it gets a statement
 * here, named, rather than the execution role being reused because it happened
 * to work.
 */
resource "aws_iam_role" "task" {
  name = "${local.name}-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${local.name}-task" }
}

/**
 * ECS Exec, off by default.
 *
 * `aws ecs execute-command` into a running container is the fastest way to
 * diagnose a task that will not start, and a shell on a box holding live
 * secrets. Turned on for an incident, turned off after — a variable rather
 * than a permanent grant.
 */
variable "enable_ecs_exec" {
  description = "Allow a shell into the running task. For an incident, not for a Tuesday."
  type        = bool
  default     = false
}

resource "aws_iam_role_policy" "task_exec_channel" {
  count = var.enable_ecs_exec ? 1 : 0
  name  = "ecs-exec"
  role  = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel",
      ]
      Resource = "*"
    }]
  })
}
