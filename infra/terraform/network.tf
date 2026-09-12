/**
 * The VPC, and the deliberate absence of a NAT gateway.
 *
 * The September comparison warned about cost creep, and a NAT gateway is the
 * clearest example: ~$32/month, forever, to give private tasks a route out.
 * So the Fargate tasks run in PUBLIC subnets with public IPs, and are kept
 * private by their security group instead — inbound only from the ALB, nothing
 * else (see security.tf). The database stays in private subnets with no route
 * to the internet at all.
 *
 * That is a real trade and worth naming: a task with a public IP is reachable
 * at the network layer if its security group is ever widened by accident,
 * where a task in a private subnet is not. The mitigation is that the security
 * group is written here, reviewed here, and has exactly one ingress rule.
 */

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "aajoo-${var.env}"
  azs  = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # RDS endpoints are names, not addresses

  tags = { Name = local.name }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = local.name }
}

# ── Public: the ALB, and the Fargate tasks ─────────────────────────────────
resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.main.id
  availability_zone       = local.azs[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true

  tags = { Name = "${local.name}-public-${local.azs[count.index]}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${local.name}-public" }
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ── Private: the database, and nothing that needs to reach the internet ────
resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 100)

  tags = { Name = "${local.name}-private-${local.azs[count.index]}" }
}

/**
 * No route table of its own, on purpose.
 *
 * Private subnets fall back to the VPC's main route table, which routes only
 * within the VPC. There is no path out and nothing to misconfigure into one.
 */
resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_vpc.main.default_route_table_id
}
