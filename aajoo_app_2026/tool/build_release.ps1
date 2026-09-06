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

param(
    [Parameter(Mandatory = $true)][string]$ApiBaseUrl,
    [Parameter(Mandatory = $true)][string]$RazorpayKey,
    [switch]$AllowTestPayments
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not $ApiBaseUrl.StartsWith('https://')) {
    throw "The API endpoint must be https. Got: $ApiBaseUrl"
}
if ($RazorpayKey.StartsWith('rzp_test_') -and -not $AllowTestPayments) {
    throw "That is a TEST payment key. Pass -AllowTestPayments if this build is for QA; a live build needs rzp_live_…"
}

$defines = @(
    "--dart-define=API_BASE_URL=$ApiBaseUrl",
    "--dart-define=RAZORPAY_KEY=$RazorpayKey"
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
& python (Join-Path $PSScriptRoot 'verify_release_apk.py') $apk $ApiBaseUrl
if ($LASTEXITCODE -ne 0) { throw "APK verification failed — do not ship this build" }

$hash = (Get-FileHash $apk -Algorithm SHA256).Hash
$size = [Math]::Round((Get-Item $apk).Length / 1MB, 1)
Write-Host "`nOK  $apk" -ForegroundColor Green
Write-Host "    $size MB"
Write-Host "    sha256 $hash"
