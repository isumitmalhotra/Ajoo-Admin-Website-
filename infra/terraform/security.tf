/**
 * Three security groups, and the chain between them is the whole design.
 *
 *   the internet  →  alb        (443, and 80 only to redirect)
 *   alb           →  tasks      (8080, from the ALB's group and nothing else)
 *   tasks         →  rds        (3306, from the tasks' group and nothing else)
 *
 * Each rule names the group it accepts FROM rather than a CIDR. A rule written
 * as a CIDR keeps working when the thing at that address changes; a rule
 * written as a group only ever admits the thing this file created.
 */

resource "aws_security_group" "alb" {
  name        = "${local.name}-alb"
  description = "Public entry. The only group with an open ingress."
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${local.name}-alb" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from anywhere"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

/**
 * Port 80 is open to REDIRECT, not to serve.
 *
 * The listener answers every :80 request with a 301 to :443 (see alb.tf when
 * it lands). Closing it instead would leave a guest who types the hostname
 * without the scheme looking at a timeout rather than the site.
 */
resource "aws_vpc_security_group_ingress_rule" "alb_http_redirect" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from anywhere, redirected to HTTPS"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_out" {
  security_group_id = aws_security_group.alb.id
  description       = "To the tasks"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "tasks" {
  name        = "${local.name}-tasks"
  description = "Fargate tasks. Public subnet, but reachable only from the ALB."
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${local.name}-tasks" }
}

/**
 * The one rule that makes a public subnet safe.
 *
 * These tasks carry public IPs so the VPC needs no NAT gateway. What keeps
 * them private is this: the only thing that may open a connection to them is
 * the load balancer's security group. Widening this rule to a CIDR is the
 * change that would quietly undo that, which is why it is worth a comment
 * rather than a line.
 */
resource "aws_vpc_security_group_ingress_rule" "tasks_from_alb" {
  security_group_id            = aws_security_group.tasks.id
  description                  = "App port, from the ALB only"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}

/**
 * Outbound is open, and has to be.
 *
 * The API talks to Razorpay, DIDIT, BotPenguin, Brevo, Firebase, Google
 * Maps/Places and Cloudinary, and pulls its own image from ECR. Restricting
 * egress to a list of addresses would mean chasing every one of those
 * providers' IP ranges for ever.
 */
resource "aws_vpc_security_group_egress_rule" "tasks_out" {
  security_group_id = aws_security_group.tasks.id
  description       = "Third-party APIs, ECR, SSM, logs"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "rds" {
  name        = "${local.name}-rds"
  description = "MySQL. Reachable from the tasks and from nothing else."
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${local.name}-rds" }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_tasks" {
  security_group_id            = aws_security_group.rds.id
  description                  = "MySQL from the tasks only"
  referenced_security_group_id = aws_security_group.tasks.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}

/**
 * No egress rule at all.
 *
 * A database does not start conversations. Terraform removes the default
 * allow-all when a group is declared with no egress, which is the intent here
 * rather than an omission.
 */
