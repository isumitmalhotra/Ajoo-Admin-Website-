# AAJOO Homes — Master Pending Tasks (single source of truth)

> **Reconciled 2026-09-04** against the live site, the live database and the three
> repos; **updated 2026-09-05** after tester builds 14–16, the proactive defect
> sweep, and a fresh set of DB counts; **updated 2026-09-13** with §8a19–8a27 — the negotiation
> rebuild, the home page's card sections, cash at the door, the booking-confirmed
> redesign, the app's inability to read its own API, a draft that reached public search,
> the Cloudinary sweep that took 111 personal records off public delivery, and
> the evening's client batch — per-room detail, icons on the category questions,
> and emergency distances the platform measures instead of asking a host to guess;
> §8a26 closes a required question that nothing on the other side ever read, and
> §8a27 closes eight client reports in one night — including a money figure that
> disagreed with itself between two screens, and one regression of my own;
> **updated 2026-09-15** with §8a28 — the same stay priced three ways on three
> screens, because a coupon was a percentage of three different things — §8a29, a
> week negotiated as a total instead of seven per-night sevenths, and §8a30, the
> web wizard that had been switching same-day bookings (and with them negotiation)
> off for every host who never answered the question; and §8a31, the client's
> answer to §1.14 — the cleaning fee is **stated, not charged** — applied as one
> switch across the quote, the booking clamp and both clients the same afternoon.
> The evening also answered "will Razorpay Payroll work for payouts?" in a document
> of its own (§2.2) and surfaced §2.2a — 194-O TDS, which no rail does for us; and
> §8a32 brought the iOS project to parity with Android, compiling on GitHub's Mac
> on every push, with the client's eight Apple-side actions in §1.16. **Updated
> 2026-09-16** with §8a33 — three reports with screenshots (unequal home-page cards, a
> "deal with no booking", "the 17th is blocked") and the tester sheet brought up to
> date as v3, including the app tab that had never been answered in a sheet; and §8a34 — the
> afternoon's five: the same-day repair RUN, KYC required to negotiate, a deal priced on the cards
> outside the listing, and the signup email's Help Centre pointed at the live page; and §8a35 — the
> evening's seven, one of which is the reason the instant counter had been silent since 12 September.
> §8a24 and §2.8 carry **AWS Days 1–5** — the whole platform as Terraform, a
> deploy pipeline that holds no AWS key at all, and the cutover runbook. None of
> it is applied — blocked on an unverified card on the AWS account, not on us.
> Supersedes the 2026-07-11 edition, which had drifted badly — nine of its open
> items were already done and two of its "done" claims were wrong.
>
> **Repos:** FE `D:/Projects/aajao-frontend-vercel` (React/Vite → Vercel) ·
> BE `D:/Projects/aajaoBackend-render` (Node/Express/Sequelize → `aajaodev.onrender.com`) ·
> Mobile `aajoo_app_2026/` (Flutter). Deploy = push to `main`; **DB migrations do NOT auto-run.**
> **Go-live sequence (2026-09-19, Render Pro + PlanetScale bought): `GO_LIVE_RUNBOOK_2026-09-19.md`** — steps 0.1–0.4 first (Razorpay key rotation, repo private, test passwords, build 106).
> Tester build in circulation: **108 (1.0.0+108)**, `aajoo-homes-1.0.0-build108-release.apk` at repo root
> (2026-09-20 21:05, versionCode 108, 95.5 MB, sha256 `4cf75ddf44f5f5bf…`), built with `tool/build_release.ps1`;
> client repo `aajoo_app_latest` main = `30edba5`. Supersedes **107**
> (2026-09-20 19:30, versionCode 107, 95.5 MB, sha256 `75f27c40a9ccfa4f…`), built with
> `tool/build_release.ps1`; client repo `aajoo_app_latest` main = `050453b`. Supersedes **106**
> (2026-09-19 night, versionCode 106, 95.5 MB, sha256 `db27821d9ffc842d…`), built with
> `tool/build_release.ps1` and read back by the verifier with the endpoint named (§8a45). 100–105
> are superseded by it; **98 and 99 are withdrawn** (built with plain `flutter build apk`, no endpoint
> compiled in — "This build is not configured"). 97 was the last of the previous line. Builds 88–96 are withdrawn: 88/89 lacked the pricing fixes, 90 and 91 each
> carried a defect the emulator found the same hour, 92 lacked the afternoon's three fixes, **93 still
> charges the cleaning fee** (the server recognises what it sends and charges without it), and 94 let a
> guest pick a stay shorter than the host's minimum and meet the refusal at booking, and 95 let an
> unverified guest open a negotiation the server would refuse, and 96 still carried the pre-rebuild
> negotiation chat that every offer notification opened. Everything before 87 was withdrawn earlier.
> Read back with `python aajoo_app_2026/tool/verify_release_apk.py <apk> https://aajaodev.onrender.com
> --allow-test-payments --expect-version=1.0.0+105`: the endpoint it was given is in it, no other
> `*.onrender.com` host is, no developer path, no plain-http endpoint, and it carries its own
> version string. Points at `aajaodev.onrender.com` with the sandbox Razorpay key — the platform
> is still in test mode, so a QA build is the only honest one.
> **The build number is internal and is not shown in the app** — Settings reads `Version 1.0.0`.
> Identify a build from the artifact: its filename, its sha256, or
> `adb shell dumpsys package com.aajoo.aajoohomes | grep versionCode`. Keep one number to one
> artifact; never rebuild an existing number with different content. (Until 46 the number WAS on
> screen and was hand-typed, stuck at 45 — which is how the seven already-fixed defects in QA sheet
> rows 20–26 came back re-reported. It is now injected from pubspec and asserted in the APK.)
> Documents delivered 2026-09-05 (repo root): `UAT_WebApp_2026-09-05.docx` (81 cases) · `UAT_AndroidApp_2026-09-05.docx` (55 cases) ·
> `Delivery_Delay_Analysis_2026-09-05.docx` · `Deployment_Options_2026-09-05.docx`.
> Documents delivered 2026-09-15: `AAJOO_NEGOTIATION_WEEKLY_MONTHLY_2026-09-15.pdf` (17 pages) — how a
> week or a month is negotiated after §8a29, guest and host flow with live numbers, and what is stored
> and charged underneath; and `AAJOO_CLIENT_REPORTS_RESPONSE_2026-09-15.pdf` (28 pages) — every
> client item from 13–15 September (§8a25–§8a29), the pricing rule in one place, a real weekly deal walked
> to the payment page on the live site, and the full test + edge-case run. Source in `report-2026-09-15/`.
> Documents delivered 2026-09-12: `negotiation-journey/Aajoo-Negotiation-User-Journey.pdf` (32 pages,
> 31 photographs of the live site) · `AAJOO_NOTIFICATIONS_AND_NEGOTIATIONS_2026-09-12.pdf` (14 pages,
> the technical reference behind it). Both rebuilt against the new engine, not edited from the old ones.
>
> **How to read the evidence column.** `verified` = checked against production or
> the live DB and the check is named (dated 09-04 unless it says 09-05). `code` =
> read in the source. `carried` = taken from the previous edition and **not**
> re-checked — treat those as the least trustworthy rows here.

---

## How this list is ordered

By **who is blocked**, not by component. Most of what is left is not engineering
work; sorting by owner is what makes that visible.

| Section | Owner | Open |
|---|---|---|
| [1. Client decisions](#1-blocked-on-client-decisions) | Client | 9 |
| [2. Ops / Render access](#2-blocked-on-ops--render-access) | Whoever holds Render + GCP | 7 |
| [3. Engineering](#3-engineering--genuinely-open) | Us | 11 |
| [4. Contract deliverables](#4-contract-deliverables-) | Us | 8 |
| [5. Section-0 redo](#5-section-0-site-redo--separate-sow) | Blocked on a signed change order | 20 |
| [6. Unproven, not broken](#6-unproven-not-broken) | Us + tester | 13 |

**If only two things get done:** §2.1 (live payment keys) and §1.1 (delete the
seed listings). The first means the product currently looks like it is taking
money and is not. The second gates every honest SEO number on the site.

---

## 1. Blocked on client decisions

| # | Item | Why it is blocking | Evidence |
|---|---|---|---|
| ~~1.1~~ | ~~**Delete the 29,227 seed listings**~~ **DONE (not by me)** | **Re-counted 2026-09-08: `tbl_properties` holds 4 rows, 1 of them host 100.** The 29k seed set has been removed since the 09-05 edition — not by me, and I did not see it happen. Public surface is now **24 URLs** (2 property, 5 blog, 17 pages). SEO figures now measure real data. | verified 09-08 — `SELECT COUNT(*)`, live child sitemaps |
| **1.2** | **Switch analytics on — after two sign-offs** | The consent banner is **built and live** (the earlier wording here was stale): three categories, "Only essential" at equal weight, Consent Mode v2 defaults denied, Hotjar barred from host/booking/account/admin routes, chat widget off the public pages. Nothing loads until the admin switch is on **and** the visitor grants the category. What is still the client's: (1) counsel reads the Privacy Policy's cookie section (`/Privacy-Policy#cookies`, drafted 09-05, names every provider); (2) if Hotjar is used, set its URL targeting to public pages only; then flip **Admin → Global SEO → Load tracking scripts**. | verified 09-05 — live banner, storage and script list on an anonymous visit |
| **1.3** | **Cash / UPI collection — 1 decision left (was 4)** | Three of the four were answered in code on 2026-09-12 (§8a21), following the recommendation already given: the **host** confirms, **at check-in or with an explicit button**, and the commission is **netted off the next payout**. What remains is the one the code cannot decide: **what happens when the host never confirms** — auto-mark collected at checkout, or flag to admin? Until that is answered a host who simply never presses the button leaves the booking unpaid for ever, and the platform never recovers its 15%. Detail in §7. | code 09-12 — `cashCollection.service.js`, `cashIsRecordedWhenCollected` |
| ~~1.4~~ | ~~**Cancellation policy — the admin controls the document asks for**~~ **CLOSED 2026-09-08** | All four Admin Panel controls built and live: enable/disable a policy, create new policy types with their own refund ladder, restrict a policy to approved hosts, and an exceptional-refund override (`1b9a4f9`, `195fa93`, `34e80ba`, `ae51f23`). Two migrations applied to the live DB. The guest-initiated **booking modification** from §4 of the document is also built — request, host approval, and the price difference charged or refunded (`7ace67d`, `99f73aa`). **The line that governs the whole module:** the registry decides what is OFFERED, never what a published policy PAYS. A booking snapshots the policy KEY, not the ladder, so editing "Firm" would rewrite what is owed to guests who already booked on it; built-in ladders stay in code and the API refuses to edit them, pinned by three separate assertions. **Not driven end to end:** the two modification screens. The renter test account's only bookings are in the past, so nothing on it is modifiable; the one future modifiable booking belongs to rentertest003@yopmail.com / hosttest002@yopmail.com. | verified 09-08 — live API, live DB, both admin screens driven |
| **1.5** | **Weather provider + key** (was E-2, RENT-7) | Renter-dashboard weather widget cannot start without a provider choice. | carried |
| **1.6** | **Brand assets** — logo set, favicon/PWA icons, animated illustrations, WhatsApp number, social links, reference designs (was E-5, S0-ASSET-1…5) | Gates most of Section-0. | carried |
| ~~1.7~~ | ~~**The five test listings that are now the public catalogue**~~ **MOOT** | Of the 6 live real-host listings, **5 are tester approvals**: four on 2026-09-04 so the site was not empty after approval started gating visibility — Garg Resorts (29263), Tharamani Farm Retreat (29265), Vrindavan Garden Farm Stay (29277), Delhi Green Farm Stay (29279 — the last two renamed from "Aish mobile host property…") — and Aish camping in the hills (29289) on 09-05, approved to prove the audit-trail fix. They are tester accounts' listings with tester phone numbers. Decide whether they stay through launch or come down with the seed data. | **2026-09-08: all five are gone** with the rest of the wipe. The catalogue is now property ids 29291-29294, of which 2 are publicly listed: "Heritage stay aish for testing" and "Ben Tree House". Both are still test names on a public site — that part of the decision survives. | verified 09-08 — sitemap-properties.xml |
| ~~1.12~~ | ~~**Email delivery is unproven**~~ **Working (client, 2026-09-11)** | The client reports the host2 signup OTP arrived and was verified within 23 s; the mailinator public inbox simply does not show mail for every alias. Signup OTP proven; password-reset and cancellation-OTP mails assumed to be on the same path. | client, 2026-09-11 |
| ~~1.9~~ | ~~**Ledger rows written by the broken verification code — run the repair**~~ **DONE 2026-09-11** | Client ran `scripts/repairLedger_2026-09-11.js --apply`: 4 `book_amount_paid`, 4 `pay_amount`, 3 `he_amount` corrected, hd 29 voided, **B283633 refunded ₹6,825 (`rfnd_TadH9kNXzOMANG`, payout held)** and **B761983 refunded ₹630 (`rfnd_TadH27lRt7HINJ`)**, both COMPLETED in Razorpay test mode. Verified in the DB afterwards. | client-run script output + DB, 2026-09-11 |
| **1.11** | **The category catalogue needs an hour of an admin's time** | Three things, all data rather than code, and all now MORE visible because Browse by category reads the catalogue live (§8a20) instead of nine hardcoded tiles. (a) **Category 1 is titled "Villas -1"** — every villa on the public site reads "Villas -1", a test rename left in `tbl_categories`; the slug `villas-1` is fine to keep. (b) **Nine of the eleven categories have no image** — the rail falls back to a rotation of stock photographs, so two categories look photographed and nine look generic; upload one icon each at Admin › Catalogue › Categories › pencil › Replace image. `Resort` carries a line-drawing icon that looks wrong beside a photograph. (c) **The CMS heading still reads "browser by caterogy"** — Admin › CMS › Homepage Content › Categories heading. All four are one click each; my sandbox refused the category edit. | admin Categories + CMS screens, 2026-09-12 |
| ~~1.10~~ | ~~**Admin approval → public listing, end to end**~~ **DONE 2026-09-11** | 29302 "QA Sunrise Villa" filed from the app (all five steps, map pin at Christ Church Kasauli, 10 tagged photos with ALT text, ownership PDF, Moderate policy, approval required, weekend/weekly/monthly rates, pets, 15:00 check-in) → Submitted tab → Mark all checked → Approve & publish → live at `/property/qa-sunrise-villa-solan-himachal-pradesh` with map pin, gallery, rules, nearby, policy ladder, negotiation, `psb_reviewed_by` recorded. Quote engine: Fri ₹3,600 + Sat ₹3,800, 10% advance discount, ₹500 cleaning, 5% GST; extra guests ₹400 × 2 × 2 nights once the app could say who is included. Found and fixed on the way: the document-upload Submit deadlock (web + app), the self check-in method erased on re-save (app), the extra-guest section missing (app), "1800 sq_ft" / "Pet Area 1" on the public page (backend). **The listing is live test content on production — delete it when the client is done with it.** | driven 2026-09-11, builds 66–68 |
| **1.13** | **Two one-off data repairs — run them** (my sandbox refuses production writes) | Both dry-run by default and print what they will touch. In PowerShell: `cd D:\Projects\aajaoBackend-render; node scripts/cleanupImageSeo_2026-09-11.js --apply` — deletes **18** `image_seo` rows whose photograph no longer exists and resets **5** rows that pre-date their photograph (media 72–75 on 29303 carried a Dharamsala cottage's ALT text; media 67 on 29302 "Wood-panelled ceiling…"). Then `node scripts/maskPropertyBankNumbers_2026-09-11.js --apply` — masks the **2** plaintext account numbers `property_bank_details` was holding (29294, 29303). Why they exist: §8a15. | dry runs printed 2026-09-11 |
| ~~1.15~~ | ~~**Run the same-day repair**~~ **RUN 2026-09-16** | `scripts/repairSameDay_2026-09-15.js --apply` put all five back (29292, 29294, 29295, 29306, 29310). `/booking/property-availability` now answers `earliest: 16-09-2026, sameDayAllowed: true` on every one of them, and the app's check-in picker offers today (`report-2026-09-15/app/build96-today-is-selectable.png`). That was the client's "still I cannot select today's date on app" — a data repair, not a code fix; the wizard has been unable to write that 0 since 2026-09-15. | §8a34 |
| ~~1.14~~ | ~~**Is the cleaning fee CHARGED, or only STATED?**~~ **ANSWERED 2026-09-15 — stated.** | Client: *"it will only be stated in Things to know and all; if the renter requested it, it can be availed at that price and payments will be taken directly by the host."* Applied the same afternoon as the one switch this row described — quote, pricer, booking clamp, both clients — with the frequency field kept as an optional courtesy ("₹500 per night") rather than a billing rule. **§8a31.** The ₹27,376 in the 14 Sep note is superseded: that stay is now ₹26,196 with the ₹1,000 said under the total. | §8a31 |
| **1.16** | **iOS — the eight things only the client's accounts can do** (asked 2026-09-15) | The iOS half of the app is at parity with Android in the repository and compiles on GitHub's Mac on every push (§8a32); nothing runs on an iPhone until the client's Apple side exists. In order: (1) enrol in the **Apple Developer Program** as the company (Organisation, needs a D-U-N-S number); (2) App ID `com.aajoo.aajoohomes` with **Push** on; (3) an **APNs key (.p8)** uploaded to Firebase → Cloud Messaging for the iOS app; (4) **`GoogleService-Info.plist`** for the iOS app from Firebase (carries the Google Sign-In client); (5) an **iOS-restricted Google Maps key** in the same Cloud project; (6) the **App Store Connect** app record + an internal **TestFlight** group with the tester's Apple ID; (7) an **App Store Connect API key** (App Manager); (8) a **distribution certificate + App Store provisioning profile**. Then the values go into the repository secrets named in `aajoo_app_2026/IOS_READINESS.md` §3 and the TestFlight job is run by hand. **Without (1) there is no iPhone build at all.** | `aajoo_app_2026/IOS_READINESS.md` |
| **1.8** | **Where the platform runs after UAT** | `Deployment_Options_2026-09-05.docx` compares staying on Render + Vercel with AWS, Azure, GCP, DigitalOcean and a VPS, with indicative costs. Recommendation: stay through UAT (Render Starter, $7/mo), then **DigitalOcean Bangalore** (~$45–75/mo) as the first managed home in India; hyperscaler only with an owner or credits; VPS only with a named operator. Needs the client's answers to §8 of that document: expected traffic, budget, who operates, existing cloud agreements. | doc |

---

## 2. Blocked on ops / Render access

| # | Item | Failure mode if missed | Evidence |
|---|---|---|---|
| **2.1** | **Live Razorpay keys + `ALLOW_TEST_PAYMENTS` off** | Checkout opens, the booking confirms, an invoice is issued — and **nothing is collected**, because every order was created against the bundled test key. Invisible from the UI by design; `/health/env` reports it. | code — `config/payments.config.js` |
| **2.2** | **The payout rail needs deciding — RazorpayX is out** | Client, 2026-09-12: "we are not eligible for razorpay X... They suggest razorpay payroll inside the razorpay to sent payments", and later "razorpay payroll has been configured and kyc verified, you can use same keys". **Payroll is the wrong product and I would not ship it without saying so:** XPayroll pays EMPLOYEES — salary runs, PF, TDS, Form 16 — and hosts are not employees; routing their money through it mischaracterises the relationship and the tax treatment, and its API is built around monthly pay cycles rather than a transfer per booking. **Razorpay Route is the marketplace product** (split and settle to linked accounts, `v2/accounts`) and genuinely does use the Payments keys, which is probably what "same keys" meant. Needs a decision before code. The swap itself is contained: `services/payouts/razorpayx.service.js` plus two call sites (`adminFinance.controller`, `razorpayxWebhook.controller`) — the penny-drop, idempotency and ledger work above it is rail-agnostic. Until then approving a payout fails at the click with "Payouts are not configured". **Written up for the client 2026-09-15:** `AAJOO_RAZORPAY_PAYROLL_FOR_HOST_PAYOUTS_2026-09-15.pdf` (source `report-2026-09-15/RAZORPAY_PAYROLL_FOR_HOST_PAYOUTS.md`) — Razorpay's own 31 July 2025 notice discontinues vendor payments through the Payroll wallet (individuals with a personal PAN under 194J or no-TDS only; no business PANs; no non-194J sections), Payroll deducts 194J at 10% where 194-O at 0.1% applies, runs monthly against weekly/15-day cycles, has no payout API or webhook, and its own notice points at "a RazorpayX-powered Current Account". The doc compares Route (recommended to evaluate first — same Payments keys, linked accounts, hold-until-check-in, reversals), RazorpayX (built), another provider, and interim manual NEFT from the admin queue, and ends with the one question to put to Razorpay in writing. | client call 09-12; Razorpay's Payroll notice of 31 Jul 2025; Route docs |
| **2.2a** | **TDS under section 194-O is not in the code — whichever rail** | Aajoo is an e-commerce operator paying hosts: 0.1% of the gross amount at credit or payment (5% where the host has given no PAN; nil for an individual/HUF under ₹5 lakh in the year who has given PAN/Aadhaar), deposited and filed quarterly. No rail — Route, RazorpayX, Payroll — does this for a marketplace. Needs: a per-host running total for the financial year, the rate decision at each payout, the deduction shown on the host's payout statement and invoice, a quarterly export for the accountant, and the PAN captured at payout onboarding (it is not today). Bounded; build once the accountant confirms the position (the doc's §7 item 5). | Income-tax Act s.194-O as amended by Finance (No. 2) Act 2024; `RAZORPAY_PAYROLL_FOR_HOST_PAYOUTS.md` §3 |
| **2.3** | **`REQUIRE_IMAGE_ALT=true`** | Server accepts an image upload with no description. Both clients have refused to upload without one since build 12; **build 16 is with testers now**, so there is no longer a reason to wait. | code |
| ~~2.4~~ | ~~**`HEALTH_TOKEN` unset**~~ **WRONG — it was set all along** | The 09-05 "verification" read `{"ready":true}` and called the token unset. That bare reply is what the endpoint gives *anyone who does not send the header* — set or not — so it proved nothing. On 2026-09-11 the client ran the probe **with** the token: full report, `dbCutoverSafe: true`, all five DB checks `match`, `FIELD_ENCRYPTION_KEY: true`. Lesson for this file: a probe that cannot distinguish the two states is not a verification. | verified 09-11 — client-run probe with header |
| **2.5** | **Credential rotation** | Deferred by instruction. Everything historic is in git history: DB password, Razorpay secret, Cloudinary secret, Gmail app password. | carried |
| **2.6** | **Google Cloud budget alert** | Maps + Places keys are live and unmetered. | carried |
| **2.7** | **Render Starter ($7/mo) + confirm Clever Cloud backups** | The API is on Render's free tier: 30–50 s cold starts hidden by a keep-alive ping, and a disk that is wiped on deploy (invoices are written there). Starter removes the sleep; Clever Cloud's backup schedule and retention should be confirmed in its dashboard before UAT — it is the only copy of the database. | verified — `KEEP_ALIVE_SETUP.md`; DB 43 MB on Clever Cloud |
| **2.8** | **AWS — Days 1–5 are written; the blocker is an UNVERIFIED CARD** | Client chose `ap-south-1` and **Terraform over console clicking** (2026-09-13). **Days 1–5** of `AWS_MIGRATION_PLAN_2026-09-11.md` are committed at `infra/terraform/`: VPC, three chained security groups, two shared ECR repositories, RDS MySQL 8, the ACM certificate, ALB with host-based routing, ECS cluster, two services (API at one task, web at two), CloudFront with its own us-east-1 certificate, and a staging workspace. **Day 4 (2026-09-13)** adds the deploy path and the watch on it: `oidc.tf` registers GitHub as an OIDC provider and creates one role whose trust policy matches the `sub` claim exactly — repository **and** `refs/heads/main`, `StringEquals` on a two-item list rather than `repo:owner/*`, so a fork's pull request, a feature branch and every future repository of that owner get nothing — which means **there is no AWS access key in either repository to leak or to rotate**; `alarms.tf` adds an SNS topic and seven alarms picked against this platform's shape rather than a CPU dashboard, the one that matters being `RunningTaskCount < 1` with `treat_missing_data = "breaching"`, because the API runs at exactly one task and a service with no tasks publishes no metric — silence IS the outage. `cpu_architecture` became a variable (now `X86_64`, was `ARM64` hard-coded in two task definitions) because GitHub's standard runners are x86 and a mismatch does not fail at build time: it fails at task start with `exec format error`, which reads like a corrupt image rather than a mismatched one. A `.github/workflows/deploy.yml` now sits in **both** application repos: test → build → push → **migrate** → update the service → wait for stable → `/health/env`. Migrations run as a one-off ECS task on the same task definition, so they read the same SSM credentials and no password ever enters GitHub, and a non-zero exit stops the deploy with the old code still serving. The website workflow passes **all ten** `VITE_*` build args the Dockerfile declares — an image built with the other nine empty is not "missing configuration", it is a finished site with no map, no payment gateway and no push notifications, and nothing says so until somebody opens it. **After apply, four things are human work:** the role ARN and distribution id into each repo's Actions variables, clicking the SNS confirmation link (until then the topic has no confirmed subscriber and alarms reach nobody), and re-pointing the **Razorpay webhook** — Terraform cannot touch the Razorpay dashboard, and a missed webhook is a payment that never reconciles. The master password is generated into SSM so nobody ever types it, and **Terraform deliberately does not create the other secrets with placeholders** — `/health/env` reports which names are SET, and a placeholder is set, which is how the last secrets move took production down. An operator supplies them with `infra/scripts/put-parameters.sh`, and `terraform plan` fails BY NAME if one of the four it cannot invent is missing. **Nothing is applied, and nothing can be:** signed into the account, **CloudShell refuses to start — "Your account verification is in progress. This may take up to two days for new accounts"**, and a new account under verification cannot reliably launch resources. The survey it did allow: **1 VPC (the default), 0 databases, 0 ECS clusters** — an empty account waiting on AWS, not on us. When it clears: `terraform init && terraform plan` and read the plan before applying, because the first apply creates a billable, durable database. Still open from §4 of the migration doc: the API hostname (it still answers **404**), DNS, who owns the console after handover, and expected traffic (sizes RDS). **Probed 2026-09-13: the block is COMPUTE, not the whole account** — created one free ECR repository and deleted it immediately, and it worked, while CloudShell still refuses. So RDS, Fargate and the ALB are what is gated, which is the detail that belongs in the support case. Client-facing write-up for forwarding: `AWS_ACCESS_AND_ACTIVATION_2026-09-13.md` / `Aajoo-AWS-Access-and-Activation.pdf` (5 pages). **THE BLOCKER IS NAMED (re-checked in the console 2026-09-13, late):** the guessing is over. **The Visa on the account reads `Unverified`.** Payment preferences lists two methods — UPI AutoPay (GooglePay), default and enabled, and **Visa •••• 1719 "AAJOO HOMES PRIVATE LIMIT", marked Unverified**. Selecting it greys out "Set as default" while leaving Edit and Delete live, which is AWS refusing to make an unverified card the default. AWS verifies a card with a small authorisation charge (₹2 in India) and activation does not complete until it clears — which is exactly an account stuck at "verification in progress" for 48h+ rather than the usual few hours. The account is on **Amazon Web Services India Private Limited (AISPL)**, billed in INR, and AISPL verification leans on the CARD: **a UPI AutoPay mandate does not substitute for it**, which is why having UPI working has unstuck nothing. **What to do, and it is not ours — card details are never ours to type:** Payment preferences → select the Visa → Edit → re-save, which triggers a fresh ₹2 authorisation (phone ready for the OTP / 3-D Secure step); if it fails the card needs **international transactions and e-mandate/recurring enabled**, both off by default on most Indian bank cards; if it still will not verify, **a different card is faster than a support case**. The Activation case from ROOT is still worth raising, but second — a support agent's first question will be why the card is unverified. Also noticed: the **billing contact email is blank**, so anything AWS emailed went only to the root mailbox. **CloudShell still refuses**, word for word: "Unable to create the environment. Your account verification is in progress. This may take up to two days for new accounts." **One root action is now DONE:** "IAM user and role access to billing information" has been switched on — the Account page renders for `sumit` (account **477624609102**, "aajoo homes"), where it refused earlier the same day. Still worth root's time: a budget with an alert, and MFA on `sumit`, whose console access is enabled without it. (Cosmetic leftover: Account *display* settings want `AWSManagementConsoleBasicUserAccess` on the user — ignore it.) Credentials never come to us — GitHub OIDC preferred, and `sumit` has no access key yet, so there is nothing long-lived to leak. **Day 5 (2026-09-13) is written: `CUTOVER_RUNBOOK_2026-09-13.md`**, plus `infra/terraform/bootstrap/` (the S3 state bucket — a separate root, because the bucket holding the state cannot be described in the state it holds; until it is applied the whole platform's state is one file on one laptop), `infra/terraform/data_migration.tf` (a one-off Fargate task, default OFF, because RDS is private and admits 3306 from the tasks SG alone — so the only thing that can write to it is a task in the VPC, which also means the dump never lands on anybody's machine), and `infra/scripts/migrate-data.sh` + `migration/{copy,verify}.sh`. **Four findings the runbook exists to carry:** (1) **the rollback window is not seven days** — the plan's "rollback is DNS" is true of the stack and false of the data; the free window ends at the FIRST WRITE on AWS, so the go/no-go gate sits inside the freeze, before users are let in, not after a day of watching; (2) **DNS is hosted at Vercel** (`ns1/ns2.vercel-dns.com`) — so "decommission Vercel" would take the website, the API *and* the MX records with it, and moving the zone to Route 53 is a prerequisite nobody had written down; (3) **every installed APK has `aajaodev.onrender.com` compiled in** by `--dart-define`, with no fallback in a release build, so switching Render off breaks every tester's app outright — the exit criterion is "no requests on the Render hostname for 48 hours", read off Render's logs, not a date, and until then Render runs as a 308 redirect (which Dio follows and Socket.io does not); (4) **`api.aajoohomes.com` already points at Vercel and answers 404**, so it is a record to CHANGE, and an APK built against it today passes the app's own `isConfigured` check and then fails every call. Confirmed harmless on the day and worth knowing because it looks otherwise: mail is unaffected (Brevo HTTP API on 443, not SMTP from our IP), and Google Maps / Firebase / `ALLOWED_ORIGINS` all key on `www.aajoohomes.com`, which does not change. Zone default TTL is already 600s. **Also closed a silent split-brain on the way:** `src/configs/apiConfigs.ts` falls back to the Render API when `VITE_API_BASE_URL` is empty — correct today, and a trap once the AWS pipeline builds, because an unset repo variable would ship a CloudFront site writing to the OLD database with both halves looking healthy. The workflow now refuses to build without it, pinned by `tests/theApiHostIsNeverGuessed.test.mjs` (which also asserts every `ARG VITE_*` in the Dockerfile is actually passed). | verified 09-13 (late) — CloudShell refusal read verbatim; Payment preferences read in the console (Visa •••• 1719 `Unverified`, UPI default); Account page now renders for `sumit`; live DNS/SOA/MX/TXT lookups; the served production bundle; `infra/terraform/README.md` |

> **On 2.2 —** the "not configured" message is raised inside the *approve*
> handler, not on page load, so its absence from the Payout Queue proves nothing.
> The queue renders and shows QUEUED/FAILED rows either way. The honest state is
> unknown; confirm in Render rather than by clicking.

---

## 3. Engineering — genuinely open

| # | Item | Notes | Evidence |
|---|---|---|---|
| ~~3.1~~ | ~~**Purge junk categories**~~ **CLOSED 2026-09-08** (`68a57de`) | `/common/categories` now requires a slug, so it serves **11**; `couple` and `party` are gone from the website filter and the app's category row without an app release. The two rows still exist and are still `cat_isActive='1'` — they are simply no longer offered — so the admin Categories screen still lists them. **Still open, and a data change needing sign-off:** `Resort` is the only singular title among plurals. | verified 09-08 — live endpoint + live search page |
| **3.2** | **13 of 32 images have no ALT text** (was "64 of 65" — that counted the seed catalogue, which is gone) | Blocks image-sitemap captions, which cannot populate until descriptions exist. Much smaller job than it was. | verified 09-08 — `image_seo` row counts |
| **3.3** | **WebP / `f_auto` delivery** | Cloudinary URLs carry no `f_auto`. Core Web Vitals, not indexing. | verified — sitemap image URLs |
| **3.4** | **`/` and `/explore` have identical titles** | Two pages competing for one query. One line of copy, or canonical `/explore` → `/`. | verified — SEO Health |
| **3.5** | **Orphan pages / broken internal links** | Needs a crawl of the rendered site; nothing in the admin does one. The health dashboard lists it as unchecked rather than reporting a false zero. | verified — SEO Health |
| **3.6** | **Cloudinary — audited, migrated and cleaned 2026-09-12/13; ONE thing left, and it is not a script** | Over two passes: **111 assets taken off public delivery** — 45 property documents, 12 guest-issue CSVs (the chatbot was minting them publicly and pasting the link into chat), and **51 of the 228 unfoldered ones**, which were read by eye off six contact sheets rather than guessed at. Those 51 were 22 legible identity documents for several different people (Aadhaar numbers and QR codes readable, a college ID with name, father's name, DOB, address, phone and blood group), 18 other personal records, and 11 of **our own** booking invoices and app screenshots carrying guest data. Old public URLs spot-checked: 404. Both uploaders now store `authenticated` and both readers sign. Privatised rather than deleted, because most of those documents are somebody else's and deleting could destroy their only copy. Two self-corrections worth keeping: two "portraits" were USER AVATARS and were put back public, and two identity documents were our own guests' KYC, which needed `getSignedImageUrl` so the admin screen kept working. **Left: this account is SHARED, and that is the root of every finding here — Aajoo needs its own Cloudinary account.** Also unresolved from August and now larger: whether the people whose documents were public have to be told, which is mostly a question for whoever else uses this account. | verified 09-13 — six contact sheets, Admin-API state before and after, per-asset probes, DB cross-reference |
| ~~3.7~~ | ~~**Host `whatsapp` field**~~ **CLOSED 2026-09-07** (`5e2b91a`) | `user_whatsapp` exists on `tbl_users`; migration `20260907140000-host-whatsapp.js` applied to the live DB. | verified 09-08 — `information_schema.columns` |
| **3.8** | **Admin Notification Management** (part of S0-ADM-1) | The only module from that list with no route. CMS, SEO, Coupons and Analytics all exist. | verified — 0 routes in `App.tsx` |
| **3.9** | **Lucide icon migration** (S0-BRAND-3) | `lucide-react` installed; MUI icons still in use app-wide. Cosmetic, and cheaper to do inside Section-0. | carried |
| **3.10** | **Web lint baseline is red** | `npm run lint` reports **~600 problems, 540 of them `no-explicit-any`**, so lint cannot gate the Vercel build (which runs `tsc -b` only). The empty-catch rule added on 09-05 therefore only bites when someone runs lint by hand. Either downgrade `no-explicit-any` to a warning and clean the rest, or fix the anys — then add `lint` to the build. | verified 09-05 — `eslint .` |
| **3.11** | **Report of listings whose stored contact fails the 6–9 mobile rule** | Two of yesterday's renames were blocked because the admin form re-validated a stored `1425369807`. The form now validates only what changed, but the junk is still stored and will surface the next time a host edits those listings in the wizard. A one-off query + host nudge. | verified 09-05 — the two numbers |
| **3.12** | **Leftovers from the sweep** | (a) Two screen-level empty catches remain in the app (`host_profile.dart:67`, `csc_picker.dart:750`); every *service* is clean. (b) `tbl_book_statuses` ids 12/13/14 double as payout-request states (`statusPayoutPending/Successfull/Failed` in `commonConfig`); 13 now counts as revenue by decision, but a booking table sharing ids with a payout table is a cleanup waiting to bite. | verified 09-05 — `flutter analyze`, `config/commonConfig.js` |
| ~~3.13~~ | ~~**The app hangs opening listing 29303 from the deal banner**~~ **CLOSED 2026-09-12** (build 82) | Never the network and never the id — the payload. `property_latitude` is a floating-point column, so the driver returns `28.47938` for one row and `"28.45936"` for the next depending on how it was written; the model declared `String?` and assigned it raw, so the numeric form threw `type 'double' is not a subtype of type 'String?'`. **Three separate faults turned that into a spinner nothing could clear**, and each was worth fixing alone: a TypeError is an Error, so `on Exception catch` in the service walked past it; `UserController.getProperty` caught it but left the previous listing in the one shared slot, so a failure looked like the stay the guest opened five minutes ago; and GetX 4.6.6's `back()` closes an open SNACKBAR and returns — with the controller's error toast on screen it never reached the `barrierDismissible: false` dialog. The notification route had the same two lines. | verified 09-12 — the 29303 notification opens the listing on build 82; tests `coordinates_are_not_always_strings`, `spinner_closes_under_a_toast`, both run against the broken code first; 370/370 |
| ~~3.16~~ | ~~**The same coordinate mismatch in three more models**~~ **CLOSED 2026-09-12** (build 83) | Asked to check the rest after §3.13, and the cause turned out not to be a data-era accident at all: `blurProperty` replaces the coordinates with **computed numbers** for any listing whose host answered "approximate location only" in the wizard, and leaves the DECIMAL column's string alone otherwise — so the JSON type is decided by a HOST SETTING, and **both shapes come back in the same response**. Two of the eight listings in the live search response are approximate. Three endpoints blur: `/properties/search`, `/properties/list`, `/properties/:id`. `properties_response_model` (map + search) and `search_property_model` both declared `String` and assigned raw, and `Data.fromJson` maps the whole array in one go — so one approximate listing threw and took the entire result list. `host_properties` wrote `?? ""`, which answers for null and lets a number walk past (defensive: that endpoint is not blurred today). `ongoing_reponse` had already got it right. | verified 09-12 — searching Gurugram on build 83 renders QA Metro PG Gurugram, an approximate listing; test `an_approximate_listing_still_parses` run against the broken code first; 376/376 |
| ~~3.17~~ | ~~**Check the review and safety models for the same mismatch**~~ **CLOSED 2026-09-12** (no app change) | **Neither has one.** Reviews is type-correct by construction and not by luck: `br_rating` is DECIMAL(10,2) so the driver returns text, `averageRating` is `.toFixed(2)` so it is a JS string, and like/dislike are `JSON.parse(...).length` so they are numbers — each lands in a field of the right type, and none of that is visible from the app, so it is pinned now. Every listing currently answers `{reviews: null, myReview: null}`, which the model handles. **Safety is DEAD CODE**: nothing calls `SafetyDataModel` or `getSafetyData()` — the Safety screen reads `getCmsPage('safety')` instead. Either wire it up or delete it; as it stands it is a parser that looks live and is not. One thing to know if it is ever wired up: `Conclusion` is a **string** in the safety block of `utils/data.js` and a **list** in both terms blocks of the same file. Then swept the rest: **153 raw `json[...]` assignments across 17 models, cross-checked against 230 keys from 13 live payloads — nothing else flagged.** | verified 09-12 — live payloads from every public `/common/*` endpoint; test `reviews_arrive_in_the_shape_we_parse` (5), checked against a numeric rating to be sure it fails; 381/381 |
| ~~3.18~~ | ~~**Close the sweep on the models behind auth**~~ **CLOSED 2026-09-12** (build 84) | The 28 assignments in the booking and host models could not be checked against a live payload — those endpoints need a token, and I do not enter credentials — so they were checked against the column types and the controllers instead. **The recurring fault is not a number type at all: it is the EMPTY response.** Every response comes from one helper whose signature ends `data = []`, so a handler that returns early sends `data: []` while its populated answer sends an object — both 200, both `success: true`. Two models call `Data.fromJson(json[“data”])` on that with no type check and throw `List<dynamic> is not a subtype of Map<String, dynamic>`: **a host with nothing in progress** (`/booking/ongoing-host`) and **a guest no host has reviewed** (`/review/host/user-review-list`) — and that second one is EVERY guest on the platform today, because nothing has been reviewed. The backend added its 200-with-empty branch precisely so the client could tell "you have none" from "the request failed"; the client could not, because the shape it sends for none was not the shape the app parsed. Also fixed: `hru_rating` is a **DOUBLE** column whose write schema is `yup.number().min(1).max(5)` with no `.integer()`, so 4.5 is a legal rating, and it was being read into an `int`. **Checked and clean:** booking history (expects a list, gets a list), create-booking (`Order?` is nullable, so pay-at-property is handled), the search list response, transactions. | verified 09-12 — column types + the controllers' own early-return branches; test `an_empty_list_is_not_a_failure` (6) run against the broken code first; 387/387. **Not driven on a device:** the host case needs a host login, and the guest case renders the same empty state either way — what changed is that it is no longer also an error |
| ~~3.19~~ | ~~**Client feedback batch, 2026-09-12 evening**~~ **CLOSED** (build 85) | Three screenshot items and the OTP channel. (a) **Internet speed above everything** — "highlighted section should open under the internet section not on top": both renderers drew every scalar field in one block and every chip group in another, and disagreed about which came first, so a host was asked how fast their internet is four rows above the row where they say whether there is any. The SCHEMA names the group each question belongs beside now (`under` / `above`) and both platforms follow it; `above` exists because kitchen_type decides whether the kitchen group shows at all. Exposed two older app faults: `has_wifi` was never set there, so an app host could not state a speed **at all**, and the app never honoured a GROUP's `showIf`, so kitchen appliances showed to a host who had said "No Kitchen". (b) **"not able to select from the listing"** on the place autocomplete — Chrome reads a place-name box inside an address-heavy form as an address field and draws its SAVED ADDRESSES in a native dropdown exactly where ours is; the host was clicking Chrome's list. `autoComplete="off"` + a non-address `name` on all three place inputs that lacked it. (c) **OTP by email only** — reset codes never go by SMS now, and typing a mobile says where the code will go and that **sign-in with a mobile and password is unchanged**, which the client confirmed explicitly. The SMS transport is held, not removed: v2 is a provider and a DLT template. | web build + 37/37, app 387/387, backend 135/135. **Not driven on a device or in a browser:** the wizard needs a host login |
| ~~3.21~~ | ~~**A host could put a DRAFT listing live**~~ **CLOSED 2026-09-12** | Reported with two screenshots: a listing badged Draft offered "Put live" in the host portal, and pressing it published it into public search with no photograph and **₹0/night**, never submitted, never seen by anyone at Aajoo. W5 closed this on the ADMIN side and left the host's own switch beside it checking ownership and nothing else. Same state machine now, with a refusal that says what to do next. The subtlety: `stateOf` reads being on the site as the strongest signal of approval, so a LEGACY listing (29,216 of them, tier never written) taken offline reads as DRAFT — a naive guard would lock its owner out, so the handler asks "with is_active forced on, would this read as approved?". **The app already had it right** (`if (adminCleared && !rejected)`); the website was the platform with the hole. **29308 has been taken off the site** (`scripts/takeListingOffline.js 29308 --apply`, dry-run first; `is_active` 1→0 and nothing else, so the host can still finish and submit it). | verified 09-12 — search near Bir now answers "no record found" and `/properties/29308` returns an empty payload; the deployed web bundle carries the new guard copy; test `aDraftCannotBePutLive` (9), source half checked against the pre-fix handler; 136/136. **The server guard itself is not exercised end to end** — that needs a host login |
| ~~3.20~~ | ~~**"Nearby" comes back empty on a cold launch**~~ **CLOSED 2026-09-13** | **It was never the request — it was the ORDER.** `getCurrentLocation()` returns the LAST KNOWN position at once and fires `_refineLocation()` in the background; `fetchProperties` then searches at that last-known point. Two `getProperties()` calls are in flight on every cold start, and both ended by assigning straight into `properties` — so **whichever finished LAST won**, however old it was. The foreground search answers in ~2s with the right stays (the same answer curl gives); the background refine lands at a different fix, finds nothing, walks out to the planetary ring (**~92 seconds, measured**) and overwrites a correct screen with its own answer. From outside: a home that had stays and then did not, with no error and nothing in a release log because `appLog` is compiled out. Fixed with a **monotonic search token** — every search takes the number it started with and only the newest may write, checked before the ring walk, on each ring, and again before the assignment. That closes the CLASS: the same race existed between any two fetches, and paging the map produced it too. Plus **capped rings for a background refine** — the planetary ring is right for a search somebody is waiting on and wrong for one nobody asked for. **It did not need the debug build.** `mapService` stopped being `final` so a stub could make the slow call slow on purpose; the five new tests were run against the pre-fix controller first and **four of the five fail**, which is the fault reproduced deterministically. 429 app tests pass. | verified 09-13 — `test/the_slowest_search_does_not_win_test.dart`, run against the unfixed controller first |
| **3.22** | **Three page BODIES are still pre-redesign, inside the new chrome** (raised 2026-09-16) | The 09-16 sweep deleted every retired page and rebuilt or redirected the rest, with three exceptions that are still reached and so could not simply go. `/state-regulation` (372 lines) is linked from the host portal sidebar, `/verify/complete` is where the KYC provider redirects a guest back to, and `/admin/status` (112 lines) is the last admin screen the portal redesign has not reached. All three now render inside `LegacyBodyInNewChrome` — the redesigned TopNav and Footer around a pre-redesign body — so the page frame matches the rest of the site and only the body is dated. They are the whole of what is left: the reachability sweep finds nothing else. Rebuilding them is a normal redesign task, not a cleanup one, and nothing is broken meanwhile. | `src/App.tsx` `LegacyBodyInNewChrome` |
| **3.17** | **Should an agreed deal HOLD the nights?** (raised 2026-09-16) | Today it does not: a deal is a price, date-locked and good until midnight, and the nights are taken by whoever books first — so two guests can hold an agreed price on the same stay and one of them will lose it (§8a35, verified live). Both clients now say "the nights aren't held until you book". If the client wants a hold, it is a real feature and not a fix: a soft lock on the dates for the life of the deal (hours at most), released when it expires, visible to the host as "held, not booked", and a rule for what happens when two deals overlap — first accepted wins, or nobody holds. Needs the client's answer before code. | §8a35 |
| **3.15** | **Sign in with Apple** — required for App Review, not for TestFlight | App Store Review Guideline 4.8: an app offering Google sign-in must offer a login that limits data collection and lets the user hide their email — Sign in with Apple. App: `sign_in_with_apple`, the button beside Google's, the Apple provider in Firebase Auth. Backend: verify Apple's identity token and create/link the account the way the Google path does (the Google-account lockout in the memory notes applies equally — role flags, unusable password). Client: enable the capability on the App ID. About a day once §1.16 (1)–(2) exist. | `IOS_READINESS.md` §4.1 |
| **3.16** | **The iOS on-device drive** — every flow driven on the Android emulator this week, on an iPhone from TestFlight | The Android drives found five defects no test had (§8a29); iOS will have its own. The list is `IOS_READINESS.md` §4.2: sign-up (OTP, Google), DOB picker, search + map + the "near me" prompt, listing page + Things to know, the booking sheet with the deposit and cleaning statements, the deal banner, Send an Offer (night / week), the host side and the popup, Razorpay (card + the UPI intent list), pay-at-property, My Bookings, notifications (foreground / background / cold start), the wizard (library photos, document picker, map pin), profile photo, share/print, tap-to-dial, WhatsApp, sign-out and the keychain. Needs §1.16 first; then a tester with an iPhone, or a Mac for the Simulator (no push there). | — |
| **3.14** | **Listing 29303 is carrying test weekend rates I added** | Put there on 09-12 to prove the dated-price work, because only 14 of the catalogue's listings have weekend rates at all. Harmless — it is a test listing — but it makes 29303 a bad control for anything else, and the next person to look at its pricing will not know why a weekend costs more. Either revert it or write it down on the listing. | code 09-12 — `nightlyRates` rows |
| ~~3.15~~ | ~~**Build 81 has never left this machine**~~ **CLOSED 2026-09-12** | Named, copied to the repo root as `aajoo-homes-1.0.0-build81-release.apk` and read back with `verify_release_apk.py` (endpoint present, no other `*.onrender.com`, no developer path, no plain-http, carries `1.0.0+81`); `aapt2 dump badging` says versionCode **81**, versionName **1.0.0**, `com.aajoo.aajoohomes`. sha256 `4b25f5410285f206c366181dcdf29714a89c14a89b73d8b8be188871bb1c8424`. **The tester had been on 49 since 09-08**, so none of the 09-12 negotiation work had ever been on a phone. Still unproven on a device: the two guest surfaces behind the deal banner (§3.13, §6). | verified 09-12 — `verify_release_apk.py` exit 0, `aapt2 dump badging`, `sha256sum` |

---

## 4. Contract deliverables 📄

Functional scope is delivered; these are the contractual artifacts. All still open.

| # | Item | Notes |
|---|---|---|
| **4.1** | **API documentation (OpenAPI/Swagger)** | No swagger/openapi tooling in the repo. |
| **4.2** | **Solution Architecture Document** | |
| **4.3** | **FMS — Functional Specification** | |
| **4.4** | **HMS — Functional Specification** | |
| **4.5** | **Security & Compliance doc + RBAC matrix** | The RBAC itself exists (`config/adminRoles.js`, incl. `SEO_MANAGER`); the document does not. |
| **4.6** | **Test suite to contract standard** | **145 backend test files pass** on `npm test`, **488 app tests** on `flutter test` and **46 web rule files** on `for f in tests/*.test.mjs; do node $f; done` (counts from 2026-09-16 night; there is no `test:rules` script — the earlier wording here named one that does not exist). A 37-case edge sweep of the pricing and negotiation helpers is in `report-2026-09-15/` (§8a28–29) but is not a permanent suite. The contract asks for >80% measured coverage, 200+ integration tests, plus load and OWASP reports. No coverage tooling is wired. |
| **4.7** | **Deployment guide + operational runbook + KT docs** | `DEPLOY_RUNBOOK.md` and the handoffs exist; `Deployment_Options_2026-09-05.docx` (05-09) covers requirements, sizing, tools, providers, cost and a migration plan. Still to formalise: the runbook for whichever host is chosen (§1.8) and the KT pack. |
| **4.8** | **UAT test cases + sign-off package** | **Manuals delivered 2026-09-05** — web (81 cases, 8 modules) and Android (55 cases, 6 modules), each with environment, accounts, procedure, defect template and sign-off table. Execution and sign-off are the client's; **an internal dry run of both manuals is recommended first** — see §6 for the cases that have only code/test-level verification so far. |

---

## 5. Section-0 site redo — separate SOW

Per contract §6 a visual overhaul is **outside** the ₹1,60,000 contract and needs
a signed change request. Per-item status lives in
[`AAJOO_SECTION0_TASKLIST.md`](AAJOO_SECTION0_TASKLIST.md) — check there before
quoting anything here.

**Already shipped from this section** (do not re-scope): brand palette `#0F766E`,
typography, the 9-category set, the CMS admin, and **the whole SEO layer**
(S0-SEO-1 — Phase 1 tasks 0–10, live; handover pack `SEO_Phase1_Handover.docx`
sent to the SEO team 2026-09-04).

**Still open:** Getting Started landing + intent routing (S0-GS-1/2/3) · OTP-first
and social auth (S0-AUTH-1/2/3) · page restructures for Home, About, Contact,
Login, Signup, FAQ (S0-PG-1…6) · property page redesign (S0-PROP-1) · branded
photo-less placeholder (S0-PROP-2) · content application (S0-CNT-1) · the five
blocked asset items (S0-ASSET-1…5).

**S0-CMS-1** is built but effectively empty — `tbl_cms_content` holds **1 row**
against 5 sections, so pages still render hardcoded copy. That is content entry,
not code. *(verified — DB count)*

**iOS App Store deployment** (OSC-1) is also a separate SOW.

---

## 6. Unproven, not broken

Nothing here is known to be defective. Each is a path nobody has exercised.

- The five destructive SEO writes: bulk apply (5,738 rows), 64-image ALT apply, CSV import apply, template enable, Global SEO save. Every one previews cleanly; only the final commit is untested.
- Sitemap generation at 29,000 URLs — measured at 26.
- The app's reviews path on a real device, after the reviews endpoint was opened to anonymous callers on 2026-09-03.
- Live end-to-end notification test (old BE-VERIFY-1) — code shipped, run deferred by the client.
- Google Search Console will not accept the sitemap without warnings until someone with GSC access submits it.
- Whether `dbCutoverSafe` currently reads true — see §2.4.
- **The emergency-distance lookup against real Google (§8a25, 2026-09-13).** `GOOGLE_PLACES_KEY` is not in the local env, so only the "not configured" branch has run here — the distance sort is unit-tested against a stub, and the HTTP path is the one the nearby picker already uses in production. What is genuinely unproven is `fire_station` as a Google type: it is documented, it was never in the `essentials` list before today, and nobody has yet seen it return a result for an Indian hill town. Open any listing's step 3 on the live site with a pin set; the three boxes should fill and say where the numbers came from. **An empty answer is not a failure** — it is what a place with no fire station within 25km looks like, and the box stays typeable.
- **The host wizard in a browser (§8a25–§8a27).** Behind a host login, and a stored password is not ours to type — which is how the step-1 regression in §8a27 reached the client. Worth sixty seconds on a phone: step 1 shows three bedroom cards for "3" and submits; Beds goes read-only once a room names one; the location map moves on ONE finger and has +/− buttons; the Homestay Type and Local Experience chips carry icons. *The checkout half of this row is done:* on 2026-09-15 the review and payment pages were walked in a real Chrome session with a live deal (§8a29) and the GST on the card matched the GST at checkout.
- **Whether the live notification popup actually appears (§8a27).** Reported as "message aa rhe h but popups nahi aa rhe" and NOT reproduced: the server emits, the rooms match, and the transport answers. The silent-failure paths are closed and the popup moved off the mobile tab bar, which may be the whole story — but only the client's own phone can say. `liveState()` now reports up-or-why-not, so the next report can come with a reason.
- **The deal price on the client's own 29310 stay (§8a28).** The deal path itself IS now proven live — a real weekly deal on 29302 walked from the dialog to the payment page on 2026-09-15 with card, review and payment agreeing to the paise (§8a29). What remains unphotographed is the client's exact 29310 case: its coupon `DEAL29310179161` is spent (B476130) and the listing's next free night is later. The same arithmetic gives ₹1,800 off / ₹27,376 there; the Razorpay sheet itself was not opened. The app's chat page handing over to the listing is tested, not driven.
- **For the tester, on build 16** (each deploys cleanly and is covered by tests, but needs a signed-in host/guest on a device): #19's merged notification feed matches the website for the same host; the guest count survives "Move to Book at Agreed Price" on a *new* negotiation; airplane mode on host Notifications, guest My Negotiations and host Profile → properties shows "Couldn't load · Try again" rather than an empty state; #13's dropdown focus jump (fixed from the code, never reproduced on the emulator).
- ~~**The app's GUEST side of the negotiation rebuild, on a device.**~~ **Driven 2026-09-15 on build 92:** the deal banner opened the listing with the deal, the offer sheet, the counter, the accept and My Negotiations were all walked (§8a29). What is still unphotographed on a device is the HOST side of a weekly negotiation and the chat page's hand-over to the listing.
- **The app's header total under the loading overlay (seen 2026-09-15, build 94).** Opening 29309 from the deal banner, the "₹… total · incl. taxes" line under the nightly price read **₹49,217.07** for about a second — under the dimmed loading overlay — before settling on the server's ₹45,199.35. The interim is the page's local estimate (7 × ₹7,000 flat, minus the 4.34% deal, plus 5%): no weekly rate, no weekend nights, no per-night banding. Nothing can be booked at it and it is gone before the overlay lifts, but it is a wrong number on screen. The website hides the figure behind "Indicative total" until the quote lands; the app should not print one at all until then.
- **`REQUIRE_IMAGE_ALT`** — whether it has been set on Render is not visible from outside (see §2.3).
- **UAT cases with code/test-level verification only (2026-09-05).** Most manual cases were walked live during the 1 Sep sweep and this week's fixes, but these have not been driven end-to-end on production or a device: web **W-BOOK-04** (cancellation card + acknowledgement on Booking review — deployed, not exercised in a real checkout), **W-ACC-03** (cancel quote from the policy snapshot), **W-BOOK-11** (double-booking race), **W-NEG-02** (guest count through an accepted counter); Android **build 17 has not been run on a device** — A-BOOK-02 (reserve-sheet card), A-EXP-04 (policy tab from the server), A-X-01 (airplane-mode states), A-ACC-07 (push), A-ONB-04 (Google sign-in), A-ACC-12 (chat after the handoff-token change). Everything else in the manuals is either verified live or a known limitation named in the manuals.

---

## 7. Cash / UPI collection — what is built and what is not

**The rail is built.** `tbl_host_dues` exists with 24 live rows, host dues offset
against payouts, and screens on web host, web admin and the app. Captured test
payments were driven on both web and the app.

**Three of the four decisions were answered in code on 2026-09-12** (§8a21), taking
the recommendation that had been sitting here unanswered since 09-04. They were
answered because leaving them open had a cost that was not visible from this
list: a pay-at-property booking stayed `book_is_paid = 0` for life, its four
ledger rows PENDING, no invoice and no queued payout — and **every finance screen
filters on COMPLETED, so the admin could not see a rupee of it and the host was
never paid.** The client asked for the button on the same day, which settled it.

1. ~~**Who confirms collection**~~ — **the host.** Admin reconciliation was the
   alternative and it scales badly: the person who took the money is the person
   who knows it arrived.
2. ~~**When**~~ — **at check-in, and also whenever they say so.** Check-in records
   it inside the check-in's own transaction, so a cash guest cannot be walked in
   while the booking still says nothing was paid. `POST
   /host/booking/collect-payment` records it on its own, because a host may
   collect before or after arrival, and a product that only records payment as a
   side effect of something else cannot answer “has this been paid?”
3. ~~**How the platform recovers 15% + GST**~~ — **netted off the next online
   payout**, which is what `tbl_host_dues` was built for and what it has been
   doing for the 24 rows already in it. The collection service deliberately does
   not touch that table: the debt was raised when the booking was made, and
   settling it is a separate act.
4. **If the host never confirms** — **STILL OPEN, and it is the one that needs
   you.** Auto-mark collected at checkout, or flag to admin? Recommendation
   unchanged: auto-flag to admin 24h after checkout rather than auto-marking,
   because auto-marking invents revenue. Until this is answered, a host who
   simply never presses the button leaves the booking unpaid for ever and the
   platform never recovers its commission — which is exactly the hole the other
   three just closed for every host who does press it.

**Guard rails already in the code**, so that answering 4 does not reopen 1–3: a CARD
booking can never be marked collected by hand (its money arrives through
Razorpay verification), collecting twice is refused rather than paid twice, a
cancelled booking cannot be collected against, and recording a payment does not
move the booking's status — whether a guest has arrived and whether they have
paid are two different facts. All four are pinned by
`tests/cashIsRecordedWhenCollected.test.js`.

The commission model itself is unchanged and already implemented in
`utils/financeRecorder.js` — 15% of room subtotal charged to the host, 18% GST on
that commission, four ledger rows per booking.

---

## 8. Closed since the last edition — do not redo

### 8a50. Closed 2026-09-20 (late) — the host half again on build 108: NG-028 accepted, three more defects, and the accept told once

**What ran (23:05—23:50 IST, host 100 on the emulator, guest 101 on the API):** offer → host counter
(above list) → guest counter-back → **host accepts** (NG-028, Critical) on 29291; earnings on the
negotiated price; a paused listing; the host's bell. **145 of 300 run.** Report: fourth sitting.

| # | What | Where | Commit |
|---|---|---|---|
| 20 | **A host counter had no price bound**: ₹2,600 on a ₹2,500 night went through. Now refused above the dated list price, and at/under the guest's own figure, with the number quoted. | backend | `2bcf1cc` |
| 21 | **A paused listing still took offers** — the tiers loader never read `is_active`; the refusal, when there was one, was for the notice hours. Says *paused* first now. | backend | `48d38b0` |
| 19b | *Booked* was matched by the stay, so the fresh deal on the same night as a spent one came back *Booked* and the guest lost *Book at the agreed price* the moment the host said yes. Matched by the deal's own code now. | backend | `f8ec735` |
| 9b | The plain accept path had the same two writers as the counter paths: two bell rows for one acceptance. One row now; and *"1 hour"*, not *"1 hours"*, on the approval request. | backend | `ac699fe` |

**Proven:** NG-022 on the app for the host (the list moved with no touch on build 108), NG-028, NG-060/061
(B021812's payout ₹1,728 = negotiated ₹2,099.75 — 15% commission — GST on it), BK-024.

> **Finance note (by design, one thing to confirm):** B021812 was pay-at-property — the host holds the cash and
> owes ₹476.99 in `tbl_host_dues`; the ₹1,728 *queued payout* is the same stay's host share, and the payout run offsets
> the one against the other (`cash_collection_blocked.md`). Confirm the offset shows on the host's payout statement so a
> cash stay never reads as money owed both ways.

**Records:** offers 235—237 on 29291 and the deal minted for 20→21 Sep (unused, expired at midnight);
29302 paused and un-paused.

---

### 8a53. Closed 2026-09-21 (11:20—13:10) — the gateway with the user at the Razorpay modal: nothing blocked; Defects 45—49

**What ran (guest 101 on the website, host 100 on the emulator, the user paying in Razorpay Test Mode):** BK-039 a failed
payment, BK-043 a dismissed one, BK-038 a paid one (B380412 ₹945), the guest cancellation with its code (Moderate · 50% ·
₹472.50, a real partial refund), NG-011 the accepted deal paid (B146234 ₹8,819.69 on #29312) and BK-068 the host cancelling
it from the phone (full refund, payout retracted). **300 of 300: 250 PASS · 35 FAIL (all fixed) · 9 SPEC · 0 BLOCKED · 6 INFO.**
Report: the "Seventh sitting" section.

| # | What | Where | Commit |
|---|---|---|---|
| 45 | **Defect 25's own re-check refunded a good payment** — the guest's abandoned hold counted as "another guest" (B653102) | backend | `3324f50` |
| 46 | A retried checkout held the nights twice; the earlier hold is now closed ("Checkout restarted") | backend | `5423467` |
| 47 | **No refund had ever reached the finance ledger** — refunded money counted as revenue/commission forever (10 bookings, ₹68,939, ~18% of revenue); `recordRefund`, full refunds reverse the credits, dashboard net of refunds, backfill run on dev | backend · web | `b1c0e92` · `4768bfc` · web `7e233d4` |
| 48 | The Upcoming card said "Confirmed — all set" under an *Awaiting approval* badge | web | `c4eec51` |
| 49 | **"Does the host approve" written twice with opposite defaults** — a NULL booking type said "request sent" and confirmed on payment with the host never asked; `utils/hostApproval` one rule; the app's wizard defaults to approval like the web | backend · app | `7380a98` · app `92c8b7c` |

**Test mailboxes:** four cancellation-code mails left Brevo ("Email sent successfully") and none showed in Mailinator, which then
dropped every other mail too — move accounts 100/101 to real mailboxes; the run read the code from the dev database.

**Records:** B283961 (superseded), B653102 (refunded in full by the platform), B380412 (₹472.50 refunded, payout po_25 on hold
₹741 for a human re-split), B146234 (refunded in full, payout po_26 retracted); invoices 0077/0078 (GENERATED — no void on
refund, a finance decision); #29312 paused again; its fake bank rows (`pbd 5`, `had 4`) still to remove.

**Still with the user:** build 109 (JDK 17/21 install), the admin refusals (payout 24, `hd_id 49`), the bank rows, the two
product decisions (exact negotiated charging; a `payment.captured` webhook).

---

### 8a52. Closed 2026-09-21 (00:20—05:10) — every case has a verdict: the booking remainder, the wizard end to end, the publish chain; Defects 23—44

**What ran (guest 101 on the website and the API; host 100 on the emulator, build 108; the admin queue on the
website; the server's own controllers driven in-process where a token would otherwise be needed):** BK-040…100
(holds, double-click, overlap/same-day/turnover, the cancel dialog to its OTP, refunds by test and by B939553, invoices,
modification, capacity search, back/refresh), NG-010/015/033/056—059/076/081/089/097—100 and the race and bot cases by
code, and **HL-001…100 on a fresh draft #29312** — five steps, every refusal typed and read, 10 photos, the sale deed,
fake bank details (flagged), submit → admin reject (with a reason) → edit and resubmit from the phone → approve → public
page → a live edit ("Changes submitted — your listing stays live"). **300 of 300 have a verdict: 245 PASS · 35 FAIL
(all fixed) · 9 SPEC · 5 BLOCKED · 6 INFO.** Report: `report-2026-09-17/TEST_RUN_300/RESULTS.md`, the "Fifth and
sixth sittings" section and every batch table filled.

| # | What | Where | Commit |
|---|---|---|---|
| 23—29 | The deposit stated under every total; the host told only of a real booking; verify re-checks the nights (`datesTaken`); the advance day gets its 10%; invoices numbered from `inv_id` (+29 backfilled) and a cash receipt; offers wait as long as the host said; a stale counter refused | backend · web · app | `b31c0a6` · web `b7bba40` · app 109 |
| 30—39 | BHK check reads the slug; parking spaces (`showIf.in`); pet price on the app; wheelchair-but-how; smart-lock note; photo reorder; min ≤ max nights (server + both); caretaker gating; dialable phones on the server; the readiness card keeps the newest answer | schema · backend · web · app | `7feb828` · web `7c8ab4a` · app 109 |
| 40 | **The reviewer's reason was never shown on the listing** (`psb_review_notes`: one writer, no reader) — `review_notes` on the host's rows, `review` on the draft; the card line and the wizard banner | all three | `66ac24d` · web `6dea8f7` · app 109 |
| 41 | A 9 MB photo passed the photo route under "must be under 8 MB" | backend | `943bd5e` |
| 42 | A type change kept the old type's answers (printed on the public page); both clients now ask first, the server drops the old groups | all three | `e333879` · web `4763f45` · app 109 |
| 43 | The app never set `has_pool` — Pool Type was never asked on the phone; `has_pool`/`has_wifi` derived on load | app · web | web `92dea0d` · app 109 |
| 44 | **The bed rule ran on the typed count while the room-card sum was stored** — #29312 went live as "2 bedrooms · 1 bed · 4 guests" | backend · app | `f8549ba` · app 109 |

Also: HL-043 built (Find an amenity, both clients); BK-018's room line says "(weekly rate)" (web `5bd9b13`); Defect 3
fixed by instruction. Backend 182/182 · web 69 files + `tsc -b` + build · app 593, analyze 0 errors.

**Build 109 is committed (monorepo `d1aabf9`, `aa4672a`) and NOT built:** Android Studio updated itself on 20 Sep 22:46
(JBR = OpenJDK 25.0.3, the old JBR gutted, no other JDK on the machine); Gradle 8.7 will not start on JDK 25. Install a
JDK 17/21, `flutter config --jdk-dir=…`, then the usual `./tool/build_release.ps1 …` and the subtree push.

**Records:** listing **#29312 is LIVE and public** on host 100 (test images, LUXE flag, fake bank rows `pbd 5` /
`had 4` ending …2222) — pause/suspend it and remove the bank rows; offers 241/242 + deal `DEAL29312101C242` (until
midnight 21 Sep, no booking); psb 15, audit 144/145, bells un 861/862; B249119 and the 22→24 Sep hold lapse.

**Still needing a hand:** BK-038/039/043 + NG-011 at the Razorpay modal (the deal above would close NG-011); NG-077 (a
second sign-in); the admin refusals (payout 24 reject, `hd_id 49` void, BK-088 price edit); the B326241 OTP cancel;
two decisions — exact charging of a negotiated price (flat-amount deal, three surfaces) vs the documented sub-rupee
round-up, and a `payment.captured` webhook as the second leg of payment confirmation.

---

### 8a51. Closed 2026-09-21 (00:00—00:20) — the host's decline, the day's lock, and the guest told of it

**What ran (after midnight so the decline could lock a fresh IST day; host 100 on the emulator, guest 101 on the API and
the website):** NG-030 the host declines (offer 238 on 29291 → *Decline* → confirm), NG-095 the guest re-offers
(two offers, same night and other dates → both refused with the day's lock), HL-077 and HL-099 from the host's own screens.
**147 of 300 run.** Report: fourth sitting, after the row for NG-084.

| # | What | Where | Commit |
|---|---|---|---|
| 22 | **The guest was not told the host declined.** A plain decline (no counter in the session, so no parting coupon and none of its notification) wrote no bell row — only the socket emit, which reaches a guest with the page open and nobody else. One row now, written only when the parting coupon's own notification did not go out; re-proven live on 29302 (offer 239, row 858). | backend | `d64abab` |

**Proven:** the decline itself (thread *declined*, `host_decline` logged, the host's list emptied, the guest's website
moved live), the lock-out for the IST day on any dates of that listing, HL-077 (*Identity verified* on the host's profile),
HL-099 (*Properties 2*, the host's own; `/host/property-search` filters on the token's id).

**Records:** offer 238 on 29291 and offer 239 on 29302, both declined; guest 101 locked out of both listings for 21 Sep
(clears at midnight). No bookings.

**Still needing a hand:** admin void of `tbl_host_dues hd_id 49` (₹476.99 on host 100, from test booking B021812);
B326241 on 29303 awaits the guest's email-OTP cancel on the emulator (or the sweep); batch 5 payments need the Razorpay
sheet; NG-048/049/050/093 need a second guest account; NG-056—058 need the bot; BK-094 (approval timeout) was
not left overnight on the client's listing; HL batches 8—10 need one of our hosts (177/194) signed in.

---

### 8a49. Closed 2026-09-20 (night) — the guest half on the app: four more defects, build 108

**What ran (20:10—21:20 IST, emulator as guest 101, build 107 → 108):** the offer → instant
acceptance → deal → pay-at-property booking loop on our own host 177's 29295 (Nainital), the
guest Negotiations screen, the booking detail and tabs, and a cancellation up to its OTP.
**139 of 300 run.** Report: `report-2026-09-17/TEST_RUN_300/RESULTS.md`, third sitting.

| # | What | Where | Commit |
|---|---|---|---|
| 16 | **The stay sitting on the search point was dropped.** `6371 * acos(x)`: for a listing ON the point x is 1.0000000000000002 and MySQL's ACOS is NULL. The geocoder answers a town with a listing's own point, so *"Stays in Nainital"* showed nothing on the app while a name search found it. Found by reading the app's request off the Render log and replaying it. Clamped at all four sites; the test evaluates each literal with MySQL semantics. | backend, High | `aad3144` |
| 17 | The app's **GST slab followed the flat rate**, not the night being charged: a ₹9,500 Sunday on a ₹7,000 listing read *GST (5%) / ₹9,975* on the sheet while the server said 18% / ₹11,210. The fallback now bands on the discounted room per night. | app, money | build 108 |
| 18 | The **booking breakdown subtracted the discount twice**: `book_price` is stored net of the deal and two screens printed it as *Room charge* next to a *Discount* line (B326241: 8,400 — 1,100 + 1,512 = 9,912). The room line is now the listed room; `book_price` rounded, not truncated. | app, money display | build 108 |
| 19 | A **spent deal still said "Book at the agreed price"** on both surfaces. The list now says *booked* with the booking (matched by guest + stay + this thread's deal code); web and app render *Booked as B326241 — view booking*. | all three | `60cbd41` · web `501ad26` · build 108 |

Also in build 108: the guest Bookings tabs file a checked-out stay under Completed (the host tabs' rule).
Backend 166/166 · web 31/31 + `tsc -b` + build · app 558/558, analyze 0.

**Records (our host 177 only; nothing on the client's host 100 this sitting):** offers 233/234 on 29295,
deal `DEAL29295101234` (spent), booking **B326241** (pri 141, 20→21 Sep, pay at property, confirmed,
₹9,912 due) with dues row `hd_id 50` (₹2,998.98, host 177). **Its cancellation is gated by an email OTP**
(aajoo.renter1@mailinator.com) — a person's step; Sumit cancels it with the code, or lets the sweep
close it after 21 Sep.

**Still open from the guest app half:** BK-074 (invoice download), the cancellation itself (OTP), NG-080
(sign-out/in). The search sheet's *"1 guest"* default and the pre-redesign Dashboard/Profile screens are
parity items, not defects.

---

### 8a48. Closed 2026-09-20 (evening) — the 300-case run, batch 6 on a live loop: seven defects found and fixed, build 107

**What ran (18:00—19:45 IST, `report-2026-09-17/TEST_RUN_300/RESULTS.md`):** guest 101 on
Chrome, host 100 on the emulator (build 106, then 107), on host 100's own listing 29291 —
offer → host counter → counter-back → host counter → accept → deal → pay-at-property
booking **B021812** → host approval → check-in (cash recorded) → guest check-out → review
prompt. Batch 6 (guest negotiation) 27 of 30 run; 14 batch-4 booking cases and 4 batch-7 host
cases proven on the same loop. **135 of 300 run.**

**Found and fixed the same evening, every one pinned by a test that fails on the old code:**

| # | What | Where | Commit |
|---|---|---|---|
| 9 | The host was told **twice** for one guest counter (two bell rows, two pushes, two emails): the 09-17 `tellHost` fix added a second writer to a branch that already had one. Then the live `negotiation:guest_reply` event, which lived in the same helper, was put back for both counter paths after the website's test caught its loss. | backend | `0008c3e` + `a7a5929` |
| 10 | ₹2,100 on a ₹2,500 night came out as **16.01%** off and billed ₹2,099.75: `1 - 2100/2500` is `0.16000000000000003` to the machine and a bare `Math.ceil` rounded it up. `dealPercent()` settles the fraction first. | backend, money | `54b13c8` |
| 11 | An offer was **accepted on a night the guest had already booked** (offer 227 for B021812's night went to the host as pending). `submitOffer` now uses the booking guard's yardstick: an occupying booking or a host block refuses with a 409 that says whose it is. | backend, High | `4a88a61` |
| 12 | A **zero-night offer** (20→20 Sep) was accepted on a listing asking two nights and six hours' notice — and the **booking gate's notice / advance / same-day / season rules had been inert since 9 Sep**: `c2dd020` fed `checkInAllowed` a rules row SELECTed for four other columns (the inert-SELECT trap). `stayRefusal()` + `RULE_COLUMNS`, spread into the SELECT; offers held to the same rules. | backend, High | `bdab3b1` |
| 13 | `/user/ongoing/bookings` read its listing id from the dotted key of a `nest: true` row — `undefined` five times over: every ongoing stay went out **without its cover, with 2 PM / 11 AM instead of the host's hours, and with the pin withheld** (since June). | backend | `4aab209` |
| 14 | The guest's Next Booking page read **"Currently Staying" / "Booking Confirmed" with a Check-out button while the host still had an hour to answer** (dates outranking approval, one layer above where `lifecycleLabel` had already fixed it); and *"The host has 1 hours to approve"*. | web | `32fb9c1` |
| 15 | **Two offers from one click**: `claimNextRound` locked the guest's existing rows (none, for a first-timer) and committed before the insert. The claim now takes the listing's row and holds it across the insert; re-proven live — four simultaneous submits, one offer. | backend, race | `62e652f` |

**App, build 107 (`4c30f5a`):** `lib/service/live_channel.dart` — **one socket per signed-in
person** (`negotiation:*` + `notification:new`), connected at sign-in and on a restored session,
dropped at sign-out; the host and guest Negotiations lists, the host bell and the dashboard's
*Offers to review* reload on it (NG-022 had failed on the app: nothing moved until
pull-to-refresh). Proven on the emulator: a guest chat message put *New message from Aajoo
Renter — now* on the host's open list, 68 → 69, no touch. Also: the guest's *Checkout* on the ongoing
view now waits for the host and the clock (the app's twin of Defect 14), and a stay checked out
early is filed under **Completed** (B021812 sat under Ongoing by its dates). 551/551, analyze 0.

**Backend 164/164 · web 30/30 + `tsc -b` + build.** Every fix is live on `aajaodev.onrender.com`
and `www.aajoohomes.com` (verified against the deployed API: the five refusals answer as written).

**Records on the client's test accounts (by Sumit's instruction of 20 Sep), all listed in the
report:** host 100's calendar block *"QA end-to-end test block"* (20—22 Sep, 29291) removed through
the app; offers 223—226 and deal `DEAL29291101C226` on 29291; **B021812** (pri 140, completed);
probe offers 227—232 expired by direct update the moment their case was read (230 expired by
itself — NG-046); one chat message 101 → 100.

> **Needs an admin hand:** `tbl_host_dues` row **`hd_id 49` — ₹476.99 PENDING against host 100**
> (commission ₹315 + GST ₹57 + accommodation tax ₹104.99) was raised by the test booking and will
> surface in the client's payout ledger unless it is **voided with reason "test run"** from Admin →
> Finance. A session cannot do this (no admin sign-in); listed here so it is not forgotten.

**Still open from batch 6:** NG-076 (LUXE listing), NG-081 (accept exactly at expiry), NG-089
(language); NG-080 is BLOCKED on a sign-in; the guest half of NG-024 / NG-022 on the app wants the
emulator signed in as a guest. Batch 4 keeps 16 cases, batch 7 keeps 26 — most of the
remaining host-side ones can now run because host 100 is on the emulator.

---

### 8a47. Closed 2026-09-20 — an admin changes their own password (current password → new password), signed out everywhere

**The request (client, 20 Sep):** "an endpoint to update the password of
super admin accounts — super admin enters the old password to verify their
identity and then the new password."

**Built (backend `88be2cf`, web `4fb5ded`):**

- `POST /admin/change-password` — body `{ currentPassword, newPassword,
  confirmPassword? }`, admin JWT required, behind the critical limiter, on
  the RBAC `ALWAYS` list so **every admin role can change their own**
  password (a support admin too); nobody can change somebody else's here —
  that stays on the Members screen. The current password is checked against
  the bcrypt hash; the new one must meet the platform policy
  (`config/passwordPolicy.js`: 8+, upper, lower, digit, special, no spaces)
  and differ from the current; the change is audited
  (`admin_password_changed`, and `admin_password_change_refused` on a wrong
  current password) with **no password or hash in the row**.
- **Signed out everywhere:** `tbl_admins.admin_password_changed_at`
  (migration `20260920100000`, **applied live**); `adminAuth` refuses any
  token whose `iat` predates it — *"Your password was changed. Please sign in
  again."* — including the token the change arrived on. Both clocks are the
  API server's.
- **Web:** Admin → **Settings → Your password** (top card): current, new
  (live policy checklist), confirm; on success the page signs the admin out
  and returns to `/admin/login`.

**Verified:** backend **159/159** (`theAdminChangesTheirOwnPassword`, 9 —
the schema, the sign-out rule, the controller with real bcrypt and the real
audit helper against a stubbed table), web **57/57** + `tsc` + build.
**Not driven live:** a real change signs the client's admin out on every
device, and a session never types a stored password (house rule).

---

### 8a46. Closed 2026-09-20 — "Chat doesn't know it's you" on a new account: what it was, what it was not, and what changed

**The report (client, 20 Sep 04:44, with a screenshot from 19 Sep 21:30 IST):**
a freshly registered guest ("Satish", iPhone Safari on 5G) saw the dashboard
notice *Chat doesn't know it's you — We still couldn't reconnect your
account… Try once more*. The client tested the chatbot from the dashboard
only, not the bot. BotPenguin's team read the message text and concluded
the account-to-chat handoff "does not return a chat token", and asked us to
trace `/bp/handoff` for the account.

**What was checked, and how:**
- `/bp/handoff` for the client's own signed-in host session, called from
  the live site: **200 in 1.9 s, token + phone + name + email +
  `support_role: host`**. The route is the same for every account; the only
  account-specific refusal it has is a deleted account.
- The two calls from the phone at **21:26:21 and 21:27:14 IST** are in the
  Render request log — they reached the server and were answered (the log
  UI would not hold a filter under automation, so their status codes were
  not read; the next fact settles it anyway).
- A 401 is excluded by the screenshot itself: the site's interceptor ends
  the session on any 401, and the dashboard was still signed in.
- The module's own code: after the handoff succeeds it waits **6 seconds**
  for BotPenguin's script (`cdn.botpenguin.com`) to draw its launcher, and
  when that did not happen it reloaded once and then set `identityMissing`
  — i.e. **a chat script that had not loaded on a phone link was reported
  as an identity failure**. And on a genuine failure the handoff was tried
  three times inside **1.6 s**, which on a Render Free instance that takes
  "50 seconds or more" to wake is three attempts before the server exists.

**So:** the message was wrong about what failed. Nothing indicates the
handoff refused the account; BotPenguin's inference came from our wording.
The bot itself was not tested by anyone.

**Changed (web `6525a64`):** two states with two sentences — *Chat doesn't
know it's you* (only when the handoff returned no token) and *Chat couldn't
load* ("Your account is recognised — try again in a moment, or email us
from Support"); the launcher gets **20 s** to draw; the handoff is retried
for **about a minute** on retryable failures (0/1/2/4/8/15/15/15 s) and
still stops at once on a definitive refusal — the older test that capped
the budget at 3 s is reversed, with the reason in it. Web **56/56** + build.

**What only the paid instance fixes:** the cold start itself (runbook §2,
Render `1c-2g`). Until then a first visitor after 15 idle minutes waits for
the server; the chat launcher now waits with them instead of giving up.

**Not driven live:** a fresh account on a phone. The behaviour is pinned by
`theChatSaysWhichThingFailed` (4) against the module; the client's
"provide support to new accounts" is answered by the same handoff that
already carries name, phone, email and role for every signed-in account —
there is no new-account path to add.

---

### 8a45. Closed 2026-09-19 — the stay ends on both ends; a finished stay no longer blocks a new booking; build 106

**The client's two reports (WhatsApp, 20:13):** "in mobile view I want to
book the property, it already shows me View your booking — fix this flow";
"check out process is still missing — both the ends." Screenshots: the
property page for booking **B115781 (13→14 Sep)** on the 19th, sticky bar
reading *View your booking*, the card reading *You're booked here*.

**One root cause.** Check-in existed (host, status 6). The ONLY thing that
ever set status 7 "Check Out" was the guest submitting a review from the
app — the website could not, and the host never could — so a stay nobody
reviewed stayed "Check In" for ever: "Staying now" on the host's list,
"You're booked here" on the property page (the 2026-09-17 rule hides Book
Now for a live booking), never "Completed". In the live table: 4 bookings
in status 6, 0 in 7.

**Built (backend `dc8cbbf`, web `8d1db05`, app in this build):**

- **One transition** in `services/stayCompletion.js` — `completeStay`:
  paid / booked / confirmed / checked-in AND started (check-in day reached,
  IST) → status 7 on `tbl_bookings` + `tbl_book_details`, a history line
  naming who ended it; already-7 answers `already: true` (a double tap is
  a quiet yes). The guest is told and asked to review
  (`booking_checked_out`, `reviewPrompt`); the host is told on the bell.
- **Host end:** `POST /host/booking/check-out`. Web: `HostBookingActions`
  used to return *nothing* for a checked-in stay — it now renders
  **Check-out** (toast: "…asked to leave a review"). App: host booking
  detail gets **Mark guest as checked-out** once the guest is in.
- **Guest end:** `POST /user/booking/check-out`. Web: the stay-in-progress
  page (`NextBooking`) gets **Check out** with a confirmation, then lands on
  the review page with the listing in navigation state. App: the existing
  *Checkout* button on the ongoing-stay screen now **ends the stay first**,
  then opens the review (it used to open the review only, so a guest who
  skipped it never checked out).
- **The sweep** (`startStayCompletion`, hourly): a CHECKED-IN stay is closed
  the day after its check-out date, guest and host told. Only status 6 — a
  paid stay nobody checked in is either a no-show (the host's call,
  non-refundable) or a host who forgot, and the platform cannot tell which.
  The four live status-6 rows will be closed by the first tick after
  deploy.
- **The property page** decides "booked here" by the DATES first
  (`hasEnded(bt_book_to)`), then the label — so a finished stay never blocks
  a new booking whatever its status. And on the phone the sticky bar now
  shows **Book other dates** beside *View your booking* — the 09-17 rule
  says a booked guest is not shown Book Now by default, not that they
  cannot book other dates; the bar was the only control in reach and read
  as "you cannot book here".

**Verified:** backend **158/158** (`theStayEndsOnBothEnds`: the IST day,
started/overdue, the sweep's rule, host and guest transitions against the
real controllers with stubbed tables, refusals, idempotence, a forgotten
check-in), web **55/55** + `tsc` + build green, app **535/535**, analyze 0
errors. **Build 106** (`aajoo-homes-1.0.0-build106-release.apk`, 95.5 MB,
sha256 `db27821d9ffc842d…`) built with `tool/build_release.ps1` and read back by the
verifier; also carries §8a44's push-token fix and §8a43's KYC wording.
**Driven live by the deploy itself:** the sweep runs once at boot, and the
first boot of `dc8cbbf` closed the four checked-in stays past their date at
16:59 UTC — B153001, B244718, **B115781** (the client's screenshot) and
B675275 — each with the history line *"Stay ended on its check-out date;
closed by Aajoo Homes"*; B115781 reads "Check Out" now, so the property
page no longer says "You're booked here" for it. The host/guest buttons are
pinned by tests against the real controllers; a tap on the deployed stack
needs a checked-in booking on one of our own accounts.

---

### 8a44. Closed 2026-09-19 — two findings from the first iOS Simulator run, and what they really were

The Mac session's first Simulator drive (Sumit, 19 Sep) reported two
things from the request log. Both were checked here against the source.

**1. "The app hardcodes credentials and auto-logs in" — NOT TRUE, but the
account matters.** The log showed `POST /user/login` for
`aajoo.renter1@mailinator.com`. That string is nowhere in the app: not in
`lib/`, `test/`, `tool/`, any plist/json/yaml, no `TextEditingController(text:)`,
no `String.fromEnvironment` login, no stored-password replay (only the
email is persisted). The sign-in was typed on the Simulator. **The account
is user 101 — the client's own test guest "Aajoo Renter"** (backend seed
`scripts/seedBotpenguinTestData.js`: GUEST_ID 101, HOST_ID 100), the one
account every rule here says never to drive as; its password was readable
in this repository (below), which is how the Mac had it. Rule for the Mac
(handoff §6): never sign in as 100/101; use 179 / 194 / 177.

**2. The 401 on the first FCM token save — REAL, and shared.**
`NotificationService.saveTokenToDatabase` posted
`/user/notification/allow-notification` with whatever the session was,
including none → `Bearer null` → 401 "jwt malformed"; it recovered only
because the home screen re-runs init after sign-in. Same Dart on Android.
**Fixed (monorepo `b5f450c`):** no session → the token is kept (it is
already in storage) and nothing is posted; `syncTokenAfterLogin()` sends it
right after sign-in, after the phone gate, off the critical path. Test
`the_push_token_waits_for_a_session_test.dart` proves the guard RUNS
(mock storage, no session, the call returns and logs "No session yet")
and that sign-in calls the sync. App **530/530**, analyze 0 errors.

**3. What the search for #1 actually found — credentials committed in the
PUBLIC monorepo.** Checked by hash against the live `.env`, values never
printed:

| What | Where (tracked) | Live? |
|---|---|---|
| **Razorpay key id + key secret** | `aajooBackend-2026/config/payments.config.js` (a stale backend copy, untouched since 12 Aug) | **YES — equal to `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET` on Render.** With the secret, anyone can forge a valid payment signature and mark a booking paid without paying. |
| Client test-account passwords (guest 101, host 100) | 3 session handoffs, `testing-checklists/` (html + js), `_archive/` ×5 | yes — the accounts the client tests with |
| Dev-admin email + password literal | `.env.example`, `src/features/admin/adminAuth/adminAuth.thunk.ts` (stale web copy) — and the **live web repo's** copy of the same file | the bypass runs only under `vite dev` with a flag, so the literal was dead in production; removed anyway (web `e590ec4`) |
| A Clever Cloud DB user/password | `aajooBackend-2026/config/config.json` | no — the old dev database, different host/user/password from live |
| An APK (build 31) | repo root | old Razorpay key id inside; key ids are public by nature |

**Done here (working tree only, monorepo `b5f450c`):** the two Razorpay
literals → empty (env-only), the DB creds blanked, `.env.example` and both
`adminAuth.thunk.ts` without literals, the two passwords replaced in all
eight docs/checklists with a redaction note, the APK untracked. Nothing
password-shaped remains in any tracked text file (regex sweep, 0 left).

**Still open — Sumit's / the client's decisions, in this order:**
1. **Rotate the Razorpay test key** (Razorpay dashboard → Settings → API
   keys → Regenerate). Then set the new pair on Render
   (`RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`), the new id on Vercel
   (`VITE_RAZORPAY_KEY`), and **cut build 106 with the new id** — every
   circulating APK (102–105) has the old id compiled in and its checkout
   stops working the moment the old key is disabled. Do the rotation and
   the build in one sitting.
2. **Make the monorepo private** (`gh repo edit isumitmalhotra/Ajoo-Admin-Website- --visibility private`,
   or Settings → Danger Zone). History still holds every value above; a
   private repo stops new readers, rotation makes the old values worthless.
   CI cost trade-off in the handoff §1 (macOS minutes at 10× under Free).
3. **Rotate the passwords of test accounts 100 and 101** (the client's; via
   Profile → change password with the email OTP, or on request a script here
   sets new ones and hands them over privately). Keep them in a password
   manager, never in a repo document again.
4. Optional: delete the stale copies `aajooBackend-2026/` (278 files) and
   the root web copy `src/` + `package.json` (438 files) — both superseded by
   the standalone repos since August; and/or rewrite history (BFG) once
   private. Not done without a yes: 716 tracked files.

---

### 8a43. Closed 2026-09-19 — a DIDIT approval is granted only when the document's name is the account's name

**What the client found (18 Sep, with a screenshot of the DIDIT flow):** an
account registered under one name completed KYC with a *friend's* Aadhaar
and came out Verified. DIDIT proves that the document is real and that the
face in front of the camera is its holder's — it does not know whose
account it is, and nothing on our side asked. "If registered name or KYC
name didn't match, do not do KYC."

**The rule now (backend `465a936`, one place — `applyDecision` in
`verify.controller.js`):** when DIDIT approves, the name it read off the
document is compared with `tbl_users.user_fullName` by
`utils/kycNameMatch.js` — normalised tokens, order-free, honorifics
dropped, initials and a one-letter slip on a long name tolerated, a name
that is a subset of the other counts ("Sunil" vs "Sunil Kumar", "Sumit
Malhotra" vs "Sumit Kumar Malhotra"). A different name is a **mismatch →
declined**: the account is not verified, the reason is kept, an admin flag
`KYC_NAME_MISMATCH` is raised, the person gets a bell/push/mail saying
"verify with your own government ID — or correct your account name first",
the admin gets a notification (ids only). No readable name → **in_review**,
never a grant. `KYC_NAME_MATCH=strict` on Render would refuse the subset
case too (not set; lenient is the default).

**Evidence:** two new columns on `tbl_kyc_verifications` —
`kv_account_name`, `kv_name_check` (exact / partial / mismatch / unknown) —
**migration applied to the live database 2026-09-19** and read back.
`/verify/status`, `/verify/check-session`, `/verify/my-session` and
`/user/detail` carry `reason` / `verification_reason`; both admin detail
endpoints send both names and the verdict. Web `007bc41`: the account
screen, the dashboard nudge and the DIDIT return page say why; the admin
host/user panel shows *Name on document · Name on account then · Name
check* and calls a mismatch out before a manual verify. App: the same
words in the post-check alert and the nudge; `verificationReason` on the
user model.

**Audit of every recorded decision (24 rows), and the backfill:** the
eight DIDIT rows that carry a document name were compared and the verdict
written into the new columns (no status touched). Three match exactly
(users 151, 152, 180). **Five do not** — users **176** (host), **187**
(host, driver's licence), **190** (guest), **207** (guest, decided 18 Sep —
almost certainly the client's own friend's-Aadhaar test) verified by DIDIT
on a document with a different name, and **165** (host) held in review on a
mismatch and later verified by hand. All five are verified today. **Open:
the client decides whether to revoke them** (admin → the user → un-verify;
the panel now shows both names). Not revoked here — 176/187 are hosts with
live listings and revoking un-publishes them.

**Verified:** backend **155/155** (`theNameOnTheDocumentIsTheNameOnTheAccount`
16 assertions: the client's case, Indian name variants, Devanagari, a thin
webhook completed from the decision endpoint, an unreadable name held,
DIDIT's own decline unchanged, the per-booking path, the reason lookup),
web **54/54** + `tsc` + build green, app **527/527**, analyze 0 errors.
**Driven live (read-only, in the client's admin session):** the deployed
backend answered `/admin/user/single` for 207 and 190 with `nameCheck:
mismatch` beside DIDIT's own `verified`, and 151 with `exact`; the deployed
admin panel for 207 showed *Latest DIDIT decision · Name check: DOES NOT
match the account name* with the call-out (web `0501985` then corrected
the wording for a pre-rule grant: "verified before the rule — un-verify it
unless…"). **A slip while doing it:** a scripted click meant for the
row's eye button hit the Active/Inactive toggle first and deactivated
user 207 for about a minute before it was toggled back (`user_isActive`
read 1 again); the toggle sends no notification and revokes no session,
but `tbl_admin_audit` carries two `status_update` rows on 207 by the
Super Admin at ~03:50 IST on 19 Sep that are mine, not the client's.
**Not driven live:** a real DIDIT session with a mismatched name needs a
real document; the refusal itself is pinned by tests against the real
controller with the tables stubbed. **No app build cut** — the app change is wording on a
declined state; the refusal itself is the server's and reaches build 105
as it is.

**Considered and not done:** DIDIT's own `expected_details` cross-check is
documented for their **v3** session API; the platform calls **v2**, and a
version change untested against a sandbox is not worth the risk for a
check we can do ourselves and fail closed on.

---

### 8a42. Closed 2026-09-18 — manual payouts driven end to end on the live platform; verification that lasts; detailed payout emails; build 105

**The live drive** (admin as Super Admin in the client's Chrome; every
write on developer records — hosts #177 "Host Mobile" and #194, the
client's Sam Tao (100) deliberately untouched and still six Queued rows):
reveal without a reason refused → reveal with a reason → both accounts
*Verified* with references → readiness matched the database to the rupee
(#177: ₹66,441.60 − ₹9,079.45 dues = ₹57,362.15; #194: ₹1,646; Sam Tao,
ashish host, Web five *not ready — no payout account*) → **PR-0001** opened
(payouts claimed, gone from readiness) → bank CSV downloaded (two rows,
NEFT/IMPS by size, narration `AAJOO PR-0001`; run → EXPORTED) → line #177
**Paid** (5 payouts COMPLETED with the UTR, 5 ledger DEBITs, the due
RECOVERED, bell + push + email) → line #194 **Bounced** (payout back to
QUEUED, host told) → run closed → **PR-0002** with the same UTR **refused
by the server** ("already recorded on run #1") → fresh UTR paid → closed.
Six audit rows per host cycle. Queue now 12 queued / 6 completed / 4
failed; two runs CLOSED.

**Three follow-ups the client asked the same evening, all built and
verified on the live server:**

1. *"Once verified it should not ask again unless the host changes the
   account."* It did ask again: `saveHostAccount` reset `had_isVerified`
   on every save. Now the destination (account number + IFSC, or UPI) is
   compared with what is on file — unchanged keeps the verification and
   updates only the holder's and bank's names; changed resets it, starts
   the ₹1 verification, and tells the host by bell, push and a dedicated
   email (the one mail that must reach the holder if somebody else made
   the change). Pinned: two assertions against stubbed tables.
2. *"The verified status should be visible in the host dashboard."* It was
   on the Profile page and the Payouts badge; it is now on the **host
   Dashboard's earnings card** too (web: *Payout account · Not added /
   Awaiting verification / Verified / Needs attention* with *Settled to
   date*; app: one chip on the home earnings card). Read live on Sam's
   dashboard: *Settled to date ₹0 · Payout account Not added →*.
3. *"Payouts visible everywhere, and a proper email as well as
   notifications."* Everywhere: host Payouts (UTR/method), Earnings
   (settled total), Statements (ledger PAYOUT rows), Settlements
   ("Deducted from a payout · payout #5"), admin queue (UTR), **admin
   payout detail (Paid by / UTR / Payout run — new)**, **admin payout
   history (UTR column — new)**, Financial Overview (completed sum),
   Ledgers. Emails: the generic one-line notification mail DID go out
   today (mail log rows 778–782 to the two hosts, status 1); it is now
   replaced by **four detailed mails** in `services/payouts/payoutMail.js`
   — paid (amount, method, UTR, date, run, every booking settled, the
   withheld line and why), bounced (the bank's reason), account verified
   (the ₹1 reference, "you will not be asked again unless you change it"),
   account needs attention — each under the host's payment-email
   preference, each notification written with the new `mailed: true` so
   the generic mail steps aside. Verified live: withdraw + re-verify on
   #194 produced `payout_account_attention` and `payout_account_verified`
   rows, status 1, body read back.

Verified: backend **154/154** (`theBankMovesTheMoneyThePlatformRecordsIt`
now 15), web **53/53** (+2) + `tsc` clean + build green, app **522/522**
with analyze 0 errors. **Build 105** built with `tool/build_release.ps1`
and read back by the verifier. Not driven live: the re-save-keeps-verified
path needs a host with a verified account signed in (the only host session
was Sam's, who has none) — it is pinned by tests; the same for the "account
changed" mail.

---

### 8a41. Closed 2026-09-18 — manual host payouts: the bank moves the money, the platform records it; build 104

**The client's line:** *"For payouts, check the system for manual payouts."*
The company is not eligible for a payout provider (§8a34: RazorpayX and Route
both refuse a pre-revenue merchant), so nothing could be paid — Approve
refused without RazorpayX credentials, and a host's account could only be
verified by the provider's penny drop. Live that morning: **18 payouts
queued (₹1,66,549), 2 accounts on file, 0 verified.**

**What was built.** `PAYOUT_MODE=manual` is the default whenever RazorpayX
is not configured (the provider path is untouched; `razorpayx` switches it
back on). In manual mode:

- **Payout accounts** (Admin → Finance → Payouts → Payout accounts): every
  host's account and its state. *Reveal* (masked until then; needs a reason;
  logged as `payout_account_revealed`), finance sends **₹1** from the company
  account, *Mark verified* with the bank's reference (`had_verify_ref`,
  `had_provider = manual`), or *Mark as needing attention* with a reason the
  host reads. A freshly saved account reads **"Awaiting verification — we
  will send ₹1"** (`awaiting_manual`), not "unconfigured".
- **Payout runs** (`GET /admin/finance/payout-runs/readiness`): every queued
  payout, **one line per host**, ready / not ready with the reason
  (unverified, on hold). Opening a run claims the payouts — `QUEUED →
  PROCESSING` with `po_run_id` in the same UPDATE, so two runs cannot take
  one payout. Pay-at-property dues are withheld oldest-first, and a host
  whose dues swallow the whole batch is refused rather than exported as ₹0.
- **The run page**: the bank's bulk-transfer CSV (beneficiary, account,
  IFSC, amount, NEFT/IMPS/RTGS by size, narration `AAJOO PR-0001`) — a
  download is an audited reveal; each line recorded **PAID** with UTR,
  method and date (settles the payouts, writes one ledger DEBIT per payout
  with the UTR, marks the dues RECOVERED, notifies the host with the amount
  and UTR) or **BOUNCED** with the bank's reason (payouts back to QUEUED,
  host told to check their account); *Close* once every line has an outcome.
- **Guards that run:** `pri_utr` is UNIQUE across every line ever recorded;
  dues that changed since the file was made **refuse** the line ("bounce it
  and open a new run") rather than re-split; a UTR already recorded names
  the run it is on.
- **The queue** in manual mode offers *Pay via run* instead of Approve,
  shows *In run #n* on a claimed payout and the UTR on a paid one; the
  server refuses Approve in manual mode regardless, pointing at the run.
- **Hosts** (web and app): *Paid · by NEFT · UTR …*, *Queued — released on
  the next payout run*, *Being paid* while a run is open, the withheld line
  with a link to Settlements.
- **Weekly nudge** to the admin bell, Tuesday 10:00 IST
  (`PAYOUT_RUN_DAY`/`PAYOUT_RUN_HOUR`): hosts ready, amount, hosts waiting.

**Schema:** migration `20260918150000-manual-payout-runs` — `tbl_payout_runs`,
`tbl_payout_run_items`, `tbl_payouts.po_run_id`; **applied to the live
database 2026-09-18** and read back (both tables present, `po_run_id`
present, `pri_utr` unique).

**Not built, on purpose:** TDS under §194-O. The admin table already has
the columns; they stay at zero until the accountant confirms the rate
(`PLANETSCALE_AND_MANUAL_PAYOUTS_2026-09-18.md` §4.4). The bank's exact
bulk-file column order is the company's bank's to name; the seven fields
are the ones every Indian bank's template takes.

Verified: backend **154/154** (`theBankMovesTheMoneyThePlatformRecordsIt`,
12 assertions against stubbed tables — the UTR guard, the dues guard, the
bounce, the reminder slot), web **53/53** + `tsc` clean + build green, app
**522/522** with analyze 0 errors. **Build 104** built with
`tool/build_release.ps1` and read back by the verifier. Not driven live:
the finance screens need an admin signed in and a password we do not
type; the row shapes are the ones the tests send.

---

### 8a40. Closed 2026-09-18 — the two negotiation decisions answered and built; the app on the client's private repo; build 103

**The client answered the 17 September decisions document** (`report-2026-09-17/NEGOTIATION_DECISIONS.md`)
in two lines: *"counter price keep it like the current structure only"* and
*"show in the upcoming till the deal is running."*

**Decision 1 — Option A, keep the sliding counter.** No code change. Pinned
by `tests/theHostSeesADealWhileItRuns.test.js`, which reproduces the worked
example the client was shown (list 2,000 / ideal 1,800 / floor 1,500 → a
₹100 offer is quoted 1,900, ₹1,000 → 1,850, ₹1,400 and ₹1,600 → 1,800, ₹1,800
accepted), so nobody later "fixes" the counter to always quote the ideal.
**Do not change `decideOffer` / `counterPrice` without a new client decision.**

**Decision 2 — in the Upcoming tab, while the deal runs, gone when it
expires** (Option A with the badge; the smaller question — show an expired
unbooked price? — answered "no" by "till the deal is running"). New host
endpoint `GET /host/deals/running`: every personal coupon minted by an
accepted negotiation on the host's listings that is live, unexpired and
unused. A used coupon is a booking and the bookings list has it; a **parting
offer** (the host's own last price after they declined, §8a-era) is the same
instrument and is deliberately left out — "price agreed" would be a lie
about it. The rupee figure is read back from the accepted offer of *that*
guest for *those* dates (the coupon carries only the percentage). **Web:**
the host Bookings page's Upcoming tab lists the deals above the bookings,
amber, badged *Price agreed*, with *Not booked yet · expires in 2h 10m*, the
guest, listing, dates, ₹/night and the stay total; re-read every minute, the
countdown ticks on the viewer's clock, and a deal that lapses while the page
is open leaves the list on its own; the tab label counts them separately
(*Upcoming (3 · 2 deals)*). **App:** the host Booking History's Upcoming tab
does the same with an amber `_DealCard`. Every row carries the sentence
*"Price agreed, not booked yet. The nights stay open to everyone until the
guest pays."* — because the same client had asked whether two agreed prices
on one weekend meant a double booking (they do not; whoever pays first gets
the nights, §8a37).

**The app is on the client's private repository.** `nameeshPatiyal100/aajoo_app_latest`
confirmed private (unauthenticated GET → 404, `isPrivate: true`) before the
push; `main` is the app-only history from `git subtree split` — **391
commits, 22 MB, every `.apk`/`.aab` stripped from history**, tip = the
build-102 commit. A fresh clone ran `flutter pub get` + `flutter test`
(510 pass, 1 skipped) before anything was pushed. `android/app/google-services.json`
is in it, as it must be for the app to build; the key inside (`…iCk-WI`)
still needs the Android-app restriction in Google Cloud that §8a36 asked
for — a private repo does not replace that.

Verified: backend **153/153**, web **52/52** + `tsc` clean + build green, app
**517/517** with analyze 0 errors. **Build 103** built with
`tool/build_release.ps1` and read back by the verifier with the endpoint
named; 102 is superseded by it. Not driven live: the deals row needs a host
signed in, and neither the client's host (§9) nor a password we would type
is available — the endpoint's filtering is exercised against stubbed
tables instead, and the row renders from the same field names the test
sends.

---

### 8a39. Closed 2026-09-18 — the client's five of the same afternoon; the India map settled; build 102

**"Have we blocked same-day check-in and check-out intentionally? Even if
yes, it should be blocked while selecting dates, not at payment."** The
server has always refused a stay of zero nights ("Booking must be at least
1 day."); the website let one through to the payment page first. The
calendar closed the range on a tap of the check-in day, and both the
property page and the draft floored the night count to 1, so the summary
read "1 night" over a stay of none until the server said otherwise. The
check-in day is now greyed on the check-out side with a tooltip ("Check-out
has to be after check-in — a stay is at least one night"), the footer reads
"Check out 21 Sept or after", and the floors are gone. The app's check-out
picker offered the check-in day too and silently moved the tap to the next
morning; it now greys the day like the web.

**"I can proceed with guest count 0; after booking it takes 2 by default."**
The adults stepper went to 0 and the review page turned 0 into 2 without a
word. Adults stop at 1, both Book Now handlers open the guest picker on an
empty party, and the review page sends a zero-guest draft back to the
listing rather than inventing a number. The app already stopped at 1.

**"My property settings say allow to see the exact location before booking,
still after booking it shows like this" / "here where the setting says
cannot see, the renter can go to maps and see it from the booking
section."** Both true, for one reason: the booking pages had no way to know
the host's answer and were deciding from the booking's status alone. Both
guest booking endpoints now carry `hostShowsExactLocation`, read through
`exactLocationAllowed`, which moved from the listing controller to
`utils/approximateLocation` so every surface asks the same question of the
same table — and which now **fails closed** (a failed lookup used to be
swallowed and answered "show"). On the web, `StayLocation` has two keys —
the host confirmed, or the host shows it to everyone anyway — applied to
the pin, the address, Get directions and the in-app Directions link and
page; the setting travels from the listing page through the draft to the
confirmation. Next Booking, which never passed `confirmed` at all and so
defaulted to the exact pin on every row, passes both. A declined request
gets no map. The app: the listing page drew the radius circle captioned
"Exact location shared after booking" on **every** listing, including the
ones whose host had chosen to show it — it now reads
`location_is_approximate` and draws a pin with no caption when the host
shows it; the confirmed screen and the ongoing-booking screen follow the
same two keys.

**"In this page, the Indian map is still incorrect."** The screenshot was
the search page with no results, drawn by **Leaflet on OpenStreetMap
tiles** at country zoom — Jammu & Kashmir dashed the way OSM maps it and
Indian law does not allow. That was the fallback while Google loaded or
when the key failed (§8a-era decision, "Google with a Leaflet fallback"): a
state nobody chose, produced by a slow script or a rejected key, with
nothing visibly broken — the loose end the 2 September doc flagged. The
keyless Google embed is no better: checked in the browser the same day, it
takes no region and dashes the same lines. **Every live map is now Google
with `region=IN` or an honest panel** — a placeholder while the script
loads, "Map unavailable right now" if it never does, with a link out only
for a guest allowed the exact spot. The host's location picker keeps search
and "use my location" without the map. No live surface imports Leaflet;
`lib/basemap.ts` stays only for the unrouted pre-redesign components under
`src/components/frontend`, which nothing mounts. The app has always been
Google-only (`google_maps_flutter`; the Android SDK draws India's borders
by the device's region, which is not ours to set). Pinned: a test that
fails if any of the three surfaces imports Leaflet or the basemap again.

**"Please check the Book Now in mobile view."** Two of them, one above the
other, once a visitor had scrolled to the rail: the card's and the phone's
fixed bottom bar. The bar now steps aside while the rail's own button is
readable — an IntersectionObserver whose root margin excludes the bar's
own strip, so a button hiding behind the bar does not count — and returns
the moment it scrolls away.

Verified on the dev server at phone width (a dev-only Vite proxy, `/__api`,
now lets a page served from localhost reach the deployed backend, which
allows only the production origins): the 20th picked, the 20th greyed for
check-out with the tooltip, "Check out 21 Sept or after"; adults stop at 1;
the bottom bar gone while the rail's Book Now is on screen and back at the
top; the search map a panel, not OSM, with no key configured. Backend
**152/152**, web **51/51** + `tsc` clean + build green, app **511/511** with
analyze 0 errors. **Build 102** built with `tool/build_release.ps1` and read
back by the verifier with the endpoint named.

---

### 8a38. Closed 2026-09-18 — six from the client's screenshots and a video; the 300-case run to batch 2; build 101

**"Host confirmed the booking but the renter side still shows Request
sent — refresh this in real time."** True on both surfaces, for the same
reason: the confirmation page took `requiresApproval` once, from the booking
response, and never looked again. The website now listens for the host's
answer on the live channel (`notification:new`, `type booking_confirmed`,
matched on the booking id) **and** polls booking history every 30 seconds —
the poll is not belt-and-braces, it is the primary path for the case that
matters, because Chrome throttles a background tab hard enough that a socket
event can arrive late or never, and this is exactly the tab a guest leaves
open while they wait. The app does the same with a foreground push and the
same poll. Both stop the moment the answer is known; a decline is said as a
decline.

**"Do not give the directions till the host confirms."** Get directions
(web) and the "Getting there" map (app) now appear the moment the decision
lands; until then both say why they are not there. A request the host may
still turn down is not a stay to set off for.

**"Booking id is missing."** On the Next Booking card, beside the dates. The
app's confirmed screen already had it.

**"If the property is already booked, do not show Book again."** A guest
holding a live stay on a listing sees *You're booked here* with the dates and
reference and a way through to the booking. Book Now returns only once they
pick other dates — a second stay somewhere they liked is a real thing to want.
The fetch is token-guarded exactly as the personal coupons are, because
`useBookings` has no login guard and an unauthenticated
`/user/booking-history` is a 401 the interceptor answers by ending the session.

**The video behind that item showed two more things.** Tapping View Property
opened *No photos yet · ₹0 / night* for a second before the real listing
arrived: `prop` is null until the fetch resolves, every field read null as
its empty value, and the shell rendered as a finished page about a place with
no pictures and no price. A skeleton now holds the frame — the client's own
case **BK-010**. And the card in the video showed **a living room that was
not the listing**: both booking endpoints resolved a cover from
`tbl_attachments` alone, the pre-wizard table, so a wizard-made listing came
back with nothing and the website put a niche stock image in its place. Both
endpoints now go through `methods.coverImagesFor` (wizard media first, the
way the listing page does); the website's fallback is the honest `NO_PHOTO`
mark the search cards use. A duplicate of that helper had been written on the
way and is removed.

**"It should check PIN validation — I can enter an invalid PIN and move to
the next page."** The server checked nothing; the website checked the shape.
`utils/pinZones.js` (mirrored in `lib/pinZones.ts`, with a test that the two
tables agree) maps India Post's circle prefixes to states — two digits, three
where a territory sits inside a larger circle — and refuses a PIN that is
certainly in the wrong state, by name: *PIN 110001 is in Delhi, not Goa*.
Ranges two states genuinely share (UP/Uttarakhand, Bihar/Jharkhand,
AP/Telangana) allow both rather than guess; the Army Postal Service and
unissued prefixes are refused. Applied in step 1 **before** the location row
is written. The PIN the client typed, 403706 in Goa, is a real Goa PIN and
still saves. Client case **HL-016**.

**"This option is twice."** The cleaning fee *Applies* menu offered four
entries for two behaviours: the website added "Per stay (default)" above the
server's list, and the server's own "One Time" and "Per Stay" are the same
arithmetic (the engine multiplies only `per_night`). The list is now
*Per stay / Per night*; a listing that chose `one_time` re-saves as
`per_stay` rather than being refused for a word no longer on the menu.

**The 300-case run.** Batches 1 and 2 are complete — 60 of 300, in
`report-2026-09-17/TEST_RUN_300/RESULTS.md` with the actual value seen for
every case and the remaining 240 arranged into eight batches by what unblocks
each. Five defects so far, four fixed and pinned: the two Critical leaks
(§8a37), a festival rate silently dropped, an accepted counter-back missing
from the ledger, and the 28–31 night pricing cliff, which is with the client
because it moves money. Three cases are the document being behind the product
(the cleaning fee, the round-one counter, countering below the floor).
**Batches 3–10 need a guest and a host account we own**: both surfaces are
signed in as the client's test guest (101), which §9 keeps live tests off.

Verified: backend **151/151**, web **50/50** + `tsc` clean + build green, app
**503/503** with analyze 0 errors. **Build 101** built with
`tool/build_release.ps1` and read back by the verifier with the endpoint
named.

---

### 8a37. Closed 2026-09-16 (night) — the chatbot is told which journey the visitor belongs in; build 99

**BotPenguin, via the client:** *"The Aajoo website passes the user's login
token, authentication status, name, email and phone to the chatbot, but it does
not pass whether that account is Guest only, Host only or both. Because
BotPenguin does not receive this, it currently has to ask every logged-in user
to choose a role."*

`/bp/handoff` now answers with **`support_role`** — `guest`, `host` or `both` —
and both clients pass it on as **`ctx-support_role`**. It rides on the two rows
`mintHandoff` already reads, so it costs no extra query.

**The role lives in TWO tables and either may carry it.** Sign-in resolves an
account by `tbl_user_creds.cred_user_isHost`; admin-side creation once wrote
only `tbl_users.user_isHost`, which is why
`scripts/backfillCredentialRoles.js` exists — an admin-created host whose
credential still said guest. So the resolver ORs the pair, the same expression
`switchMode.controller.js` and `utils/userContact.js` already use. Reading
either one alone routes a real host into the guest flow.

Two deliberate choices, both pinned by tests. The role is built **inside** the
try that assembles the profile, so a failed lookup sends **no role** and the
bot goes on asking — absent is the one safe way to not know, where a guess
starts somebody in the wrong conversation. And a `0/0` row answers **guest**,
not unknown: `isUser` was not always written, so that shape is real, and guest
is the journey with nothing privileged behind it.

**Routing only**, said in the code where someone would be tempted to reuse it.
`/switch-mode` still refuses a guest asking for a host token whatever this says.

**Checked against live data before choosing the mapping:** 18 guest-only, 14
host-only, 1 both, with the two tables agreeing on every row — so all three
shapes are real and **14 of 33 accounts stop being asked**. Also checked that
**no host has ever booked a stay as a guest**, which is what makes routing a
host-only account straight to Host safe in practice, even though switchMode
lets any host drop back to guest mode ("every host is also a guest"). Worth
BotPenguin keeping a way across in the Host journey regardless.

**The third item was a real bug, and it predates the role.** The client asked
that the chat "reload with the latest token and role when the user logs in,
logs out or changes accounts". On the website the widget mounts **once** and
lives for the rest of the SPA session, so it kept whoever was signed in when
the first chat-visible page opened: sign out, sign in as someone else, and the
bot still held the FIRST account's handoff. It was already greeting people by
the previous name; a role would have made it route them wrongly too. The widget
now records which token it was mounted for and `syncBotpenguinIdentity` purges
and remounts when that no longer matches — wired into
`setBotpenguinChatVisible`, which App.tsx already calls on every route change,
so a sign-in, a sign-out and an account switch all reach it without their own
hooks. Same account is a no-op, or the vendor script would reload constantly.

**Sign-out is the case worth naming:** a widget left mounted with the previous
token is the previous person's chat session, still open for whoever signs in
next on a shared browser.

BotPenguin refuses a second init ("The bot element already exist") and renders
nothing, which is worse than a stale identity — so the remount is confirmed
with `waitForWidget` and falls back to the same one-reload-per-session path the
Reconnect control uses, surfacing Reconnect if even that fails. The reconnect
warning the client asked for **already existed** and was left alone.

**The app needed none of that:** it builds the chat URL fresh from secure
storage every time the chat opens, so account changes are already carried. What
it did need was a guard against deriving the role locally — using the app's own
`isHost` would route on whichever MODE the user last switched into rather than
on what the account is. A test forbids it.

Verified: backend **146/146**, web **49/49** + `tsc` clean + build green, app
**497/497** with analyze 0 errors. **Build 99**
(`sha256 624a5780…61e254bc`, versionCode 99).

**Still with the client/BotPenguin:** once the backend and website are
deployed, BotPenguin update the English and Hindi routing and retest from a
logged-in session — the standalone BotPenguin test page cannot exercise this,
as it has no Aajoo login. One caution passed on: a Guest-only test account must
be a genuine `0/1` row; an admin-created account may carry the
credential/account mismatch the backfill script exists to repair.

---


### 8a36. Closed 2026-09-16 (night) — the two test negotiations cleared, and ~11,300 lines of retired UI deleted

**"Clean up those two test negotiations on 29302."** Done. Both were mine,
written by a probe on 15 September while proving the same-day and deal-pricing
fixes: `2 coupon(s), 4 offer row(s), 2 log row(s)`, both coupons unspent
(`cpn_used_count = 0`), so nothing downstream referred to them. Property 29302
now reads `coupons: 0 / offers: 0 / logs: 0`. The two scratch scripts that did
it are deleted rather than left in `scripts/`. A first pass found nothing
because it filtered on `DATE(created_at) = CURDATE()` — the rows are stored in
UTC and the IST date had already rolled over — so the delete was retargeted by
explicit row id.

**"Clean codebase for all the older UI; check if it is connected anywhere in
the web or app, and if it is, remove it from there and connect the corrected
new UI page."** The routes were retired last night, which stopped anyone
*reaching* the old pages but left them in the tree looking like live code.
Anyone searching for "checkout" or "Footer" found two of each and no way to
tell which one ships. Both trees are now swept, and nothing was deleted on
appearance — every file was proven unreferenced first.

**Web — 51 files, 9,141 lines gone.** The pre-redesign guest pages (help
centre, the dashboard and its four tabs, the old checkout, confirmation and
cancel-result, the profile and review pages); the SECOND auth flow with its
login, signup, OTP, forgot- and reset-password forms; the old shell
(CommonLayout, Header, Footer, loginLayout) and the form primitives only that
flow used; the host AddProperty form the 5-step wizard replaced; the
pre-redesign admin Bookings screen and the PrivacyPolicyPage that LegalPage
replaced; a dead redux slice and a stray second `adminSession`.

Two **barrels** were what kept most of it looking alive. `src/pages/index.ts`
and `src/components/index.ts` re-export by name, so reachability analysis
counts every target as used whether or not anything consumes it — which is why
an earlier sweep reported these files as live. Both are pruned and both now
have zero unused exports. The sweep is down from **39 unreachable files to 3**,
and all three of those are ambient `.d.ts` declarations, which are never
imported by design.

Two near-misses worth recording. `auth/PersonalInfo.tsx` and
`auth/AddressInfo.tsx` looked live because the admin AddUserModal imports
`PersonalInfo` and `AddressInfo` — from its OWN folder, same names, different
files. And `components/layout/Footer.tsx` looked live because the redesign has
a `Footer` too. Both were cleared by matching the full import path rather than
the basename.

**One thing came across rather than going with it.** The old footer's
`socialLinks.ts` held Aajoo's real profile URLs — the same three the app links
to, with handles corroborated against the live accounts. The **redesigned**
footer was still pointing at the bare network home pages, so every social icon
on every page of the live site opened a signed-out Instagram rather than Aajoo.
Those URLs now sit in the redesign footer and in the Contact page's CMS
defaults, so the two web surfaces and the app finally name the same three
profiles. YouTube and LinkedIn are dropped rather than guessed at again:
nothing anywhere corroborates either, and an icon that opens a dead page is the
bug being fixed.

**App — 1,401 lines gone.** Opening any listing as a guest ran
`Get.put(NewPropertyController())`: 313 lines of the HOST's add-property form
state, every field of the listing wizard and its submit calls, to read three
members. All the page wanted was the reviews, and the renter side already had
`PropertyReviewController` with exactly those three members and identical
bodies. The host controller's file was even named `..._legacy.dart` — the
wizard replaced the form it belonged to long ago, and it survived only because
that one import kept it reachable, so no orphan sweep could see it was dead.
Also deleted: `update_property_page.dart` (the 684-line pre-wizard edit form)
and `ongoing_widget.dart`, which StayBanner replaced — the old widget only
showed a stay while the guest was PHYSICALLY IN the property, so a booking for
next week put nothing on the home screen. `state_city_dropdowns.dart` is live
and stayed, but moved out of a `screens_host/add_property/` folder that no
longer had an add-property screen in it.

**Four imports that looked like a dark feature, and were not.** The home screen
imports `ResumeBookingBanner`, `CounterOfferBanner`, `NegotiatedDealBanner` and
`OngoingBookingWidget` and renders none of them. Each was checked before being
touched, because three of them answer client reports — the KYC detour that
loses a booking, and a host's counter nobody sees. All three are live through
`HomeBannerRail`, which consolidated four stacked cards into one swipeable
rail; only the imports were leftovers. No feature was dark. The fourth was the
retired widget above.

Verified: web `tsc -b` clean, **48/48** rule tests, build green; app
`flutter analyze` **0 errors**, **493/493** tests — six new tests pin the
deletions, the controller swap, the moved widget and the footer's links, so
none of this can quietly come back.

---

### 8a35. Closed 2026-09-16 (evening) — seven from the videos, and a dead function behind two of them

**"Auto counter offer stopped, it is not giving me auto counter offer."**
True, and it had been since **12 September**. `claimNextRound`'s own
return statement still named `used` and `cap` — the three-offer allowance
removed that day — so **every call threw `ReferenceError: used is not
defined`**, the catch fell back to the unguarded `nextRound()`, and two
things went quiet together: the round came from the property's WHOLE
history instead of the current negotiation, so a returning guest's first
offer arrived as round 4 and the engine only auto-counters on **round
1** — the instant counter worked once per guest per property, ever — and
the "one live price at a time" guards never ran at all, so an offer could
be stacked on a pending one. Found by putting a real offer through the
service against the live tiers and reading the log line nobody greps.
Fixed (BE `7d2d89a`); the fallback now logs at ERROR and says what is off
while it is off. Pinned by `theRoundClaimActuallyRuns.test.js`, which
calls the function against a stubbed database — two of its six checks
fail on the previous commit.

**"Which negotiation page it is taking me from notifications??"** The
pre-rebuild chat, `PriceNegotiationPage` — thirty-second countdown,
quick-price chips, its own offer counter, a second client for one engine.
The rebuild replaced it on 2026-09-12 **for the listing only**: the push
router, the in-app notification list and the host's inbox all still
opened it, so a notification was the way back into a screen nothing else
used. `lib/ui/screens_common/price_negotiation` is **deleted** — page,
wrapper, controller, parts — and `/negotiation` now IS My Negotiations for
whichever side is signed in (app `1c32ad0`).

**"Check negotiate button hidden behind navigation bar."** The booking
sheet's container padded a fixed 16 at the bottom, so its last control sat
under the system bar. `viewPadding.bottom` now — the third time this trap
has been fixed on this app, and the first on this screen.

**"After negotiating, again showing button to negotiate is wrong."** The
sheet was right (Send an Offer goes disabled: "Already agreed for these
dates"); the sticky strip — what you see coming back from My
Negotiations — still said **Negotiate & Reserve** over a settled price. It
reads **"Book at the agreed price"** once a deal covers the dates on
screen.

**"No use of this drop down per night and monthly."** Correct: it decided
nothing. It once multiplied the total by thirty (charging for nights
nobody booked); after that was removed it was a label the server never
received, because `bookingType` is not in `createBooking`'s schema and
validation runs with `stripUnknown`. Removed, with its field and its dead
payload key.

**"If negotiations are already done for these dates but I go outside and
try to book again, it books at the original rate."** `hasDeal` read
`widget.dealCode`, which is only set when the listing is opened THROUGH
the deal (the home banner, My Negotiations). From search, or on a second
visit, the page knew nothing and sent no coupon. It now asks
`DealsController` for its own deal, applies it, and adopts the agreed
nights when the guest has not chosen others. Pinned by
`a_deal_applies_wherever_the_listing_is_opened_test.dart`. The website had
this closed the same morning (§8a33).

**"If two renters negotiated for the same property for the same dates and
agree, it becomes unavailable for both."** **It does not** — checked
against the live system rather than reasoned about: two guests were given
an agreed price on the same nights on 29302, and each sees only their own
lock and their own code, a third guest sees neither, `bookedRanges` stays
empty and no date is blocked. What IS true, and what nothing said, is that
a deal is a **price, not a hold** — the first to book takes the nights.
Both clients now say so on the accepted-deal line (web `022ebaf`).
Holding the nights for the length of a deal is a product decision, not a
bug: **§3.17**.

### 8a34. Closed 2026-09-16 (afternoon) — five from the client, one of them a data repair

**"Have you checked? I still cannot select today's date on the app."**
Correct, and it was never a code fault: **§1.15 had not been run.** The
five listings the web wizard had silently switched same-day OFF on still
carried the 0, and an offer is only taken on a stay that starts today, so
today was unbookable and unnegotiable on every one of them. The repair is
**applied now** — `/booking/property-availability` answers `earliest:
16-09-2026, sameDayAllowed: true` on 29292, 29294, 29295, 29306 and
29310, and the app's check-in picker opens on today
(`report-2026-09-15/app/build96-today-is-selectable.png`). The wizard has
been unable to write that 0 since 2026-09-15, so it cannot come back.

**"Clicking Help Centre opens the old website."** The signup email's
footer was hard-coded to `/help-center`, which is the **pre-redesign**
page — still routed, so it answers 200 and nobody notices. It points at
**/faq** now, which is where the live footer's Help Center already goes,
and `/help-center` redirects there so every link already sent lands on
the right page (verified live: `/help-center` → `/faq`, "How can we
help?"). The year was hard-coded too ("© 2025"); it is the current year
now, and every email link comes off one `SITE_URL`.

**"I logged in with a new account and did not do KYC — without KYC
neither negotiation nor booking should happen."** Booking has required a
current verification since 2026-09-01; **negotiating required nothing**,
so an unverified guest could open a thread, put a host through a round of
offers, agree a price, and be refused at the end. `/user/negotiations/offer`
and `/respond` now use the same `assertVerified` verdict (BE `c13f86e`);
**declining is still allowed** — walking away needs no identity, and
refusing it would strand the thread. Both clients say so first rather
than letting the guest find out: a disabled **Send an Offer** with the
reason and a way to the check, the treatment the decline lock already
gets, with its own sentence per state (pending is an unfinished check,
not a review). Pinned by `kycGatesNegotiationToo.test.mjs` and
`kyc_gates_negotiation_too_test.dart`. **Not photographed:** showing the
disabled state needs an unverified account, and creating accounts is not
something I do — the client's new account is exactly the case.

**"I negotiated but did not book; back on the home page the price should
show the deal, as it does inside."** Every card priced at the list rate:
a deal is per-guest and the card never asked for one. The rails, the
search grid (web `1ba83bb`) and the app's `CuratedCard` (build 96) now
wear it the way they wear a host's running discount — struck price, deal
price, "% off" pill — **percentage deals only**, rounded UP so a card
never advertises below the server's quote, and a host's running offer
still wins. Because a deal is **date-locked**, the card's link carries
the agreed nights: a smaller number over undiscounted dates is the exact
trap the listing page had. Pinned by `myDealShowsOutsideTheListing.test.mjs`
and `a_deal_shows_outside_the_listing_test.dart`. **Not photographed
live:** the only guest account this machine can drive is the client's own
test guest (101), which §9 now forbids using, and its deal expired at
midnight — the client has live deals on 29310 on accounts 164/204/205 and
will see it on their own screen.

**"The offer went on but the price did not change, and with negotiation
over it should say Book Now."** The first half was the empty-dates dead
end closed this morning (§8a33): with the deal's dates now filled in, the
price on screen IS the deal price. The second half already worked once
the dates match — `negotiationLockHere` turns Send an Offer into a
disabled "Already agreed for these dates" with "the agreed price applies
at checkout, go ahead and book". It read as live only because, with no
dates, the lock did not apply. Left as a disabled control rather than
removed: a button that vanishes reads as a broken feature.

144 backend files, 484 app tests, 46 web files.

### 8a33. Closed 2026-09-16 — three screenshots, and the tester sheet as v3

**"Equal sizes of cards, and a little smaller, 6–7 show, across platform."**
The Trending rail showed four cards of four heights: one address wrapped
to two lines, one card had no cancellation badge, and the items were
268px with a 20px gap. Now 196px with 14px (six in the 1320 container,
the seventh peeking — the density Airbnb's desktop rail runs at), the
address and the title clamp to one line with the whole text as a hover
tooltip, the badge keeps a 20px slot on every card, and the track
stretches its items; on a phone the web rail shows two cards, like the
app, whose home rail was already 200dp cards of one fixed height. Web
`2880a35`, pinned by `railCardsAreEqual.test.mjs`; measured live on
/explore: every card 196 × 261 (`report-2026-09-15/img/s33-trending-rail.png`
— two cards only, because that profile is in LUXE and the catalogue has
two LUXE listings; there is no place with seven test listings to
photograph six across).

**"No booking currently on, but it shows accepted and offers a deal."**
The deal was real and ours: `DEAL29302101C175`, 7.9% on QA Sunrise Villa
for 15→22 Sep, struck at 06:38 on the 15th by the morning's live test of
the weekly-negotiation change — on the client's own test guest account
**"Aajoo Renter" (101)**, which is also the account the puppeteer rig and
the emulator were signed in as. It expired at midnight. What WAS wrong:
with no dates picked, the card said "pick the agreed nights to use it"
and, under two empty date boxes it had locked, "your deal is agreed for
these dates, so they cannot be changed" — the lock was keyed on the deal
EXISTING, not on it APPLYING. A dated deal now fills empty date boxes
with its own dates, the lock holds only while the deal applies to the
dates on screen, and the mismatch banner offers "Use the agreed nights"
with one click (web `2880a35`, pinned in `aDealPricesOnlyItsOwnNights`).
**Rule from here: live tests use "Renter test web" (179), never the
client's test guest (101)** — see §9.

**"Check-in 16, the 17th is blocked, check-out 18 — the host side shows
no booking or block on the 17th."** There is none: no booking and no
block on 29302 in the database, and `/booking/property-availability`
answers `bookedRanges: []`. The 17th greyed as a CHECK-OUT because the
listing's own step-5 rule is a **minimum stay of 2 nights** — after a
16th check-in the earliest check-out is the 18th — which the website's
calendar says in its header ("Minimum 2 nights — check out 18 Sept or
after") and its footnote. The host's calendar shows no block because it
is not one. **Parity gap found on the way:** the Android app read neither
`minNights` nor `maxNights`, so it let a guest pick 16→17 and be refused
at booking. **Build 95** (app `6cd9a82`) applies both in the check-out
picker (title "MINIMUM STAY 2 NIGHTS", the 17th greyed, opens on the
18th) and says the rule under the date rows in the website's words;
driven on the emulator on 29302 (`report-2026-09-15/app/build95-*.png`);
pinned by `the_minimum_stay_is_a_rule_not_a_block_test.dart`.

**"Please provide an update on the sheet points Ashish shared."** The
newest sheet on this machine is "Aajoo Homes (2).xlsx" of 2 September
(19 web rows, 7 app rows); v2 answered the web tab that day and the app
tab had never been answered in a sheet. **`Aajoo - Tester Bug Sheet -
status 2026-09-15 (v3).xlsx`** at the repo root carries every row with a
15/16 Sep status: the 19 web rows still hold (with what has changed
around each since); the 7 app rows were all fixed between 2 and 7
September (builds 13+: the keypad reserved three times over, the DOB
wheel submitting age 0 — and a second DOB failure closed on the 15th —
two controls under the navigation bar, the OTP sheet, the profile save
that never ran, the ten house-rule toggles sharing one empty id), with
row 4 photographed on build 94 and rows 1/3/5/6 left to the tester's own
account to walk end to end; and a third tab for the three items above.
If Ashish has sent a newer sheet than 2 September, it is not on this
machine — ask for it.

### 8a32. Closed 2026-09-15 (evening) — the iOS project, brought to parity with Android

**The ask:** "start with the codebase and get it ready for iOS; it should
work exactly like Android." **The finding:** `ios/` was the day-one
Flutter template — the phone would have shown **"Rent Home"** with
**Flutter's blue logo** and a blank launch screen; the deployment floor
(iOS 12) was below what four plugins need; there was no usage string for
location or photos (iOS refuses to prompt without one), no Maps key
(blank tiles), no Google Sign-In callback (the Google sheet would never
return), no push entitlement or background mode, no `LSApplicationQueries-
Schemes` (tap-to-dial, WhatsApp, directions and Razorpay's UPI list all
dead, the iOS twin of the Android `<queries>` trap), every
`permission_handler` permission compiled out (requests answer "denied"
without asking), no privacy manifest, and no build script, verifier or
CI. None of the Dart needed changing except push. Full picture in
`aajoo_app_2026/IOS_READINESS.md`.

**Done (app `ae89661`, BE `1e54441`).** Info.plist (name, strings,
schemes, background mode, export-compliance flag, and two **placeholders**
only the client's accounts can fill — the iOS Maps key and the Google
client — which `tool/verify_release_ipa.py` refuses); AppDelegate (Maps
key → `GMSServices`, notification delegate); Podfile (`platform 14.0`,
the permission flags); Xcode project (target 14.0, `aps-environment`
entitlement, `PrivacyInfo.xcprivacy`); the 19 icons and 3 launch images
generated from the Android sources; `NotificationService` registers with
APNs and waits for its token before asking FCM (the Simulator has no APNs
— push is simply off there, and the `token!` that used to throw inside the
permission flow no longer does), and presents foreground pushes; the
server's every push carries an `apns` payload (sound, content-available,
priority 10 — pinned by `aPushReachesAnIphone`). `tool/build_ios.sh` and
`tool/verify_release_ipa.py` are the macOS twins of the Android script
and verifier. **`.github/workflows/ios-build.yml`** compiles the app
unsigned on a `macos-15` runner on every push that touches it (free —
the repo is public; no Apple account needed) and has a hand-run job that
signs and uploads to TestFlight once the secrets in `IOS_READINESS.md`
§3 exist, refusing with the names of any that are missing. **Run
34996287126 is green:** 20 pods, Xcode build 240 s, 472 tests on the Mac,
verifier OK, `Runner-1.0.0+94-unsigned.app.zip` (40.7 MB) as the artifact.
(Run 34994667340 before it built the same app and failed in the verifier,
which had read three `http://` identifiers inside the Google/Firebase/
Razorpay SDKs as endpoints — the verifier now scans the four files that
define a build and reports SDK constants as notes, `97f0dbc`.)

**Not done, and why:** nothing can be *run* on an iPhone from here — no
Mac, no Apple account. §1.16 is the client's list; §3.15 (Sign in with
Apple, needed for App Review) and §3.16 (the on-device drive) follow it.
One build number stays one artifact across platforms: iOS `1.0.0+N` is
Android `1.0.0+N` from the same commit.

### 8a31. Closed 2026-09-15 (evening) — the cleaning fee is stated, not charged

**The decision (§1.14).** Asked on the 14th whether the cleaning fee is
charged or only stated, the client answered on the 15th: *"it will only be
stated in Things to know and all; if the renter requested it, it can be
availed at that price and payments will be taken directly by the host."*
That reverses **C18** of the 10 September spec, under which the fee had
been quoted, clamped, taxed and paid to the host for five days
(2026-09-10 to 09-15). The frequency field "goes with it": kept, optional,
as a courtesy to the guest ("₹500 per night") rather than a billing rule.

**What changed — one switch, four places.**

- **Server** (BE `2034ca9`). `/pricing/quote` and the shared pricer still
  carry `cleaningFee` and `cleaningFeeType` so every screen can say what
  the host charges, and now say `cleaningFeeCharged: false`; the figure
  has left `total`, `taxes` and `grandTotal`. Booking create expects
  room + party + pets. A client built while the fee WAS charged — app
  builds 88–93, the website before this deploy — sends exactly that plus
  the cleaning fee; that figure is recognised and **charged at the price
  without it**, so a guest on an old build pays less than its screen
  showed, never more (`sentWithCleaning` replaces `sentWithoutCleaning`,
  which would now have accepted a price ₹500 *under* the truth). The
  wizard no longer refuses a fee without a frequency.
- **Website** (web `d96b312`). `summarize()` keeps the fee out of
  `chargeable`; the property card, the review and the payment page drop
  the "Cleaning fee" line and say, under the total and beside the deposit
  note, **"The host charges ₹1,000 for cleaning if you ask for it —
  arranged and paid directly with them, not included in this total."**
  One sentence, built once (`lib/cleaningFee.ts`), so three pages cannot
  drift into three phrasings. Things to know → House rules carries
  **"Cleaning available at ₹1,000 per stay, paid to the host"** from the
  listing, before any dates are picked — the client's words for where it
  lives. The wizard's frequency select reads "Applies · Per stay
  (default)" and its hint quotes what the guest will read.
- **App** (build **94**, app `94bd68c`). `priceStay()` keeps the fee out
  of the price it sends; the booking sheet drops the line and states the
  fee under the total in the website's sentence, word for word
  (`utils/cleaning_fee.dart`); Things to know carries the same line as the
  web; the wizard's help says the fee is stated, not added to a booking.

**Verified live.** `/pricing/quote` for 29310 (₹12,000 a night, ₹1,000
cleaning), two nights: `subtotal 24000 · cleaningFee 1000 ·
cleaningFeeCharged false · total 24000 · taxes 4320 · grandTotal 28320` —
not the 29,500 of the day before. 29302 (₹500 per stay): 6,660 + 333 =
**6,993**, not 7,518. Website, 29310 for 17–19 Sep as the signed-in
renter: card ₹24,000 − ₹2,400 advance discount, GST ₹3,888, **Total
₹25,488**, the deposit note, then the cleaning sentence; Things to know
carries the line; Book Now → review says the same ₹25,488 with the same
sentence under it (`report-2026-09-15/img/s31-*.png`). App, build 94 on
the emulator, 29309 opened from the accepted-deal banner: Base ₹45,000,
deal −₹1,953, GST 5% ₹2,152.35, **Total ₹45,199.35** — build 93's
₹45,724.35 less the ₹500 and its 5% — no cleaning line, the sentence under
the total (`report-2026-09-15/app/build94-29309-cleaning-stated.png`).

**Pinned.** BE `theCleaningFeeIsStatedNotCharged.test.js` (the 28,320,
the payload, the clamp's shape, the old-client escape, no payout code
touches cleaning; six of its eight fail on the previous commit),
`seasonalRatesAndFees` C18 pins inverted, `aCouponIsOnTheRoom` postscript
— **143/143 files**. Web `theCleaningFeeIsStatedNotCharged.test.mjs`
(was `cleaningFeeReachesCheckout`, inverted: 6,993; the sentence; every
page states and none charges), `aCouponIsOnTheRoom` (26,196),
`answeredFieldsAreNotRefused` — **43/43**, `tsc -b` and the build clean.
App `the_cleaning_fee_is_stated_not_charged_test.dart`,
`booking_pricing_test` (29302 → 6,993; the emulator case re-derived
without the fee: 48,243.40 with the Sunday still at 18%),
`a_coupon_is_on_the_room_test` (26,196) — **472 pass**, analyzer clean.

**Not touched.** Bookings taken between 10 and 15 September carry the fee
in `book_price`; all are test records. A modification of one of them
would now be priced without the fee and the difference refunded — the
correct outcome, noted so it does not read as a bug when it happens.

### 8a30. Closed 2026-09-15 (afternoon) — four more from the client, one of them the reason negotiation died

**"On app, renter cannot select today… so cannot negotiate at all. It is
major."** True, and the cause was on the website. Price offers are only
taken on a stay that STARTS TODAY (the pricing architecture's real-time
rule), so a listing with same-day bookings off cannot be negotiated on.
The web wizard loaded `pbr_same_day_booking` with `=== 1`, so a listing
whose host had never been asked (NULL — which the server reads as
allowed) loaded as **"No"**, and the next Save on ANY step wrote that No
to the row. The client edited 29310 on the web on 14 September for the
rooms work; from the 15th the app said "This host does not take same-day
bookings" and the picker said "Out of range" for today. **Five** test
listings carry a 0 with negotiation on; none of their hosts chose it.
Fixed at the source (web loads `!== 0`, a new listing defaults to Yes,
both wizards warn a host who turns same-day off with negotiation on), and
`scripts/repairSameDay_2026-09-15.js` puts the five back — **for the
client to run, §1.15** (production writes are refused from here). Pinned
in `crossFieldWarnings`.

**"Tester chose the DOB from 2001 and it failed: you need to be 18."** The
app sends DD/MM/YYYY, the server's age check did `new Date(value)`, and
JavaScript reads "25/06/2001" as month 25 — Invalid Date — so every app
signup with a birthday after the 12th of the month was refused, and one
before the 12th had its day and month swapped. The website never hit it
(it sends YYYY-MM-DD). `parseDob()` reads the three spellings the clients
use explicitly and refuses 31 February instead of rolling it into March.
Pinned in `aBirthdayIsReadTheWayItWasWritten` (BE `10d755c`).

**"Not responsive in Moto"** — a photograph of Property details with
"Local Experience" running one letter per line. The value Text was
unconstrained, so a long one took the row and the Expanded label was
left a few pixels wide — the narrow-screen word-break trap, again. Both
sides bounded (2:3), value wraps; verified on the emulator at a 720-px
width (photograph in `report-2026-09-15/app/`). A scan for the same shape
elsewhere found five rows, all with short values.

**"Explain the weekly/monthly negotiation flow in a doc."**
`AAJOO_NEGOTIATION_WEEKLY_MONTHLY_2026-09-15.pdf`, 17 pages: the rule, the
guest's and the host's flow with the two live deals, a month worked on two
real listings, and what is stored and charged underneath.

Build **93** carried the app side (BE `10d755c` `7f82979`, web `849ccb9`,
app `07df7d6`); superseded the same evening by **94** (§8a31), which has
everything here. 463 app tests; 142 backend files at the time.

### 8a29. Closed 2026-09-15 — a week is negotiated as a total

Client, with a screenshot of Send an Offer on a seven-night stay reading
"Your offer per night (₹) · Listed at ₹12,000 / night": *"while
negotiating for weekly or monthly booking, renter should be asked total
price instead of per night?? renter will not be able to calculate easily
per night … for less than 7 days, per night negotiations is fine. But for
weekly and monthly it should be on the total."*

**They are right, and the engine half-agreed already.** A dated offer has
been judged against the composite stay totals divided back to a per-night
figure since W2 (`tiersForDates`), so on a week the "per night" was a
derived number all along — nobody sets a weekly rate as ₹10,714.29 a
night, which is what that dialog was in fact asking a guest to argue with.

#### The rule

| stay | the conversation | example |
|---|---|---|
| under 7 nights | per night, as before | "₹3,000/night" |
| 7 nights or more | the stay total | "₹75,000 for 7 nights — the host's weekly rate (≈ ₹10,714 / night)" |

**The unit of record did not change.** `offer_price`, `nl_offer_price`,
the engine's min/ideal/max, the coupon percentage and every socket event
still carry a per-night figure. A guest who types ₹70,000 for a week
sends 10,000/night; a host who counters ₹1,00,000 sends 14,285.71 (the
column is DECIMAL(10,2)); every screen multiplies back and rounds, which
recovers the typed total for any stay under a hundred nights. The
alternative — changing the stored unit — would have touched the ledger,
the engine and the coupon arithmetic for a sentence's worth of
difference.

#### Where it lives

One helper per platform, the same threshold as the weekly rate
(`WEEKLY_NIGHTS = 7`): BE `utils/negotiationUnit.js` (`priceLine`,
`perNightOf`, `stayTotal`, `nightsOf`), web `lib/negotiationUnit.ts`, app
`utils/negotiation_unit.dart`. Every sentence the server writes — accept,
counter, the refusal above list, expiry, the parting coupon, the host's
email — goes through it, and every negotiation event now carries
`nights` so the clients' live toasts can pick the unit. Web: the offer
dialog (label, placeholder, "Listed at", the ceiling compared total to
total), the counter-back, the outcome lines, `CounterOfferDialog`, both
Negotiations pages and the transcript. App: `send_offer_sheet` (now
handed the stay's list total, `originalSubtotal`), the guest and host
negotiation screens, the host home card.

**Verified live 2026-09-15 06:07** on 29310, 20–27 Sept: "Your offer for
the 7 nights (₹)", placeholder 75000, "Listed at ₹75,000 for 7 nights —
the host's weekly rate (≈ ₹10,714 / night)". A two-night stay reads as it
did. **And walked end to end at 06:38** on 29302 from today: ₹17,100 for
7 nights offered → countered ₹17,500 for 7 nights → accepted → coupon
`DEAL29302101C175` at 7.9% → card, review and payment all ₹19,000 −
₹1,501 + ₹500 + ₹899.95 = **₹18,898.95**. Nothing paid. Two things found
on the walk and fixed (web `b8a241c`): the tax line printed "₹900" over a
.95 total, and the unselected "Pay at property" card was white in LUXE.
Photographs in `report-2026-09-15/img/`.

#### The emulator, builds 90 → 92 (08:00)

Build 90 carried the app side of §8a28–§8a29 and was driven on the
emulator, signed in as the test guest, against the live backend. It
found **three defects no test had**, build 91 fixed them and found two
more, and build 92 is what the tester gets:

- **GST banded on the base tariff.** The booking sheet on the Gurugram
  cottage (29309) for a week said "GST (5%) ₹2,275 · ₹47,775"; the server
  bands each night on its own share and charges ₹3,279.43 · ₹48,779.43 —
  which is the Razorpay order. §8a27's website fault, in the app. The
  quote now carries the server's night weights, `priceStay` splits across
  them, rounds once and names the bands; the pricer's ₹7,500 boundary was
  still `>` and is `>=`. Build 91: "GST · 6 nights at 5% · 1 night at
  18% ₹3,279.43 · ₹48,779.43".
- **Totals to the rupee** (₹18,899 for ₹18,898.95) — `rupeesExact`, the
  app's twin of the web fix in §8a28.
- **A week counted as six nights.** The offer sheet took a raw `.inDays`
  between a check-in carrying the wall-clock time and a midnight
  check-out; 15 → 22 September at 07:43 was "6 nights", so it asked per
  night. Calendar days now.
- **An offer accepted on the listing was not applied to it.** "Accepted
  at ₹43,050 for 7 nights" → "Book at this price" → the same sheet at
  ₹48,779.43 with no coupon; `hasDeal` reads the widget, and the reload
  only re-drew the lock line. A booking from there went out at full
  price. The page now reopens the listing THROUGH the deal
  (`openPropertyById`), as the banner does. Build 92: Discount (4.34% —
  `DEAL29309101C177`) −₹1,953 · GST (5%) ₹2,177.35 · **₹45,724.35**, and
  `taxForNights` on the server gives the same to the paise — the coupon
  moved the Sunday's share under ₹7,500.
- **"book within 24 hours"** on the accepted sheet and the host's accept
  dialog, ten days after the window became the IST day. "Before midnight
  tonight."

Two real weekly deals were struck on test listings on the way
(`DEAL29302101C175` on the web, `DEAL29309101C177` on the app); neither
was booked. Photographs in `report-2026-09-15/app/`.

#### Pinned

BE `aWeekIsNegotiatedAsATotal.test.js` (threshold = `WEEKLY_NIGHTS`, the
round trip, the coupon never lands above the typed total, every sentence
uses the helper) — **141/141**; three older pins updated for the new
signatures. Web `aWeekIsNegotiatedAsATotal.test.mjs` — **43 files pass**.
App `a_week_is_negotiated_as_a_total_test.dart`, `booking_pricing_test`
(the emulator case, the boundary), `money_test` (`rupeesExact`) — **463
pass**. Commits BE `ced1558`, web `b8a8621`, app `af25544`, `e1a6363`,
`522a828`. **Build 92** carries all of it.

### 8a28. Closed 2026-09-15 — the same stay, priced three ways

Client, 2026-09-14, two screenshots of listing 29310 ("Glamping at the
ladakh test": ₹12,000 a night, ₹1,000 cleaning, 14–16 September, a
negotiated deal at ₹11,100 a night): *"it should be 27376 not 26196 …
Cleaning fee is excluded here but showing charged … during payment the
price is again different, pls check, price is most important part of app …
discount and gst showing different on different pages."* All of it true,
and all of it one fault wearing three faces.

#### The fault

**A coupon was a percentage of three different things.** The server mints
a negotiated deal as a percentage of the stay's ROOM subtotal
(`negotiationCoupon.js`) — chosen so the percentage reproduces the agreed
per-night price exactly. That only works if the percentage is then applied
to the same figure, and nobody applied it to the same figure:

| screen | 7.5% of… | total |
|---|---|---|
| property card (web) | the room — but it had dropped the cleaning fee, the pets and the tax weights while still PRINTING the cleaning line | **₹26,196** |
| review page (web) and `/booking/create` | room + party + pets + cleaning | **₹27,288** (B476130 stored discount 1,875, total 27,287.50) |
| property page (app) | room + party | — |
| what the host agreed to | the room, then the fees on top, GST on the sum | **₹27,376** |

An offer already discounted the room only ("a discount is on the room and
not on the cost of cleaning it" — `stayPricing.js`), and so did the
advance-booking discount. A coupon now does too, in every place that
takes one: `booking.controller` (`couponBase = quote.subtotal`, the
discount taken off the whole price), `/user/coupons/validate` (the base is
worked out **from the stay** — `couponApply.roomSubtotalFor` — and only
the client's figure when the listing has no rate card; the response says
what it used), web `summarize()`, and the app's `priceStay()` /
`_discountOnRoom` / `_applyCoupon`. The host is paid ₹23,200 for a room
they let for ₹23,200.

#### The faces

**"Cleaning fee is excluded here but showing charged"** — the web property
card under a deal. The local quote it fell back to had no cleaning fee, no
pet fee and no per-night tax weights, while the card read the cleaning
line straight off the server's quote — a ₹1,000 line over a total that did
not contain it. The card now builds a negotiated stay from the server's
own components less the deal, names the tax bands it actually charged
with, and is flagged as an estimate when there is no quote at all, deal or
no deal.

**"discount … showing different on different pages"** — 7.5% printed as
"−8%" on the review badge and "−7.5%" on the card. One formatter now
(`pct()`, the same digits the app's `_pct` prints): a deal stored to two
decimals so the guest is charged what the host agreed is not improved by
rounding it where they can see it.

**"during payment the price is again different"** — ₹27,287.50 was
"₹27,288" on the page and "₹27,287.50" on the Razorpay sheet. The totals on
the card, the review and the payment page — and the pay button — are now
printed to the paise, because that is the figure the gateway opens with.

**The app's chat negotiation page booked on its own.** Per-night price ×
GST, for TONIGHT, no coupon, posted as `price` — taxed twice (the server
treats `price` as pre-tax), no cleaning or party charge, not the agreed
dates, and refused by the booking clamp anyway. Its three booking buttons
now open the listing with the deal's coupon, the way the Negotiations
screen and the home banner already did, so a deal is priced in one place.
The bottom sheet and success dialog that only served that path are gone.

**LUXE: "pls correct this luxe UI, it is not readable."** `.modal` was
`background:#fff` with `--ink` (near-white) text on it — the Send an Offer
dialog at 1.14:1. Same fault and same fix as the chat bubble:
`--surface-pop`. Classic resolves to white, so nothing moves there.

**Found on the way: "Nearest police station — 0 km away", three times.**
Under Things to know on the same listing. `Number(null)` is 0 — the trap
§8a25 closed on the LOOKUP side ("absent, not zero") was open on the
READ side, so every listing whose host left the step-3 boxes blank
printed three distances of nothing. A blank is now absent, and 0 is not a
distance (BE `8733040`, pinned in `theNearestIsNotTheMostFamous`).

**Verified on production, 2026-09-15 00:55:** the LUXE `.modal` resolves
to `#141416` with `#F2F0EA` text and a gold hairline (computed style,
anonymous visit); the 29310 card reads ₹24,000 + ₹1,000 + ₹4,500 =
₹29,500 with every line in its total. The deal path itself needs a
signed-in guest — §6.

#### What was NOT changed, and why

The client's note also says cleaning is *"on demand"* and should be shown,
not charged. That reverses **C18** (spec, 10 Sep) and contradicts the
₹27,376 in the same message, which has the fee in it. Recorded as a
decision, **§1.14**, not made silently — **and answered the next
afternoon: stated, not charged. §8a31.** The same stay is ₹26,196 now.

#### Pinned

BE `aCouponIsOnTheRoom.test.js` (1,800 not 1,875; 27,376; the clamp and
the validate endpoint read the room) — **140/140**. Web
`aCouponIsOnTheRoom.test.mjs` (summarize, the card's deal path, the
badge, the paise) + `luxContrast` pins the modal — **42 files pass**;
`aDealPricesOnlyItsOwnNights` updated for the estimate rule. App
`a_coupon_is_on_the_room_test.dart` (priceStay, the two property-page
bases, the chat page hands over) — **451 pass**. Commits BE `e8c5791`, web
`c47cef6`, app `86797e4`. No APK yet — build 89 is with the tester; the app
side ships with the next build.

### 8a27. Closed 2026-09-13 (night) — eight client reports, and one of them was mine

Two rounds of screenshots from the client, eight faults between them, all
closed. Taken together they are worth reading as one entry because the
client's covering note was **"maximum of them are working fine earlier and
now breaking out of nowhere… you fixed something and make worse something
else"** — and that is true of exactly one of the eight. The rest were
long-standing and were simply met for the first time. Saying which is
which is the point of writing it down.

#### The one that was mine

**Step 1 could not be submitted: "Fix the highlighted fields to continue"
with nothing highlighted anywhere.** A host could not register a property
at all. Introduced the same day by §8a25's own work: Beds became a derived
read-out once a room names one, and `f.beds` stopped being written — so a
host who had typed 3 and then described five bedrooms failed the "5
bedrooms need at least 5 beds" rule against a **stale 3**, and the error
was attached to a field that is no longer an input and therefore could not
turn red. Validation now reads the number the screen shows, the read-out
can turn red like anything else, and the payload carries what was
displayed.

**And a guard for the class, because this must not be able to happen
silently again.** `fe.set` scrolls to `[data-field=…]`; an error raised
against a field that is not RENDERED scrolls nowhere and marks nothing. The
toast now says the MESSAGE when the first error has nowhere to land. *A
form that refuses and will not say why is worse than no validation.*

#### Money, and it was real

**The Amount on a stay card was not the amount charged.** The upcoming-stay
headline rendered `book_price` — the ROOM SUBTOTAL, pre-tax and
pre-discount. Booking **B115781**, read from the live row: `book_price`
2099.75, `book_total_amt` 2204.74, `book_amount_paid` 2204.74. The card
understated that stay by **₹104.99**, and every other by whatever its tax
and discount came to. The right number was already on the same object as
`total`; the line read the one beside it. `useOngoing` had no total at all
and now carries one. **The app was never wrong here** — both its screens
already did `bookTotalAmt > 0 ? bookTotalAmt : bookPrice`.

**GST differed between the property page and checkout: 9.68% / ₹25,226
against 18% / ₹27,140. Same stay, one screen apart, ₹1,914 between them.**
Neither was arithmetic gone wrong. `/pricing/quote` bands EACH NIGHT on its
own share — ₹8,280 at 18%, two nights of ₹7,360 at 5% — and the property
page asks it. The review page never did: `summarize()` had one number to
band, so it banded the AVERAGE night (₹7,666, just over the line) at 18% on
everything. Its own comment called itself a fallback; the review page was
simply never moved onto the quote. The comment in `customerApi.ts` had
already named the disease — *three implementations of one set of rules,
agreeing only while somebody remembers all three.* Fixed by carrying the
server's per-night WEIGHTS in the draft the property page already builds,
and splitting the taxable amount across them at checkout. Verified against
`utils/methods.taxForNights` directly: both sides now give 2,226.4 and
9.68%, and the old path gives exactly the ₹4,140 in the screenshot.

**"Balance received" on a stay that was paid once.** A guest who booked
pay-at-property, then pressed "Pay online instead" and paid in full, was
sent a receipt for a second instalment they had never made. The condition
was `!firstPayment`, and firstPayment is a STATUS check — a booking sits at
`statusPaymentPending` only until its first verified payment, and a
pay-at-property booking never sits there at all. What separates the two is
whether MONEY had arrived before, which `book_amount_paid` records. Fixed
in all three places the word appears: the guest's notification, the host's,
and the booking history.

#### Three that had never worked

**Typing "nainital" found nothing.** The picker's list is a transliterated
gazetteer — its own asset holds `"Naini Tāl"` and `"Dehra Dūn"` — and every
filter was a plain `toLowerCase().contains()`. A macron is not an "a" and a
space is not nothing. `searchFold()` folds for COMPARISON only; the label
still reads "Naini Tāl". The table was **generated from that asset**, not
guessed: 276 distinct non-ASCII characters in it, 170 folding to a single
ASCII letter. It deliberately does not strip what it cannot fold —
Devanagari passes through, because deleting it leaves an empty needle that
matches EVERYTHING (the `\p{L}`-without-`\p{M}` trap, which once deleted
matras from real names here).

**The map took two fingers.** Called a blocker on host and admin: "not able
to zoom in or drop pin at a particular street or area". The picker set no
`gestureHandling` at all, so it ran Google's default `'auto'`, which on a
TOUCH device resolves to `'cooperative'` — one finger pans the PAGE and the
map answers "use two fingers to move the map". That is the right default
for a map inside an article and exactly wrong for a component whose whole
job is "move the map under the pin", which fills a modal with nothing
behind it to scroll to. It is also why the marker could not be DRAGGED.
`greedy` here, plus `zoomControl`. **Left alone on AreaMap and ResultsMap**,
which are display surfaces inside scrolling pages and want the default.

**Live notification popups.** Reported as "message aa rhe h but popups nahi
aa rhe". **Not reproduced, and not claimed as fixed.** The server does emit
for guest notifications, the room names match on both sides, and a probe
against the live API answers `Authentication required`, so the transport
reaches Render. What was wrong is that when it fails it fails INVISIBLY:
a missing token was permanent (the effect depends on `userId` alone, and a
fresh sign-in writes the two separately), and a refused handshake was
silent because nothing listened for `connect_error`. Both now retry and
report. The popup also asked for bottom-right with a 76px margin, which on
a phone is where `.mobile-tabbar` and the chat bubble live — top-centre
under 820px now. A popup behind the navigation reads exactly like one that
never came, so this may be the whole story; it is not proven.

#### One that was never broken

**"Another guest" could not be "selected and used".** It could. The click
sets state, the id reaches the payload as `guestProfileId`, it IS
whitelisted in `booking.schema.js` so `stripUnknown` keeps it, and the
controller checks it belongs to the account before writing — the whole path
was traced before anything was touched, and the card is green in the
client's own screenshot. What it never did was LOOK like it had done
anything: having picked a saved traveller you are asked for a Full name, a
Phone and an Email immediately underneath, with nothing saying those are
the BOOKER's. The code knew — there is a comment in `BookingReview.tsx`
saying exactly that, written for whoever reads the source and never for the
guest. The picker now reports who was chosen and the block says whose
details it wants.

Backend 138/138 files · app 440 tests · web 40 rule tests, `tsc -b` and a
real `npm run build` clean. **Still not driven in a browser** — the host
wizard and checkout are behind a host login (see §6), which is how the
step-1 regression reached the client in the first place.

### 8a26. Closed 2026-09-13 (late) — a required question with nothing on the other end of it

Raised as a question rather than a bug: on a listing set to **Fixed price
only** and **Instant Book**, why is "How quickly do you usually reply?"
required — *"We are using this somewhere in this case?"*

**No.** Traced every consumer of `pbr_response_time_hours`, and each one
is gated on one of the two things that combination switches off:

| Consumer | Gate |
|---|---|
| negotiation threads (`user.controller`) | negotiation must be on |
| the property page rail | `requiresApproval ? … : …` |
| the payment page | `requiresApproval ? … : …` |
| the booking-confirmed page | the approval flow |
| `bookingApprovalExpiry.js` | `if (type !== 'approval') continue` |

So a host wanting the simplest listing there is — a fixed price, booked
instantly — was stopped by a required question about a situation their
listing cannot produce. **The refusal message said so itself:** "shown to
them while they wait", on a listing where nobody waits, and the help text
under the field read "Shown to guests waiting on a price offer".

Required now when negotiation is allowed **or** the host approves each
request, and the help text names whichever of the two is asking instead
of always claiming both. One derived flag per client, used by the field
AND its validation, so a form cannot draw a question it will not check or
check one it did not draw; the server applies the same two conditions.

*Worth keeping, because it is the kind of thing that reads as fixed and
is not:* **the stored answer is preserved.** `upsertByProperty` writes
every column it is handed, so passing null would have DELETED a host's
reply time the moment they switched to fixed-price instant-book — and
switching back would have demanded it again as though they had never
answered. Found because a comment claiming the value was kept was written
before the code that kept it; the comment was wrong for one commit.

*And the app's version has a trap of its own:* the negotiation check is
`!= false`, not `== true`. The platform is negotiation-first, the default
is ON, and a draft saved before that key existed loads without it —
reading null as OFF would have silently stopped asking a question those
listings genuinely need answered.

`tests/responseTimeRequired.test.js` pinned the OLD blanket rule and
failed, correctly. **Renamed and inverted rather than deleted**, the same
treatment the SMS-to-email change got: the 2026-09-05 reasoning for
making it required is still worth reading, and the two cases where it
stays required are now pinned explicitly — including that the sweeper
still skips non-approval listings, which is what makes this rule right in
the other direction. The ten new app tests were run against the old
unconditional rule first to check they bite; five failed, as they should.

Backend 138/138 files · app 424 tests · web 39 rule tests, `tsc -b` and a
real `npm run build` clean. Not driven in a browser — the wizard is
behind a host login (see §6).

### 8a25. Closed 2026-09-13 (evening) — three client notes about the listing form, and the bot sitting on the button

Four screenshots, three asks, and one thing nobody had reported.

**"give some icon for looks attached and see all identifi for categories
releated to."** On one screen the Outdoor amenities carried icons and
Homestay Type, Local Experience and Shared Spaces carried none. Not a
styling difference — **two different renderers**. Amenity chips go
through `Chips` in `ListProperty.tsx`, which looks an icon up; the
category questions come from `CATEGORY_FLOWS` through `SchemaField.tsx`,
which never did. A **third** lookup rather than widening the amenity one,
because that table matches by KEYWORD and these labels are short generic
words that mean something only under their own question — "Private",
"Shared", "Open", "Single", "Family", "None". A keyword scan over those
fires on the wrong thing constantly, and widening the table would have
changed what amenity chips render as well. Two questions stay bare on
purpose: `host_interaction_level` is High/Medium/Low and `height` is
three measurements, and because the fallback is per FIELD rather than per
option, a question draws icons on all of its chips or on none — a row
never has one chip shorter than its neighbours. **The app was the worse
half: it had NO icon on any wizard chip, amenities included.** Fixed
there too, so the parity rule holds.

**"add bedrooms class / bed classs / bathroom class / like master bedroom
/ queen sized bed / shared bathroom / attached etc"** — and, on the
desktop wizard, "also here too it should be updated". Three integers
cannot answer what a guest asks before booking: is the room I get a queen
or a bunk, and is the bathroom mine or the corridor's. Asked which shape
this should take, the client chose **per-room detail** over flat chips.

*The design decision worth not undoing:* **THE COUNT DRIVES THE LIST.**
No Add and no Remove — type 3 in Bedrooms and you get three cards. Give a
host a list they can grow independently and the number says 3 while the
list has 4, with nothing deciding which is true: search filters on the
number, the guest page prints the list, and one listing advertises two
different properties. It is the same fault as the Apartment Type naming a
bedroom count while step 1 asks separately, which is why a `bhkMismatch`
warning exists on the website today. Enforced on the SERVER
(`utils/propertyRooms.js` writes exactly `pc_bedrooms` rows, padding and
truncating), because a rule enforced in one client is a rule the other
breaks. **Beds became derived** for the same reason, like Total Guests
already was — with one carve-out that matters: when NO room names a bed
the host's own number stands, because otherwise every listing saved
before today and anything from an un-updated app would have had a stated
fact overwritten with 0. New table `property_rooms`, migration **applied
to the live database and round-tripped through it** (duplicate queens
merged, a `waterbed` dropped, JSON survived the driver, orphan test rows
removed). Guests get "Where you'll sleep" on both platforms, printing
lines the SERVER writes so the two cannot phrase the same room
differently.

**"these as well find by google location distance and all like showing in
things to know."** Asking a host how far the fire station is gets a
guess, a blank, or a number copied off another listing — and a guest
reading "2 km to hospital" in an emergency is reading a guess. Measured
from the pin now. *The trap:* `nearbyPlaces` sorts by how many people
have RATED a place, which is right for "what is worth seeing" and exactly
wrong here — ask it for one police station within 25km and it returns the
district headquarters, not the outpost at the end of the road, and the
usual `minRatings` would drop the rural station nobody has reviewed,
which is very often the only one there is. So it asks wide and re-sorts
by distance. Also: **`fire_station` was missing from the nearby
`essentials` types entirely**, so that box had nothing behind it even in
principle. Suggested, never imposed — only EMPTY boxes are filled.
Straight-line, so the guest line says "nearest" and never "X minutes":
4 km as the crow flies is a twenty-minute drive in the hills.

**And the thing nobody reported:** in two of the screenshots the
BotPenguin "May I help you?" bubble was drawn on top of the Continue
button, so a host on a phone could not submit the step without dismissing
the bot. **Lifted, not hidden** — this is the longest form on the
platform and the place a host most wants help, and taking the chat away
to fix an overlap trades the feature for 96 pixels. (Registration and
verification DO hide it; a form you complete once is not where help is
worth an obstruction.)

*Two defects the tests caught before they shipped, both worth keeping:*
`Number(null)` is **0 and finite**, so an unset pin sailed past the
coordinate guard and measured from the **Gulf of Guinea** — every such
listing would have been given ~8,800 km to the hospital, saved, and shown
to guests. `coordsFor()` already guarded that value; this did not. And
the property page's nav maps `TABS` unconditionally, so adding "Where
you'll sleep" gave EVERY listing a button, including listings with no
room detail where it scrolled to nothing.

*Not verified, and worth someone's thirty seconds:* the wizard and
property page in a browser — that is behind a host login, and a stored
password is not ours to type. The live Google lookup is also unproven
from here: `GOOGLE_PLACES_KEY` is not in the local env, so only the
"not configured" branch ran. The call path is the one the nearby picker
already uses in production and the distance sort is unit-tested against a
stub, but the first real `fire_station` query happens on Render.

Backend 138/138 files · app 414 tests · web 39 rule tests, `tsc -b` and a
real `npm run build` clean.

### 8a24. Written 2026-09-13 — the whole platform as Terraform, and not one line of it applied

**This entry is in section 8 for one reason: do not redo it.** Nothing here
is live. §2.8 stays OPEN and stays blocked, on AWS rather than on us.

The client chose `ap-south-1` and **Terraform over clicking in a console**,
and all five days of `AWS_MIGRATION_PLAN_2026-09-11.md` were written in one
sitting at `infra/terraform/` — VPC, three chained security groups, two
shared ECR repositories, RDS MySQL 8, ACM, an ALB with host-based routing,
an ECS cluster, two services, CloudFront with its own us-east-1
certificate, a staging workspace, the deploy pipelines and the cutover.

*Three shape decisions worth not re-litigating.* **Exactly one API task** —
the rate limiter, the SEO cache, the scheduler and Socket.io all hold state
in the process, so a second task is not more capacity, it is two platforms
disagreeing. **An ALB rather than API Gateway**, because Socket.io needs
real WebSockets. **No NAT gateway** — tasks sit in public subnets with a
security group that admits the ALB and nothing else, which is the same
isolation for ~$35/month less.

*And one refusal.* Terraform creates the database password into SSM and
then **deliberately does not create the other secrets with placeholders**.
`/health/env` reports which required names are SET, and a placeholder is
set: the deploy would go green on a `JWT_SECRET` of "REPLACE_ME" and the
first guest to log in would find out. An operator supplies them from a file
only they hold (`infra/scripts/put-parameters.sh`), and `terraform plan`
fails BY NAME if one of the four it cannot invent is missing.

**Day 4 — a deploy path with no standing credential.** GitHub is registered
as an OIDC provider, so there is no AWS access key in either repository to
leak or to rotate. The trust policy matches the `sub` claim exactly —
repository AND `refs/heads/main`, `StringEquals` on a two-item list rather
than `repo:owner/*`, because the wildcard would trust every repository that
owner ever creates. `iam:PassRole` is pinned to the two task roles;
unscoped, that one statement is the usual way a CI pipeline quietly becomes
an account administrator. Seven alarms, of which one matters: **zero running
tasks**, with missing data treated as breaching, because at one task there
is no partial failure and a service with no tasks publishes no metric —
silence *is* the outage. `cpu_architecture` became a variable (X86_64) where
two task definitions had ARM64 written in, because that mismatch does not
fail at build time: it fails at task start with "exec format error", which
reads like a corrupt image rather than a mismatched one.

The website pipeline passes **all ten** `VITE_*` build args the Dockerfile
declares. An image built with the other nine empty is not "missing
configuration" — it is a finished site with no map, no payment gateway and
no push notifications, and nothing says so until somebody opens it.

**Day 5 — and the correction it exists to make.** The plan says "rollback is
DNS". That is true about the stack and false about the data: the moment AWS
takes one write the two databases have diverged, and rolling back means
returning to the old one as it was at the freeze. So there are two windows —
a free one that ends at the **first write**, and the seven-day watch, which
is not free at all — and the go/no-go gate therefore sits INSIDE the freeze,
before users are let in, not after a day of watching.
`CUTOVER_RUNBOOK_2026-09-13.md` is built around that, with reversibility
marked per step.

The copy runs as a one-off Fargate task, default off. Not a preference: RDS
is private and admits 3306 from the tasks security group alone, so a task in
the VPC is the only thing in the world that can write to it. It gives the
right answer anyway — the alternative leaves a file containing every guest's
KYC, every host's bank account and every booking in somebody's downloads
folder. Two failure modes in the copy script both **report success** if you
let them: missing `set -o pipefail` (a dump that dies half way still feeds
valid SQL to the target, which applies it and exits 0), and un-stripped
`DEFINER` clauses (the restore fails near the END, after the data has
loaded, which reads like "only the last bit failed" and is how a platform
ends up with no triggers). Verification counts rows with `COUNT(*)`, never
`information_schema.table_rows` — an estimate that passes on a half-copied
database — and checks the schema character set, because arriving as `latin1`
does not fail: it stores every Devanagari name as mojibake and nobody
notices until a host cannot find their own listing.

*Three facts checked rather than assumed, each of which changed the plan:*
**DNS is hosted at Vercel** (`ns1/ns2.vercel-dns.com`), so "decommission
Vercel" would take the website, the API and the MX records with it — moving
the zone is a prerequisite nobody had written down. **Every installed APK
has `aajaodev.onrender.com` compiled in** by `--dart-define`, with no
fallback in a release build, so switching Render off breaks every tester's
app outright; the exit criterion is "no requests on that hostname for 48
hours" off Render's own logs, not a date. And **`api.aajoohomes.com` already
points at Vercel and answers 404** — a record to CHANGE, and an APK built
against it today passes the app's own `isConfigured` check and then fails
every call. Three things are genuinely unaffected, which is worth knowing
because they look otherwise: mail (Brevo HTTP on 443, not SMTP from our IP),
the Google Maps referrer restrictions, and `ALLOWED_ORIGINS` — all keyed on
`www.aajoohomes.com`, which does not change.

*One defect found on the way and fixed.* `src/configs/apiConfigs.ts` falls
back to the Render API when `VITE_API_BASE_URL` is empty — correct today,
and a trap once a second place can build the site: an unset repository
variable would ship a CloudFront site writing to the OLD database, with both
halves looking healthy. Not an outage, two live copies of the business
diverging quietly. The pipeline now refuses to build, pinned by
`tests/theApiHostIsNeverGuessed.test.mjs`, which also asserts every `ARG
VITE_*` is actually passed. Both deploy jobs are additionally guarded on
`AWS_DEPLOY_ROLE` being set, so until AWS exists they run the tests and skip
deploying rather than failing red on every commit — a pipeline that is
always red is a pipeline nobody reads.

**Blocked, and precisely on what.** Signed in, **CloudShell refuses: "Your
account verification is in progress"**. A probe narrowed it — one free ECR
repository created and deleted immediately, and it worked — so **the block
is COMPUTE, not the account**: RDS, Fargate and the ALB are what is gated,
which is the detail that belongs in the support case. The account is 48h+
old against AWS's own "up to 24 hours", so it is stuck rather than slow. Two
things only ROOT can do: flip "IAM user and role access to billing
information" (still off — which is why nobody can read the verification
state from `sumit`), and raise a free **Account and billing › Account ›
Activation** case. Written up for forwarding as
`AWS_ACCESS_AND_ACTIVATION_2026-09-13.md` / `Aajoo-AWS-Access-and-Activation.pdf`.

### 8a23. Closed 2026-09-13 — a draft on the public site, and a media account nobody owned

**A host could publish a listing nobody had approved.** Reported with two
screenshots: a listing badged **Draft** offered "Put live", and pressing
it put it into public search with no photograph and ₹0/night, never
submitted, never seen by anyone at Aajoo. W5 closed this on the ADMIN
side and left the host's own switch beside it checking ownership and
nothing else — its own comment reads "a state is only real if the
transitions out of it are the only way to leave it", and the host's
switch was the other way out. Same state machine now, with a refusal that
names what to press next.

The trap in fixing it: `stateOf` reads being on the site as the strongest
signal of approval, because 29,216 legacy listings carry
verification_status "unverified" and were published by the old admin
flow. One of those, paused by its host, therefore reads as DRAFT — so a
naive guard would have locked 29,216 owners out of their own listings.
The handler asks it the other way round: with `is_active` forced on,
would this read as approved? **The app already had this right**
(`if (adminCleared && !rejected)`); the website was the platform with the
hole, and the website is what the client was using. Listing 29308 was
taken off the site afterwards; search near Bir and `/properties/29308`
both answer "no record found".

**And the Cloudinary account was a shared drawer.** §3.6 had said
"nobody has swept it" since August. Swept: **1,003 assets**, not the 704
on record, and **111 were taken off public delivery over two passes**.

*What was public, measured unauthenticated against real assets:* 39
property documents — ownership and identity papers photographed on a
phone — answering HTTP 200; 12 guest-issue CSVs carrying `guest_name`
and `guest_phone`, which the **chatbot was minting publicly and pasting
into a chat message as a plain link**; and, among the 228 unfoldered
assets, **22 legible identity documents belonging to several different
people** (Aadhaar numbers and QR codes readable, a college ID with name,
father's name, DOB, address, phone and blood group), 18 other personal
records, and **11 of our own booking invoices** with a guest's name,
email and address on them.

The 6 PDFs beside the documents answered 401, **which reads like
protection and is not**: this account blocks public PDF delivery by
default, a free-plan setting that covers neither a JPEG of an Aadhaar nor
a CSV. That distinction is the lesson worth keeping.

*What changed:* both uploaders store `authenticated` now and both readers
sign; the report link expires in 24 hours and says so; 111 assets
migrated with our own rows repointed in the same pass. **Privatised, not
deleted** — most of those documents belong to whoever else uses this
account, and deleting could destroy their only copy.

Two self-corrections, both found by asking what actually REFERENCES an
asset rather than what it looks like: two "portraits" were user avatars
and were put back public, and two identity documents were our own guests'
KYC, which needed a signed reader (`getSignedImageUrl`) so the admin
verification screen kept working. Closing an exposure and breaking the
legitimate reader are the same edit unless you check.

*Not closed:* the document IMAGES keep an edge-cache residue — the exact
versioned old URL still answers 200 for anything fetched before the
rename, `max-age` 2592000 — thirty days, or one invalidation in the
Media Library. And **the account is shared, which is the root of every
finding here**. Aajoo needs its own.

Also this day, from four client notes: the internet SPEED pickers moved
**under** the Internet group (the schema names where each question
belongs now, so both platforms agree and cannot drift — and it exposed
that `has_wifi` was never set on the app, so an app host could not state
a speed **at all**); "not able to select from the listing" turned out to
be **Chrome's saved-address dropdown drawn over ours**, fixed with
`autoComplete="off"` on three place inputs; and password-reset codes now
go by email only, with sign-in by mobile untouched, the SMS transport
held rather than removed.

### 8a22. Closed 2026-09-12 (night) — the app could not read its own API

One listing would not open from the deal banner. It was never the network
and never the id: `property_latitude` is a floating-point column, so the
driver returns `28.47938` for one row and `"28.45936"` for the next, and
a model that declared `String?` threw `type 'double' is not a subtype of
type 'String?'` on the numeric form.

**The type is decided by a HOST SETTING, not by when a row was written.**
`blurProperty` replaces the coordinates with computed NUMBERS for any
listing whose host answered "approximate location only", and leaves the
DECIMAL string alone otherwise — so both shapes come back **in the same
response**, and a host can flip a working listing into the broken shape
at any time. Three endpoints blur. **Four models** parse coordinates and
three had it wrong; the fourth (`ongoing_reponse`) had a `_coord()`
converter and was fine. In the map/search model it was not one missing
card: `Data.fromJson` maps the whole array, so one approximate listing
took the **entire result list**.

Then the same question one layer down. Every response comes from one
helper whose signature ends `data = []`, so a handler that returns early
sends an empty **ARRAY** while its populated answer sends an **OBJECT**,
both 200, both `success: true`. Two models called `Data.fromJson(json["data"])`
on that with no type check: **a host with nothing in progress** and **a
guest no host has reviewed** — the second being every guest on the
platform, since nothing has been reviewed yet. The backend added that
200-with-empty branch precisely so the client could tell "you have none"
from "the request failed"; the client could not.

**Three faults turned a parse error into a hang**, and each was worth
fixing alone: a TypeError is an Error, not an Exception, so `on Exception
catch` walked past it; `getProperty` caught it but left the previous
listing in the one shared slot, so a failure looked like the stay opened
five minutes ago; and GetX 4.6.6's `back()` **closes an open SNACKBAR and
returns**, so with the controller's error toast on screen it never
reached the `barrierDismissible: false` dialog. Read out of the library
source, not guessed.

**And the answer to the location prompt was being thrown away.**
`getCurrentLocation` read the permission once, called
`requestPermission()` inside an un-awaited `.then`, and tested the stale
value — so a guest who tapped Allow got `null` anyway, and the search ran
from a hardcoded fallback in Delhi NCR where there are no listings. An
empty home screen on the one run that makes a first impression. The
position was also fetched at BEST accuracy with no time limit, which is a
grey shimmer until the GPS chip answers; last known first now, eight
seconds for a fresh fix, refine afterwards.

Builds 81 through 87, each one withdrawn as the next found something:
81 could not open some listings, 82 could not put them in a search
result, 83 turned an empty list into a failure, 84 predates the client's
step-3 note, 85 and 86 were superseded before they circulated. **87 is
the one to hand out**; the tester had been on 49 since 09-08. Still
unexplained and logged as §3.20: Nearby comes back empty on a cold
relaunch at coordinates that answer with a listing from curl.

### 8a21. Closed 2026-09-12 (evening) — the booking-confirmed page, the host's photograph, and cash at the door

Three from one client message, with a photograph of the confirmation page.

**The page came apart because a three-track grid held FOUR children.**
`1fr 1.1fr 340px` with four blocks in it wraps the fourth under the first:
the confirmation stranded in a tall empty column, the map cut off
mid-tile, the summary doing the most work while sitting furthest right,
"What's Next?" orphaned below. Three columns were never right for this
page — it answers four questions in a fixed order (did it work, what did
I book, where is it, what now) and side by side asks the reader to choose
where to look at the one moment they want to be told. One column now,
capped at 760 and centred. Three alignment faults went with it: the facts
row was `space-between` and wrapped whenever a value ran long (it is a
four-up grid now, two on a phone); the reference and payment mode were
buried in a corner when they are the two facts a guest copies down; and a
"Details" button led to the same screen as "Booking details" four inches
below it. Measured at 1440 and 390 rather than eyeballed. (`fix(web): the
booking-confirmed page is one column`.)

**A host could not set a profile picture anywhere in the product.** The
host Profile screen showed a bundled stock avatar — or the first letter
of their name — and offered no way to change either, so the picture on
screen was never theirs even when they had uploaded one on the guest
side. Same endpoint as guest settings: one profile per person, because a
second upload path gives a host two pictures and no way to know which one
guests see.

**A pay-at-property booking that had been paid could not say so**, which
is §7 question 1 and 2 answered in code. A cash booking was confirmed
with nothing paid and stayed that way for life: `book_is_paid = 0`, its
four ledger rows PENDING, no invoice, no queued payout — and every
finance screen filters on COMPLETED, so **the admin could not see a rupee
of it and the host was never paid**. The machinery already existed and
was never called: `recordBookingFinance({ collected })` was written to
record PENDING with no payout and promote on a second call. Both of the
client's suggestions are implemented, because they are different
questions: **check-in records it** (inside the check-in's own
transaction, so a guest cannot be walked in without it) and
**`/host/booking/collect-payment`** records it on its own, because a host
may collect before or after and a product that only records payment as a
side effect cannot answer "has this been paid?". Deliberately does not
touch `tbl_host_dues`, cannot mark a CARD booking paid, cannot collect
twice, and does not move the booking's status — arrival and payment are
two different facts. New test `cashIsRecordedWhenCollected`; 135/135.

### 8a20. Closed 2026-09-12 (afternoon) — the home page's card sections were compiled in, and eight filters were inert

Client asked whether Trending Stays, Featured Destinations and Featured
Collections could be managed, and whether the collections were calling
the right API with working filters.

**Eight cards filtered nothing.** Collections sent "Luxury", "Family",
"Pet-Friendly" and "Workcation"; the platform's categories are "Luxury
Stays" and "Pet-Friendly Stays", and Family and Workcation do not exist.
Travel Inspiration sent "Weekend Getaways", "Family Vacations",
"Workcations", "Extended Stays" — kinds of TRIP, not categories.
`/search` resolves a category TITLE to a `cat_id`, so all eight opened an
unfiltered search and looked as though they had worked. Each card now
carries a real category, and a test checks the shipped defaults against
the live catalogue, because a default that names nothing ships the same
bug. Verified by clicking: Pet-Friendly Stays lands on `/search` with the
filter ticked, and Workcations — which filtered nothing at all — now
lands on Apartments.

**And none of the three sections could be edited.** A new `rows` CMS
field type holds a small table rather than one value, stored the way
`images` already is: one record per line in the same TEXT column, cells
separated by " | ". The backend whitelists PAGES and not keys, so this
needed **no migration, no endpoint and no schema change**. Destinations,
Collections and Travel Inspiration are now lists an admin edits, each row
with its own picture upload, reorder arrows and a delete; every one falls
back to exactly what the page did before when its field is empty.

**Trending is worked out, not chosen** — stays near the visitor, boosted
first, then rating, then review count — and nothing said so anywhere an
admin would look. The field's help now says it and points at the Featured
rail on Homepage Content, which IS a list they pick. A test pins that
description to the ordering the page applies so the two cannot drift.

Also this afternoon: **Browse by category was a hardcoded nine** with
nine bundled photographs while the catalogue held eleven — so the names
were wrong ("Villas" for a category the platform calls "Villas -1"),
Resort and Pool House were unreachable, and every tile was inert for the
same reason as the collections. It reads `/common/categories` now, with
the admin's uploaded icon, and is a **rail** rather than a grid that grows
downwards. The admin side was not missing but invisible: the endpoint has
accepted a `cat_icon` upload since the screen was written and the table
never displayed it. New tests `categoriesComeFromTheCatalogue`,
`homeSectionsAreManaged`; web 47/47.

### 8a19. Closed 2026-09-12 (morning) — the negotiation rebuild, and one fault in eight places

The five changes the client asked for, shipped and photographed: unlimited
counters, an answer written under every offer, a one-hour parting price
after a decline, a same-day lockout, and a live notification layer (a
popup on any screen, an email, and a push). Full write-up in
`AAJOO_NOTIFICATIONS_AND_NEGOTIATIONS_2026-09-12.pdf`; the user-journey
document was rebuilt from scratch against the new engine
(`Aajoo-Negotiation-User-Journey.pdf`, 32 pages, 31 photographs taken on
the live site that day).

**The thing worth remembering from it:** one fault appeared in EIGHT
separate places in a single day — a price that depends on the dates, read
from a column that does not. Weekend and seasonal rates make a listing's
nightly column and what a particular night costs different numbers. The
offer ceiling, the struck-through headline, the parting price, both
negotiation cards, the "for your dates" line, the app's offer sheet, and
— the only one that cost money — **the counter-back verdict**, which
accepted ₹850 on a stay whose accept line was ₹1,050 because ₹850 clears
the FLAT ideal. The host sold a night ₹200 under what they would have
agreed to and was never asked. The derivation now lives in one exported
function, `negotiationService.tiersForDates()`, and everything asks it.

**The privacy property was demonstrated, not asserted:** three opening
offers a rupee apart straddling the host's floor, each its own
negotiation, produced three **byte-for-byte identical** answer
screenshots. Section 6 of the journey document carries them.

App parity closed the same day (build 81): the offer button greys with
its reason, the host's thread renders with "Answered for you" marked, one
shared labelling rule across four screens, and a dated offer ceiling.
Backend 135/135, app 360/360, web 47/47.

### 8a18. Closed 2026-09-12 — "Only images or PDF documents are allowed" on ten real photographs

Client report with a DevTools screenshot: uploading 10 photos to a listing
on the WEBSITE answered `{"success":false,"message":"Only images or PDF
documents are allowed."}` — every thumbnail had rendered in the page, so
the browser could decode all ten. Second time it has been seen.

**Cause.** The wizard's picker accepts `image/*` — whatever the operating
system calls an image — and the server's allowlist was seven MIME types.
AVIF (what a current Chrome or Android camera saves by default, and
already present in this catalogue as `.avif` files), TIFF, `.jfif`, and
the non-standard aliases Windows and older Androids send (`image/jpg`,
`image/pjpeg`, `image/x-png`, `image/x-ms-bmp`) were all refused. A file
whose type the sender's system could not name (`application/octet-stream`)
was refused too. And multer stops at the FIRST bad file in a multipart
request, so one odd photo failed all ten with a sentence naming none of
them — which is why it could not be diagnosed without DevTools.

**Fixed** (`240848f`, `d82a0ae`): the allowlist now covers every type a
camera or browser really produces; an untyped file is judged on its
extension; and the refusal names the file and what it claimed to be.

**And the bigger one found underneath it.** The justification for a wider
allowlist is that `verifyUploadedContent` reads the first bytes of every
file after it lands and throws out anything whose contents contradict its
extension. That check was wired into **2 of the ~20 upload routes** —
blog and the property importer. The listing wizard, guest ID documents,
signup, reviews and every admin CMS image were relying on the allowlist
alone. It is now attached to multer itself, so every route has it and a
new upload route cannot be added without it.

Verified against production after deploy:

| sent | before | now |
|---|---|---|
| `.jfif` as `image/jpeg` | refused by the filter | reaches auth ✓ |
| `.jpg` as `application/octet-stream` | refused by the filter | reaches auth ✓ |
| real `.avif` | refused by the filter | reaches auth ✓ |
| SVG | refused | refused, and names the file ✓ |
| `.png` whose bytes are an executable | **reached auth** | "contents don't match its type" ✓ |

Tests: `realPhotosAreAccepted` (new — drives the real fileFilter over 15
accepted shapes, the refusals, the named message, the byte check and the
wiring of all four uploaders), `apkFindings` updated. 125/125.

### 8a17. Closed 2026-09-11 (late) — a Camping listing, filed by a PROPERTY MANAGER

**29305 "QA Riverside Camp Rishikesh"** (host 194 acting as a manager for
owner Rakesh Verma), the second category and the second host type through
the wizard. Everything category-specific reached the database and the
public page: camp type Riverside, 6 tents, shared washroom, electricity,
bonfire, adventure activities (trekking / rafting / rock climbing);
manager block (`property_manager` row with the owner's name, contact and
`pm_authorization_available`); **Instant Book** (29303 tested
approval-required), 3-hour reply, **Seasonal** availability with seven
open months, 2-night minimum, 4-hour notice; weekend pricing Fri 3,200 /
Sat 3,500 / Sun 3,000 with its own min–ideal pair; **Firm** cancellation
policy; pets + pet food + pet area; ownership proof AND the owner's
authorisation; GST number. Approved from the admin → live at
`/property/qa-riverside-camp-rishikesh-tehri-garhwal-uttarakhand` (200,
indexable), Firm ladder printed, nearby places found by lookup from the
pin, and **September is greyed out in the guest's calendar while October
is open** — the seasonal rule reaches the booking card.

Found and fixed (backend `529fd51`, web `5da0c44`, app build **76**):

- **A sheet that closes hands the keyboard back.** Closing the tag sheet, photo picker or describe sheet restored focus to the last number field, which reopened the keyboard and scrolled the form away from the photo grid; the next tap landed in that field. Two distance fields were silently rewritten ("129", "127") and the page jumped three times. All three sheets now drop focus on the way in and out (`sheets_do_not_steal_focus_test`).
- **The owner's authorisation was shown to nobody.** Step 5 has required it from a manager since that path shipped; `currentDocumentsFor` never listed it, so the admin reviewing a manager's listing saw "Verification documents (1)" — the ownership proof alone.
- **"Sleeps: 16 guests · bd · 4 ba"** on the review panel: a camp has tents, not bedrooms. Empty segments dropped.
- **"Collected from guests" counted a stay twice and kept refunded money** (app dashboard): it summed `pay_amount` over every paid row — the pre-tax subtotal, whole on a deposit row — so a ₹2,000 stay read ₹3,800, and a refunded payment still counted. Sums each payment's gateway figure now, skipping rows marked Refunded.
- **A refund was taken from the LAST payment only** (backend): a settled deposit stay is two payments, so a full refund would have been asked of the ₹1,890 row and refused. It now walks the captured payments newest first and marks each one refunded; what they cannot cover goes to MANUAL_REVIEW (`refundSpansPayments`).

Confirmed working, not changed: the ALT text of all ten photos landed on
the right photograph with clean filenames (yesterday's `image_seo` fix on
a second listing); the cover tile reads "Cover Photo" from the flag;
"10 of 10 required photos added" and the required-tag list updating as
each was tagged; the weekend-ideal validation refusing ₹3,100 against a
₹3,000 Sunday rate, marked on the field; step 5 reading "Earnings from
this listing go to HDFC Bank XXXX9012" (yesterday's payout-account fix);
the Host Agreement not re-asked for a second listing.

**Live test content on production:** 29302, 29303, **29305**, host 194.

### 8a16. Closed 2026-09-11 (night) — deposit → approve → balance → check-in, driven on production

**B434315** (29303, 12–14 Sep, ₹2,100): guest paid the ₹210 deposit on the
website, host approved on the app, guest paid the ₹1,890 balance, ledger
promoted PENDING → COMPLETED (GUEST_PAYMENT 2,100 / HOST_EARNING 1,646).
**B386357** (29303, today, pay-at-property ₹1,155): requested, approved,
checked in from the app; guest's Ongoing page shows it; host's Settlements
shows ₹250 due (₹165 commission + ₹30 GST on it + ₹55 accommodation GST,
host keeps ₹905).

Fixed on the way (backend `1acb276`, `99f3b00`; web `c2260a1`, `37c985b`; app builds **73–74**):

- **The balance put an approved stay back to "awaiting approval"** (8 → 5), asked the host to approve again, wrote the approval history line twice and re-sent the new-booking chat message, emails and invoice. verifyPayment now knows a first payment (status 1) from the rest.
- **"Refunded in full if the host doesn't answer"** on the payment page vs "confirmed automatically" on the confirmation page. The sweeper auto-confirms (client decision); both pages say so. Deposit button says "& request" on an approval listing.
- **The cancellation ladder recited closed windows** ("100% refund if you cancel by 6 Sept" on 11 Sept; a same-day booking after check-in hour listed three past windows). Read from now: closed windows are said to be closed, the live one is "if you cancel now", a stay already begun says no refund.
- **A guest's own abandoned checkout greyed out their night for 30 minutes** on the calendar (createBooking already ignored their own hold; the calendar did not). Own unpaid hold hidden when signed in.
- **App:** "Cancel this booking" under "Confirm this booking" on an unapproved request → "Decline this request" with an honest refund line; chips wrap instead of clipping "₹1,890 du"; arrival controls appear only once approved; a check-in the server completed but whose answer was lost is re-read instead of reported as a failure (B386357 — the server said 6, the app said "Could not").

Leftovers noted, not fixed: "Staying now" chip on a confirmed stay before the host has checked the guest in; the guest booking card's stock photo for 29302/29303; guest card "Paid" pill beside "₹1,890 is still due"; B205678 "CHECK-IN 25 Sept, 2 AM" (check-in time on 29291?); `createOrder` failures are logged only to console ("Something went wrong, while creating order" twice during a Render restart); B934179 (Ben Tree House, ₹10,030, awaiting approval) was made from the renter account at 19:58 IST by someone other than me.

**Decline → refund, driven (later the same night):** the client paid the ₹210 deposit on B229372; declined from the app (build 74: "Decline this request", dialog names the ₹210) → `book_refund_amount` 210 COMPLETED, ledger rows REVERSED, host card "Cancelled · Refunded ₹210". Found on the way and fixed (backend `3543996`, web `8c4d3ef`, app build **75**): **the guest's side did not say the same thing** — the guest list never carried the refund columns, the web Cancelled page recited "any eligible refund is processed per the cancellation policy" and summed booking totals as "Eligible Amount ₹9,618", and the app's guest card and detail page each had a private "Paid" badge. One badge, one set of facts, on all four surfaces now (`tests/hostSeesWhatWasPaid`, `depositIsNotPaidInFull`, `deposit_badge_test`). The host detail no longer shows "DUE BEFORE CHECK-IN" on a cancelled booking. B968669 / B299521 are abandoned holds, harmless. **No-show:** mark B434315 tomorrow (12 Sep) from the app.

### 8a15. Closed 2026-09-11 (evening) — a brand-new host lists from the phone, is approved, and is paid to the right account

Host **194** (aajoo.host2@mailinator.com, created and admin-verified by the
client) filed **29303 "QA Metro PG Gurugram"** on build 71: PG/shared room,
map pin on MG Road Sector 28, 12 amenities, safety, nearby (metro 100 m
manual, Kingdom of Dreams 1.8 km, IGI 8.7 km), 6 photos with ALT text and
tags, ₹900 / ₹5,600 / ₹18,000 with min–ideal ladders, ₹200 one-time
cleaning, negotiation on, **approval required / 12 h**, Moderate policy,
manual key, bank + emergency + caretaker, ownership PDF, six declarations,
Host Agreement v1.0 (IP + device recorded). Admin: Submitted → Review →
Mark all checked → Approve & publish (`psb_reviewed_by = 1` — proven at
last). Public page 200 + indexable, `/property?id=29303` 301s, Google map
at the pin, Moderate ladder, "Hosted by Sumit Malhotra", quote 2 nights =
₹1,800 + ₹200 cleaning, availability says approval / 12 h, search by
coordinates finds it, "Your listing is live" notification on the app.

Found and fixed on the way (backend `9977e59`, `2586f76`; app `fb960cf`, build **72**):

- **ALT text thrown away, old listing's words kept.** `image_seo` is keyed on the media id; `property_media` was rebuilt at the 09-04 cutover and its ids came round again; `findOrCreate` found the old rows. Upload now writes its row; delete removes it; cleanup script in 1.13.
- **Two "Cover Photo" tiles.** The app sent `cover_photo` on a sixth photo it believed was the first (its list had not refreshed); the server kept the tag without the flag. Tag now follows the flag; tagging Cover Photo in the sheet makes it the cover.
- **The app said "0 of 5" with five photos on the server**, then would have let the host upload them again. On any upload error or list-less answer the app now re-reads the server's list before telling the host anything.
- **Ownership PDF answered 404 in the admin review panel.** A raw Cloudinary id keeps its extension; the reader stripped it before signing. Measured live: 404 → 200.
- **Account holder never saved** — app posted `account_holder_name`, server reads `account_holder`. The step-4 key guard now covers step 5, and caught `trade_licence` (stored nowhere) as well.
- **Compliance asked different questions on the phone** (GSTIN + trade licence) than on the web (six yes/no + GST when it applies). Same six on both now; GST required for a commercial property.
- **"No bank account on file" after typing the bank details.** Step 5 wrote them per property, in plaintext, to a table payouts never read. One writer now (`payoutAccount.service.saveHostAccount`): encrypted, penny drop started, used by step 5 and the Payouts screen alike. Proven on the device: re-saved step 5 → Bank Account screen reads "Currently on file: ••••9012". Mask script in 1.13.
- **"How your listing will appear" showed a URL that 404s** (the hierarchical path from the SEO doc, which nothing serves). Now `/property/<slug>`.

Not changed, noted: the web's step 5 asks "Caretaker available?" while guests read the step-4 house-rule copy; `pbr_same_day_booking` is stored NULL when the app's default-on toggle is untouched (readers treat NULL as allowed, so harmless); the RazorpayX keys are still unset, so the new payout account sits at `verify_status = unconfigured` with the reason recorded (2.2).

**Live test content on production:** 29302, 29303, host 194, bookings B205678 / B736755 — delete when the client is done.

### 8a14. Closed 2026-09-11 (afternoon) — a deposit booking, approved, then cancelled and refunded

Guest booked 29302 on the website (B736755, 18–20 Sep, 2 guests + 1 pet,
**10% deposit**, Razorpay test netbanking), host approved from the app,
guest cancelled with the email OTP (read from the database — see 1.12),
refund of the ₹751.80 actually received went through Razorpay
(`rfnd_TacNrzdO8nmo8u`), ledger REVERSED, host card reads "Refunded ₹752".
The deposit ledger was right at every step (amount_paid 751.80, host share
₹716, ledger PENDING, no payout). Fixed on the way:

- **Cleaning fee charged, never shown or sent** — both clients (host unpaid ₹500 on every booking since 09-10).
- **"Confirmed outright" / "Paid ₹7,518"** on an approval-required deposit booking — approval rule now reaches checkout; confirmation prints paid + balance.
- **Expired session = empty account** (app) — guard on all 17 HTTP clients; goes to login with a message.
- **A failed account lookup answered 401** (backend) — one DB blip signed a guest out mid-cancellation; only token problems are 401 now.
- **Deposit read "Paid" to the host**, refund never shown — host lists carry pay mode/amount paid/refund/pets; badges on web and app say "Deposit paid · ₹6,766 due" / "Refunded ₹752"; guest card says what is still due; "Pending Payments" counts it; four formatters that printed "₹6,766.2" share one.
- Tester build **71**. Backend 118/118, web +3, app 315.

### 8a13. Closed 2026-09-11 (later) — every cancellation moves the money; a listing filed end to end

- **Chatbot cancel moved no money** (B283633): wrote "refund PENDING", promised the guest, and stopped — no refund, ledger not reversed, host payout still queued. Website's cancel and the bot's now share `services/cancellationSettlement.js`.
- **Host cancel refunded the price, not the payment** (B761983: ₹6,300 asked of a ₹630 deposit → FAILED). Refunds `book_amount_paid` now.
- **Document upload could not unlock Submit** (web + app): the gate reads the verification row, which only step 5's save writes, which ran inside the disabled Submit. Upload files it and re-asks.
- **App step 4**: self check-in method rendered unchosen and was erased on re-save; extra-guest fee had no "guests included" so the engine charged nobody — section added to match the website.
- **Public page**: "1800 sq_ft" → "1800 sq ft"; pet amenities no longer listed as "Pet Area 1" under Property details.
- Tester build **68** (`aajoo-1.0.0-build68-qa.apk`). Backend 116/116, web +2, app 306.

### 8a12. Closed 2026-09-11 — the host money screens, driven on the device

Tasks "4–6" of the host-onboarding readiness list: approve a booking from
the app (B205678 → 8, guest sees Confirmed · Paid), documents (ownership PDF
upload/replace round-trips; identity control correctly hidden on a
DIDIT-verified host), and every Profile-menu screen — Performance, Payouts,
Settlements, Invoices, server invoice PDF in the print sheet, Notifications
(tap lands on the booking). All render. Four of them were wrong:

- **Invoices said ₹5,000 for a ₹5,250 stay**, and the app's own PDF said so
  too while the website's said ₹5,250. Both clients now show the booking's
  tax-inclusive total with GST under it; the app fetches the server PDF.
  Pulling on that thread found the verification lookup (W4, raw SQL) had
  dropped `pay_gateway_amount`, so every booking since recorded the pre-tax
  price as "received" — deposit balances, refunds (B761983 ₹6,300 on ₹630)
  and host earnings all wrong, nothing errored. Fixed with
  `hostShareOf()`; payLater's tax-inclusive `pay_amount` fixed too.
- **Settlements: "Payable now ₹512" on B703473**, a cash stay the guest then
  paid online. The due is now voided at verification.
- **Dashboard chart "No bookings in this period yet"** on a host with five
  that month: it read a list the dashboard had stopped loading. Now
  `/host/booking-dates`.
- **"Request payout" in the app** wrote to a queue nothing processes, against
  the legacy uncommissioned balance. Removed; payouts are automatic and the
  page has said so since the engine shipped.
- Admin: **"7 Pending Approvals" → "Nothing submitted"**. A deleted listing's
  row was counted, and six `updated` (live, host-edited) rows had no tab.
  Count fixed; **Updated tab** added — re-approving records the look.

Tester build: **65** (`aajoo-1.0.0-build65-qa.apk`). Tests: backend 114/114,
web +1, app 302.

### 8a11. Closed 2026-09-08 (later)

**The cancellation module, finished.** All four Admin Panel controls plus the
guest booking modification from §4 — see 1.4 above for what governs it.

**QA sheet, two rows.** Both reproduced first; neither had been fixed, despite
looking like day-before work.

- *Ownership documents duplicated and would not open.* Two causes. The wizard's
  Replace button uploads a new `property_media` row and retires nothing, and two
  admin views listed every version ever uploaded — one of them alongside the
  current documents, so a live document appeared twice on its own. And PDFs went
  up with `resource_type: "auto"`, filing them as IMAGES on `/image/upload/`,
  where Cloudinary blocks public PDF delivery: measured `.jpg` 200 / `.pdf` 401
  before, `.pdf` 200 `application/pdf` after (`4e14a90`).
  **A third thing nobody reported: those documents answered 200 to an
  unauthenticated request.** Ownership proof readable by anyone holding the URL.
  Signed, expiring links now.
  One property's asset is gone from Cloudinary entirely — confirmed through the
  Admin API — so it answers an honest 404 and that host must re-upload.

- *LUXE readability.* The primary colour is dark teal classic and GOLD in LUXE;
  components painted white on it regardless — 2.10:1. Then the booking pages
  (`/booking/review`, `/payment`, `/confirmed` — all public routes) wrapped
  themselves in a literal white while their text followed `--ink`, which is
  `#F2F0EA` in LUXE: **1.14:1**. Same fault in the legal card and in the global
  toast style, so every toast on every public page was unreadable. `--on-primary`
  and `--page`/`--surface-pop` fix both; measured 8.65:1 and 17.36:1 after, with
  the classic skin unchanged because those tokens are `#ffffff` there
  (`8b9846a`, `dda7b60`).

**BotPenguin's report.** Their team found the login-to-chat handoff made ONE
attempt and, on failure, opened the chat signed-out with no retry — and nothing
recovered, because the next mount short-circuits once the script tag exists. Now
three attempts, a 401/403 deliberately not retried, and a visible "Reconnect my
account" when it still fails (`63db8bd`). Their second report — `/account/dashboard`
serving a Vercel login page — was MY outage, already fixed; no URL change needed.

**Two outages I caused and fixed on 09-07/08.** `seo-render` cached the previous
build's `index.html` from the CDN, so every page asked for hashed assets the
deploy had deleted: blank white page site-wide behind a valid 200. My first fix
made it worse — it read the shell from `VERCEL_URL`, which is behind Deployment
Protection and returned **Vercel's own login page**, cached as the app shell.
Both fixed and guarded (`92f028f`, `1e2317c`).

---

**What this session should change about how the next one works.**

Twelve defects were found by RUNNING the thing and essentially none by
re-reading the diff. A representative few, all of which looked correct in
review: `CHANGEABLE` silently collapsed to `[5]` because two of three
`commonConfig` constants do not exist and a tidy `.filter(v => v !== undefined)`
swallowed them, so every "Booking Confirmed" stay was refused; a finished stay
could be moved to a future date; the refund looked up `tbl_payments` /
`pay_book_id` / `pay_payment_id`, none of which exist; a `logger?.error?.()`
on an identifier that was never imported; the admin policies screen drew the
whole chrome twice; "1 days before".

And **three separate deploy checks reported success having checked nothing** —
a CSS hash on a commit that touched only `.tsx`, a local-vs-production bundle
hash (Vercel inlines its own env vars, so they legitimately differ), and a
marker string that already existed in the previous build. The rule that works:
grep the SERVED bundle for a string unique to the change.

### 8a10. Closed 2026-09-07 → 09-08

Shipped and verified live unless the line says otherwise.

**Web**
- Home hero: white wash removed, CMS-managed slider with 4 placeholder images advancing every 6s, upload at Admin → CMS → Home → Hero (`f6ebdbd`, `898047a`). Dots now announce the active slide (`c6e2859`).
- **The sticky header stopped dragging the page.** Its search bar sat in flow, so collapsing it took 61px off the top of the document and slid the whole page — measured 62.9px of movement for 2px of scroll. Out of flow on `.hero-top`: 1.6px. Background and shape now change at one moment instead of two, with hysteresis (64px collapse / 8px reopen) (`7428616`).
- Phone home: the search bar shows place **and** dates **and** party (they were `display:none`); map decluttered, zoom buttons dropped, Google's grey loading colour replaced (`40c109e`).
- Blog preview cards cycle their gallery (`e917588`).
- Nearby: eight named sections a guest reads, host picks real places instead of typing distances, phone swipe rail (`6344e50`, `dcd12dd`, `ea9013a`, `fe7a481`).
- **Listing photos must be landscape** — web picker, admin cover, app, and the server, which measures via Cloudinary and destroys a refused asset. Ratio 1.2 in three repos, pinned by a test (`633fe69`, `5ef9bad`, `380750a`).
- **The identity check is explained before the guest leaves.** Pressing Pay ran `window.location.href` to Didit in the same tick; a client filmed a checkout replaced by a stranger's ID form. Now a panel, then a button (`d12267e`). The app already did this.

**API**
- Guests are only offered property types they can browse — see 3.1.
- Safety/SOS, blog galleries, WhatsApp on the host profile, SMS signup code, Google-identity fixes.

**Two outages I caused and fixed on 09-07, both invisible to every check we had**
1. `uploadImages` was hung off `exports.` in a controller that reassigns `module.exports`, so the routes file threw, `app.js` swallowed it, and **every CMS endpoint 404'd** — including the public read that had worked for weeks. Health checks passed. Guarded by `tests/routesLoad.test.js` (`b68b74b`).
2. `seo-render` cached the **previous** build's `index.html` from the CDN, so every page asked for hashed assets the deploy had already deleted: **blank white page on every route, behind a valid 200 with a correct title.** My first fix made it worse — it read the shell from `VERCEL_URL`, which is behind Deployment Protection and returned **Vercel's own login page**, cached as the app shell. Fixed by requiring the shell to be recognisably ours and busting the CDN with the deployment id (`92f028f`, `1e2317c`), guarded by `tests/seoRenderShell.test.mjs`.

**Verification lesson, now in the deploy notes:** never confirm a deploy by comparing a local `dist/` hash to production. Vercel inlines its own env vars, so the JS hash differs for the same commit. CSS usually matches, which makes the method look sound until a commit touches only `.tsx` — then the unchanged CSS matches instantly and the poll reports success having checked nothing. That happened. Grep the served bundle for a string from the change.

---

### 8a9. Closed 2026-09-05 — response time required, and the app was discarding it

Asked since the wizard was built, left optional, and skipped: 4 of 19 listings
with booking rules had one and none were live — so the guest-facing line that
needs it was correct and invisible on every bookable stay.

| | Was | Now |
|---|---|---|
| **Server** | Optional; any number accepted. | Required, and must be one the schema offers. Verified live on the deployed API: missing → refused, 0 → refused, 7 → refused naming the allowed values, 3 → accepted. The test posted the row's own values, and the row is byte-for-byte unchanged after it. |
| **Website** | Optional, and shown **only** under "Approval Required" — so an instant-book host could never be described to a waiting guest at all. | Required, asked of every host, help text naming whichever uses apply. |
| **App** | **Never saved it.** The wizard posted `response_time`; the server has always read `response_time_hours`, and the step-4 payload is a spread of that map — so the answer went over the wire, was ignored and dropped. The draft loader maps `pbr_response_time_hours` back to the long key, so the control could not be refilled on a resume either. It looked like a working field for as long as nobody checked what it saved. | Same key as the server and the site, required to leave step 4. Build 22. |

**Not defaulted, deliberately.** 24 hours against a host who answers in one
loses them the booking; one hour against a host who answers tomorrow is a
promise the platform made on their behalf.

**Existing listings:** most have no figure, so the next step-4 save on each will
ask for one. That is the intent, and it is the only way the stock gets filled
in.

### 8a8. Closed 2026-09-05 — the same negotiation flow, checked on the app (build 21)

| Rule | App before | Now |
|---|---|---|
| Offer reaches the host (email, in-app, socket) | **Already right** — server-side, shared with the site. | unchanged |
| 90-second auto-counter at the host's ideal | **Already right** — server-side. The counter arrives as a real offer row with a push notification, so the app needs nothing. Confirmed against live data: the auto-countered thread and its wording come back on the endpoint the app reads. | unchanged |
| Deal expires at midnight IST | **Already right** — the deal banner reads `validTo` off the coupon, so the shorter window simply shows a shorter countdown. | unchanged |
| Negotiation off in the pre-booking flow | **Already right, and ahead of the website** — both pre-booking surfaces have passed `showNegotiationButton:false` since they were built. But it never said WHY, and a control that vanishes unexplained reads as a missing feature. | **Same sentence as the site** now sits under the Reserve button. |
| Host's stated response time while waiting | **Missing.** "Waiting on host" with no number reads as "possibly for ever". | **Built.** The model carries it and the thread says "‹host› is away at the moment. They usually reply within N hours." Absent, zero, negative or unparseable all mean the host never said, and then nothing is shown — "0 hours" would read as instant. |

**Data gap, not a code gap:** only **4 of 19** listings with booking rules have
a response time on file, and all four are inactive — so the line is correct and
currently invisible on every bookable listing. Same shape as the pets finding:
the wizard asks the question and hosts are skipping it.

### 8a7. Closed 2026-09-05 — negotiation: 90 seconds, then we quote the host

Client rules for what happens after a guest offers below the host's ideal.

| Rule | Was | Now |
|---|---|---|
| **The offer reaches the host** by email, in-app and website notification. | **Already built** — socket event, in-app notification and email all fire on escalation. Verified, not rebuilt. | unchanged |
| **90 seconds, then the platform counters at the host's ideal** with a comment. | The thread sat until the expiry sweeper killed it at 30 minutes and told the guest the host was unavailable — true, and a wasted booking. | **Built.** `services/negotiationAutoCounter.js`, swept every 20s because ninety seconds is a promise to someone watching a screen. Claims the row before writing, so two overlapping sweeps cannot both answer. Live: an offer of ₹2,200 was answered at ₹2,500 with "The host hasn't replied yet, so here's their usual rate for these dates — ₹2,500/night. Accept it and it's yours until midnight tonight." |
| **Once only** — a guest who counters the auto-counter waits for a person, and sees the host's stated response time. | Nothing was shown; "Waiting on host" with no number reads as "possibly for ever". | **Built.** The wizard has asked hosts their average response time all along and only booking-approval chasing ever read it. Now on the thread. Silent when the host never gave one — a duration nobody promised is worse than silence. |
| **An accepted deal lasts until midnight IST**, not 24 hours. | A rolling 24 hours from acceptance, so two guests who agreed the same price on the same day had different deadlines. | **Built.** Live proof, same property: the old coupon ran 23:53→23:53; the new one was struck at 21:34 and expires 00:00. |

The expiry sweeper stays as the backstop for a thread that goes quiet *after*
the two of them are talking. Its 30-minute default and per-property window are
unchanged.

### 8a6. 2026-09-05 — pre-booking: three rules built, one question open

Client stated the pre-booking rules. Audited each against the code; three are
built and verified live, one needs a decision before it can be.

| Rule | Was | Now |
|---|---|---|
| **A stay starting tomorrow IST or later is a pre-booking**, whatever time it is booked. | **No such concept.** `booking_pref` (instant/pre_booking) is a HOST preference; `/pre-booking` is a browse surface. Nothing keyed off the stay's start date. | **Built.** `utils/preBooking.js` owns it. The server runs on UTC, so "today" off the clock is the wrong day between 18:30 UTC and midnight — 00:00–05:30 in India — and a guest booking at 11pm IST would have been told their stay starts today. |
| **One month maximum per booking**, the real month the stay starts in: 31 / 30 / 28, and 29 in a leap year. | **Not implemented.** A per-host `pbr_max_stay_nights` existed; no platform cap, nothing calendar-aware. | **Built and enforced** at booking creation. Verified live: Jan 31, Apr 30, Feb 2027 28, Feb 2028 29, with the century rule. No booking has ever exceeded it (longest 28 nights), so nothing in flight breaks. |
| **Weekly / monthly pricing applies, with a "best deal" banner.** | **Engine already correct** — host states what a week and a month COST, the rate divides across every night, monthly beats weekly. But none of it left `/pricing/quote`, so **a host who set a monthly price was giving a discount no guest could see**. | **Built.** The quote carries the label, saving and percentage; the rail names it. Live: 9 nights → "weekly rate", 28 nights → "You're getting this host's monthly rate — ₹51,000 less than booking these nights one at a time — 32.7% off". |
| **Negotiations disabled on pre-booking.** | Not implemented. | **Built.** Scoped to the FLOW, per the client: a stay opened from pre-booking swaps Send an Offer for a line saying the running discount is already in the price. Read literally — every stay starting tomorrow — it would have switched negotiation off for 84% of bookings on a site branded negotiation-first. The same stay opened from search still negotiates. |

**The monthly divisor — settled at 30/31.** A month is the month being booked:
31 from January, 30 from April, 28 from February, 29 in a leap year. It was a
flat 28, so a guest booking January paid a month's price for 28 of its 31
nights and three more at full nightly rate. A month package now forms when the
stay covers a whole month, the same way a week needs seven nights. Verified
live across all four month lengths, both sides of the leap year.

**Both remaining pieces done (build 20).**

*The date pickers now stop at the limit.* The web calendar greys out every day
past the month's last night once a check-in is picked, with the reason on
hover, and answers a click that still gets through by naming the number —
"up to one month" without it leaves a guest counting squares. Verified live: a
10 September check-in caps the checkout at 10 October and greys 11–31 October.
The app's check-out picker offered a year ahead against a server that accepts
one month; it stops at the month's last night now.

*The app's own month rule was still 28.* The bigger find of the two. The app
carries its own copy of the host's long-stay maths so a guest sees a number
before any request lands — and that copy still divided the monthly price by a
flat 28 after the server moved to the calendar month. The app was quoting,
confidently, a price the booking endpoint would refuse. It now uses the month
the stay starts in and needs a whole month to qualify, matching the server;
with no start date it falls back to 28, the same fallback the server keeps.

The app already had the savings banner ("You saved 32% — ₹51,000 with the
monthly rate"), so nothing new was needed there — it was reading a wrong
number, not missing a display.

The arithmetic now lives in three places (server, website, app) because none
can share code with the others: a few pure lines with a test on each side,
which is the cheapest way to keep three copies honest.

### 8a5. Closed 2026-09-05 — the listing wizard's location picker

Client: the map picker sits below the fields it fills, Street Address comes out
as a locality where Google prints a street number, and moving the pin fills
"half the fields" slowly and leaves the City blank. Four separate faults.

| Was | Now | Evidence |
|---|---|---|
| **The picker sat at the BOTTOM** of "Where is the property?", under the six fields it fills, so hosts typed the address and then had the pin overwrite it. | **First in the section**, with a line saying it will fill the rest. | live — field order confirmed on the deployed wizard |
| **Picking a place from the search filled NOTHING but the coordinates.** The picker trusted the search hit's own address; the legacy Places Text Search cannot return address components at all, and production runs on it, so every hit arrived blank. The fields the client did see came later, from a map click — which is the "half the fields, slowly" they reported. | **Fixed.** The hit is used when it carries an address, otherwise the pin is looked up. One request, only for the chosen place. | live — every field fills on the first pick |
| **Street Address dropped the house number.** It was built as route + sublocality; Google returns the number separately as `street_number`, and a pin on a landmark with no route filled the locality name alone. | **Fixed.** Number and road, else the building's own name, else Google's formatted line with city/state/PIN/country trimmed. The two Google generations had a mapping each and had already drifted — one mapping now. | live — "S25/062, Katra Ahluwalia", "109 Court Road", "1, Chaura" |
| **The City the pin set was wiped a moment later.** `StateCityFields` clears the city when the state changes, since the old city belonged to the old state — but the map writes both in one update, so the clear ate the city that had just arrived. | **Fixed.** It tells the two cases apart by whether the city changed in the same commit. | live — City fills as "Amritsar", was blank |
| **Moving the pin left stale fields.** Merging non-empty values is right for a nudge, wrong for a move: Karnal → Amritsar kept "Karnal Division" in District. | **Fixed.** A different city or state replaces the address block outright. Same rule in the admin property form. | live — Amritsar → Karnal replaced all six fields |

**Closed the same day — the app's host wizard now has the picker too (build
19).** It had none: hosts typed the whole address and no coordinate was ever
captured, so a listing created on the app could not be returned by any
location-based search. It sat in the catalogue and was invisible in the one
place guests look.

The app now opens the same section with a map, in the same order and with the
same rules as the website:

* a sheet with search, "My location", and a fixed centre pin the map moves
  under — dragging a marker on a phone means covering the thing you are aiming;
* the address is looked up for the point actually chosen, never taken from the
  search suggestion, because suggestions arrive with an empty address whenever
  the backend answers from Google's legacy Text Search;
* a nudge inside one town fills only what was found; a move to another town
  replaces the address block outright;
* a pin is now required to leave step 1, as it is on the website;
* `StateCityFields` reloads its city list when the pin sets a new state, and
  does not clear a city that arrived with it.

A failed lookup still keeps the pin and says so — coordinates are the one thing
the form cannot do without, and the fields stay editable.

### 8a4. Closed 2026-09-05 — app search parity, and pets in the search bar

**App (build 18).** The app carried every fault the website had just been fixed
for, in its own dialect. All verified against live data through the endpoints
the app calls.

| Was | Now | Evidence |
|---|---|---|
| **Map search sent a POINT and nothing else.** Whatever was typed went to the geocoder and no further, so a property NAME was resolved as a place. Worse, when the geocoder could not place it — which is what happens to a name — the app refused the search and told the guest to try a nearby town. | **Fixed.** The term goes to the server, which matches name and address wherever the search is centred; a term that will not geocode searches instead of dead-ending. | live — a name centred on the wrong continent returns the stay |
| **Price narrowed in Dart** over the properties already fetched. | **Fixed.** Sent to the server, and held on the controller with the dates so no refetch drops it. | live |
| **Results screen searched and sorted its own page.** A name search looked inside 60 rows; "Price: Low to High" ordered those 60 and presented them as the cheapest on the platform. | **Fixed.** Both are the API's, debounced to one request per typing pause. | live — asc opens at ₹900, desc at ₹12,000 |
| **`sort_by` went straight into the ORDER BY** as a column name, so an unknown value was a 500; and "rating" was sorted after the query, over the page that survived the limit. | **Fixed.** Allowlisted, ordered in SQL, unrated last. | live — ratings 5, 4, then unrated; a junk sort is ignored, not a 500 |
| **The radius cancelled the search term** — distance and text were AND-ed, so a named stay outside the searched area was lost. | **Fixed.** OR-ed, exactly as the website's endpoint. | live |

Category, price, rating, guests, dates and pets were already server-side on the
app's results screen and were re-verified. Paging exists on the endpoint
(`limit`/`offset` both honoured); the app still asks for one page of 60 and has
no "load more" — the one remaining difference from the website, listed in §6.

**Pets in the search bar (web).** The bar collected adults, children and
infants and stopped, so a guest travelling with a dog met the question for the
first time at checkout, after choosing a stay that may not take one. The
stepper was already built and switched off with a note saying the search API
could not filter on pets — it has been able to since August. In search the
count means "stays that take pets": pets never occupy beds, so it narrows on
the host's answer, and the host's own cap still applies on the listing. On the
desktop popover and the phone sheet both. The sidebar tick reflects a pet
carried in from the bar, and unticking it clears the pet.

*Verified live:* adding one pet on a Delhi search took 4,006 stays to 2.

### 8a3. Closed 2026-09-05 — pagination, result consistency, card design

Client, comparing our Delhi results with Airbnb's: "632 properties in delhi, on
map shows 100 stays only … no pagination exist … our page looks more like a
dummy". Six more defects, all fixed, deployed and re-verified live.

| Was | Now | Evidence |
|---|---|---|
| **No pagination.** The API answered with its first 100 rows and there was no way to ask for row 101 — `limit` had never been whitelisted (stripUnknown deleted it, which is where the suspiciously round 100 came from) and `offset` did not exist. | **Fixed.** 24 stays a page with a numbered pager: first and last page always reachable, current page ± 1, ellipsis over the gap. Changing the search returns to page one. | live — "1–24 of 4,006", page 2 shows "25–48" with different stays |
| **The header promised what the pages could not deliver.** The live-host rule (a listing whose owner is deleted or deactivated is not for sale) ran in JavaScript over the fetched rows while the total was pure SQL. | **Fixed.** Same rule, applied where the counting happens, so the total and every page agree. | test + live |
| **Sort ordered the page, not the search.** "Price: low to high" sorted the 24 stays on screen and presented that as the cheapest on the platform. | **Fixed.** Server-side, from a fixed map (never caller text — it lands in an ORDER BY). A search term still leads the ordering. Sorting returns to page one. | live — price_asc opens at ₹900, an invalid sort is refused 403 |
| **Guest rating filtered the page.** A 4-star filter searched 24 stays out of 632. | **Fixed.** A subquery over the same rows the ratings helper averages; unrated is excluded by a floor rather than counted as zero. | live — 2 stays at 4★+, 1 at 4.5★+ |
| **A ticked property type could search the wrong category.** The title→id map was keyed by a normalised title, and the normaliser strips a trailing "s", so "Villa" and "Villas" collapse to one key — both of which an admin may create. | **Fixed.** Keyed by the exact title. | code; no collision in today's data |
| **Cards read as a form beside Airbnb's.** Hard border, 14px padding, a 16/11 crop that made the photograph a thumbnail, and the tightest grid on the site (2 columns, 16px). | **Fixed.** 18px radius, border traded for a soft hover lift, 4/3 image, 16–18px padding, blurred pills that sit in the photograph, 24px grid taking a third column above 1600px. Same markup, so the rails move with it. | live — computed styles confirmed on the deployed page |

**Filters audited end to end against live data** — property type (single, multi-
select, an admin-created category, and one an admin switched off), price (each
bound alone), sort (all four), guest rating, pets, guests, dates, and a
combined query. All narrow at the database and all agree with their counts.

**Left as data, not code:** only **7 of 29,232** live listings have a
house-rules row at all, and 5 say pets are allowed — so "Travelling with a pet"
is correct but almost always answers empty. Separately, 3,247 listings sit in
the "Pet-Friendly Stays" *category* and none of them says pets are allowed in
its house rules. The two are different things and the filter reads the host's
actual answer; making the category stand in for it would tell a guest they can
bring a dog when no host ever said so.

### 8a2. Closed 2026-09-05 — property search and filters (client report)

Client: "we can't search property by entering the property exact name", and a
Kullu listing at ₹2,500 came back for neither Kullu nor a 2500–2500 price
band. Seven defects sat behind those two sentences. All fixed, deployed and
re-verified against live data; guarded by `tests/propertySearchFilters.test.js`.

| Was | Now | Evidence |
|---|---|---|
| **Search by name impossible (web).** `/properties/search` had no text parameter at all. The site geocodes whatever is typed, so a property NAME was resolved as a place — "Aish camping in the hills" resolved to a street in Woodbourne, New York, and the search ran there. | **Fixed.** `q` matches name / address / city / state, whitelisted in the schema. Name matches rank first and that order survives the second fetch. | live — site returns the property; API probe |
| **Search by name impossible (app).** `searchProperty` posted `latitude:"" longitude:"" radius:10`. `Number("")` is 0 and `isFinite(0)` is true, so every text search asked for stays within 10km of 0°N 0°E, in the Atlantic. | **Fixed server-side**, so installed builds are fixed too; the app also stops sending the blank values. | live — the old payload now returns the property |
| **A listing's address didn't reach search.** Distance was the only geo test, and the Kullu listings sit ~50km from Kullu, so no sane radius reached them. | **Fixed.** The text match is OR-ed against the geo group, so an address answers for itself whatever the pin says. | live — Kullu at radius 5 returns 51 stays, was 0 |
| **Price filter mostly inert.** Server: `if (minPrice && maxPrice)` around a BETWEEN, so a ceiling with no floor narrowed nothing and a floor of 0 disabled the filter. Web: filtered in the browser over the 100 rows already fetched. | **Fixed.** Two independent bounds, in SQL, on both endpoints; the web sends them instead of sieving a page. | live — Kullu 3000–3300 returns 23, all ₹3,300 |
| **LUXE deleted real stays from search.** The browse partition was applied to searches too, and three of the five real active listings are marked luxury — ordinary search sends `isLuxury:0`, so it could not return them. It also contradicts the host wizard, which promises only that luxury stays *appear* in the LUXE collection. | **Fixed.** Shelves stay separate while browsing (tester #17 still holds); a search answers from both. Cards keep their LUXE mark. | live — both the fix and the #17 guard re-checked |
| **LUXE overwrote the text search (app).** Both were assigned to `whereClause[Op.or]`, the same key. Whichever ran last won, so any search carrying `isLuxury` discarded the term and answered with the whole non-luxury catalogue. | **Fixed.** Both live under `Op.and`. | live — a nonsense term now returns nothing |
| **Two filter clauses could only throw or miss.** `filters.amenities` set a `property_amenities` column that does not exist, with a Postgres operator this MySQL dialect cannot render. `filters.city` was an exact match. | **Fixed.** Dead clause removed with a note on where amenity narrowing belongs; city matches loosely. | test + live |

**Left as data, not code:** listing 29289's map pin sits 50.6km from the Kullu
address it carries — the host placed it there. Every other real listing is
within 11km of the town it claims. Search no longer depends on the pin, but the
map and distance ordering still do, so it is worth correcting in admin.

### 8a. Closed 2026-09-04 → 09-05 (tester rounds, builds 13–16, the sweep)

| Was | Now | Evidence |
|---|---|---|
| **App #13** dropdown selection jumps back to the last numeric field | **Fixed, build 13.** The field kept focus under the pop-up sheet; it now unfocuses before the sheet opens. | code — not reproduced on the emulator, see §6 |
| **App #14** emails with `+` rejected at login | **Fixed, build 13.** The app's own regex; the server never had the rule. Sign-up was blocked by the same check, so the tester's `+host2` address had never existed. | verified — device |
| **App #15** white band above the keypad at login | **Fixed, build 13.** The keyboard inset was subtracted three times. | verified — device |
| **App #16** last wizard step blank on resume | **Fixed, build 13 + web + server.** `/listing/draft` never returned the step-5 tables; house rules were read under `ph_` instead of `phr_`; the web's `p5` was never hydrated either. Bank account comes back masked and is deliberately not re-filled. | verified — draft payload |
| **App #17** Submit for Review spun for three minutes | **Fixed, build 13.** 45-second submit timeout, then a read-back of the listing's state. | verified — device |
| **Admin** submitted listing never reached Pending Review | **Fixed, live.** New listings were created live+verified and submit changed nothing — **admin approval was gating nothing**, and unapproved listings were public and in Google. Migration `20260904100000-listing-offline-until-approved` applied on the live DB; unapproved listings now answer **404** at the edge (after a second fix — `build()` in `seoResolve.js` was dropping the `live` field). | verified 09-05 — `property_submission` rows; curl `Age: 0` → 404 |
| **App #18** ownership proof: no file upload, no document type | **Fixed, build 14 (in 16).** Image picker → file picker (PDF/DOC/DOCX/JPG/PNG); seven ownership + four identity types matching the web; upload was saved under a key the server never read. | verified — draft payload |
| **App #19** host notifications blank | **Fixed, server.** Hosts are written to two tables; the app read the rarely-used one (2 rows vs the website's 17). `hostSearch` now unions both; mark-read routes by `source`. | verified — DB counts per table |
| **Admin** "Ownership document missing" on approval | **Same root cause as #18** — the file was stored, the reference was not. Listings created before build 14 need one re-upload. | verified — DB column empty |
| **Web** guest count reset to 2 after a negotiation | **Fixed, live + app parity.** The party size was never stored with the offer. Migration `20260905100000-negotiation-offer-guests` (`offer_guests`) applied live; travels with the offer, comes back on the deal. | verified — column present, web build |
| **Reviews behind auth** | **Fixed 2026-09-03** in three places at once (route auth, client gate, edge markup); `aggregateRating` now server-rendered. | verified — curl of served HTML |
| **Duplicate `LodgingBusiness` + soft 404** on listing pages | **Fixed.** One business per page; a gone/unapproved listing answers 404 with `noindex`. | verified — curl |
| **Page SEO could not be saved** (ever) | **Fixed.** yup `.nullable()` rejected `""`; the empty audit log hid it. | verified — save round-trip |
| **Admin SEO scattered across menus** | **Done.** Dedicated SEO section in the nav + "Search & SEO" dashboard panel; change log now lists every SEO screen's edits; bulk tab sends its mode; keywords shown as lines, not JSON. | verified — admin UI |
| **SEO Phase 1 handover** | **Delivered** — `SEO_Phase1_Handover.docx` + artifact page, sent to the SEO team. | file |
| **Sweep class 1** — 26 silent-empty catches in app services | **Done, builds 15–16.** All 27 log through `utils/service_log.dart`; empty-vs-broken (`LoadFailed` + retry) on host notifications, guest negotiations, host properties; guest bookings already had it. | verified — `flutter analyze`, 138 tests |
| **Sweep class 2** — 34 `.nullable()` numerics with no empty-string transform | **Done.** 38 sites on `nullableNumber()`; `tests/nullableNumberSweep.test.js` rescans every schema. | verified — 43 test files |
| **Sweep class 3** — `.catch(() => {})` on the web | **Done — 37 sites, not 18.** The ESLint rule added at the end found 19 more written with a comment inside the braces. Four got real error states: notification bell, Book Now (was stuck on "one moment"), host and admin offer pickers. | verified 09-05 — `eslint .` 0 hits, real build |
| **Sweep class 4** — two arrays disagreeing on which statuses are revenue | **Done.** One list in `utils/bookingStatus.js` (3,5,6,7,8,9,10,13); a third, complement-shaped list in property analytics folded in; guard test refuses a private list. No real booking sits at 4/12/13, so no figure moved. | verified 09-05 — DB status counts |
| **Sweep class 5** — admin form validating untouched fields | **Done.** `PropertyForm.tsx` validates and sends only what changed. | verified — the two renames went through |
| **"14 listings moved into the review queue"** (build-14 sheet note) | **Overstated.** The DB records **4 approvals** on 09-04 (→ §1.7). Real-host listings after 09-05: 6 live, 1 approved-but-inactive, 9 drafts, 0 awaiting review. | verified 09-05 — DB |
| **Admin → Properties → "Approve & publish" was a second, broken approval path** (was 3.13) | **Fixed 2026-09-05.** It counted documents in two tables while the wizard writes them to a third (`property_media`), so it refused **15 of the 16 real-host listings** — and had the count ever passed, it would have approved with no state machine, no completeness gate, no `property_submission` record and no SEO regeneration. The queue's handler body is now `reviewListing()` — one implementation, no HTTP in it — and both entry points call it; the Properties dialog keeps its tier choice, drafts are refused with the machine's own message, and only older-form listings still take the attachment path (whose gate now counts all three tables). `tests/listingReview.test.js` pins the shape. Follow-up the same day: the list now carries `verification_status`, so the Pending tab shows drafts as **Draft / "Not submitted"** with no Approve button, and the review dialog says so and disables approve. | verified 09-05 — production probe on a draft answers the lifecycle message; live Pending tab shows 9 drafts with Review only; 44/44 |
| **Queue approvals never reached the admin audit ledger** (was 3.14) | **Fixed 2026-09-05.** Every decision, from either entry point, goes through `auditDecision()` → `tbl_admin_audit` as `property_approved / _rejected / _changes_requested / _suspended` with before/after. | verified 09-05 — audit row on the post-deploy re-approval |
| **UAT manuals, delay analysis, deployment options** | **Delivered 2026-09-05.** Two UAT manuals (web 81 cases, Android 55 cases) with sign-off tables; the delivery-delay analysis against the 13 July plan with a dated timeline and owners; the hosting comparison with sizing, tools, provider costs, VPS route, decision matrix and a migration plan. Generated from the repos and the session record, not from memory; structural check passed (no raw markup, tables intact). | verified 09-05 — files at repo root |
| **Cancellation & Refund Policy v1.0 — final copy** (was 1.4) | **Implemented 2026-09-05 against the client's document.** The five ladders already matched; two loopholes did not: a booking did **not** keep the policy it was made under (the refund read the listing's *current* policy — 48 bookings carried no snapshot), and "hours before check-in" was measured from **midnight UTC**, so a guest's free-cancellation window was up to ~18 h shorter than promised. Both fixed (`book_cancel_policy` snapshot; check-in = `pbr_checkin_time` in IST, default 14:00). Also: *Non-Refundable* and *Custom* removed from host selection (not in the document; no listing used them); guest-facing rules generated in the document's words; refund-timeline copy per §9; the app's hardcoded Firm/Strict sentences (wrong) replaced by the server's. New: `/cancellation-policy` page (web + app, one text served by `/common/cancellation-policy`), this stay's refund dates + a required acknowledgement before payment on web and app, colour-coded badge on every card, links from listing pages, footer, Settings and host menu. `tests/cancellationPolicyV1.test.js` pins the ladders to the document's table. | verified 09-05 — 46/46 BE, 138/138 app, live page 200 + index, cards badged on the live search |
| **Cookie banner asked for analytics, loaded marketing** (was inside 1.2) | **Fixed 2026-09-05.** One "yes" loaded GA4, GTM, a Meta pixel and Hotjar under a banner that mentioned only analytics; the chat widget fingerprinted every public visitor before the question; "Read more" went to Terms. Now: three categories at equal weight, Consent Mode v2 defaults denied, Hotjar barred from sensitive routes, BotPenguin mounted only in the signed-in renter area, policy section drafted and linked. The client's remaining part is in §1.2. | verified 09-05 — anonymous visit: no cookies, no vendor scripts, v2 storage shape |
| **BotPenguin was handed the user's 30-day session JWT** (was 3.13) | **Fixed 2026-09-05.** The widget now asks `POST /bp/handoff` (user session required) for a **15-minute, purpose-bound handoff token** signed with a key of its own, so no session verifier accepts it; `/bp/session/start` takes that, and an old tab's session token only until 2026-09-13. Consumed once at session start — a conversation cannot expire mid-way; a chat opened >15 min after landing falls back to the phone/OTP path. Bot flow on the vendor side unchanged. `tests/botHandoff.test.js`. | verified 09-05 — production mint: purpose `bp_handoff`, exp−iat = 900 s, rejected by `/user/detail` |
| **`psb_reviewed_by` fix unproven** | **Proven on production 2026-09-05.** Approving 29289 through Listing Verification wrote `psb_reviewed_by = 1` (admintest, super_admin), `psb_reviewed_at`, `psb_published_at` and all nine checks; the listing went `verified`/active and its slug page answers 200 `index, follow`. It reaches the property sitemap when that document's hour-long in-process cache expires (Admin → Global SEO → Regenerate forces it) — approval does not purge the cache. Found two things on the way → §3.13, §3.14. | verified 09-05 — DB + curl |

### 8b. Closed before 2026-09-04

The 2026-07-11 edition listed all of these as open. Each was checked on
2026-09-04 and found already delivered. Re-opening any of them wastes a day.

| Was | Now | Evidence |
|---|---|---|
| **B-1 / C-2** secrets hardcoded in `db.config.js` | **Done.** File is env-only with empty fallbacks; `/health/env` reports `ready: true` (vars present **and** DB reachable); Cloudinary uploads work in production. | verified |
| **C** "Render env never populated", "DB_* set but wrong" | **Stale.** Those warnings described July–August. The cutover has happened. | verified |
| **BE-4** "web has no socket client — web chat would be a net-new build" | **Done.** `socket.io-client` is a dependency; `useChat.ts` and `useNegotiationLive.ts` ship. | verified |
| **MOB-1** DIDIT KYC absent from the app | **Done.** `didit_kyc_screen.dart`, `kyc_controller.dart`, `verify_service.dart` mirror the web flow. | verified |
| **MOB-2** app still uses the old `/host/add` | **Done.** The 5-step schema wizard is the only property form on web and app since 2026-08-20. | code |
| **MOB-3** verification status not surfaced in the app | **Done.** `isKycVerified` drives the host profile and payout screens. | verified |
| **S0-SEO-1** per-page SEO | **Done.** The entire SEO Phase 1 — tasks 0 through 10 — is live. See `SEO_CMS_PHASE1_TASKLIST.md`. | verified |
| **S0-BLOG-1** blog frontend | **Done.** `tbl_blogs` holds 16 rows; the public blog and admin editor ship. | verified |
| **S0-ADM-1** admin missing CMS / SEO / Coupons / Analytics | **Done except Notification Mgmt** (→ §3.8). SEO alone now has 8 routes. | verified |
| **S0-HOST-1** host missing Calendar / Offers / Occupancy | **Done.** `/host/calendar`, `/host/offers`, `/host/performance`, `/host/boost`, `/host/settlements` all ship. | verified |
| **G-1** doc cleanup uncommitted | **Done.** `_archive/` holds 45 files and the tree is clean. | verified |
| **G-2** `aajoo_homes-main/` still tracked in git | **Done.** `git ls-files` returns 0. The directory remains on disk, untracked. | verified |
| **"29,232 listings have no photograph"** | **Misleading, now corrected.** Only 6 listings belong to real hosts and **all 6 have photos**. The gap is entirely inside the seed corpus no crawler sees. | verified |
| **"Seed data spells Uttarakhand as Uttrakhand"** | **Not reproducible.** 0 rows in `property_state`. | verified |

---

## 9. Keeping this file honest

- **Live tests run as "Renter test web" (179), never as the client's test
  guest "Aajoo Renter" (101) or their host "Sam Tao" (100).** A deal, a
  booking or a negotiation left on 101 shows up on the client's own
  screen the next morning as something they did not do (§8a33). The
  puppeteer rig's `.chrome/renter` profile and the emulator were both
  signed in as 101 on 15 September; re-sign them as 179 before the next
  drive.

The previous edition drifted because items were marked done in commit messages
and session handoffs but never reconciled back here, while other items stayed
open long after they shipped. Three habits prevent it:

1. **Check the running system, not the note.** Every row above says how it was
   established. A row that only says `carried` has not been checked and should be
   the first thing anyone re-tests.
2. **An empty result is a finding, not a pass.** Several defects this cycle hid
   as absence — an empty change log, a form that rendered perfectly and could not
   save, a 401 swallowed into "this property has no reviews", a host with
   seventeen notifications shown "No notifications yet". Where a number should
   exist and does not, treat that as unverified rather than clean.
3. **A green suite is not a driven build.** Build 90 on 2026-09-15 passed
   459 tests and, on the emulator, banded GST on the wrong night, counted a
   week as six nights and booked an accepted deal at full price. Drive a
   build before it is named the tester build; withdraw the number if the
   drive finds anything.
4. **A count from a grep is a lower bound.** The web catch sweep was "18 sites"
   until an AST rule found 37; the "14 listings approved" note was 4 in the DB.
   When a number goes into this file, measure it with the tool that cannot be
   fooled by formatting — a lint selector, a guard test, a `COUNT(*)` — and say
   which one.

Detailed context: `Delivery_Delay_Analysis_2026-09-05.docx` (why the date slipped, and what changes) · `Deployment_Options_2026-09-05.docx` · `PROACTIVE_FINDINGS_2026-09-05.md` · `SEO_CMS_PHASE1_TASKLIST.md`
· `AAJOO_SECTION0_TASKLIST.md` · `CONTRACT_COMPLIANCE_CHECK.md` ·
`CLIENT_INPUTS_REQUIRED.md` · `RENDER_ENV_CHECKLIST.md` · `PAYOUTS_SETUP.md` ·
latest `SESSION_HANDOFF_*.md`.

AWS, in reading order: `AWS_MIGRATION_PLAN_2026-09-11.md` (what and why, for the
client) · `infra/terraform/README.md` (what each day built, and the traps in it)
· `CUTOVER_RUNBOOK_2026-09-13.md` (the day itself) ·
`AWS_ACCESS_AND_ACTIVATION_2026-09-13.md` (what is blocked and who can unblock
it — written to be forwarded).
