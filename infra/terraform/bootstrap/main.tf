/**
 * The state bucket, and nothing else.
 *
 * This is a SEPARATE Terraform root for one unavoidable reason: the bucket
 * that holds the platform's state cannot itself be described in the state it
 * holds. Something has to exist before the backend can point at it, so this
 * root keeps its own small state file locally and is applied exactly once.
 *
 *   cd infra/terraform/bootstrap
 *   terraform init && terraform apply
 *
 * Then uncomment the `backend "s3"` block in ../versions.tf and run
 * `terraform init -migrate-state` in the parent directory. Terraform reads the
 * local state, writes it to the bucket, and every apply after that is shared.
 *
 * Until that happens, the platform's state lives in ONE file on ONE laptop.
 * That is the whole reason this is Day 5 work rather than optional: a state
 * file that exists in one place is a platform that can be rebuilt by one
 * person, and only while that laptop is alive.
 */
terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "aajoo-homes"
      ManagedBy = "terraform"
      Repo      = "ajoo-admin-website/infra/terraform/bootstrap"
    }
  }
}

variable "region" {
  description = "Same region as the platform."
  type        = string
  default     = "ap-south-1"
}

variable "bucket_name" {
  description = "Must match `bucket` in ../versions.tf. Globally unique across all of AWS."
  type        = string
  default     = "aajoo-terraform-state"
}

resource "aws_s3_bucket" "state" {
  bucket = var.bucket_name

  /**
   * The one resource in this repository that must never be destroyed by a
   * command. Losing this bucket does not lose the infrastructure — it loses
   * Terraform's knowledge of it, which turns every future change into a manual
   * import of sixty resources.
   */
  lifecycle {
    prevent_destroy = true
  }

  tags = { Name = var.bucket_name }
}

/**
 * Versioning is the actual backup.
 *
 * State corruption is usually not "the file is gone" — it is an interrupted
 * apply writing a half-file, or two people applying at once. Versioning means
 * the previous good state is one `aws s3api list-object-versions` away.
 */
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

/**
 * State contains the RDS endpoint, security group ids, and — depending on the
 * resource — secrets. It is not a document, it is a credential.
 */
resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

/**
 * Every version for ever is a slow bill and a slowly growing pile of old
 * secrets. Ninety days is long enough to recover from any mistake anybody
 * notices, and short enough that a rotated password does not live in the
 * bucket indefinitely.
 */
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration { noncurrent_days = 90 }
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

output "bucket" {
  description = "Put this in ../versions.tf as the backend's `bucket`."
  value       = aws_s3_bucket.state.id
}

output "next_step" {
  value = <<-EOT
    1. Uncomment the backend "s3" block in ../versions.tf
    2. cd .. && terraform init -migrate-state
    3. Confirm when it asks. Then delete the local terraform.tfstate* files.
  EOT
}
