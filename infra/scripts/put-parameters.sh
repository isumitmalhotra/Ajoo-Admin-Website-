#!/usr/bin/env bash
#
# Put the application's environment into SSM Parameter Store.
#
# Terraform owns what it knows — the database host, name, user, port and the
# password it generated. It deliberately does NOT create the rest with
# placeholder values, because `/health/env` reports which names are SET, and a
# placeholder is set: the deploy would go green on a JWT_SECRET of "REPLACE_ME"
# and the first guest to log in would find out. So the rest come from here.
#
# Run it from YOUR machine, against a file only you hold. The values never go
# through a chat, a ticket, or this repository.
#
#   cp .env.aws.example .env.aws     # then fill it in
#   ./put-parameters.sh .env.aws prod
#
# Re-running is safe: every parameter is overwritten with what the file says,
# so the file is the source of truth and drift gets corrected rather than
# accumulating.
set -euo pipefail

FILE="${1:-}"
ENVNAME="${2:-prod}"
REGION="${AWS_REGION:-ap-south-1}"

if [[ -z "$FILE" || ! -f "$FILE" ]]; then
  echo "usage: $0 <env-file> [env-name]   (e.g. $0 .env.aws prod)" >&2
  exit 2
fi

# Anything on this list is stored encrypted. The default is encrypted: a name
# is only ever a String if there is a reason, and the reason is that something
# needs to read it without permission to decrypt.
PLAIN_NAMES=("FRONTEND_URL" "DB_DIALECT" "FIREBASE_PROJECT_ID" "MAIL_FROM" "SAFETY_ALERT_EMAIL")

is_plain() {
  local n="$1"
  for p in "${PLAIN_NAMES[@]}"; do [[ "$n" == "$p" ]] && return 0; done
  return 1
}

written=0
skipped=0

while IFS= read -r line || [[ -n "$line" ]]; do
  # Comments and blanks.
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line// }" ]] && continue
  [[ "$line" != *=* ]] && continue

  name="${line%%=*}"
  value="${line#*=}"
  name="$(echo "$name" | tr -d '[:space:]')"
  # Strip one layer of surrounding quotes, which .env files usually carry.
  value="${value%\"}"; value="${value#\"}"
  value="${value%\'}"; value="${value#\'}"

  if [[ -z "$value" ]]; then
    # An empty value is not the same as an absent one, and absent is what we
    # want: `/health/env` should say "missing", not report a name that is set
    # to nothing.
    echo "  skip   $name (empty)"
    skipped=$((skipped + 1))
    continue
  fi

  if is_plain "$name"; then type="String"; else type="SecureString"; fi

  # --overwrite, and the value passed with --value on purpose rather than
  # echoed: nothing here prints a secret, and the only place it appears is the
  # argument list of a command running on your own machine.
  aws ssm put-parameter \
    --region "$REGION" \
    --name "/aajoo/${ENVNAME}/${name}" \
    --type "$type" \
    --value "$value" \
    --overwrite \
    --output text >/dev/null

  echo "  wrote  $name  ($type)"
  written=$((written + 1))
done < "$FILE"

echo
echo "$written written, $skipped skipped, into /aajoo/${ENVNAME}/ in ${REGION}."
echo
echo "Next: terraform plan. It reads the four it cannot invent — JWT_SECRET and"
echo "the three CLOUDINARY_* — and fails by name if one of them is missing."
