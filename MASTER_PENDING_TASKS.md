# AAJOO Homes — Master Pending Tasks (single source of truth)

> **Reconciled 2026-09-04** against the live site, the live database and the three
> repos; **updated 2026-09-05** after tester builds 14–16, the proactive defect
> sweep, and a fresh set of DB counts; **updated 2026-09-13** with §8a19–8a23 — the negotiation
> rebuild, the home page's card sections, cash at the door, the booking-confirmed
> redesign, the app's inability to read its own API, a draft that reached public search,
> and the Cloudinary sweep that took 111 personal records off public delivery.
> Supersedes the 2026-07-11 edition, which had drifted badly — nine of its open
> items were already done and two of its "done" claims were wrong.
>
> **Repos:** FE `D:/Projects/aajao-frontend-vercel` (React/Vite → Vercel) ·
> BE `D:/Projects/aajaoBackend-render` (Node/Express/Sequelize → `aajaodev.onrender.com`) ·
> Mobile `aajoo_app_2026/` (Flutter). Deploy = push to `main`; **DB migrations do NOT auto-run.**
> Tester build in circulation: **87 (1.0.0+87)**, `aajoo-homes-1.0.0-build87-release.apk` at repo root
> (2026-09-12, sha256 `81ac7a45…4f725a`, versionCode 87, 95.5 MB). Everything before it is withdrawn
> and deleted — 81…84 each carried a defect found the same day, 85 and 86 were superseded before
> they circulated. All of them supersede **49**, which the tester has had since 09-08.
> Read back with `python aajoo_app_2026/tool/verify_release_apk.py <apk> https://aajaodev.onrender.com
> --allow-test-payments --expect-version=1.0.0+87`: the endpoint it was given is in it, no other
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
| [1. Client decisions](#1-blocked-on-client-decisions) | Client | 7 |
| [2. Ops / Render access](#2-blocked-on-ops--render-access) | Whoever holds Render + GCP | 7 |
| [3. Engineering](#3-engineering--genuinely-open) | Us | 12 |
| [4. Contract deliverables](#4-contract-deliverables-) | Us | 8 |
| [5. Section-0 redo](#5-section-0-site-redo--separate-sow) | Blocked on a signed change order | 20 |
| [6. Unproven, not broken](#6-unproven-not-broken) | Us + tester | 10 |

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
| **1.8** | **Where the platform runs after UAT** | `Deployment_Options_2026-09-05.docx` compares staying on Render + Vercel with AWS, Azure, GCP, DigitalOcean and a VPS, with indicative costs. Recommendation: stay through UAT (Render Starter, $7/mo), then **DigitalOcean Bangalore** (~$45–75/mo) as the first managed home in India; hyperscaler only with an owner or credits; VPS only with a named operator. Needs the client's answers to §8 of that document: expected traffic, budget, who operates, existing cloud agreements. | doc |

---

## 2. Blocked on ops / Render access

| # | Item | Failure mode if missed | Evidence |
|---|---|---|---|
| **2.1** | **Live Razorpay keys + `ALLOW_TEST_PAYMENTS` off** | Checkout opens, the booking confirms, an invoice is issued — and **nothing is collected**, because every order was created against the bundled test key. Invisible from the UI by design; `/health/env` reports it. | code — `config/payments.config.js` |
| **2.2** | **The payout rail needs deciding — RazorpayX is out** | Client, 2026-09-12: "we are not eligible for razorpay X... They suggest razorpay payroll inside the razorpay to sent payments", and later "razorpay payroll has been configured and kyc verified, you can use same keys". **Payroll is the wrong product and I would not ship it without saying so:** XPayroll pays EMPLOYEES — salary runs, PF, TDS, Form 16 — and hosts are not employees; routing their money through it mischaracterises the relationship and the tax treatment, and its API is built around monthly pay cycles rather than a transfer per booking. **Razorpay Route is the marketplace product** (split and settle to linked accounts, `v2/accounts`) and genuinely does use the Payments keys, which is probably what "same keys" meant. Needs a decision before code. The swap itself is contained: `services/payouts/razorpayx.service.js` plus two call sites (`adminFinance.controller`, `razorpayxWebhook.controller`) — the penny-drop, idempotency and ledger work above it is rail-agnostic. Until then approving a payout fails at the click with "Payouts are not configured". | client call 09-12; product comparison from Razorpay's own docs |
| **2.3** | **`REQUIRE_IMAGE_ALT=true`** | Server accepts an image upload with no description. Both clients have refused to upload without one since build 12; **build 16 is with testers now**, so there is no longer a reason to wait. | code |
| ~~2.4~~ | ~~**`HEALTH_TOKEN` unset**~~ **WRONG — it was set all along** | The 09-05 "verification" read `{"ready":true}` and called the token unset. That bare reply is what the endpoint gives *anyone who does not send the header* — set or not — so it proved nothing. On 2026-09-11 the client ran the probe **with** the token: full report, `dbCutoverSafe: true`, all five DB checks `match`, `FIELD_ENCRYPTION_KEY: true`. Lesson for this file: a probe that cannot distinguish the two states is not a verification. | verified 09-11 — client-run probe with header |
| **2.5** | **Credential rotation** | Deferred by instruction. Everything historic is in git history: DB password, Razorpay secret, Cloudinary secret, Gmail app password. | carried |
| **2.6** | **Google Cloud budget alert** | Maps + Places keys are live and unmetered. | carried |
| **2.7** | **Render Starter ($7/mo) + confirm Clever Cloud backups** | The API is on Render's free tier: 30–50 s cold starts hidden by a keep-alive ping, and a disk that is wiped on deploy (invoices are written there). Starter removes the sleep; Clever Cloud's backup schedule and retention should be confirmed in its dashboard before UAT — it is the only copy of the database. | verified — `KEEP_ALIVE_SETUP.md`; DB 43 MB on Clever Cloud |
| **2.8** | **AWS — Day 1 is written and cannot be applied yet** | Client chose `ap-south-1` and **Terraform over console clicking** (2026-09-13). **Days 1–3** of `AWS_MIGRATION_PLAN_2026-09-11.md` are committed at `infra/terraform/`: VPC, three chained security groups, two shared ECR repositories, RDS MySQL 8, the ACM certificate, ALB with host-based routing, ECS cluster, two services (API at one task, web at two), CloudFront with its own us-east-1 certificate, and a staging workspace. The master password is generated into SSM so nobody ever types it, and **Terraform deliberately does not create the other secrets with placeholders** — `/health/env` reports which names are SET, and a placeholder is set, which is how the last secrets move took production down. An operator supplies them with `infra/scripts/put-parameters.sh`, and `terraform plan` fails BY NAME if one of the four it cannot invent is missing. **Nothing is applied, and nothing can be:** signed into the account, **CloudShell refuses to start — "Your account verification is in progress. This may take up to two days for new accounts"**, and a new account under verification cannot reliably launch resources. The survey it did allow: **1 VPC (the default), 0 databases, 0 ECS clusters** — an empty account waiting on AWS, not on us. When it clears: `terraform init && terraform plan` and read the plan before applying, because the first apply creates a billable, durable database. Still open from §4 of the migration doc: the API hostname (it still answers **404**), DNS, who owns the console after handover, and expected traffic (sizes RDS). **Root-user actions still outstanding (2026-09-13):** MFA on root is done, but **"IAM user and role access to billing information" is still OFF** — re-checked, and Account, Contact information and Payment preferences all still refuse for the IAM user, which is why nobody can see the verification state from `sumit`. That switch is root-only (account menu › Account › Edit › Activate IAM Access). The user already holds `AdministratorAccess`, so it was never a policy problem. The account is 48h+ old against AWS's own "up to 24 hours", so activation is stuck rather than slow: **raise a free Account and Billing case from ROOT** (Support › Create case › Account and billing › Account › Activation). Usual causes are a card that has not authorised — Indian cards often need international transactions or an e-mandate enabled — or an unanswered identity/phone check in the root mailbox. Also worth root's time while there: a budget with an alert (needs the switch above first) and MFA on `sumit`, whose console access is enabled without it. Credentials never come to us — GitHub OIDC preferred, and `sumit` has no access key yet, so there is nothing long-lived to leak. | verified 09-13 — console survey as an IAM user; `infra/terraform/README.md` |

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
| **3.20** | **"Nearby" still comes back empty on a cold launch — unexplained** | Chasing the client's "properties are not loading", I fixed the permission answer being discarded (§3.19a) and proved it: granting location now fills the screen with "1 home in Gurugram". But a COLD RELAUNCH at the same coordinates still shows "No stays here yet" with the shimmer still running after 16 seconds, while `POST /properties/search` with exactly those coordinates and no filters returns 1 from curl in under two seconds. Every filter the app adds is null or false on a cold start, so the two requests should be identical. I could not close the gap: the release build logs nothing (`appLog` is compiled out) and the emulator's own location stack is visibly unhealthy in logcat (`FusedLocation: stationary throttling engaged`, `DeadObjectException` on the app's registration), so it is a poor witness. **Needs a debug build**, which means uninstalling the release APK and the renter logging in again. Workaround that does work: the search sheet — it lists "Gurugram — 1 stay" and opens it. | reproduced 09-12 on the emulator, builds 86 and 87; curl comparison |
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
| **4.6** | **Test suite to contract standard** | **136 backend tests pass** on `npm test`, **387 app tests** on `flutter test` and **37 web rule files** on `for f in tests/*.test.mjs; do node $f; done` (43 / 138 / — on 09-05; there is no `test:rules` script — the earlier wording here named one that does not exist), but the contract asks for >80% measured coverage, 200+ integration tests, plus load and OWASP reports. No coverage tooling is wired. |
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
- **For the tester, on build 16** (each deploys cleanly and is covered by tests, but needs a signed-in host/guest on a device): #19's merged notification feed matches the website for the same host; the guest count survives "Move to Book at Agreed Price" on a *new* negotiation; airplane mode on host Notifications, guest My Negotiations and host Profile → properties shows "Couldn't load · Try again" rather than an empty state; #13's dropdown focus jump (fixed from the code, never reproduced on the emulator).
- **The app's GUEST side of the negotiation rebuild, on a device.** The host side was driven on the emulator on 09-12 and the shared labelling is under test, but the two guest surfaces that changed — the offer button greying with its reason, and the dated “Listed at” line — have not been seen on a phone. The defect that blocked them is fixed (§3.13, build 82: the 29303 notification now opens the listing), but the deal BANNER still could not be tapped, because the test guest has no live deal and cannot make one on 29303 until midnight — the same-day decline lockout, working as designed. Both surfaces are covered by `negotiation_lock_test` and `offer_ceiling_test` and both are verified on the website; what is unproven is the app rendering them.
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
3. **A count from a grep is a lower bound.** The web catch sweep was "18 sites"
   until an AST rule found 37; the "14 listings approved" note was 4 in the DB.
   When a number goes into this file, measure it with the tool that cannot be
   fooled by formatting — a lint selector, a guard test, a `COUNT(*)` — and say
   which one.

Detailed context: `Delivery_Delay_Analysis_2026-09-05.docx` (why the date slipped, and what changes) · `Deployment_Options_2026-09-05.docx` · `PROACTIVE_FINDINGS_2026-09-05.md` · `SEO_CMS_PHASE1_TASKLIST.md`
· `AAJOO_SECTION0_TASKLIST.md` · `CONTRACT_COMPLIANCE_CHECK.md` ·
`CLIENT_INPUTS_REQUIRED.md` · `RENDER_ENV_CHECKLIST.md` · `PAYOUTS_SETUP.md` ·
latest `SESSION_HANDOFF_*.md`.
