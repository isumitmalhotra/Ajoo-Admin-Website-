# Build a release APK and prove what is inside it.
#
# The release-candidate findings ask for two things that cannot be asserted
# from source alone (P0-01/FE-01, P0-02/FE-02, section 7):
#
#   * no development API URL in the artifact
#   * no test Razorpay key in the artifact
#
# Both defaults are compiled out of release builds, so a release APK has
# neither unless it is given one — which means the endpoint and the payment key
# have to be named here, deliberately, every time. The script then reads the
# built APK back and fails if anything unexpected is in it, because "we removed
# it" and "it is not in the file" are different claims and only the second one
# is evidence.
#
# Usage:
#   ./tool/build_release.ps1 -ApiBaseUrl https://api.example.com -RazorpayKey rzp_live_xxx
#
# For a QA build that must still use the sandbox gateway, pass the test key and
# say so out loud:
#   ./tool/build_release.ps1 -ApiBaseUrl https://… -RazorpayKey rzp_test_xxx -AllowTestPayments

# Saved with a UTF-8 BOM on purpose. Windows PowerShell 5.1 reads a BOM-less
# file as ANSI, which turns the em-dashes in the messages below into bytes it
# cannot parse -- and the failure looks like a Gradle problem rather than an
# encoding one. pwsh does not need the BOM; it does no harm there.

param(
    [Parameter(Mandatory = $true)][string]$ApiBaseUrl,
    [Parameter(Mandatory = $true)][string]$RazorpayKey,
    [switch]$AllowTestPayments,
    [switch]$AllowDevEndpoint,

    # Skip the endpoint reachability probe (offline builds only).
    [switch]$SkipEndpointCheck
)

# The one endpoint a shipping build may point at.
#
# EMPTY ON PURPOSE, and the script refuses a build without -AllowDevEndpoint
# until it is filled in. As of 2026-09-07 there is no production API host:
# api.aajoohomes.com resolves to VERCEL and answers 404, so it serves the
# website, not the API. A build made with the endpoint the audit prescribes
# would install and reach nothing at all. Set this the day the backend has a
# production home, and the guard below starts doing its real job.
$ProductionApiBase = ''

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not $ApiBaseUrl.StartsWith('https://')) {
    throw "The API endpoint must be https. Got: $ApiBaseUrl"
}
if ($RazorpayKey.StartsWith('rzp_test_') -and -not $AllowTestPayments) {
    throw "That is a TEST payment key. Pass -AllowTestPayments if this build is for QA; a live build needs rzp_live_…"
}

# The same rule for the endpoint, which the payment key had and it did not.
#
# Finding A-1 cites a real incident: a release APK once shipped with the dev
# URL baked in. Making the endpoint mandatory stops an EMPTY one; it does
# nothing about the WRONG one. A build that is not pointed at production now
# has to say so out loud, exactly as a sandbox payment key does.
if ($ProductionApiBase -and $ApiBaseUrl -ne $ProductionApiBase -and -not $AllowDevEndpoint) {
    throw "That is not the production endpoint ($ProductionApiBase). Pass -AllowDevEndpoint if this build is for QA."
}
if (-not $ProductionApiBase -and -not $AllowDevEndpoint) {
    throw "No production endpoint is configured in this script yet, so every build is a QA build. Pass -AllowDevEndpoint to acknowledge that, or set `$ProductionApiBase once the API has a production host."
}

# Does that endpoint actually answer?
#
# The guards above catch an EMPTY endpoint and, once $ProductionApiBase is set,
# a non-production one. Neither catches the case that actually bit us: a URL
# that is perfectly well-formed and serves nothing. api.aajoohomes.com is
# exactly that — it resolves, it speaks https, and it returns Vercel's
# DEPLOYMENT_NOT_FOUND — and an audit prescribed it as the build endpoint. The
# app's own isConfigured() cannot help, because it only asks whether the string
# starts with https://.
#
# So ask the server. Two seconds here replaces an APK that installs, opens and
# fails every call in a tester's hands.
if (-not $SkipEndpointCheck) {
Write-Host "Checking $ApiBaseUrl is alive..." -ForegroundColor DarkGray
try {
    $probe = Invoke-WebRequest -Uri "$ApiBaseUrl/health" -TimeoutSec 45 -UseBasicParsing -ErrorAction Stop
    if ($probe.Content -notmatch '"status"\s*:\s*"ok"') {
        throw "answered $($probe.StatusCode) but does not look like the Aajoo API: $($probe.Content.Substring(0, [Math]::Min(120, $probe.Content.Length)))"
    }
    Write-Host "  endpoint is live" -ForegroundColor DarkGray
} catch {
    throw @"
$ApiBaseUrl does not serve the Aajoo API.

  $($_.Exception.Message)

GET $ApiBaseUrl/health must return {"status":"ok",...}. A build against a host
that does not answer will install and then fail every request, which is far
harder to diagnose than this message. Pass -SkipEndpointCheck only if you are
building offline and know the host is right.
"@
}
}

# Read straight out of pubspec rather than passed in: a version somebody has
# to remember to supply is a version that will eventually be wrong.
$AppVersion = (Select-String -Path (Join-Path $root 'pubspec.yaml') -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()
if (-not $AppVersion) { throw "Could not read the version from pubspec.yaml" }
Write-Host "Building $AppVersion" -ForegroundColor Cyan

$defines = @(
    "--dart-define=API_BASE_URL=$ApiBaseUrl",
    "--dart-define=RAZORPAY_KEY=$RazorpayKey",
    # The version this artifact will REPORT on its Settings screen.
    #
    # Taken from pubspec, so the number a tester reads is the number of the
    # build in their hands. It used to be typed into settings_page by hand and
    # was therefore wrong as soon as anyone built anything -- it still claimed
    # build 45 while 46 was being cut. A tester who cannot say which build they
    # are on re-reports fixed defects, which is exactly what happened with rows
    # 20-26 of the QA sheet.
    "--dart-define=APP_VERSION=$AppVersion"
)
if ($AllowTestPayments) { $defines += "--dart-define=ALLOW_TEST_PAYMENTS=true" }

Write-Host "Building release APK" -ForegroundColor Cyan
Write-Host "  endpoint : $ApiBaseUrl"
Write-Host "  gateway  : $($RazorpayKey.Substring(0, [Math]::Min(12, $RazorpayKey.Length)))…"

& flutter build apk --release @defines
if ($LASTEXITCODE -ne 0) { throw "flutter build failed" }

$apk = Join-Path $root 'build/app/outputs/flutter-apk/app-release.apk'
if (-not (Test-Path $apk)) { throw "APK not found at $apk" }

Write-Host "`nVerifying the artifact" -ForegroundColor Cyan
# The verifier has to be TOLD, or it fails a QA build on the very key that
# build was asked for. The switch reached this script and stopped here.
$verifyArgs = @((Join-Path $PSScriptRoot 'verify_release_apk.py'), $apk, $ApiBaseUrl)
if ($AllowTestPayments) { $verifyArgs += '--allow-test-payments' }
# And that the artifact can name itself, which is the only way a tester's
# defect report can be tied to a build.
$verifyArgs += "--expect-version=$AppVersion"
& python @verifyArgs
if ($LASTEXITCODE -ne 0) { throw "APK verification failed — do not ship this build" }

$hash = (Get-FileHash $apk -Algorithm SHA256).Hash
$size = [Math]::Round((Get-Item $apk).Length / 1MB, 1)
Write-Host "`nOK  $apk" -ForegroundColor Green
Write-Host "    $size MB"
Write-Host "    sha256 $hash"
