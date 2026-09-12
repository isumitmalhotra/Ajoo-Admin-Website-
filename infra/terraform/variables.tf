variable "region" {
  description = "Mumbai. Guests and hosts are in India, and the plan's decision 1."
  type        = string
  default     = "ap-south-1"
}

variable "env" {
  description = "Name that goes into every resource name. One environment today."
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "Room for a second AZ and a growth tier without renumbering."
  type        = string
  default     = "10.20.0.0/16"
}

/**
 * TWO availability zones, and no more.
 *
 * RDS requires a subnet group spanning at least two AZs even for a
 * single-AZ instance, so two is the floor rather than a resilience choice.
 * The API runs at exactly one task (see the plan §3 — in-process rate
 * limiter, SEO cache, scheduler and Socket.io all assume one process), so a
 * third AZ would buy nothing today and cost cross-AZ traffic.
 */
variable "az_count" {
  description = "How many AZs to spread subnets across."
  type        = number
  default     = 2
}

variable "db_instance_class" {
  description = "db.t4g.micro is ample for a 43 MB database; decision 5 revisits it."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "GB of gp3. Well above the 43 MB in use; the floor that gets sane IOPS."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "aajoo"
}

variable "db_username" {
  description = "Master user. NOT a secret, and not the password — see rds.tf."
  type        = string
  default     = "aajoo_admin"
}

variable "backup_retention_days" {
  description = "Automated backups. Seven days, with point-in-time recovery on."
  type        = number
  default     = 7
}

/**
 * Deletion protection, ON.
 *
 * A `terraform destroy` that takes the production database with it is the one
 * mistake this whole file exists to make hard. Turning it off is a deliberate
 * edit, reviewed like any other.
 */
variable "db_deletion_protection" {
  description = "Refuse to delete the database."
  type        = bool
  default     = true
}
