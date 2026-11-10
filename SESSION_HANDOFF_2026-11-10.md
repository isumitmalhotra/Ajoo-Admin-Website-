# Session handoff — Aajoo platform, 10 November 2026

Written for a session starting cold in another account. Everything below marked
**verified** was checked against the live system or the repos today, not
carried over from notes. Everything marked **unverified** needs an account I
do not have — say so rather than assuming.

This supersedes the November handoff produced in the Antigravity session on
three points; see §5.

---

## 1. The remote mix-up — resolved 10 November

A previous session believed `aajoo_app_2026/` was its own git repository and
repointed the **monorepo's** `origin` at the client's Flutter app repo. It is
not — it is a directory inside the monorepo, and the two have unrelated
histories and different tree shapes.

**Resolved.** `origin` is back to `isumitmalhotra/Ajoo-Admin-Website-`, local
`main` tracks it, and `git push --dry-run` reports "Everything up-to-date".
The client's repo was never touched — verified at tip `ea17695`, 22.9 MB, zero
`.apk`/`.aab`.

Nothing was lost: the "1007 unpushed commits" git reported was monorepo
history measured against unrelated app-repo history. With unrelated histories
a plain push would have been *rejected* as non-fast-forward; the real hazard
was someone force-pushing to clear that rejection.

## 1a. One copy of the app, from now on

The app is developed in **`nameeshPatiyal100/aajoo_app_latest`**, cloned on
this machine at **`D:\Projects\aajoo_app_latest`**. In that repo the app is at
the **ROOT** — `lib/`, `ios/`, `pubspec.yaml` — not under a prefix. The Mac
clones the same repo. Verified there today: `flutter test` → **774 passing,
1 skipped**.

`aajoo_app_2026/` in the monorepo stays, and stays correct, but must not be
edited. It now carries `DO_NOT_EDIT_HERE.md` (commit `0623166`) saying so.

> **It is a faithful copy, not a stale one.** Compared file by file today:
> **610 identical, 0 present only in the monorepo**, and the 3 reported
> differences were stray carriage returns with byte-identical content. The 2
> extra files in the app repo are the iOS docs. Nothing is lost by leaving it
> alone.

**This repo has already shipped the double-edit mistake once:** the Google
Analytics tag was added both to the frontend repo, where it deploys, and to
the stale `index.html` at the monorepo root, where it does nothing. That root
`index.html` is a dead copy of the frontend's — do not edit it, ever.

---

## 2. Repository map (corrected)

| What | Path | Remote | How it ships |
|---|---|---|---|
| **Backend API** | `D:\Projects\aajaoBackend-render` | `nameeshPatiyal100/aajaoBackend` | push `main` → Render auto-deploys → `api.aajoohomes.com` **and** `www.aajoohomes.com` |
| **Web frontend** | `D:\Projects\aajao-frontend-vercel` | `nameeshPatiyal100/Aajao-Admin-WebSIite` | submodule `web/` of the backend, built in its Dockerfile — see §3 |
| **Flutter app (client/prod)** | `D:\Projects\aajoo_app_latest` | `nameeshPatiyal100/aajoo_app_latest` | **app is at the repo ROOT.** Edit the app here and nowhere else; the Mac builds from this repo |
| **Monorepo (internal)** | `D:\Projects\ajoo admin website` | `isumitmalhotra/Ajoo-Admin-Website-` | **PUBLIC**, not deployed. Docs, trackers, build artifacts. Holds a **read-only mirror** of the app at `aajoo_app_2026/` — see §1a |

The monorepo and the client app repo are **different repositories with
unrelated histories**. The app repo was created once by a subtree split with
every APK stripped. **Never split again** — mirror the monorepo's tracked
`aajoo_app_2026/` tree onto the client repo's tip and commit. Last sync:
3 November, builds 118→128.

**The monorepo is public.** Never commit a credential to it.

### Current state (verified today)

| Repo | Tip | Clean? |
|---|---|---|
| Backend | `955075c` | clean, 0 unpushed |
| Frontend | `32db178` | clean, 0 unpushed |
| Monorepo | `94b15cb8` | 26 untracked docs; in sync with its real remote |
| Client app repo | `ea17695` | 22.9 MB, 0 APKs |

---

## 3. How the website actually deploys — read this before trusting either doc

The Antigravity handoff says the frontend "auto-deploys to Vercel". My own
notes said the opposite: that a frontend push ships nothing until the backend's
submodule pointer is bumped. **Both are wrong as stated.** What I measured
today:

- `www.aajoohomes.com` is served by **Render** behind Cloudflare
  (`x-render-origin-server: Render`). Not Vercel.
- The backend's pinned submodule is `55dd18d`, which does **not** contain the
  CMS change.
- Yet `story.image` **is** in the served bundle, and the GA tag **is** in the
  served HTML.

So the Render build resolves the submodule to the frontend's current `main`
rather than the pinned SHA. A frontend-only push did reach production.

**I could not establish the mechanism** (whether Render uses
`git submodule update --remote`, or someone triggered a manual deploy after
the frontend pushes). So do not rely on it either way:

> After any frontend push, **grep the served bundle for a string from your
> change**. If it is absent, bump `web/` in the backend and push that.
> ```bash
> B=$(curl -s https://www.aajoohomes.com/ | grep -oE '/assets/index-[A-Za-z0-9_-]+\.js' | head -1); curl -s "https://www.aajoohomes.com$B" | grep -c "<a string from your change>"
> ```
> Never compare a local `dist/` hash to production's — Render and Vercel inline
> their own env vars, so hashes legitimately differ for the same commit.

---

## 4. What is live and verified today

- **Apple sign-in fix** — backend `955075c` deployed, and migration
  `20261103090000-user-cred-email-nullable.js` reports **`up`**. Both halves
  are live. The App Store rejection of 1.0 (127) under Guideline 2.1(a) is
  addressed on the server; no binary change was needed for it.
- **Google Analytics** `G-N94KXBX9ZG` — present twice in the served HTML.
- **CMS image fields** — `story.image` present in the served JS bundle.
- **Property 9 (Tara Anchal Cottage)** — `POST /pricing/rooms` returns
  `{"rentalMode":"whole","rooms":[]}`. Still unconverted. The Antigravity
  diagnosis of this is **correct**.
- **Build 128 artifacts**, both rebuilt 3 November and verified by reading the
  binary back (endpoint, key and version all present):

  | | |
  |---|---|
  | APK | `D:\Projects\ajoo admin website\aajoo-homes-1.0.0-build128-release.apk` · 96 MB · sha256 `0730fea2…0029b2` |
  | AAB | `D:\Projects\ajoo admin website\aajoo_app_2026\build\app\outputs\bundle\release\app-release.aab` · 88.3 MB · sha256 `b37d7450…53f50d` |

  Both carry `api.aajoohomes.com`, `rzp_live_TjqzCwo7CT9g4E`, `1.0.0+128`.
  **The APK charges real cards at checkout.**

  > These two files are the ones to ship for 128. They live at the **monorepo**
  > paths above because that is where they were built on 3 November. Any build
  > you run from now on happens in `D:\Projects\aajoo_app_latest` and lands
  > under **that** repo's `build/` instead. Check the path and the timestamp
  > before uploading, or it is trivially easy to upload the older file.

---

## 5. Corrections to the Antigravity handoff

1. **"Mobile App (Flutter) → `D:\Projects\ajoo admin website\aajoo_app_2026` →
   `aajoo_app_latest.git`"** — wrong, and it is what caused §1. That path is a
   folder in the monorepo, not a checkout of the app repo.
2. **"Web Frontend → auto-deploys to Vercel"** — Render serves it. See §3.
3. **"`D:\Projects\ajoo admin website`: Clean"** — it has 26 untracked files
   and a mis-pointed remote.

Everything else in that document checked out, including the multi-room
investigation and the three frontend commits.

---

## 6. Open tasks, in the order I would do them

### A. Ship what is already built — *blocked on accounts I do not have*

1. **Google Play.** Upload the **AAB** (not the APK) at the path in §4.
   Production → Create new release → notes from `PLAY_RELEASE_NOTES_128.md`.
   **Status unverified** — I cannot see Play Console.
   > ⚠ The AAB built on 2 November was **unshippable**: built without
   > `--dart-define`, so it carried no API endpoint and the app would have
   > shown a build-configuration screen instead of starting. It was replaced on
   > 3 November. Confirm you are uploading the **18:56 / 88.3 MB** file.
   Traps: a draft release greys out "Create new release"; a blank Release name
   means the AAB never attached; managed publishing stays **ON**; the store
   page's "Updated on" date lags reality.

2. **iOS 1.0 (128).** Full instructions are in the app repo as
   `IOS_SUBMISSION_PROMPT.md` — clone `nameeshPatiyal100/aajoo_app_latest` on
   the Mac, open Claude Code at its root, paste that file's prompt.
   **Status unverified** — I cannot see App Store Connect.
   Since the Apple fix is server-side and now fully live, Apple can also
   re-review the **existing 127 binary** with no upload at all. That is the
   fastest path to approval if 128 is not ready.

### B. Will cause another App Store rejection if left

3. **`FIELD_ENCRYPTION_KEY` is not set on Render.** `rememberRevocationToken`
   deliberately **discards** every Apple refresh token rather than store it in
   the clear, so account deletion revokes nothing — and Apple requires that it
   does (Guideline 5.1.1(v)). Setting that one env var is the whole fix.
   `/health/env` returns `{"ready":true}` regardless, because the key is on the
   optional list, so that endpoint cannot confirm it.
4. **The host demo account** in App Review Information is still
   `>>> REPLACE THIS LINE WITH THE HOST EMAIL AND PASSWORD <<<`. Sent as-is
   that is its own 2.1 rejection. Verify the guest login works too.
5. **SPF** — add `include:spf.brevo.com`. Without it, mail to Apple relay
   addresses (`@privaterelay.appleid.com`) bounces and Apple's "Register Email
   Sources" step cannot pass.

### C. Security debt

6. **Rotate the Firebase service-account key.** `utils/serviceFirebase.json` is
   **still tracked** in the backend repo. Rotate in the Firebase console
   (project `aajoo-bdb20` → Service accounts), set `FIREBASE_PROJECT_ID`,
   `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` on Render, then untrack the
   file. It is deliberately still tracked so the running deploy keeps its
   fallback — untrack only *after* the env vars are in place, or Apple and
   Google sign-in both break.

### D. Product work

7. **Property 9 conversion** — client/admin action, not code. Admin →
   Management → Room Type Conversion (`/admin/room-types`) → Review → Apply.
   Then in the listing editor set rental mode to "Rent by room" (step 1) and
   give each room type a price, occupancy and **3 photos** (step 4). Then open
   `aajoohomes.com/property/9` **and pick dates** — the table does not render
   without them.
8. **Guest-facing partial room cancellation has no UI.** `POST
   /user/cancel/rooms/quote` and `POST /user/cancel/rooms` are live and tested;
   nothing on web or app calls them. This is the only phase-3 piece without a
   screen.
9. **Room preview before dates are picked.** `RoomTypeTable.tsx` returns `null`
   without `bookFrom`/`bookTo`, so a converted property looks unchanged until
   the guest picks dates. Showing room types with baseline prices and "Select
   dates to check availability" would remove the main confusion behind the
   client's report. Worth doing.
10. **Per-room seasonal/festival rates** — deliberately deferred, not forgotten.

---

## 7. Traps that cost real time here

- **Sequelize drops undeclared attributes** from every create and update before
  SQL is built. The query runs, `updated_at` moves, the value never changes.
  That is how custom roles were never assigned from the day the feature
  shipped. Declaring a column on the model is not optional.
- **Run migrations from the backend repo**, not the monorepo:
  `cd "D:/Projects/aajaoBackend-render" && npx sequelize-cli db:migrate`.
  Migrations do **not** run on deploy.
- **PlanetScale runs Vitess** — no multi-table `UPDATE ... JOIN`. Select, then
  update one row at a time.
- **Verify the artifact, not the intention.** `strings` is not installed on
  this machine; a command using it returns empty and looks like proof of
  absence. Read binaries with Python. This is exactly how the broken AAB was
  nearly missed.
- **A build with no `--dart-define=API_BASE_URL` compiles fine** and produces a
  dead app. Always build through `tool/build_release.ps1` / `tool/build_ios.sh`
  and read the artifact back.
- **JDK 21 is required** for Gradle 8.7; JDK 25 breaks it. `JAVA_HOME` here is
  already Temurin 21.
- **Live tests drive as user 179**, never 101/100 — those are the client's.
- **The monorepo is public and once held a live Razorpay secret.** Never put a
  credential in a repo doc.

---

## 8. Reference documents

| File | Where | What |
|---|---|---|
| `IOS_SUBMISSION_PROMPT.md` | client app repo | The Mac session prompt — canonical |
| `APP_STORE_SUBMISSION_GUIDE.md` | client app repo | What is already saved in App Store Connect |
| `IOS_MAC_PROMPT_2026-11-03.md` | monorepo root | Same prompt + Android + status |
| `PLAY_RELEASE_NOTES_128.md` | monorepo root | Play release notes |
| `SESSION_HANDOFF_2026-10-23_ROOM_TYPES.md` | monorepo root | Room-level booking design, incl. §10 on why existing properties were not auto-converted |
| `MASTER_PENDING_TASKS.md` | monorepo root | The master list — single source of truth |
