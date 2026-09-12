/**
 * The alarms that would have told somebody, on this platform specifically.
 *
 * A generic alarm set watches CPU. The ones below are chosen against things
 * that have actually gone wrong here or that this shape makes likely:
 *
 *   the API runs at ONE task      so "zero tasks running" is a total outage,
 *                                 not a degraded service
 *   the database is single-AZ     so storage and connections are the two ways
 *                                 it stops answering
 *   the SEO renderer serves the   so 5xx from the web target group is a
 *   public site                   crawlable error page, not just a bad request
 *
 * Every one of them notifies the same place, because an alarm nobody receives
 * is a dashboard.
 */

variable "alarm_email" {
  description = <<-EOT
    Where alarms go. Empty means no subscription is created and the alarms fire
    into an unattended topic — which is worth knowing rather than discovering.
  EOT
  type        = string
  default     = ""
}

resource "aws_sns_topic" "alarms" {
  name = "${local.name}-alarms"
  tags = { Name = "${local.name}-alarms" }
}

/**
 * The subscription is only created when there is an address, and AWS then
 * emails to ask for confirmation. Until somebody clicks that link the topic has
 * no confirmed subscriber and nothing is delivered — so confirming it is part
 * of the job, not an afterthought.
 */
resource "aws_sns_topic_subscription" "alarms_email" {
  count     = var.alarm_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

locals {
  alarm_actions = [aws_sns_topic.alarms.arn]
}

# ── The API, which has nowhere to fail over to ─────────────────────────────
/**
 * Zero running tasks. The one that matters most.
 *
 * At desired_count 1 there is no partial failure: the API is up or the platform
 * is down. `treat_missing_data = "breaching"` because a metric that stops
 * arriving is itself the symptom — a service with no tasks publishes nothing.
 */
resource "aws_cloudwatch_metric_alarm" "api_no_tasks" {
  alarm_name          = "${local.name}-api-no-running-tasks"
  alarm_description   = "The API has no running task. The platform is down."
  namespace           = "ECS/ContainerInsights"
  metric_name         = "RunningTaskCount"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.api.name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
  tags          = { Name = "${local.name}-api-no-running-tasks" }
}

resource "aws_cloudwatch_metric_alarm" "api_unhealthy_hosts" {
  alarm_name          = "${local.name}-api-unhealthy"
  alarm_description   = "The load balancer cannot get a healthy answer from /health."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.api.arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
  tags          = { Name = "${local.name}-api-unhealthy" }
}

/**
 * 5xx from the application, not from the load balancer.
 *
 * `HTTPCode_Target_5XX_Count` is the API returning errors; the ELB's own 5xx
 * usually means no healthy target, which the alarm above already covers. Ten in
 * five minutes rather than one, because a single 500 is a bug report and a
 * stream of them is an incident.
 */
resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "${local.name}-api-5xx"
  alarm_description   = "The API is returning server errors."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 10
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.api.arn_suffix
  }

  alarm_actions = local.alarm_actions
  tags          = { Name = "${local.name}-api-5xx" }
}

# ── The website ────────────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "web_unhealthy_hosts" {
  alarm_name          = "${local.name}-web-unhealthy"
  alarm_description   = "The website's renderer is not answering."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.web.arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
  tags          = { Name = "${local.name}-web-unhealthy" }
}

# ── The database ───────────────────────────────────────────────────────────
/**
 * Free storage, with a threshold that leaves time to act.
 *
 * Storage autoscaling is on (max 100 GB), so this should never fire — which is
 * exactly why it is worth having: if it does, autoscaling has failed and the
 * database is minutes from read-only. 2 GB on a 20 GB volume.
 */
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${local.name}-rds-low-storage"
  alarm_description   = "Under 2 GB free. Storage autoscaling has not kept up."
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 2147483648
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "missing"

  dimensions = { DBInstanceIdentifier = aws_db_instance.main.identifier }

  alarm_actions = local.alarm_actions
  tags          = { Name = "${local.name}-rds-low-storage" }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${local.name}-rds-cpu"
  alarm_description   = "Sustained high CPU on a db.t4g.micro — usually a query, not traffic."
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  threshold           = 85
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = { DBInstanceIdentifier = aws_db_instance.main.identifier }

  alarm_actions = local.alarm_actions
  tags          = { Name = "${local.name}-rds-cpu" }
}

/**
 * Connections, because a leak looks like slowness before it looks like an
 * error. The platform runs one API task with a Sequelize pool; a climb here
 * means connections are not being returned.
 */
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${local.name}-rds-connections"
  alarm_description   = "Connection count climbing — look for a pool that is not releasing."
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 50
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = { DBInstanceIdentifier = aws_db_instance.main.identifier }

  alarm_actions = local.alarm_actions
  tags          = { Name = "${local.name}-rds-connections" }
}

output "alarm_topic_arn" {
  description = "Subscribe more people here. An email subscription needs its confirmation link clicked."
  value       = aws_sns_topic.alarms.arn
}
