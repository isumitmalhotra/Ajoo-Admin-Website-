/**
 * One repository per image. Both Dockerfiles already exist in the app repos —
 * the backend's runs as non-root under tini on 8080 with a HEALTHCHECK that
 * hits /health without touching the database, and the frontend's ships the SPA
 * and the SEO renderer as one image. Nothing to write; somewhere to push.
 */

locals {
  images = toset(["api", "web"])
}

resource "aws_ecr_repository" "app" {
  for_each = local.images

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

/**
 * Keep the last 20 images, expire the rest.
 *
 * Storage is $0.10/GB/month and these images are not small. Twenty is enough
 * to roll back past a bad week without keeping every build since launch.
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
