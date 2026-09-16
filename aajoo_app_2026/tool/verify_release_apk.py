"""Read a release APK back and say what is actually in it.

The release-candidate findings ask for evidence, not assurance: "no development
API URL in the production APK", "no test Razorpay key", "no localhost or
developer-machine path", "HTTPS only". Every one of those is a statement about
a file, so it is checked against the file.

Scans the compiled Dart (`lib/*/libapp.so`), the Java/Kotlin classes
(`classes*.dex`) and the manifest. Exits non-zero on any failure, so a build
script can refuse to publish.

    python tool/verify_release_apk.py build/app/outputs/flutter-apk/app-release.apk https://api.example.com
"""

import re
import sys
import zipfile

# Strings that must never appear in a release artifact. The test payment key is
# added to this list at run time unless --allow-test-payments was passed.
FORBIDDEN = [
    ("emulator loopback host", rb"\b10\.0\.2\.2\b"),
    ("windows developer path", rb"[A-Z]:\\Users\\[A-Za-z0-9_.\-]{2,20}"),
    ("unix home path", rb"/(?:home|Users)/[A-Za-z0-9_.\-]{2,20}/(?:Desktop|Documents|Projects|dev)/"),
]

# Only these hosts may appear as plain http. They are XML namespace identifiers,
# not endpoints — every Android artifact carries them and none is fetched.
HTTP_ALLOWED = (
    b"http://schemas.android.com",
    b"http://ns.adobe.com",
    b"http://www.w3.org",
    b"http://localhost",  # Android/AndroidX library constants, not our config
    b"http://xmlpull.org",
    b"http://apache.org",
    b"http://java.sun.com",
    b"http://javax.xml",
)


def scanned_entries(zf):
    for name in zf.namelist():
        if name.endswith("libapp.so") or re.fullmatch(r"classes\d*\.dex", name):
            yield name
        elif name == "AndroidManifest.xml":
            yield name


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: verify_release_apk.py <apk> [expected-api-base-url] "
              "[--allow-test-payments] [--expect-version=1.0.0+46]")
        return 2

    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    # A QA build may legitimately carry the sandbox gateway, but only when the
    # person building it said so — the same flag the build script demands.
    allow_test_payments = "--allow-test-payments" in sys.argv
    # The version this build claims to be, asserted against the file.
    expect_version = next(
        (a.split("=", 1)[1] for a in sys.argv if a.startswith("--expect-version=")),
        None,
    )

    apk_path = args[0]
    expected_api = args[1].encode() if len(args) > 1 else None

    # No endpoint argument means this verified almost nothing — say so, loudly.
    #
    # Every endpoint assertion below is guarded by `if expected_api`, so running
    # this with only an APK path skipped all of them and still printed
    # "OK  no unexpected endpoint…". That sentence was true and worthless: an
    # APK with NO endpoint at all passes it.
    #
    # Builds 98 and 99 shipped that way on 2026-09-16 — compiled with a plain
    # `flutter build apk` instead of tool/build_release.ps1, so no
    # --dart-define reached them and neither the API base nor the payment key
    # was in the artifact. Both opened on "This build is not configured" on the
    # tester's phone, after this script had called them OK.
    #
    # An unconfigured APK is broken by definition, so this refuses rather than
    # warns. --no-endpoint-check is there for the rare artifact that genuinely
    # has no endpoint, and it has to be typed.
    if not expected_api and "--no-endpoint-check" not in sys.argv:
        print("FAIL  no expected endpoint given, so nothing about the endpoint was checked.\n"
              "      An APK compiled without --dart-define=API_BASE_URL passes every other\n"
              "      check in this file and then opens on 'This build is not configured'.\n"
              "\n"
              "      usage: verify_release_apk.py <apk> https://your-api-host\n"
              "      (or --no-endpoint-check if this artifact really has no endpoint)")
        return 1

    zf = zipfile.ZipFile(apk_path)
    blobs = {name: zf.read(name) for name in scanned_entries(zf)}
    if not blobs:
        print("FAIL  nothing to scan — is this an APK?")
        return 1

    failures = []

    checks = list(FORBIDDEN)
    if not allow_test_payments:
        checks.append(("test payment key", rb"rzp_test_[A-Za-z0-9]+"))

    for label, pattern in checks:
        for name, data in blobs.items():
            found = {m.group(0) for m in re.finditer(pattern, data)}
            for hit in found:
                failures.append(f"{label} in {name}: {hit.decode('utf-8', 'replace')}")

    # Plain-http endpoints, minus the namespace identifiers every APK carries.
    for name, data in blobs.items():
        for m in re.finditer(rb"http://[a-z0-9.\-]{4,60}", data):
            url = m.group(0)
            if any(url.startswith(ok) for ok in HTTP_ALLOWED):
                continue
            failures.append(f"plain http endpoint in {name}: {url.decode('utf-8', 'replace')}")

    # The endpoint this build was told to use has to be the one in it, and no
    # other Aajoo host may be.
    if expected_api:
        host = expected_api.split(b"//", 1)[-1].rstrip(b"/")
        if not any(host in data for data in blobs.values()):
            failures.append(f"the endpoint this build was given is not in the APK: {host.decode()}")
        # Only other API-shaped hosts are a problem. The public website
        # (aajoohomes.com) is linked from the app on purpose — terms, sharing,
        # a listing's own page — and is not an endpoint.
        for m in {m.group(0) for data in blobs.values()
                  for m in re.finditer(rb"[a-z0-9\-]+\.onrender\.com", data)}:
            if m != host:
                failures.append(f"an endpoint this build was NOT given is in the APK: {m.decode()}")

    # Does the artifact know which build it is?
    #
    # Not a security check — a QA one, and it earned its place. The Settings
    # screen used to carry a hand-typed version string, so build 46 introduced
    # itself as build 45. Testers could not say which APK they were holding,
    # re-tested fixed defects against stale code, and re-reported seven of them
    # (QA sheet rows 20-26). A build that cannot name itself costs a QA cycle.
    if expect_version:
        want = expect_version.encode()
        if not any(want in data for data in blobs.values()):
            failures.append(
                f"this build does not carry its own version ({expect_version}) — "
                "APP_VERSION was not passed, so Settings will say 'development build'"
            )

    print(f"scanned: {', '.join(sorted(blobs))}")
    if failures:
        print(f"\n{len(failures)} problem(s):")
        for f in sorted(set(failures)):
            print("  FAIL ", f)
        return 1

    note = "" if not allow_test_payments else "\n    (a sandbox payment key was permitted for this build)"
    # Name the endpoint that was actually found. "No unexpected endpoint" reads
    # the same whether the APK points at the right host or at nothing at all,
    # which is how an unconfigured build was signed off twice.
    where = (f"points at {expected_api.decode()}" if expected_api
             else "endpoint check SKIPPED by --no-endpoint-check")
    print(f"\nOK  {where}; no developer path, no plain-http endpoint." + note)
    return 0


if __name__ == "__main__":
    sys.exit(main())
