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

## ✅ BLOCKER 1 — upload key: reset REQUESTED 2026-10-05

Play Console now reads *"There is a pending request for resetting the upload key
of this app."* Submitted with reason **"I lost my upload key"**.

| | |
|---|---|
| New upload key | `D:/Projects/aajoo_upload_key_2026-10-05/aajoo-upload.jks`, alias `upload` |
| Its certificate | SHA-256 `D9:6D:EA:13:B0:DA:74:AE:6D:B3:59:25:21:E2:9C:AC:F2:2A:24:52:19:0A:B4:F7:58:76:C3:A5:26:83:49:8E` |
| Key | 4096-bit RSA, SHA384withRSA, valid to **20 Feb 2054** |
| Key Play still expects until approval | `55:A4:97:CB:77:BD:7C:AD:…:A6:34` |

**Do not switch `key.properties` yet.** Until Google approves, Play still accepts
only the old key — which we do not have — so nothing can be uploaded either way;
after approval only the NEW key works. Switch `storeFile` and `keyAlias` to the
new keystore at that point, in one change, so there is never a window where the
file and the console disagree.

**The keystore is the one secret that cannot be regenerated.** It sits outside
every repo deliberately; `**/*.jks` and `key.properties` are gitignored and have
never been committed (checked across all history). It needs a backup somewhere
that is not this machine.

The old `android/app/aajoo-testing.jks` is dead — it was never the upload key.

---

## Historic — how the mismatch was found

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

### 6. Data safety — COMPLETE 2026-10-05, staged, not yet sent for review

Exported from the console 2026-10-05. What is declared today:

* Personal info: **Name, Email address, Phone number**
* Location: **Approximate, Precise**
* **Files and docs**
* Every item "Collected" (not shared), "required", purpose **App functionality**
* Account creation: **username and password only**
* Data deletion: **"No, but user data is automatically deleted within 90 days"**
* Encrypted in transit: **false**

Four of those are not true of the app that exists.

#### a. "Encrypted in transit: false" — wrong, and it publishes badly

There is no `usesCleartextTraffic`, no network security config, and **not one
`http://` host anywhere in `lib/`**. Everything goes to
`https://api.aajoohomes.com` and to HTTPS third parties. The declaration
currently prints **"Data isn't encrypted in transit"** on the public store
listing — a visible red flag to every person deciding whether to install, and
untrue.

#### b. Account creation says password-only, but the app has two OAuth paths

`google_sign_in: ^6.3.0` and `sign_in_with_apple: ^6.1.4`, wired in
`auth_controller.dart`, `apple_sign_in.dart` and `auth_page.dart`. Sign in with
Apple has been live since 09-24. **`OAuth` has to be ticked.**

#### c. FIXED (a) and (b); (c) was my mistake — read the question in full

**Corrected 2026-10-05.** I reported that the form "says there is no way to
request deletion" and that the deletion URL "does not exist yet". Both wrong.

* A **Delete account URL is already filled in** and works:
  `https://api.aajoohomes.com/account-deletion-policy` returns **200** and
  serves a real Account Deletion Policy page. The Play account-deletion
  requirement is already satisfied.
* The question I misread is the **optional** one underneath it: *"Do you
  provide a way for users to request that **some or all** of their data is
  deleted, **without requiring them to delete their account**?"* That is about
  PARTIAL deletion, which is a different thing from the Delete Account button
  in `settings_page.dart`.

**The real problem with that answer is different, and still a problem.** It
currently claims *"No, but user data is automatically deleted within 90 days."*
Nothing in the backend does that. The five scheduled services are
`balanceReminders`, `bookingApprovalExpiry`, `negotiationExpiry`,
`payoutRunReminder` and `stayCompletion` — reminders and expiries, none of
which delete user data. A booking platform holding tax and payout records is
unlikely to auto-purge at 90 days either.

So the declaration promises users a retention behaviour that does not exist.
The truthful answer is probably plain **"No"**, but that is a claim about the
business's retention policy rather than something provable from the code, so
**it is left unchanged pending a decision.**

#### d. Missing data types

| Missing | Why it is collected |
|---|---|
| **Photos** | `ImagePicker` in 6 files — listing photos, profile photos, KYC capture. "Files and docs" is a different category and does not cover it |
| **Purchase history** | the app shows booking and transaction history from our own backend |
| **User payment info** | Razorpay collects card details inside the app. There is genuine ambiguity about the processor exemption — **check the policy before answering**, do not guess either way |
| **User IDs** | the account id the backend issues and the client stores |
| **Device or other IDs** | FCM push tokens, `firebase_messaging` |

Identity documents (DIDIT KYC) have no category of their own; they land under
Personal info → other, or Photos for the captured document. **Decide this
deliberately** — identity documents and financial info are *sensitive* under
Play policy, so getting these wrong is a policy violation rather than an
untidy form.

> Source export: `data_safety_export.csv`, pulled from the console on
> 2026-10-05. Everything above was checked against the code, not inferred from
> the form.

#### Corrected and saved 2026-10-05 (verified after a full page reload)

| Answer | Was | Now |
|---|---|---|
| Encrypted in transit | **No** | **Yes** — preview reads "Data is encrypted in transit" |
| Account creation | password only | **password + OAuth** |
| Partial-deletion question | "auto-deleted within 90 days" | **No** — the false retention promise is gone |

Staged in **Publishing overview as "Changes not yet submitted for review"**, and
deliberately NOT sent: the data-type corrections below are still outstanding and
sending now would spend a review cycle on a half-corrected form. Send once, with
the release.

**Still open, needs a decision:** Photos, Purchase history, User IDs, Device or
other IDs — all collected, none declared. And the payment-info question, which
turns on whether Razorpay's in-app collection falls under the processor
exemption. Sensitive category; read the policy rather than guessing.

#### The four missing data types, added 2026-10-05

Verified by reloading the page and re-reading each section's own counter, not
by trusting a save toast:

| Section | After |
|---|---|
| Personal info | **4/9** — Name, Email, Phone + **User IDs** |
| Financial info | **1/4** — **Purchase history** only |
| Photos and videos | **1/2** — **Photos** (not Videos) |
| Device or other IDs | **1/1** |
| Files and docs | 1/1 (already there; it is where the KYC document belongs) |

Each is **Collected**, not Shared — Cloudinary, Razorpay and Firebase are
service providers processing on our behalf, and Play's own guidance says a
transfer to a service provider is not sharing. None are ephemeral. Purposes:
App functionality, plus Account management on User IDs.

**Photos is the one marked "users can choose"**, the others required: a renter
can use the whole app and never upload one, so it is an elected action rather
than a condition of using the app.

#### User payment info is deliberately NOT declared

Play's guidance: you need not declare what a payment service collects *"if …
Your app never accesses this information; and The payment service collects this
information directly from the user, and collection is governed by that service's
terms."*

Both hold. Our code passes `amount`, `order_id` and prefill name/email/phone,
then calls `razorpay.open()`; Razorpay's SDK draws its own checkout and no card
number ever reaches our code. **Purchase history is still declared** — that is
our own backend's booking and transaction records, which is a different thing.

> This was the one genuine ambiguity. It was resolved by reading the policy,
> not by guessing, and it resolved toward NOT declaring.

#### Managed publishing is now ON

Was off, which means an approved release goes live the moment Google says yes.
For a first production launch that hands the timing to the reviewer. With it on,
approval parks the release in "Changes ready to publish" and **somebody has to
press publish** — which is what you want when the release is coordinated with a
client, a payment gateway switch or an announcement.

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
