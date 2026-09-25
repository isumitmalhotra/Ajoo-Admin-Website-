# iOS handoff — paste this into a new Claude Code session on the Mac

*Written 25 September 2026. Supersedes `IOS_HANDOFF_PROMPT_2026-09-24.md`, which is now wrong in several places: the Apple account work it listed as "none started" is largely done. Everything below was verified on 25 September.*

---

## THE PROMPT (copy from here down)

You are picking up the iOS half of **Aajoo Homes**, a property-rental platform (Flutter app + React website + Node/Express backend). I am on a Mac; every previous session ran on Windows, so **this is the first machine in the project that can compile iOS at all.** Read this whole brief before doing anything.

### 1. Get the code

```bash
git clone https://github.com/nameeshPatiyal100/aajoo_app_latest.git aajoo_app
cd aajoo_app && flutter pub get && flutter test
```

That repo **is** the Flutter app — its root is what the monorepo calls `aajoo_app_2026/`. It is private; I have access. Expect **641 passing, 1 skipped**. Tip `2ea6efc`, `version: 1.0.0+114`.

Reference documents live in the public monorepo `https://github.com/isumitmalhotra/Ajoo-Admin-Website-`: `aajoo_app_2026/IOS_READINESS.md` (the full iOS picture, 15 September) and `SESSION_HANDOFF_2026-09-18_IOS.md`.

⚠️ **That monorepo is ~24 commits behind and will stay behind** — it is public, so infrastructure documentation is deliberately never pushed to it. Reference only. **The client repo above is the source of truth for app code.** It is also why the iOS CI is irrelevant now (see §5).

### 2. The state of the world, which those documents predate

- **The backend moved.** Production API is **`https://api.aajoohomes.com`** — a Render service in **Singapore** on a **fresh, EMPTY PlanetScale database**. `aajaodev.onrender.com` (Oregon + Clever Cloud) still runs and still holds the OLD data; the website no longer uses it.
- **The website is already on the new stack.** www.aajoohomes.com serves from Singapore.
- **The database is empty. No guest or host account exists** — only four admin accounts. **Nothing authenticated can be tested on any platform until someone registers a guest and a host.** There is **no OTP shortcut**: the fixed-code bypass and the `OTP_TEST_ACCOUNTS` allowlist were deleted from the code, not switched off, so a real mailbox is required (Mailinator drops our mail; `+` aliases on Gmail work).
- **Android build 114** (`1.0.0+114`, `sha256 05a44304…0d835`) is current and points at the new host. **One build number = one artifact across platforms:** the iOS build of `1.0.0+114` must come from the same commit with the same configuration.
- **Razorpay is still in test mode**; builds pass `--allow-test-payments` with `rzp_test_XUTODhUdMAshi6`.
- **Sign in with Apple is BUILT and DEPLOYED** on iOS, Android and the website, backed by `POST /user/auth/apple`, live on both API services, with `cred_apple_id` / `cred_apple_private_relay` migrated on both databases. See §4 — it has traps.

### 3. What is already done in the Apple/Google consoles

Do not redo any of this.

| | |
|---|---|
| Apple Developer Program | Enrolled, **Team `MN75V92B83`**, renews 13 Sep 2027 |
| Enrolled as | **Individual**, not Organisation — the App Store will show a person's name as seller, not "Aajoo". Changing it means a fresh enrolment with a D-U-N-S number and a transfer |
| App ID | `com.aajoo.aajoohomes` with **Push Notifications** and **Sign In with Apple** |
| APNs key | Created (Sandbox **&** Production, Team Scoped) and uploaded to Firebase `aajoo-bdb20` → Cloud Messaging, to **both** the development and production slots |
| Sign in with Apple key | Created; its `.p8` is in Firebase's Apple provider config |
| Services ID | **`com.aajoo.aajoohomes.web`**, return URL `https://aajoo-bdb20.firebaseapp.com/__/auth/handler` |
| Firebase Auth | Apple provider **enabled**, OAuth code flow configured |
| App Store Connect | App record **created** — `Aajoo Homes`, iOS, English (U.K.), SKU `aajoo-homes-ios`, **app id `6816023762`** |
| TestFlight | Internal group **`Aajoo Internal`** created with **automatic distribution on** (that setting cannot be changed later) |

**Still to be created, and they block the build:**

1. **iOS Maps key** — Google Cloud Console → same project → Credentials → new API key → restrict to **iOS app**, bundle `com.aajoo.aajoohomes`, enable **Maps SDK for iOS**. The Android key will NOT work: it is restricted to the Android signing certificate.
2. **`GoogleService-Info.plist`** — Firebase → `aajoo-bdb20` → Project settings → General → the **`com.aajoo.aajoohomes`** app. ⚠️ There are **two** iOS apps in that project; the other is `com.example.rentHome`, a leftover Flutter template. Taking the file from the wrong one costs an afternoon.

### 4. Sign in with Apple — three traps, all of which fail silently

Do not "simplify" any of these. Each has tests; read them before changing anything.

1. **The email arrives ONCE.** Apple returns the address on the first authorization and never again; later sign-ins carry only the stable subject. So the server identifies by subject and records the address at creation. Matching on email works exactly once per person and then creates a duplicate account.
2. **The name is not in the token at all.** Apple hands it to the client on first authorization, so it reaches the server only in the request body — a preference, never identity.
3. **The nonce goes out twice, in two forms.** Apple gets `sha256(raw)`; Firebase gets the raw string. Send the same form to both and Firebase refuses with a generic "invalid credential" that never mentions a nonce.

Plus: a **Google** Firebase ID token verifies on the Apple route perfectly well, so the route requires `firebase.sign_in_provider == "apple.com"`.

**And the iOS-specific one I fixed on 25 September:** `ios/Runner/Runner.entitlements` was missing `com.apple.developer.applesignin`. It now has it. **Xcode must also show "Sign in with Apple" under Signing & Capabilities**, or automatic signing issues a profile without the entitlement and the archive will not sign. `tool/build_ios.sh` now refuses to build if either required entitlement key is missing.

### 5. What to do first, on this Mac

The CI existed only because nobody had a Mac. **Build locally instead** — and the CI is stale anyway, since it lives in the monorepo that no longer receives pushes.

**Step 1 — prove it compiles here, no Apple account needed:**

```bash
tool/build_ios.sh --api https://api.aajoohomes.com --razorpay rzp_test_XUTODhUdMAshi6 \
  --allow-test-payments --no-codesign
python3 tool/verify_release_ipa.py build/ios/iphoneos/Runner.app https://api.aajoohomes.com \
  --allow-test-payments --allow-placeholders --expect-version=1.0.0+114
```

Report the **Xcode, CocoaPods and Flutter versions** you used. The CI pins Flutter **3.44.0**, and a local mismatch is the first thing that would explain any difference.

**Step 2 — fill the three placeholders** in `ios/Runner/Info.plist` (lines 113, 121, 128) from §3's two items. The verifier refuses a build that still carries them; that is deliberate, not a bug.

**Step 3 — signing.** `open ios/Runner.xcworkspace` (the **workspace**, never the `.xcodeproj` — that skips CocoaPods). Runner target → Signing & Capabilities → **Automatically manage signing** ✓ → Team **Nameesh Patiyal (MN75V92B83)** → Bundle Identifier `com.aajoo.aajoohomes` → confirm **Push Notifications** and **Sign in with Apple** are both listed.

**Step 4 — archive and upload.** Product → Destination → *Any iOS Device (arm64)* → Product → **Archive** → Organizer → **Distribute App → App Store Connect → Upload**. It lands in app `6816023762`, appears under TestFlight → Builds after 5–15 minutes of processing, and automatic distribution sends it to `Aajoo Internal`.

Export compliance will not stop the upload: `ITSAppUsesNonExemptEncryption = false` is already in Info.plist. The build number comes from `pubspec.yaml` and Apple requires it to be unique per upload — bump it every time.

**Step 5 — the Simulator**, as far as an empty database allows: launch screen, app name and icon, the login screen with both social buttons, the permission prompts, and whether anything breaks around the notch or home indicator. **Push does not work on the Simulator** (no APNs) — expected, not a defect.

**Do not** create accounts, enter passwords, or upload to TestFlight without asking me first.

### 6. Known outstanding work, in rough priority

1. **Account deletion with Apple token revocation.** Apple requires any app offering account creation to offer deletion, and an Apple-linked account must have its token revoked at Apple. **Not built.** It needs the Sign in with Apple `.p8` on our backend as a Render environment variable. This *will* be an App Review rejection if it is still missing.
2. **SPF excludes Brevo** — `v=spf1 include:secureserver.net -all`. Until `include:spf.brevo.com` is added, **Hide My Email is dead** (relay addresses bounce) and Apple's "Register Email Sources for Communication" step cannot pass.
3. **A guest and a host account on the new database** — blocks every authenticated drive on both platforms.
4. **The on-device drive** on a real iPhone. `IOS_READINESS.md` §4.2 has the flow list. The Android drives found five defects no test had; iOS will have its own.
5. **App Store listing** — 6.7" and 6.5" screenshots, privacy questionnaire, age rating, review notes with a test account and test card. Recommend iPhone-only for the first release.
6. **A 1024-px icon from the designer** — the current marketing icon is upscaled from the 512-px Android master.
7. **Digital Services Act trader status** — required before submitting to the EU App Store. Does not block TestFlight.

### 7. How I work

- Tell me plainly what you verified and what you did not. If something is untested, say so rather than implying it works.
- Where the code disagrees with a document, **change the code** — unless the document is `IOS_READINESS.md` or this brief, which describe a state of the world rather than a spec.
- Never write a credential into a repository file. The monorepo is public.
- Check `git status` in every repo before blaming a deploy.
- Reply in English.

Start by reading `IOS_READINESS.md`, then run Step 1 and tell me what the Mac says.

## (end of prompt)
