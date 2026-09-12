/**
 * The environment the API runs with, and the gate that refuses a half-set one.
 *
 * THE HISTORY THIS IS BUILT AROUND
 * --------------------------------
 * Moving this platform's secrets to environment variables was attempted once
 * before and took production down: the code was switched to read `process.env`
 * while the host had never had the variables set. `config/requiredEnv.js` and
 * `/health/env` exist because of that day, and the migration plan makes
 * `/health/env` the gate before any traffic moves.
 *
 * WHY TERRAFORM DOES NOT CREATE THESE WITH PLACEHOLDERS
 * -----------------------------------------------------
 * The obvious shortcut is for Terraform to create every parameter with a
 * "REPLACE_ME" value and let somebody fill them in. That would defeat the one
 * check the platform has: `presence()` reports which names are SET, and a
 * placeholder is set. The deploy would go green on a JWT_SECRET of
 * "REPLACE_ME" and the first guest to log in would find out.
 *
 * So the split is:
 *
 *   Terraform owns what it KNOWS      DB_HOST, DB_NAME, DB_USER, DB_PASSWORD,
 *                                     DB_PORT  (rds.tf and below)
 *   An operator supplies the rest     JWT_SECRET, CLOUDINARY_*, and every
 *                                     optional key, via infra/scripts/put-parameters.sh
 *                                     run from their own machine
 *
 * and the data sources below make `terraform plan` FAIL, by name, if one of
 * the ones Terraform cannot know is missing. Failing at plan time is the whole
 * point: the alternative is failing at 2am on a task that will not start, or
 * worse, starting.
 */

resource "aws_ssm_parameter" "db_port" {
  name  = "/aajoo/${var.env}/DB_PORT"
  type  = "String"
  value = tostring(aws_db_instance.main.port)
  tags  = { Name = "${local.name}-db-port" }
}

/**
 * The four this stack cannot invent.
 *
 * A JWT secret Terraform generated would be fine for a fresh platform and
 * wrong for this one: every session token already issued is signed with the
 * current secret, and regenerating it would sign every guest out at cutover.
 * The Cloudinary keys belong to an account that already exists.
 *
 * `data` rather than `resource`, so Terraform reads them and never writes
 * them. If one is absent, plan stops and names it.
 */
locals {
  operator_supplied = toset([
    "JWT_SECRET",
    "CLOUDINARY_CLOUD_NAME",
    "CLOUDINARY_API_KEY",
    "CLOUDINARY_API_SECRET",
  ])
}

data "aws_ssm_parameter" "operator_supplied" {
  for_each = local.operator_supplied
  name     = "/aajoo/${var.env}/${each.key}"

  # Terraform reads the NAME to build the task definition; it never needs the
  # value, and with_decryption off means the plaintext never enters state.
  with_decryption = false
}

/**
 * Everything else the container should be given, by name.
 *
 * Optional in `requiredEnv.js` means the service boots without it and a
 * feature degrades — several of them loudly, and one silently until a host
 * cannot be paid (FIELD_ENCRYPTION_KEY). They are listed here so the task
 * definition injects whatever exists, and absent ones simply are not passed:
 * that is the same behaviour as Render today, and the reason `/health/env`
 * reports presence rather than assuming it.
 *
 * Adding a variable later is one line in this list plus one run of
 * put-parameters.sh. It is a variable rather than a hardcoded list so an
 * environment can carry a different set without editing this file.
 */
variable "optional_parameter_names" {
  description = "Optional env vars to inject if they exist in SSM."
  type        = list(string)
  default = [
    "MAIL_EMAIL", "MAIL_PASSWORD", "MAIL_FROM", "BREVO_API_KEY",
    "RAZORPAY_KEY_ID", "RAZORPAY_KEY_SECRET",
    "FIELD_ENCRYPTION_KEY",
    "FRONTEND_URL", "DB_DIALECT",
    "BOTPENGUIN_API_TOKEN", "ADMIN_API_TOKEN", "FIREBASE_PROJECT_ID",
    "SAFETY_ALERT_EMAIL",
    "HEALTH_TOKEN",
  ]
}

/**
 * HEALTH_TOKEN is on that list for a reason.
 *
 * `/health/env` is the migration's gate, and it is only readable with the
 * token. It has been unset on Render since the cutover, which is why
 * `dbCutoverSafe` has never been checked from outside (master list §2.4).
 * Setting it here is a one-line difference between "we believe the
 * environment is complete" and "we checked".
 */

data "aws_ssm_parameters_by_path" "optional" {
  path            = "/aajoo/${var.env}"
  with_decryption = false
}

locals {
  # Which of the optional names actually exist right now. Injecting a name with
  # no parameter behind it makes the task fail to start with an opaque error.
  present_optional = [
    for n in var.optional_parameter_names :
    n if contains([for p in data.aws_ssm_parameters_by_path.optional.names : reverse(split("/", p))[0]], n)
  ]
}
