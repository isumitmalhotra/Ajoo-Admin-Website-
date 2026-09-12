/**
 * Aajoo Homes on AWS — provider and state.
 *
 * Written rather than clicked, on the client's instruction (2026-09-13).
 * Infrastructure built in a console is infrastructure nobody can reproduce,
 * diff or hand over; this can be read, reviewed and re-applied.
 *
 * STATE lives locally until the account can create an S3 bucket. That is not a
 * preference — see README: the account is new and AWS account verification was
 * still in progress when this was written, so nothing could be provisioned yet,
 * including the state bucket. The remote backend below is written out and
 * commented so that switching to it is one uncomment and a `terraform init
 * -migrate-state`, not a decision to make again later.
 *
 * Do NOT commit terraform.tfstate. It contains the RDS endpoint and, depending
 * on the resource, secrets. .gitignore in this directory covers it.
 */
terraform {
  # 1.10 for S3 native state locking (use_lockfile), which is why there is no
  # DynamoDB lock table below: one fewer resource to create before the first
  # apply can run.
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Uncomment once the bucket and lock table exist (see README §Bootstrap).
  # backend "s3" {
  #   bucket       = "aajoo-terraform-state"
  #   key          = "platform/terraform.tfstate"
  #   region       = "ap-south-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}

provider "aws" {
  region = var.region

  # Every resource carries these, so a bill can be read by service and an
  # orphan can be traced back to the thing that made it. The account is shared
  # with nothing today, but the Cloudinary account was shared with nothing once
  # either.
  default_tags {
    tags = {
      Project   = "aajoo-homes"
      ManagedBy = "terraform"
      Repo      = "ajoo-admin-website/infra/terraform"
    }
  }
}
