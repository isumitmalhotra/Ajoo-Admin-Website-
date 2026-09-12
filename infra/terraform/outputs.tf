/**
 * What the next day's work needs, and nothing a log should not carry.
 *
 * The database ENDPOINT is here because Day 2 needs it; the password is not,
 * and cannot be — it exists only in SSM. `terraform output` on this directory
 * is safe to paste into a ticket.
 */

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Where the ALB and the Fargate tasks go."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Where RDS lives. No route to the internet."
  value       = aws_subnet.private[*].id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "tasks_security_group_id" {
  value = aws_security_group.tasks.id
}

output "ecr_repository_urls" {
  description = "docker push targets, one per image."
  value       = { for k, r in aws_ecr_repository.app : k => r.repository_url }
}

output "db_endpoint" {
  description = "Host only. The password lives in SSM at /aajoo/<env>/DB_PASSWORD."
  value       = aws_db_instance.main.address
}

output "db_port" {
  value = aws_db_instance.main.port
}
