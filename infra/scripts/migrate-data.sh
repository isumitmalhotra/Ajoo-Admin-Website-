#!/usr/bin/env bash
#
# Copy the live database into RDS, or verify that it arrived intact.
#
#   ./migrate-data.sh copy      # dump the source straight into RDS
#   ./migrate-data.sh verify    # compare the two, table by table
#
# Both run as a one-off Fargate task inside the VPC, because RDS is private and
# admits port 3306 from the tasks security group and nothing else. Nothing is
# downloaded; there is no dump file on anybody's machine at any point.
#
# PREREQUISITES
#   1. enable_data_migration = true in terraform.tfvars, and applied.
#   2. The source credentials in SSM:
#        aws ssm put-parameter --type SecureString --name /aajoo/prod/migration/SOURCE_HOST     --value '…'
#        …SOURCE_PORT, SOURCE_USER, SOURCE_PASSWORD, SOURCE_DB
#      Delete them the moment the cutover is signed off:
#        aws ssm delete-parameters --names /aajoo/prod/migration/SOURCE_{HOST,PORT,USER,PASSWORD,DB}
set -euo pipefail

MODE="${1:-}"
ENVNAME="${ENVNAME:-prod}"
REGION="${AWS_REGION:-ap-south-1}"
CLUSTER="aajoo-${ENVNAME}"
FAMILY="aajoo-${ENVNAME}-migration"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$MODE" in
  copy|verify) ;;
  *) echo "usage: $0 <copy|verify>" >&2; exit 2 ;;
esac

SCRIPT="${HERE}/migration/${MODE}.sh"
[ -f "$SCRIPT" ] || { echo "missing $SCRIPT" >&2; exit 2; }

# The script is shipped base64-encoded, and that is not obfuscation.
#
# The override is JSON, inside a shell argument, containing a shell program
# that itself contains quotes, backticks and $. Every layer wants to escape
# something, and one mis-escaped backtick in a program that runs `mysql` on a
# production database is not a class of bug worth risking to save a pipe.
# Encoded, the program crosses all three layers as one opaque token.
#
# `tr -d '\r'` first, and it is not paranoia. .gitattributes checks these out
# with LF, but anything that opens one in a Windows editor and saves can put
# the carriage returns back, and the result is a shebang line reading
# "#!/usr/bin/env bash\r" — "bad interpreter", inside the freeze window, on the
# step that moves the database. Stripping here means the file on disk cannot
# ruin the run whatever a text editor did to it.
B64="$(tr -d '\r' < "$SCRIPT" | base64 | tr -d '\n')"

echo "cluster: ${CLUSTER}"
echo "task   : ${FAMILY}"
echo "mode   : ${MODE}"

SUBNETS=$(aws ec2 describe-subnets --region "$REGION" \
  --filters "Name=tag:Name,Values=aajoo-${ENVNAME}-public-*" \
  --query 'Subnets[].SubnetId' --output text | tr '\t' ',')
SG=$(aws ec2 describe-security-groups --region "$REGION" \
  --filters "Name=group-name,Values=aajoo-${ENVNAME}-tasks" \
  --query 'SecurityGroups[0].GroupId' --output text)

[ -n "$SUBNETS" ] || { echo "no public subnets found — is the stack applied?" >&2; exit 1; }

OVERRIDES=$(cat <<JSON
{"containerOverrides":[{"name":"migration","command":["echo ${B64} | base64 -d | bash"]}]}
JSON
)

TASK=$(aws ecs run-task --region "$REGION" \
  --cluster "$CLUSTER" \
  --task-definition "$FAMILY" \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[${SUBNETS}],securityGroups=[${SG}],assignPublicIp=ENABLED}" \
  --overrides "$OVERRIDES" \
  --query 'tasks[0].taskArn' --output text)

echo "task: ${TASK}"
echo "waiting…"
aws ecs wait tasks-stopped --region "$REGION" --cluster "$CLUSTER" --tasks "$TASK"

ID="${TASK##*/}"
echo "--- log ---"
aws logs get-log-events --region "$REGION" \
  --log-group-name "/aajoo/${ENVNAME}/migration" \
  --log-stream-name "migration/migration/${ID}" \
  --query 'events[].message' --output text 2>/dev/null | tr '\t' '\n' || \
  echo "(log stream not readable yet — aws logs tail /aajoo/${ENVNAME}/migration)"

CODE=$(aws ecs describe-tasks --region "$REGION" --cluster "$CLUSTER" --tasks "$TASK" \
  --query 'tasks[0].containers[0].exitCode' --output text)
REASON=$(aws ecs describe-tasks --region "$REGION" --cluster "$CLUSTER" --tasks "$TASK" \
  --query 'tasks[0].stoppedReason' --output text)

echo "--- exit ${CODE} (${REASON}) ---"
if [ "$CODE" != "0" ]; then
  echo "FAILED. Do not proceed to the next runbook step." >&2
  exit 1
fi
echo "OK."
