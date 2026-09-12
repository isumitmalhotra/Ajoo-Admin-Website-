/**
 * GitHub Actions deploys without a single long-lived credential.
 *
 * The alternative is an IAM user's access key pasted into GitHub secrets. That
 * key then exists for ever, in a place several people can read, and rotating it
 * is a job nobody schedules. OIDC replaces it: GitHub presents a short-lived
 * token that proves which repository and which branch is asking, AWS checks
 * that against the trust policy below, and hands back credentials good for the
 * length of one job.
 *
 * Nothing to leak, nothing to rotate, and a stolen workflow file from another
 * repository cannot assume this role.
 */

variable "github_repositories" {
  description = <<-EOT
    The repositories allowed to deploy, "owner/name".

    Exact strings, including the typo in the website repository's name — it is
    what GitHub actually calls it, and a trust policy that does not match
    letter for letter simply refuses.
  EOT
  type        = list(string)
  default = [
    "nameeshPatiyal100/aajaoBackend",
    "nameeshPatiyal100/Aajao-Admin-WebSIite",
  ]
}

variable "github_deploy_ref" {
  description = "Only this ref may deploy. A branch, not a wildcard."
  type        = string
  default     = "refs/heads/main"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_shared_resources ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]

  /**
   * AWS stopped validating this thumbprint for GitHub's provider in 2023 and
   * now trusts the certificate chain itself. It is still a required field, so
   * the documented value goes here rather than a fetched one: a `tls_certificate`
   * data source would make every plan depend on a live TLS handshake with
   * GitHub, which is a strange thing for a plan to need.
   */
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = { Name = "github-actions" }
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_shared_resources ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  github_oidc_arn = var.create_shared_resources ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

resource "aws_iam_role" "github_deploy" {
  name = "${local.name}-github-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.github_oidc_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          /**
           * The `sub` claim is the whole security boundary.
           *
           * It names repository AND ref, so a pull request from a fork, a
           * feature branch, or another repository in the same account cannot
           * assume this role — only a workflow running on main in one of the
           * two repositories listed. `StringEquals` on a list rather than
           * `StringLike` with a wildcard, because "repo:owner/*" would trust
           * every repository that owner ever creates.
           */
          "token.actions.githubusercontent.com:sub" = [
            for r in var.github_repositories : "repo:${r}:ref:${var.github_deploy_ref}"
          ]
        }
      }
    }]
  })

  tags = { Name = "${local.name}-github-deploy" }
}

/**
 * What a deploy is allowed to do, and deliberately not more.
 *
 * Push an image, register a new task definition, tell the service to use it,
 * and run the migration task. It cannot read the application's secrets, create
 * a database, or touch IAM.
 */
resource "aws_iam_role_policy" "github_deploy" {
  name = "deploy"
  role = aws_iam_role.github_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "GetAnEcrLoginToken"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*" # this action takes no resource
      },
      {
        Sid    = "PushToOurRepositoriesOnly"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = [
          for k in local.images :
          "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/aajoo/${k}"
        ]
      },
      {
        Sid    = "DeployTheServices"
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition", # takes no resource
          "ecs:DescribeTaskDefinition",
        ]
        Resource = "*"
      },
      {
        Sid    = "UpdateOnlyThisClustersServices"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:RunTask",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
        ]
        Resource = "*"
        Condition = {
          ArnEquals = { "ecs:cluster" = aws_ecs_cluster.main.arn }
        }
      },
      {
        /**
         * PassRole, scoped to exactly two roles.
         *
         * Registering a task definition means naming the roles the task will
         * run as, and IAM treats that as handing over those roles. Unscoped,
         * this one statement would let a deploy run a container as any role in
         * the account — which is the usual way a CI pipeline quietly becomes
         * an administrator.
         */
        Sid      = "PassOnlyTheTaskRoles"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = [aws_iam_role.task_execution.arn, aws_iam_role.task.arn]
        Condition = {
          StringEquals = { "iam:PassedToService" = "ecs-tasks.amazonaws.com" }
        }
      },
      {
        Sid      = "ReadDeployLogs"
        Effect   = "Allow"
        Action   = ["logs:GetLogEvents", "logs:DescribeLogStreams"]
        Resource = "${aws_cloudwatch_log_group.api.arn}:*"
      },
      {
        Sid      = "InvalidateTheCdnAfterAWebDeploy"
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation"]
        Resource = aws_cloudfront_distribution.web.arn
      },
    ]
  })
}

output "github_deploy_role_arn" {
  description = "Put this in each repository's Actions variables as AWS_DEPLOY_ROLE. It is an ARN, not a secret."
  value       = aws_iam_role.github_deploy.arn
}
