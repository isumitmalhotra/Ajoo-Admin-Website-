# Session handoff — 18 September 2026 → the iOS work on the Mac

**Read this first on the Mac.** It is written for a fresh Claude Code session
on macOS that has none of the Windows machine's memory. Everything it needs
to know about Aajoo Homes is either in this file or in a file it points at;
the single source of truth for open work is `MASTER_PENDING_TASKS.md` in this
repository (never an older edition of it).

---

## 0. GitHub on the Mac — yes, sign in first

Three of the four repositories are private (§1), so the Mac needs Sumit's
GitHub identity before anything but the monorepo clone will work.

```bash
brew install gh
gh auth login          # GitHub.com → HTTPS → "Login with a web browser": Sumit does this himself
gh auth setup-git      # so plain git clone/push over HTTPS uses the same login
gh auth status         # must say: Logged in to github.com account isumitmalhotra
```

The session never types the password, the one-time code or a token — Sumit
completes the browser step; the session only runs `gh auth status`
afterwards to confirm. If Sumit prefers SSH keys, `gh auth login` offers
that too and the remotes in §1 become `git@github.com:…`. Repository
secrets for the monorepo (§5a step 4) also go through `gh` under this login;
Sumit is the repo's admin, so `gh secret set` works without anyone else.

## 1. The repositories — clone all four

| What | Remote | Deploys to | Tip tonight |
|---|---|---|---|
| **Monorepo** (docs, trackers, the Flutter app under `aajoo_app_2026/`) | `https://github.com/isumitmalhotra/Ajoo-Admin-Website-.git` | not deployed | `f9d3729` |
| **Backend** (Node 20 / Express / Sequelize / MySQL) | `https://github.com/nameeshPatiyal100/aajaoBackend.git` | Render → `https://aajaodev.onrender.com` on push to `main` | `d07ed6f` |
| **Web** (React / TS / Vite; customer + host + admin) | `https://github.com/nameeshPatiyal100/Aajao-Admin-WebSIite.git` | Vercel → `https://www.aajoohomes.com` on push to `main` | `6b21875` |
| **Client's app repo** (app-only history, APKs stripped) | `https://github.com/nameeshPatiyal100/aajoo_app_latest.git` (private) | — | `b534bc7` = monorepo `427ed58` |

**Visibility, checked 18 Sep night:** the monorepo is **PUBLIC** (Sumit is
its admin); the backend, the web and the client's app repo are **PRIVATE**
(Sumit has write access as a collaborator, account `isumitmalhotra`). So:

- Cloning the monorepo needs no login; **pushing to it, and cloning or
  pushing the other three, needs GitHub sign-in on the Mac** — see §0.
- The public monorepo holds the whole app source and every client document
  (trackers, handoffs, PDFs, this file). Making it private is one click
  (repo Settings → Danger Zone → Change visibility) and changes nothing in
  the clone commands, but it **changes the CI bill**: on a public repo the
  `macos-15` compile job is free; on a private repo under GitHub Free the
  2,000 included minutes are charged at 10× for macOS, and the compile job
  took 12 min today (run 35362902160) — about 16 runs a month before Actions
  stops, unless a spending limit is set. Sumit's call; the doc assumes
  public until he says otherwise.

```bash
mkdir -p ~/Projects && cd ~/Projects
git clone https://github.com/isumitmalhotra/Ajoo-Admin-Website-.git "ajoo admin website"
git clone https://github.com/nameeshPatiyal100/aajaoBackend.git aajaoBackend-render
git clone https://github.com/nameeshPatiyal100/Aajao-Admin-WebSIite.git aajao-frontend-vercel
```

Keep the folder names above: the docs, scripts and tests refer to them
(the backend's PIN test reads `../aajao-frontend-vercel/src/redesign/lib/pinZones.ts`).
**Work on the app in the monorepo** (`aajoo_app_2026/`), not in the client's
copy; the client's repo is refreshed from the monorepo with `git subtree split`
(recipe in §9).

**Not in git, by design — copy by hand only if needed:**
- `aajaoBackend-render/.env` — the live DB credentials, keys. Needed only to
  run backend tests that touch the DB or to run migrations. **Never rotate
  `FIELD_ENCRYPTION_KEY`** (it lives on Render; the Windows copy of `.env`
  does not have it; losing it makes every stored bank account unrecoverable).
- `aajoo_app_2026/android/key.properties` + `android/app/aajoo-testing.jks` —
  Android signing. Not needed for iOS.
- Vercel and Render env vars — in their dashboards.

---

## 2. Where things stand tonight (what shipped 18 September)

All in `MASTER_PENDING_TASKS.md` §8a38–§8a42, summarised:

- **Build 105** (`1.0.0+105`) is the Android tester build; 100–104 superseded,
  98/99 withdrawn. Built only with `tool/build_release.ps1` (Windows) — see §4
  for the Mac twin.
- **Manual host payouts** are live: `PAYOUT_MODE=manual` by default, payout
  runs with a bank CSV and UTR-guarded recording, account verification by
  finance's own ₹1 transfer, detailed emails. Driven end to end on production
  today on developer hosts #177 and #194. RazorpayX stays dormant.
- **Maps**: Google (region IN) only on the web; the OSM fallback is gone
  (it drew J&K wrong). The app has always been Google-only.
- **Negotiation decisions** answered by the client: counter price unchanged
  (Option A); agreed deals show in the host's Upcoming tab while they run.
- **Hosting**: two client PDFs at the repo root —
  `AAJOO_HOSTING_RENDER_VS_AWS_2026-09-18.pdf` (recommendation: Render
  Singapore, 1 CPU/2 GB, Pro workspace) and
  `AAJOO_PLANETSCALE_AND_MANUAL_PAYOUTS_2026-09-18.pdf` (PlanetScale yes, in
  the same region as the API). Awaiting the client's answers.

Test counts tonight: backend 154/154, web 53/53 (+ `tsc -b` + `vite build`),
app 522/522 with `flutter analyze` 0 errors.

---

## 3. iOS — exactly where it is

**Code-complete and proven to compile on every push.** The GitHub workflow
`.github/workflows/ios-build.yml` (monorepo) runs a `compile` job on
`macos-15` for every push that touches the app: Flutter 3.44.0, `flutter
test`, `tool/build_ios.sh --no-codesign`, the IPA verifier with
`--allow-placeholders`, and the unsigned `Runner.app` kept as an artifact.
**Latest run: 35362902160, success, on `f9d3729` (tonight).** The
`testflight` job exists too (workflow_dispatch) and stops with a named list of
any missing secret.

**Nothing runs on an iPhone yet** because the client's Apple side does not
exist. The eight things only the client can do are §3 of
`aajoo_app_2026/IOS_READINESS.md` and master list §1.16:

1. Apple Developer Program enrolment (as an Organisation — D-U-N-S)
2. App ID `com.aajoo.aajoohomes` with Push on
3. APNs key (.p8) → Firebase Cloud Messaging → iOS app
4. `GoogleService-Info.plist` for the iOS app (carries the iOS OAuth client)
5. iOS-restricted Google Maps key
6. App Store Connect app record + internal TestFlight group
7. App Store Connect API key (App Manager)
8. Distribution certificate + App Store provisioning profile

Then the values go into the monorepo's repository secrets named in
`IOS_READINESS.md` §3, and the `testflight` job is run by hand.

**Two of those eight do not need Apple and may be doable from our side
now:** #4 and #5 live in the Firebase project and the Google Cloud project
(`aajoo-bdb20`) that Sumit already administers (he created the Android key
restrictions). Doing them first unblocks a real Simulator drive with working
maps and Google sign-in.

**Placeholders the verifier refuses in a signed build** (fine for
`--allow-placeholders` compile checks): `ios/Runner/Info.plist` →
`GMSApiKey = REPLACE_WITH_IOS_MAPS_KEY` and
`GIDClientID = REPLACE_WITH_IOS_CLIENT_ID.apps.googleusercontent.com`
(+ its reversed form as the URL scheme).

**Firebase already knows the iOS app**: `firebase_options.dart` carries the
iOS app values (`1:1006999733744:ios:…`, bundle `com.aajoo.aajoohomes`).

**What still has to be built for App Review** (not for TestFlight):
**Sign in with Apple** — Guideline 4.8 requires it beside Google sign-in. Both
sides: app (`sign_in_with_apple`, the button, the Apple provider in Firebase
Auth) and backend (verify Apple's identity token; create/link the account the
way the Google path does — mind the Google-account-lockout note: Google
sign-ups get an unusable password and role flags drift). About a day, plus
the client enabling the capability on the App ID. Details in
`IOS_READINESS.md` §4.

---

## 4. Mac setup — what to install and check first

```bash
# Xcode 16.x from the App Store, then:
sudo xcode-select -s /Applications/Xcode.app && sudo xcodebuild -license accept
xcodebuild -runFirstLaunch
# Flutter — the CI pins 3.44.0 stable; match it (fvm or the direct download)
flutter --version        # must read 3.44.0
# CocoaPods
sudo gem install cocoapods   # or brew install cocoapods
flutter doctor -v        # Xcode + CocoaPods green; Android toolchain optional on the Mac
```

Then, in the monorepo:

```bash
cd "aajoo admin website/aajoo_app_2026"
flutter pub get
(cd ios && pod install)
flutter test                                   # expect 522 passing
flutter analyze                                # 0 errors (the ~385 infos are known lints)
# Compile check, exactly what CI does (no Apple account needed):
chmod +x tool/build_ios.sh
tool/build_ios.sh --api https://aajaodev.onrender.com --razorpay rzp_test_XUTODhUdMAshi6 \
  --allow-test-payments --allow-dev-endpoint --no-codesign
python3 tool/verify_release_ipa.py build/ios/iphoneos/Runner.app https://aajaodev.onrender.com \
  --allow-test-payments --allow-placeholders --expect-version=1.0.0+105
```

(Those are the exact flags CI passes — `.github/workflows/ios-build.yml`
lines 65 and 162; the script refuses an http URL, an onrender endpoint
without `--allow-dev-endpoint`, and a test key without
`--allow-test-payments`.) **Never** build a release with plain `flutter build ios`: the release
configuration is `--dart-define`d in by the script, and a build without it
installs and reaches nothing ("This build is not configured" — builds 98/99
were withdrawn for exactly this).

**Simulator drive** (no Apple account needed):
`open -a Simulator` → `flutter run -d <iPhone simulator> --dart-define=API_BASE_URL=https://aajaodev.onrender.com --dart-define=RAZORPAY_KEY=rzp_test_XUTODhUdMAshi6 --dart-define=ALLOW_TEST_PAYMENTS=true`.
Known Simulator limits (by design, `IOS_READINESS.md` §5): **no push** (no
APNs), maps blank until #5 above is done, Google sign-in fails until #4,
Razorpay's UPI intent list depends on installed apps. Drive the rest.

---

## 5. The iOS task list on the Mac, in order

1. **Environment** (§4) until `flutter test` and the `--no-codesign` build pass locally.
2. **The two Google-side items (§5a)** — the Firebase plist for the iOS app
   and an iOS-restricted Maps key. Sumit does them in the consoles; the
   session wires the results in with `tool/ios_local_secrets.sh` and puts
   the same values into the repository secrets. **This is the first real
   task on the Mac** — the session should check the state in §5a.0 and, if
   either item is missing, ask Sumit for it before anything else.
3. **Simulator drive** of `IOS_READINESS.md` §4.2's list, minus push. Log every
   defect as a §8a-style entry in the master list; fix web/app in the same
   pass when a defect is shared (parity rule, §7).
4. **Sign in with Apple** — app + backend + tests. Backend pattern: mirror the
   Google path in `controllers/auth*.js`/the auth service; the web does not
   need it (Apple's rule is about the iOS app).
5. **1024-px marketing icon** from the designer (the current one is upscaled).
6. **When the client's Apple account exists**: secrets → Actions → iOS build →
   Run workflow → testflight → device drive (§4.2, all of it, push included)
   → App Store Connect listing (§4.3) → Review. One build number per artifact:
   the iOS build of `1.0.0+N` is the Android build of `1.0.0+N`, same commit.

---

## 5a. The Google-side prerequisites — step by step

Both live in the **one** Google project the platform already uses:
Firebase project **`aajoo-bdb20`** = Google Cloud project `aajoo-bdb20`
(Sumit administers it — he set the Android key restrictions there). No
Apple account is involved in any of this. The iOS app is **already
registered** in Firebase: app id `1:1006999733744:ios:d18b876d15ef8a2b050935`,
bundle id `com.aajoo.aajoohomes` (in `lib/firebase_options.dart`), so
nothing has to be created in Firebase — only downloaded.

### 5a.0 How the Mac session tells what is still missing

```bash
cd "aajoo admin website/aajoo_app_2026"
ls ios/Runner/GoogleService-Info.plist 2>/dev/null || echo "MISSING: Firebase plist (step 1)"
grep -c REPLACE_WITH ios/Runner/Info.plist        # 3 = placeholders still in place (normal in git; fill locally with step 3)
gh secret list -R isumitmalhotra/Ajoo-Admin-Website- | grep -E "IOS_MAPS_KEY|IOS_GOOGLE_CLIENT_ID|IOS_GOOGLE_SERVICE_INFO_PLIST_BASE64" \
  || echo "MISSING: the three Google secrets (step 4)"
```

As of 18 Sep night all three are missing: no plist on any machine, the
placeholders in Info.plist, no `IOS_*` secrets on the repo (the Apple ones
are missing too, but those wait for the client — §3).

### 5a.1 Download the iOS `GoogleService-Info.plist` (Sumit, ~3 minutes)

1. https://console.firebase.google.com → project **aajoo-bdb20** → gear
   next to *Project Overview* → **Project settings** → *General* tab →
   scroll to **Your apps**.
2. Select the **iOS** app (`com.aajoo.aajoohomes`; it sits beside the
   Android app). Click **GoogleService-Info.plist** (download button). It
   lands in `~/Downloads`.
3. Check it carries the Google Sign-In client — the session can do this,
   it prints ids, not secrets:
   ```bash
   /usr/libexec/PlistBuddy -c "Print :CLIENT_ID" ~/Downloads/GoogleService-Info.plist
   /usr/libexec/PlistBuddy -c "Print :REVERSED_CLIENT_ID" ~/Downloads/GoogleService-Info.plist
   /usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" ~/Downloads/GoogleService-Info.plist   # must be com.aajoo.aajoohomes
   ```
   `CLIENT_ID` must end in `.apps.googleusercontent.com`. **If the key is
   absent**, Firebase has not minted an iOS OAuth client yet: Firebase →
   *Build → Authentication → Sign-in method → Google* — it is already
   enabled for Android; open it, press *Save* once (that re-provisions the
   OAuth clients for every registered app), then download the plist again.
   If it is still absent, create it by hand: https://console.cloud.google.com
   → project aajoo-bdb20 → *APIs & Services → Credentials → Create
   credentials → OAuth client ID → iOS* → bundle id `com.aajoo.aajoohomes`
   (App Store id and Team id can stay empty) → copy the client id into
   `~/.aajoo/ios.env` as `IOS_GOOGLE_CLIENT_ID=…` (step 3). Same project, so
   Firebase Auth accepts it without any safelisting.
4. Move it into place — it is gitignored (`/ios/Runner/GoogleService-Info.plist`),
   so `git status` stays clean:
   ```bash
   mv ~/Downloads/GoogleService-Info.plist "aajoo admin website/aajoo_app_2026/ios/Runner/GoogleService-Info.plist"
   ```
   Nothing in the backend changes for this: the app sends Firebase's ID
   token and `controllers/googleAuth.controller.js` verifies it with
   `admin.auth().verifyIdToken`, which does not care which platform's OAuth
   client produced it.

### 5a.2 Create the iOS-restricted Maps key (Sumit, ~5 minutes)

1. https://console.cloud.google.com → project selector → **aajoo-bdb20**.
2. *APIs & Services → Library* → search **Maps SDK for iOS** → **Enable**
   (the Android and JavaScript SDKs are already enabled; this one is not).
   `geocoding` on iOS uses Apple's CLGeocoder, so no Geocoding API is needed
   for the app.
3. *APIs & Services → Credentials → + Create credentials → API key*. Rename
   it **Aajoo iOS Maps** (pencil icon), then:
   - *Application restrictions* → **iOS apps** → *Add* → bundle id
     `com.aajoo.aajoohomes` → Done.
   - *API restrictions* → **Restrict key** → tick only **Maps SDK for iOS**.
   - **Save.** (Restrictions take a few minutes to apply.)
4. Copy the key into a file the session can read but the chat never sees:
   ```bash
   mkdir -p ~/.aajoo && chmod 700 ~/.aajoo
   printf 'IOS_MAPS_KEY=PASTE_THE_KEY_HERE\n' > ~/.aajoo/ios.env && chmod 600 ~/.aajoo/ios.env
   open -e ~/.aajoo/ios.env      # Sumit pastes the key in TextEdit and saves
   ```
   **Do not paste the key into the chat, a commit, or the master list.**
   Refer to it by its last six characters, as the other keys are.
5. Add the new key to the same billing budget alert as the Android and
   browser keys (master list §2.6) — *Billing → Budgets & alerts* on the
   same project; the key inherits the project's budget, so this is only a
   check that the alert exists.

### 5a.3 Wire both into the local app for the Simulator drive (the session)

```bash
cd "aajoo admin website/aajoo_app_2026"
chmod +x tool/ios_local_secrets.sh
tool/ios_local_secrets.sh          # fills GMSApiKey, GIDClientID and the callback URL scheme in ios/Runner/Info.plist
grep -c REPLACE_WITH ios/Runner/Info.plist   # must now print 0
```

The script (new tonight; mirrors the three PlistBuddy lines the `testflight`
job runs, and has not been executed yet — there is no PlistBuddy on the
Windows machine) reads `~/.aajoo/ios.env` and takes the client id from the
plist's `CLIENT_ID` unless `IOS_GOOGLE_CLIENT_ID` is set. **`Info.plist` is a
tracked file with the real key in it now**: before every commit run
`tool/ios_local_secrets.sh --restore` and confirm `git status` does not list
`ios/Runner/Info.plist`. Commit by naming files, never `git add -A`.

Then the drive: `open -a Simulator`, `flutter run -d <iPhone>` with the
dart-defines from §4. Maps should draw tiles, Google sign-in should reach
the account picker (then the backend), push stays off (no APNs on a
Simulator). If maps are blank, the SDK is not enabled yet or the
restrictions are still propagating — the AppDelegate logs
`Aajoo: GMSApiKey is not set` only when the placeholder is still there, so
a blank map with no log line is a key/SDK problem, not a wiring one.

### 5a.4 Put the same values into the repository secrets (the session, under Sumit's login)

So the `testflight` job has them the day the Apple secrets arrive:

```bash
cd "aajoo admin website/aajoo_app_2026"
. ~/.aajoo/ios.env
R=isumitmalhotra/Ajoo-Admin-Website-
gh secret set IOS_MAPS_KEY -R $R --body "$IOS_MAPS_KEY"
gh secret set IOS_GOOGLE_CLIENT_ID -R $R --body "$(/usr/libexec/PlistBuddy -c 'Print :CLIENT_ID' ios/Runner/GoogleService-Info.plist)"
gh secret set IOS_GOOGLE_SERVICE_INFO_PLIST_BASE64 -R $R --body "$(base64 -i ios/Runner/GoogleService-Info.plist)"
gh secret list -R $R     # the three IOS_* rows appear; values are never shown
```

Secrets on a public repo are fine — Actions exposes them only to workflows
of this repository, never to a fork's pull request. After this, the
readiness picture is: **Google side done; the eight Apple-side actions
(§3) remain**, and the `testflight` job will list exactly the Apple secrets
still missing when run.

### 5a.5 Record it

Add a dated `8a` entry to `MASTER_PENDING_TASKS.md` §8 saying the two
Google items are done (key by last six characters, plist by its `GOOGLE_APP_ID`),
tick step 4 and step 5 in `aajoo_app_2026/IOS_READINESS.md` §3, and push.

## 6. Non-negotiable rules (from the Windows machine's memory — keep them)

- **Never type a stored password or credential into any field** (web, app,
  emulator, simulator, API). Sumit signs in; the session then drives. No
  account creation either.
- **Never test live on the client's accounts** — guest *Aajoo Renter* (user
  101) or host *Sam Tao* (user 100). Use our own: guest **179 "Renter test
  web"**, host **#194 (Sumit)** or **#177 "Host Mobile"** (dev host). A test
  deal left on 101 was once reported by the client as a bug.
- **Never print card details, Razorpay keys, API keys or PII in chat.** Refer
  to keys by their last six characters.
- **Never rotate `FIELD_ENCRYPTION_KEY`.** Never paste AWS keys anywhere.
- **Test only development records.** Never a real booking, payout, refund,
  support case or customer account for a destructive test.
- **One build number = one artifact.** Never rebuild an existing number with
  different content; withdraw a number if a drive finds a defect.
- **Web ⇄ app parity**: a renter/host bug is fixed on both platforms in one pass.
- **Where code differs from a client document, change the CODE.**
- **Always reply in English**, even when Sumit writes in Hinglish.
- **DB migrations do not run on deploy.** From the backend repo, with `.env`:
  `npx sequelize-cli db:migrate` (the CLI is in devDependencies). Read the
  migration before applying it to the live database; additive only without
  a conversation.
- `api.aajoohomes.com` **serves nothing** (points at Vercel, answers 404).
  Every APK has `aajaodev.onrender.com` compiled in. Do not build against
  the dead domain until it is pointed at the API (hosting decision pending).
- The deployed backend allows **only production origins**; a page served
  from localhost cannot call it directly — the web repo's `vite.config.ts`
  has a dev proxy (`/__api`) and `.env.local` sets `VITE_API_BASE_URL=/__api`.
- Dates are **DD-MM-YYYY** throughout the API. Money columns are DECIMAL and
  the driver returns strings — always `Number()`.
- Line endings are mixed across the repos (Windows history);
  `aajoo_app_2026/.gitattributes` normalises Dart to LF. Tests that read
  source normalise `\r\n` → `\n` before asserting. Do the same in new tests.

---

## 7. Open threads that are NOT iOS (so the Mac session does not re-do them)

| Thread | State | Who moves it |
|---|---|---|
| Hosting: Render (Singapore, 1c-2g, Pro) vs AWS (blocked on the client's unverified card) | Two PDFs sent 18 Sep; awaiting answers | Client |
| Database: PlanetScale (same region as the API) | PDF sent; awaiting answer | Client |
| Payouts: bank name for the bulk-file column order; TDS §194-O rate | Awaiting the company's bank and accountant | Client |
| 300-case manual test run | Batches 1–2 done (60/300), report at `report-2026-09-17/TEST_RUN_300/RESULTS.md`; batches 3–10 need our own guest + host accounts signed in | Sumit signs in; a session drives |
| Google keys | Android Firebase key `…iCk-WI` still needs its Android-app restriction; Maps browser key `…T0_n34` referrer-restricted | Sumit, Google Cloud |
| "Villas -1" category name and 9 categories without images | Admin data, one click each (§1.11) | Client/admin |
| Client's app repo | Refreshed after every app build (§9) | Any session |

---

## 8. Verifying a change before calling it done (the house standard)

- Backend: `for f in tests/*.test.js; do node "$f" >/dev/null 2>&1 || echo "FAILED $f"; done` (154 files). Tests must exercise behaviour, not just read source; a guard that "reads right" but never runs has bitten this project before.
- Web: `for f in tests/*.test.mjs; …` (53) **and** `npm run build` (`tsc -b` + Vite — a `--noEmit` check misses errors that block the deploy).
- App: `flutter test` (522) and `flutter analyze` (0 errors).
- Then drive it: emulator/simulator or the live site (as our own accounts), read the payload, screenshot every screen. A caught error can make a broken feature look finished — verify at the payload.
- Record the outcome in `MASTER_PENDING_TASKS.md` §8 as a dated `8a` entry, with what was verified and what was not, and update the header's tester-build line when a build ships.

---

## 9. Refreshing the client's app repo after an app change

From the monorepo (history without APK blobs; the fast-forward check protects the client's `main`):

```bash
git branch -D app-export 2>/dev/null; git subtree split --prefix=aajoo_app_2026 -b app-export
B=/tmp/app_push.git; rm -rf "$B"; git clone -q --bare --branch app-export --single-branch . "$B"
cd "$B" && FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --index-filter 'git rm --cached --ignore-unmatch -q "*.apk" "*.aab"' --prune-empty -- --all
rm -rf refs/original && git reflog expire --expire=now --all && git gc --prune=now --aggressive
git fetch -q https://github.com/nameeshPatiyal100/aajoo_app_latest.git main:refs/remotes/client/main
git merge-base --is-ancestor refs/remotes/client/main app-export && git push https://github.com/nameeshPatiyal100/aajoo_app_latest.git app-export:refs/heads/main
```

Before the first push of a day, clone the result and run `flutter test` on the clone — a fresh checkout has caught two CRLF-dependent tests before.

---

## 10. Files to read on the Mac, in this order

1. `MASTER_PENDING_TASKS.md` — header (current build, repos, deploy), §1–§2 (open), §8a38–§8a42 (this week), §9 (how to keep it honest).
2. `aajoo_app_2026/IOS_READINESS.md` — all of it.
3. `aajoo_app_2026/tool/build_ios.sh`, `tool/verify_release_ipa.py`, `.github/workflows/ios-build.yml`.
4. `aajoo_app_2026/REDESIGN_WIRING_STATUS.md` and `MOBILE_APP_TASKLIST.md` — app parity gaps.
5. `report-2026-09-17/TEST_RUN_300/RESULTS.md` — the test-case run and its batch plan.

**Then run §5a.0** — the three commands that say what is missing — and
report the result to Sumit before starting; that is how the session
identifies the Google items as the next step rather than re-deriving it.

Suggested first memory notes for the Mac session (its own `memory/`): the four
remotes and deploy targets; the "never on 100/101, use 179/194/177" rule; the
build-script rule; `FIELD_ENCRYPTION_KEY` never rotates; migrations do not
auto-run; the placeholders in Info.plist and who fills them.

---

*Written 18 September 2026 at the end of the Windows session. Everything in
all four repositories is pushed; nothing is uncommitted.*
