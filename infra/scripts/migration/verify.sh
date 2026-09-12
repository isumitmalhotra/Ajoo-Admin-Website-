#!/usr/bin/env bash
#
# Runs INSIDE the one-off Fargate task, after copy.sh.
#
# Compares the two databases table by table and exits non-zero on any
# difference. This is the step that decides whether DNS moves.
set -euo pipefail
set -o pipefail
umask 077

cfg() {
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

q_src() { mysql --defaults-file=/tmp/src.cnf -N -B -e "$1"; }
q_dst() { mysql --defaults-file=/tmp/dst.cnf -N -B -e "$1"; }

failures=0
note() { echo "MISMATCH: $*"; failures=$((failures + 1)); }

# ── Tables ─────────────────────────────────────────────────────────────────
SRC_TABLES=$(q_src "SELECT table_name FROM information_schema.tables
  WHERE table_schema='$SOURCE_DB' AND table_type='BASE TABLE' ORDER BY table_name")
DST_TABLES=$(q_dst "SELECT table_name FROM information_schema.tables
  WHERE table_schema='$TARGET_DB' AND table_type='BASE TABLE' ORDER BY table_name")

SRC_N=$(echo "$SRC_TABLES" | grep -c . || true)
DST_N=$(echo "$DST_TABLES" | grep -c . || true)
echo "tables: source $SRC_N, target $DST_N"
[ "$SRC_N" = "$DST_N" ] || note "table count $SRC_N vs $DST_N"

MISSING=$(comm -23 <(echo "$SRC_TABLES" | sort) <(echo "$DST_TABLES" | sort) || true)
[ -z "$MISSING" ] || note "tables absent from the target: $(echo "$MISSING" | tr '\n' ' ')"

# ── Row counts, counted rather than estimated ──────────────────────────────
#
# information_schema.table_rows is an ESTIMATE for InnoDB, routinely wrong by
# tens of percent and occasionally by an order of magnitude. A verification
# built on it passes on a half-copied database, which makes it worse than no
# verification at all. COUNT(*) on a 43 MB database costs seconds.
echo "--- row counts ---"
printf '%-44s %12s %12s\n' TABLE SOURCE TARGET
for t in $SRC_TABLES; do
  s=$(q_src "SELECT COUNT(*) FROM \`$SOURCE_DB\`.\`$t\`")
  d=$(q_dst "SELECT COUNT(*) FROM \`$TARGET_DB\`.\`$t\`" 2>/dev/null || echo "-")
  printf '%-44s %12s %12s' "$t" "$s" "$d"
  if [ "$s" = "$d" ]; then echo ""; else echo "   <-- MISMATCH"; failures=$((failures + 1)); fi
done

# ── The things a row count does not notice ─────────────────────────────────
for kind in VIEW PROCEDURE FUNCTION TRIGGER EVENT; do
  case "$kind" in
    VIEW) sq="SELECT COUNT(*) FROM information_schema.views WHERE table_schema=" ;;
    TRIGGER) sq="SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema=" ;;
    EVENT) sq="SELECT COUNT(*) FROM information_schema.events WHERE event_schema=" ;;
    *) sq="SELECT COUNT(*) FROM information_schema.routines WHERE routine_type='$kind' AND routine_schema=" ;;
  esac
  s=$(q_src "$sq'$SOURCE_DB'")
  d=$(q_dst "$sq'$TARGET_DB'")
  printf '%-44s %12s %12s' "$kind(s)" "$s" "$d"
  if [ "$s" = "$d" ]; then echo ""; else echo "   <-- MISMATCH"; failures=$((failures + 1)); fi
done

# ── Character set, because this platform stores Devanagari ─────────────────
#
# A database that silently arrives as latin1 does not fail. It stores every
# non-ASCII name as mojibake and nobody notices until a host in Dehradun
# cannot find their own listing.
SRC_CS=$(q_src "SELECT default_character_set_name FROM information_schema.schemata WHERE schema_name='$SOURCE_DB'")
DST_CS=$(q_dst "SELECT default_character_set_name FROM information_schema.schemata WHERE schema_name='$TARGET_DB'")
echo "charset: source $SRC_CS, target $DST_CS"
[ "$SRC_CS" = "$DST_CS" ] || note "character set $SRC_CS vs $DST_CS"

# ── AUTO_INCREMENT, because a reset one collides on the first insert ───────
echo "--- auto_increment (target must be >= source) ---"
q_src "SELECT table_name, IFNULL(auto_increment,0) FROM information_schema.tables
  WHERE table_schema='$SOURCE_DB' AND auto_increment IS NOT NULL ORDER BY table_name" > /tmp/ai_src
while read -r t v; do
  [ -n "${t:-}" ] || continue
  d=$(q_dst "SELECT IFNULL(auto_increment,0) FROM information_schema.tables
    WHERE table_schema='$TARGET_DB' AND table_name='$t'" 2>/dev/null || echo 0)
  if [ "${d:-0}" -lt "${v:-0}" ]; then note "auto_increment $t: source $v, target $d"; fi
done < /tmp/ai_src

echo "--- result ---"
if [ "$failures" -eq 0 ]; then
  echo "IDENTICAL. The target matches the source."
  exit 0
fi
echo "$failures difference(s). DO NOT MOVE DNS."
exit 1
