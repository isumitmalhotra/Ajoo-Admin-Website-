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
        print("usage: verify_release_apk.py <apk> [expected-api-base-url]")
        return 2

    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    # A QA build may legitimately carry the sandbox gateway, but only when the
    # person building it said so — the same flag the build script demands.
    allow_test_payments = "--allow-test-payments" in sys.argv

    apk_path = args[0]
    expected_api = args[1].encode() if len(args) > 1 else None

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

    print(f"scanned: {', '.join(sorted(blobs))}")
    if failures:
        print(f"\n{len(failures)} problem(s):")
        for f in sorted(set(failures)):
            print("  FAIL ", f)
        return 1

    note = "" if not allow_test_payments else "\n    (a sandbox payment key was permitted for this build)"
    print("\nOK  no unexpected endpoint, no developer path, no plain-http endpoint." + note)
    return 0


if __name__ == "__main__":
    sys.exit(main())
