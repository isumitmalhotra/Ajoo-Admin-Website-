"""Read an iOS build back and say what is actually in it.

The iOS twin of verify_release_apk.py, holding the same line: "no development
API URL", "no test Razorpay key unless the builder said so", "no developer
path", "HTTPS only", "the build knows which build it is" — every one a
statement about a file, checked against the file. Plus the two things an iOS
artifact can get wrong that an APK cannot: a placeholder left in Info.plist
(the Maps key, the Google Sign-In client) and a bundle id that is not ours.

Accepts an .ipa, a zipped Runner.app, or a Runner.app directory (what
`flutter build ios --no-codesign` leaves in build/ios/iphoneos/).

    python tool/verify_release_ipa.py build/ios/iphoneos/Runner.app https://api.example.com \
        [--allow-test-payments] [--expect-version=1.0.0+94] [--allow-placeholders]

`--allow-placeholders` is for the unsigned CI compile check only, which runs
before the client's accounts have issued the real values; a build meant for a
phone must never be verified with it.
"""
import os
import plistlib
import re
import sys
import zipfile

BUNDLE_ID = "com.aajoo.aajoohomes"

FORBIDDEN = [
    ("emulator loopback host", rb"\b10\.0\.2\.2\b"),
    ("windows developer path", rb"[A-Z]:\\Users\\[A-Za-z0-9_.\-]{2,20}"),
    ("unix home path", rb"/(?:home|Users)/[A-Za-z0-9_.\-]{2,20}/(?:Desktop|Documents|Projects|dev)/"),
]

# Plain-http prefixes every iOS binary carries as identifiers, not endpoints.
HTTP_ALLOWED = (
    b"http://www.apple.com",
    b"http://www.w3.org",
    b"http://localhost",
    b"http://schemas.",
    b"http://ns.adobe.com",
    b"http://xml.org",
)


def wanted(rel):
    """The four files that say what a build IS: the app's own Info.plist, the
    native Runner binary, the Dart AOT snapshot (App.framework/App — where
    every --dart-define lands) and the provisioning profile. Not the forty
    Info.plists of the bundled SDKs."""
    if rel.endswith("App.framework/App"):
        return True
    # Inside an .ipa the app sits under Payload/<name>.app/; a Runner.app
    # directory has no prefix. Either way the app root is where Runner lives.
    parts = rel.split("/")
    depth_ok = len(parts) <= 3 and not any(p.endswith((".framework", ".bundle", ".storyboardc")) for p in parts)
    return depth_ok and parts[-1] in ("Runner", "Info.plist", "embedded.mobileprovision")


def load(path):
    """{name: bytes} for the files worth scanning, however the build is packed."""
    blobs = {}
    if os.path.isdir(path):
        for root, _dirs, files in os.walk(path):
            for f in files:
                full = os.path.join(root, f)
                rel = os.path.relpath(full, path).replace(os.sep, "/")
                if wanted(rel):
                    blobs[rel] = open(full, "rb").read()
        return blobs
    zf = zipfile.ZipFile(path)
    for name in zf.namelist():
        if not name.endswith("/") and wanted(name):
            blobs[name] = zf.read(name)
    return blobs


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not args:
        print(__doc__)
        return 2
    allow_test_payments = "--allow-test-payments" in sys.argv
    allow_placeholders = "--allow-placeholders" in sys.argv
    expect_version = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--expect-version=")), None)
    expected_api = args[1].encode() if len(args) > 1 else None

    blobs = load(args[0])
    if not blobs:
        print("FAIL  nothing to scan — is this an .ipa or a Runner.app?")
        return 1
    failures = []

    # The app's own Info.plist: identity, placeholders, version.
    info_name = next((n for n in blobs if n.endswith("Info.plist") and ".framework" not in n and ".bundle" not in n), None)
    info = {}
    if info_name:
        try:
            info = plistlib.loads(blobs[info_name])
        except Exception as e:  # noqa: BLE001
            failures.append(f"Info.plist unreadable: {e}")
    else:
        failures.append("no Info.plist found")
    if info:
        if info.get("CFBundleIdentifier") != BUNDLE_ID:
            failures.append(f"bundle id is {info.get('CFBundleIdentifier')!r}, not {BUNDLE_ID}")
        if info.get("CFBundleDisplayName") != "Aajoo Homes":
            failures.append(f"display name is {info.get('CFBundleDisplayName')!r} — the phone will show it")
        for key in ("GMSApiKey", "GIDClientID"):
            v = str(info.get(key, ""))
            if not v or v.startswith("REPLACE_WITH"):
                (failures if not allow_placeholders else []).append(
                    f"{key} is a placeholder — maps blank / Google Sign-In dead until the client's value is in Info.plist")
        schemes = [s for t in info.get("CFBundleURLTypes", []) for s in t.get("CFBundleURLSchemes", [])]
        if any("REPLACE_WITH" in s for s in schemes) and not allow_placeholders:
            failures.append("the Google Sign-In URL scheme is a placeholder — the sign-in sheet will never come back to the app")
        for key in ("NSLocationWhenInUseUsageDescription", "NSPhotoLibraryUsageDescription"):
            if not info.get(key):
                failures.append(f"{key} missing — iOS refuses the permission prompt without it")
        if info.get("ITSAppUsesNonExemptEncryption") is not False:
            failures.append("ITSAppUsesNonExemptEncryption is not false — every TestFlight upload will stop to ask")
        if expect_version:
            name, _, number = expect_version.partition("+")
            got = f"{info.get('CFBundleShortVersionString')}+{info.get('CFBundleVersion')}"
            if got != f"{name}+{number}":
                failures.append(f"Info.plist says {got}, the build was meant to be {expect_version}")

    checks = list(FORBIDDEN)
    if not allow_test_payments:
        checks.append(("test payment key", rb"rzp_test_[A-Za-z0-9]+"))
    for label, pattern in checks:
        for name, data in blobs.items():
            for hit in {m.group(0) for m in re.finditer(pattern, data)}:
                failures.append(f"{label} in {name}: {hit.decode('utf-8', 'replace')}")

    # Plain http. Strict in the Dart snapshot and Info.plist, which is where
    # OUR configuration lives. The native Runner binary statically links the
    # Google, Firebase and Razorpay SDKs, whose own constants include a few
    # http:// identifiers (www.google.com, example.invalid, "goto"); those are
    # not endpoints this build talks to, so they are reported, not failed —
    # unless one of them is an Aajoo host.
    notes = []
    for name, data in blobs.items():
        for m in {m.group(0) for m in re.finditer(rb"http://[a-z0-9.\-]{4,60}", data)}:
            if any(m.startswith(ok) for ok in HTTP_ALLOWED):
                continue
            ours = b"aajoo" in m or b"onrender" in m
            if name.endswith("/Runner") or name == "Runner":
                if ours:
                    failures.append(f"plain http Aajoo endpoint in native code: {m.decode('utf-8', 'replace')}")
                else:
                    notes.append(f"native SDK constant, not an endpoint: {m.decode('utf-8', 'replace')}")
            else:
                failures.append(f"plain http endpoint in {name}: {m.decode('utf-8', 'replace')}")

    if expected_api:
        host = expected_api.split(b"//", 1)[-1].rstrip(b"/")
        if not any(host in data for data in blobs.values()):
            failures.append(f"the endpoint this build was given is not in it: {host.decode()}")
        for m in {m.group(0) for data in blobs.values() for m in re.finditer(rb"[a-z0-9\-]+\.onrender\.com", data)}:
            if m != host:
                failures.append(f"an endpoint this build was NOT given is in it: {m.decode()}")

    if expect_version:
        want = expect_version.encode()
        if not any(want in data for name, data in blobs.items() if name.endswith("App.framework/App")):
            failures.append(f"the Dart code does not carry its own version ({expect_version}) — APP_VERSION was not passed")

    print(f"scanned: {', '.join(sorted(blobs))}")
    if failures:
        print(f"\n{len(failures)} problem(s):")
        for f in sorted(set(failures)):
            print("  FAIL ", f)
        return 1
    if allow_test_payments:
        notes.append("a sandbox payment key was permitted for this build")
    if allow_placeholders:
        notes.append("PLACEHOLDERS PERMITTED — this is a compile check, not a build for a phone")
    print("\nOK  bundle id, display name, permissions strings, no unexpected endpoint, no developer path, no plain-http endpoint."
          + ("".join(f"\n    ({n})" for n in notes)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
