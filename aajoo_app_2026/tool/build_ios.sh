#!/usr/bin/env bash
# The iOS twin of build_release.ps1. Runs on macOS (Xcode + CocoaPods) — on a
# developer's Mac or the GitHub Actions macOS runner in
# .github/workflows/ios-build.yml. Same --dart-define set as the Android
# build, so the two artifacts of one build number are the same code with the
# same configuration.
#
#   tool/build_ios.sh --api https://aajaodev.onrender.com --razorpay rzp_test_xxx \
#       [--allow-test-payments] [--allow-dev-endpoint] [--no-codesign | --export <ExportOptions.plist>]
#
# --no-codesign      compile only (build/ios/iphoneos/Runner.app); no Apple
#                    account needed. This is what CI runs on every push.
# --export <plist>   archive and export a signed .ipa for TestFlight / the
#                    App Store with the given export options; needs the
#                    signing identity and provisioning profile installed.
set -euo pipefail

API=""; KEY=""; ALLOW_TEST=""; ALLOW_DEV=""; MODE="--no-codesign"; EXPORT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --api) API="$2"; shift 2;;
    --razorpay) KEY="$2"; shift 2;;
    --allow-test-payments) ALLOW_TEST=1; shift;;
    --allow-dev-endpoint) ALLOW_DEV=1; shift;;
    --no-codesign) MODE="--no-codesign"; shift;;
    --export) MODE="--export"; EXPORT="$2"; shift 2;;
    *) echo "unknown argument: $1" >&2; exit 2;;
  esac
done
[ -n "$API" ] || { echo "--api is required" >&2; exit 2; }
[ -n "$KEY" ] || { echo "--razorpay is required" >&2; exit 2; }

cd "$(dirname "$0")/.."

# The same refusals build_release.ps1 makes, so a QA build cannot be cut by
# accident with a production key or a production build with a dev endpoint.
case "$API" in
  https://*) ;;
  *) echo "the API base URL must be https: $API" >&2; exit 1;;
esac
if [[ "$API" == *"onrender.com"* && -z "$ALLOW_DEV" ]]; then
  echo "$API is the development endpoint; pass --allow-dev-endpoint for a QA build" >&2; exit 1
fi
if [[ "$KEY" == rzp_test_* && -z "$ALLOW_TEST" ]]; then
  echo "a sandbox Razorpay key needs --allow-test-payments" >&2; exit 1
fi

VERSION=$(grep -E '^version:' pubspec.yaml | sed 's/version:[[:space:]]*//')
echo "Building $VERSION for iOS"
echo "  endpoint : $API"
echo "  gateway  : ${KEY:0:12}…"

DEFINES=(
  "--dart-define=API_BASE_URL=$API"
  "--dart-define=RAZORPAY_KEY=$KEY"
  "--dart-define=APP_VERSION=$VERSION"
)
[ -n "$ALLOW_TEST" ] && DEFINES+=("--dart-define=ALLOW_TEST_PAYMENTS=true")

flutter pub get
(cd ios && pod install --repo-update)

if [ "$MODE" = "--no-codesign" ]; then
  flutter build ios --release --no-codesign "${DEFINES[@]}"
  echo "built build/ios/iphoneos/Runner.app (unsigned)"
  python3 tool/verify_release_ipa.py build/ios/iphoneos/Runner.app "$API" \
    ${ALLOW_TEST:+--allow-test-payments} --expect-version="$VERSION" --allow-placeholders
else
  flutter build ipa --release "${DEFINES[@]}" --export-options-plist "$EXPORT"
  IPA=$(ls build/ios/ipa/*.ipa | head -1)
  echo "built $IPA"
  python3 tool/verify_release_ipa.py "$IPA" "$API" \
    ${ALLOW_TEST:+--allow-test-payments} --expect-version="$VERSION"
  shasum -a 256 "$IPA"
fi
