/**
 * One repository per image. Both Dockerfiles already exist in the app repos —
 * the backend's runs as non-root under tini on 8080 with a HEALTHCHECK that
 * hits /health without touching the database, and the frontend's ships the SPA
 * and the SEO renderer as one image. Nothing to write; somewhere to push.
 */

locals {
  images = toset(["api", "web"])
}

/**
 * The repositories are SHARED between environments, and only one Terraform
 * state may own them.
 *
 * Sharing is the point: staging should run the exact artifact that will run in
 * production, promoted rather than rebuilt — a staging sign-off on a different
 * binary proves nothing. But two states both declaring `aajoo/api` means the
 * second apply fails with "already exists". So the production workspace
 * creates them and every other workspace looks them up.
 */
variable "create_shared_resources" {
  description = "True in exactly ONE workspace. Staging sets it false."
  type        = bool
  default     = true
}

resource "aws_ecr_repository" "app" {
  for_each = var.create_shared_resources ? local.images : toset([])

  name                 = "aajoo/${each.key}"
  image_tag_mutability = "IMMUTABLE"

  /**
   * IMMUTABLE tags, deliberately.
   *
   * The app side of this project learned the same lesson the hard way: one
   * build number must mean one artifact, because a tester holding "build 46"
   * that is really build 45 re-reports seven fixed defects. A mutable `latest`
   * is that bug at deployment scale — a task definition that says `latest`
   * cannot tell you what is running. Deployments reference the commit SHA.
   */

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "aajoo-${each.key}" }
}

data "aws_ecr_repository" "app" {
  for_each = var.create_shared_resources ? toset([]) : local.images
  name     = "aajoo/${each.key}"
}

locals {
  # One place that answers "where do I push, and what do I pull" whichever
  # workspace is running.
  ecr_urls = var.create_shared_resources ? {
    for k, r in aws_ecr_repository.app : k => r.repository_url
    } : {
    for k, r in data.aws_ecr_repository.app : k => r.repository_url
  }
}

/**
 * Keep the last 20 images, expire the rest.
 *
 * Storage is $0.10/GB/month and these images are not small. Twenty is enough
 * to roll back past a bad week without keeping every build since launch. Only
 * the workspace that owns the repositories writes this.
 */
resource "aws_ecr_lifecycle_policy" "app" {
  for_each   = aws_ecr_repository.app
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the last 20 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 20
      }
      action = { type = "expire" }
    }]
  })
}
