# Android — Play Store production release

**Checked live in Play Console on 2026-10-05**, account `aajoodev@gmail.com` →
developer **Aajoo Homes** (personal, ID `7426732159063341052`), app
**Aajoo Homes: Real-Time Stays** (`com.aajoo.aajoohomes`, ID `4976284914285218081`).

---

## Where the app actually stands

| | |
|---|---|
| Production track | **Inactive** — but a draft release exists, 178 countries already chosen |
| Production access | **Not gated.** No "apply for production access", no 12-tester/14-day wait |
| Current state | **Closed testing**, 3 testers |
| Bundles Play has | versionCode **1, 2, 3** — all 1.0.0, uploaded Oct–Nov 2025 |
| Store listing | **Live**, last updated 28 Oct 2025 |
| App content declarations | **All complete** — "You're all caught up" |
| Local app | Flutter 3.44 · JDK 21 · AGP 8.6 · Gradle 8.7 · compileSdk **36** · versionCode **120** |

Two pleasant surprises: the account is **not** subject to the 12-testers-for-14-days
rule, and every policy declaration is already filled in. Those were the two things
that could have cost two weeks. Neither applies.

---

## 🔴 BLOCKER 1 — the upload key on this machine is the wrong key

Play has registered this upload certificate:

```
SHA-256  55:A4:97:CB:77:BD:7C:AD:47:C0:1F:6B:67:18:24:29:3D:14:9F:4E:00:FA:9A:07:C0:82:8E:84:99:37:A…
```

The only keystore on this machine, `android/app/aajoo-testing.jks`, signs as:

```
SHA-256  1F:8A:60:76:E2:C2:DB:39:0E:8D:C9:03:95:B7:CD:85:0E:0C:77:67:38:98:95:47:ED:88:FA:0C:EF:4A:A1:13
Owner    CN=Aajoo Homes, OU=Testing, O=Aajoo, L=NA, ST=NA, C=IN
Created  08 Jun 2026
```

**They are different keys.** Any bundle built here is rejected with *"Your Android
App Bundle is signed with the wrong key."* The dates explain it: Play's bundles
went up in Oct–Nov **2025**; this keystore was made in June **2026**. The real
upload key belongs to whoever built the Oct/Nov 2025 release and is not on this
machine — a search of `D:/Projects` and the user profile found no other keystore,
and none was ever committed to git.

**This is not fatal to the app's identity.** Play App Signing holds the *app
signing key*, so the app keeps its identity and existing installs upgrade
normally. Only the upload key changes.

Two ways out, in order of preference:

1. **Find the original keystore.** Ask the client / whoever cut the Nov 2025
   build. If it turns up, use it and this blocker evaporates today.
2. **Request an upload key reset** — Play Console → Test and release → App
   signing → *Request upload key reset*. Google typically actions it in 1–2
   business days. Then register a proper production key.

**If we go the reset route, do not register `aajoo-testing.jks`.** It is named
and stamped `OU=Testing`. Generate a clean production upload key, store it off
this machine, and back it up — this is the one secret that cannot be regenerated.

> Direct link: Test and release → App signing →
> `…/app/4976284914285218081/keymanagement`

---

## 🔴 BLOCKER 2 — Android developer verification is overdue

Console warning, deadline **30 Sep 2026 — already passed**:

> *"Play apps not registered will be removed from Play globally."*

This is account-level, not app-level, and it is the one with the harshest
consequence on the list. It needs the account owner to complete verification
under **Android developer verification** in the left nav of the developer home.
Nobody else can do it.

---

## 🔴 BLOCKER 3 — target API level

Console warning, deadline **31 Aug 2026 — already passed**:

> *"Update your target API level by August 31, 2026 to release updates to your app."*

`android/app/build.gradle` pins `targetSdk = 35`. Required is **36**.

**This is a one-line change, not a toolchain upgrade.** Flutter 3.44 already
defines `compileSdkVersion = 36` and `targetSdkVersion = 36`, and the app already
compiles against 36 — only `targetSdk` was hardcoded back to 35:

```gradle
targetSdk = flutter.targetSdkVersion   // was: targetSdk = 35
```

**But it needs real QA after.** Targeting API 36 forces **edge-to-edge** on
Android 15+ with no opt-out. Bottom-anchored controls and sheets are exactly
where this app has had inset bugs before (see the bottom-anchored-controls and
narrow-screen notes). Every screen with a bottom bar, sheet or sticky button has
to be driven on an Android 15/16 emulator before this ships.

---

## Build and release — once the three blockers clear

### 4. Rebuild the bundle (the one on disk is stale)

`build/app/outputs/bundle/release/app-release.aab` is from **25 Sep 2026** and
predates the last fortnight of work. Rebuild:

```powershell
./tool/build_release.ps1 -AppBundle -ApiBaseUrl https://api.aajoohomes.com -RazorpayKey <live key>
```

The script refuses a dev endpoint, preflights `GET /health`, and runs
`verify_release_apk.py` to prove the production host is actually inside the
artifact. **A release build has no baked-in API host** — it comes only from
`--dart-define=API_BASE_URL`. Omit it and you ship an app that cannot call
anything.

versionCode: local is **120**, Play's highest is **3**. No conflict, plenty of
headroom.

### 5. Refresh the store listing

Live, but last touched **28 Oct 2025** — before the Sand & Indigo redesign and
LUX mode. The screenshots show an app that no longer exists. Needs new phone
screenshots, and the description re-read for anything now untrue.

### 6. Re-check Data safety against what the app does *now*

Declared Oct 2025. Since then the app gained **KYC document capture (DIDIT)**
and **live payments**. Data safety has to match reality or it is a policy
violation, so this is a re-read, not a tick-through.

### 7. App access instructions — the one reviewers fail apps for

The app is behind a phone-OTP login wall. Google's reviewer cannot get in
without working credentials. Play Console → App content → **App access** needs a
test account plus a way past OTP. Without it the usual outcome is rejection for
an unreviewable login wall.

### 8. Create the production release

Production track → the existing draft → attach the new bundle, write release
notes, confirm the 178 countries, choose a staged rollout percentage, submit.

---

## What only a person can do

1. **Complete Android developer verification** (account owner — overdue).
2. **Produce the original upload keystore, or approve the reset request.**
3. **Supply the live Razorpay key** for the release build.
4. **Decide the rollout percentage** and whether to go out at 100% or staged.

## Order of play

Blockers 2 and 3 can run in parallel with blocker 1, and blocker 1 has the
longest lead time. **Start the upload key hunt / reset request first** — the
code work is hours, the key is days.
