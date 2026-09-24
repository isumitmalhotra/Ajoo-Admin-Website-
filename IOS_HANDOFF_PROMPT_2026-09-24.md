# iOS handoff — paste this into a new Claude Code session on the Mac

*Written 24 September 2026 from the Windows session. Everything below was verified today unless it says otherwise.*

---

## THE PROMPT (copy from here down)

You are picking up the iOS half of **Aajoo Homes**, a property-rental platform (Flutter app + React website + Node/Express backend). I am on a Mac; every previous session ran on Windows, so **this is the first machine in the project that can compile iOS at all.** Read this whole brief before doing anything.

### 1. Get the code

```bash
git clone https://github.com/nameeshPatiyal100/aajoo_app_latest.git aajoo_app
cd aajoo_app && flutter pub get && flutter test
```

That repo **is** the Flutter app — its root is what the monorepo calls `aajoo_app_2026/`. It is private; I have access. Expect **632 tests passing, 1 skipped**. Its tip is `18a26f9` and its `pubspec.yaml` says `version: 1.0.0+113`.

Two reference documents live in the public monorepo `https://github.com/isumitmalhotra/Ajoo-Admin-Website-` — **read both before touching anything**:

- `aajoo_app_2026/IOS_READINESS.md` — the full iOS picture: what was configured on 15 September, what the build machinery does, the eight things only the client's Apple account can supply, and the differences a tester will legitimately see on iOS.
- `SESSION_HANDOFF_2026-09-18_IOS.md` — the earlier iOS handoff.

⚠️ **That monorepo is about 16 commits behind** and will stay behind — it is public, so infrastructure documentation is deliberately not pushed to it. Treat it as reference only. **The client repo above is the source of truth for app code.**

### 2. What changed today that those documents do not know

- **The backend moved.** The production API is now **`https://api.aajoohomes.com`** — a Render service in **Singapore** reading a **fresh, empty PlanetScale database**. The old `aajaodev.onrender.com` (Oregon + Clever Cloud) is still running but is the *old* data; the website no longer uses it.
- **`tool/build_ios.sh` and the CI workflow were corrected today** to build against `api.aajoohomes.com`. The script used to refuse only hosts containing `onrender.com` — a denylist of one. It now takes one production host and anything else must pass `--allow-dev-endpoint`.
- **The database is empty. No guest or host account exists yet.** Only four admin accounts. Someone is creating a guest and a host through the website; until they do, **nothing authenticated can be tested on iOS or Android**. There is **no OTP bypass** — it was deleted from the code, not switched off, so a real mailbox is required (Mailinator drops our mail).
- **Android build 113** (`1.0.0+113`, `sha256 0226b16e…61bf`) is the current build and points at the new host. **One build number = one artifact across platforms:** the iOS build of `1.0.0+113` must come from the same commit with the same configuration.
- Razorpay is still in **test mode**; builds pass `--allow-test-payments` with `rzp_test_XUTODhUdMAshi6`.

### 3. What is actually left on iOS

**Already done in the repo** (15 September, unchanged): `Info.plist` (display name, all four usage strings, `LSApplicationQueriesSchemes`, background modes), `AppDelegate.swift` (Maps key handoff, notification delegate), `Podfile` at iOS 14.0 with the `permission_handler` flags, `Runner.entitlements` for push, `PrivacyInfo.xcprivacy`, the full icon set, the launch screen, `tool/build_ios.sh`, `tool/verify_release_ipa.py`, and `.github/workflows/ios-build.yml`. The unsigned compile has been **green on GitHub's macOS runners** — last proven on build 111, 23 September.

**Open, in the order that unblocks the most:**

1. **Sign in with Apple — not built at all.** App Store Review Guideline 4.8: an app offering Google sign-in must also offer Sign in with Apple. Needed for **App Review**, not for TestFlight. It is work on both sides:
   - app: the `sign_in_with_apple` package (not currently a dependency), the button beside Google's, the Apple provider enabled in Firebase Auth;
   - backend (`D:/Projects/aajaoBackend-render` → `https://github.com/nameeshPatiyal100/aajaoBackend`, private): verify Apple's identity token and create-or-link the account exactly as the Google path does. **Read the "Google account lockout" note in `MASTER_PENDING_TASKS.md` first** — Google signups got an unusable password and the role flags drifted; the Apple path must not repeat it.
   - Estimate about a day, plus the client enabling the capability on the App ID.
2. **The eight client Apple actions** (`IOS_READINESS.md` §3) — Developer Program enrolment, App ID with Push, an APNs `.p8` uploaded to Firebase, `GoogleService-Info.plist`, an iOS-restricted Maps key, the App Store Connect app record plus an internal TestFlight group, an App Store Connect API key, and a distribution certificate with an App Store provisioning profile. **As far as we know none of these have been started.** Nothing reaches an iPhone without 1–3 and 6.
3. **Two placeholders in `ios/Runner/Info.plist`** — `GMSApiKey` and `GIDClientID` (plus its reversed form as a URL scheme). CI fills them from secrets; a local signed build needs them filled on the Mac. The verifier refuses a build that still carries a placeholder, which is deliberate.
4. **The on-device drive** — every flow driven on the Android emulator has to be driven on a real iPhone. `IOS_READINESS.md` §4.2 lists them. Blocked on the accounts above.
5. **App Store listing** — 6.7" and 6.5" screenshots, the privacy questionnaire, support and privacy URLs (both exist on the website), age rating, review notes with a test account and test card. Recommend marking the first release **iPhone-only**.
6. **A 1024-px icon from the designer** — the current marketing icon is upscaled from the 512-px Android master.

### 4. What I want you to do first, on this Mac

The CI existed only because nobody had a Mac. **That changes now.** Start here:

```bash
tool/build_ios.sh --api https://api.aajoohomes.com --razorpay rzp_test_XUTODhUdMAshi6 \
  --allow-test-payments --no-codesign
python3 tool/verify_release_ipa.py build/ios/iphoneos/Runner.app https://api.aajoohomes.com \
  --allow-test-payments --allow-placeholders --expect-version=1.0.0+113
```

Needs no Apple account. It proves the iOS half builds **on a real machine** rather than only on a runner, and it tells us in minutes whether the pods resolve under the Xcode on this Mac. Report the Xcode version, the CocoaPods version and the exact Flutter version you used, because the CI pins Flutter **3.44.0** and a local mismatch is the first thing that will explain a difference.

Then **run the app in the iOS Simulator** and drive as far as an empty database allows: the launch screen, the app name and icon, the login screen, the signup form (do **not** submit — I will tell you when accounts exist), the permission prompts, and whether any screen breaks on a notch or the home indicator. Push does not work on the Simulator (no APNs) — that is expected, not a defect.

**Do not** create accounts, enter passwords, or upload anything to TestFlight without asking me first.

### 5. How I work

- Tell me plainly what you verified and what you did not. If something is untested, say so rather than implying it works.
- Where the code disagrees with a document, **change the code** — unless the document is one of the two iOS references above, which describe a state of the world rather than a spec.
- Never write a credential into a repository file. The monorepo is public.
- Check `git status` in every repo before blaming a deploy.
- Reply in English.

Start by reading `IOS_READINESS.md`, then run the compile in §4 and tell me what the Mac says.

## (end of prompt)
