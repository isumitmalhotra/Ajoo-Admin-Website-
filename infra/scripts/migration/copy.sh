#!/usr/bin/env bash
#
# Runs INSIDE the one-off Fargate task. Never on a laptop.
#
# Everything it needs arrives as environment variables: SOURCE_* from the
# migration SSM path, TARGET_* from the platform's own parameters. No value is
# ever echoed, and the connection files below are written with umask 077 into a
# container that is destroyed when the task stops.
set -euo pipefail

# THE flag that matters in this whole file.
#
# Without pipefail, `mysqldump | sed | mysql` exits with the status of `mysql`.
# A dump that dies half way through — connection dropped, source restarted,
# table locked — still feeds valid SQL into the target, which applies it
# happily and exits 0. The task goes green, the runbook ticks the box, and the
# platform cuts over onto a database missing however many tables came after the
# break. It is the single most plausible way this cutover ends badly.
set -o pipefail

umask 077

cfg() { # cfg <file> <host> <port> <user> <password>
  cat > "$1" <<CFG
[client]
host=$2
port=$3
user=$4
password="$5"
default-character-set=utf8mb4
CFG
}

cfg /tmp/src.cnf "$SOURCE_HOST" "$SOURCE_PORT" "$SOURCE_USER" "$SOURCE_PASSWORD"
cfg /tmp/dst.cnf "$TARGET_HOST" "$TARGET_PORT" "$TARGET_USER" "$TARGET_PASSWORD"

echo "source: $SOURCE_USER@$SOURCE_HOST:$SOURCE_PORT/$SOURCE_DB"
echo "target: $TARGET_USER@$TARGET_HOST:$TARGET_PORT/$TARGET_DB"

# Reachability before anything destructive. A dump that fails after DROP TABLE
# has run on the target leaves the target worse than it found it.
mysql --defaults-file=/tmp/src.cnf -N -B -e "SELECT VERSION()" | sed 's/^/source version: /'
mysql --defaults-file=/tmp/dst.cnf -N -B -e "SELECT VERSION()" | sed 's/^/target version: /'

# --single-transaction gives a consistent snapshot of InnoDB tables WITHOUT
# locking them. It does nothing for MyISAM, which is silently dumped
# inconsistently mid-write. Say so before, not after.
NONINNO=$(mysql --defaults-file=/tmp/src.cnf -N -B -e "
  SELECT GROUP_CONCAT(table_name)
  FROM information_schema.tables
  WHERE table_schema='$SOURCE_DB' AND table_type='BASE TABLE' AND engine <> 'InnoDB'")
if [ -n "$NONINNO" ] && [ "$NONINNO" != "NULL" ]; then
  echo "WARNING: non-InnoDB tables, not covered by the consistent snapshot: $NONINNO"
  echo "WARNING: these are only safe while writes are frozen."
fi

echo "--- dumping and loading ---"
date -u +"start %Y-%m-%dT%H:%M:%SZ"

mysqldump --defaults-file=/tmp/src.cnf \
  --single-transaction \
  --quick \
  --routines --triggers --events \
  --hex-blob \
  --no-tablespaces \
  --set-gtid-purged=OFF \
  --column-statistics=0 \
  --default-character-set=utf8mb4 \
  "$SOURCE_DB" \
| sed -E '
    s/DEFINER=`[^`]*`@`[^`]*`//g;
    s#/\*!50013 SQL SECURITY DEFINER \*/##g;
  ' \
| mysql --defaults-file=/tmp/dst.cnf \
    --init-command="SET FOREIGN_KEY_CHECKS=0" \
    "$TARGET_DB"

date -u +"finished %Y-%m-%dT%H:%M:%SZ"
echo "--- done ---"

# Why the sed: every view, trigger, procedure and event in a dump carries
# DEFINER=`someuser`@`somehost`. That user exists on the source and does not
# exist on RDS, and the restore fails on the first one — near the END of the
# dump, after the data has loaded, which reads like "the data is fine, only the
# last bit failed" and is how a platform ends up with no triggers.
