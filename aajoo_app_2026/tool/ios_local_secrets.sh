#!/usr/bin/env bash
# Fill (or restore) the two Info.plist placeholders on a developer's Mac, for
# a Simulator/device drive — the same three PlistBuddy commands the
# `testflight` job in .github/workflows/ios-build.yml runs from the repository
# secrets. Values come from files outside the repository, never from the
# command line or the chat, and Info.plist is a tracked file: run
# `--restore` before any commit (git status must not list it).
#
#   tool/ios_local_secrets.sh            fill from ~/.aajoo/ios.env + GoogleService-Info.plist
#   tool/ios_local_secrets.sh --restore  put the placeholders back (git checkout)
#
# ~/.aajoo/ios.env (create it yourself, mode 600):
#   IOS_MAPS_KEY=AIza...            the iOS-restricted Maps key (IOS_READINESS.md §3 step 5)
#   IOS_GOOGLE_CLIENT_ID=...        optional — taken from ios/Runner/GoogleService-Info.plist
#                                   (CLIENT_ID) when that file is present (§3 step 4)
set -euo pipefail
cd "$(dirname "$0")/.."
PLIST=ios/Runner/Info.plist
GSI=ios/Runner/GoogleService-Info.plist
PB=/usr/libexec/PlistBuddy

if [ "${1:-}" = "--restore" ]; then
  git checkout -- "$PLIST"
  echo "restored $PLIST to the committed placeholders"
  exit 0
fi

[ -x "$PB" ] || { echo "PlistBuddy not found — this runs on macOS only" >&2; exit 2; }
ENV_FILE="$HOME/.aajoo/ios.env"
[ -f "$ENV_FILE" ] || { echo "missing $ENV_FILE (see the header of this script)" >&2; exit 2; }
# shellcheck disable=SC1090
. "$ENV_FILE"

MAPS="${IOS_MAPS_KEY:-}"
GID="${IOS_GOOGLE_CLIENT_ID:-}"
if [ -z "$GID" ] && [ -f "$GSI" ]; then
  GID=$("$PB" -c "Print :CLIENT_ID" "$GSI" 2>/dev/null || true)
fi
[ -n "$MAPS" ] || { echo "IOS_MAPS_KEY is empty in $ENV_FILE" >&2; exit 2; }
[ -n "$GID" ] || { echo "no Google client id: set IOS_GOOGLE_CLIENT_ID or put $GSI in place" >&2; exit 2; }
case "$GID" in *.apps.googleusercontent.com) ;; *) echo "client id should end in .apps.googleusercontent.com" >&2; exit 2;; esac

GID_ID="${GID%%.apps.googleusercontent.com}"
REVERSED="com.googleusercontent.apps.${GID_ID}"
"$PB" -c "Set :GMSApiKey $MAPS" "$PLIST"
"$PB" -c "Set :GIDClientID $GID" "$PLIST"
"$PB" -c "Set :CFBundleURLTypes:0:CFBundleURLSchemes:0 $REVERSED" "$PLIST"
echo "filled $PLIST: Maps key …${MAPS: -6}, client …${GID_ID: -6}"
echo "remember: tool/ios_local_secrets.sh --restore before committing"
