# AAJOO — Release Candidate Task List

From the seven documents shared 2026-08-29 (`Hii.docx` + 6 PDFs). Written to answer the
client's actual ask: **Finding ID → Fix implemented → Developer tested → Status**.

| | |
|---|---|
| Finding IDs across all docs | ~200 |
| Client's release position | 🔴 BLOCKED on all four surfaces (Web, Admin, Backend, APK) |
| Repos | `aajao-frontend-vercel` (web + admin UI), `aajaoBackend-render` (API), `aajoo_app_2026` (Flutter) |

---

## 0. Read this first — what these documents actually are

`Hii.docx` is explicit that these are **layers of one product**, not competing requirements.
They fall into three different kinds, and conflating them is the main risk:

| Kind | Documents | How to treat it |
|---|---|---|
| **Reference** (what the product *is*) | Business Model, POC/Design | Do not implement from these directly. Use to settle disputes. |
| **QA findings** (what is *broken*) | Website Guest/Host, Admin QA, APK, Host List Property | The action list. Each has a finding ID. |
| **Spec changes** (what must be *built differently*) | **Pricing Architecture**, Host Listing SEO Publish Fix | ⚠️ These are **new/changed scope**, not bug fixes. Sized separately below. |

**The single most important thing in the pack is not a bug.** It is
`Aajoo Homes Pricing Architecture.pdf`, which redefines pricing (§W2). Everything downstream —
negotiation, booking, payment, refunds, host earnings, commission — computes off it. It has to
be settled before the flows that consume it are "fixed", or they get fixed twice.

---

## 1. Findings I verified in code today

Not restating the client's claims — these were checked against the actual source.

| ID | Client's claim | Verified | Evidence |
|---|---|---|---|
| ADM-P0-01 | Finance routes lack RBAC | ✅ **True, worse than stated** | Only **3 of 27** routes in `adminFinance.routes.js` use `requireRole`. 24 are `adminAuth` only. |
| ADM-P0-02 / PROD-01 | Razorpay TEST creds bundled | ✅ **True, in two places** | `rzp_test_XUTODhUdMAshi6` hardcoded as fallback in `config/db.config.js:64` **and** `config/payments.config.js:22`. |
| ADM-P0-03 / PROD-02 | CORS allows all origins | ✅ **True** | `app.js:59` `origin: true` (HTTP); `app.js:295` `origin: "*"` (Socket.IO). Both carry a "consider restricting in production" comment. |
| ADM-P0-04 / DB-01 | RBAC storage incomplete | ✅ **True** | `tbl_admins` has only `admin_isAdmin`, `admin_isActive`. No finance/support role column exists. |
| ADM-P1-01 | Rate limiter reads wrong claim | ✅ **True** | `middleware/rateLimiter.js` uses `req.admin?.id` in 3 places; tokens carry `adminId`. Per-admin buckets silently fall back to per-IP. |
| PROD-05 | `/db-test` exposed | ✅ **True** | `app.js:241` public. `/health/env` at `app.js:195`. |
| WEB-P0-01 | `/property/detail/undefined` reachable | ✅ **True, root cause found** | Legacy components still emit these links: `FeaturedProperties.tsx:182`, `HomePropCard.tsx:291` (`id != null` guard is wrong — `undefined` string still routes), `HotelTooltip.tsx:39`. |

**Read-across:** every one of the seven spot-checks was accurate. Treat the rest of the client's
findings as credible-until-disproven rather than re-litigating them.

---

## 2. Already done — claim these against finding IDs

Work completed in recent sessions that closes findings already. **Needs regression evidence, not
new development.**

| Finding IDs | What exists | Status |
|---|---|---|
| G-09, G-10, G-12 | Location search rebuilt on our own place index; date/guest params carried | ✅ Shipped 2026-08-29 (`a94b789`/`7cc46b3`) |
| G-11 | Guest count validated against host capacity server-side | ✅ Shipped |
| G-20 (partial) | Tax-inclusive totals, backend-computed | ✅ Shipped |
| N-01…N-11 (partial) | REST negotiation engine: offer → host decide → coupon → checkout | ⚠️ Partial — see §W3 |
| H-16…H-21 | Host calendar, block/unblock, occupancy rules | ✅ Shipped 2026-08-18 |
| H-34…H-40 (partial) | Payouts: RazorpayX, penny-drop, AES-256-GCM | ⚠️ **Built, blocked on 4 env vars** |
| SEO-03, SEO-10, SEO-11 | robots status rules, sitemap filtered to indexable | ✅ Shipped 2026-08-28 |
| SEO-04, SEO-05 | Slug uniqueness at DB level; slug change auto-creates 301 | ✅ Shipped 2026-08-28 |
| SEO-07 | Self-canonical absolute HTTPS | ✅ Shipped 2026-08-27 |
| WEB bugs #1,#4,#5,#6,#7 | From `Aajoo Homes.xlsx` | ✅ Shipped 2026-08-29 |

---

## 3. Workstreams

Ordered by **what unblocks what**, not by severity alone.

### W0 — Production hardening `~2–3 days` · do first, cheapest risk reduction

Nearly all config, no product logic. Unblocks the client's "production/test separation" gate.

| Task | Finding IDs |
|---|---|
| Remove both hardcoded `rzp_test_` fallbacks; production **fails closed** without live keys | ADM-P0-02, PROD-01, P0-02, BE-01 |
| Restrict CORS + Socket.IO origins to approved domains | ADM-P0-03, PROD-02, PROD-07, SEC-08 |
| Remove/protect `/db-test`; restrict `/health/env` | PROD-04, PROD-05, SEC-10 |
| Split liveness vs readiness; refuse traffic when DB/config unhealthy | ADM-P0-06, PROD-03 |
| Fix admin rate limiter to use `adminId` | ADM-P1-01, PROD-08 |
| Centralised log redaction (OTP, tokens, payment signatures, KYC, PII) | P0-05, SEC-06 |
| Private uploads off public static; authorised retrieval only | P0-08, PROD-06, SEC-05, H-06 |
| **Set the 4 missing Render env vars** (payouts already blocked on these) | — |

> ⚠️ Memory flag: *Render env is NOT correctly set (verified)*. This is a standing blocker that
> W0 finally forces to be resolved.

### W1 — Authorization & RBAC `~1 week` · cross-cutting, blocks sign-off

| Task | Finding IDs |
|---|---|
| Canonical role/permission storage (admin/finance/support/host/guest) replacing `admin_isAdmin` | ADM-P0-04, ADM-P1-02, DB-01 |
| Apply RBAC to all 27 finance routes + negative tests per role | ADM-P0-01, ADM-P1-04 |
| Admin creation route requires authenticated super-admin | ADM-P1-03 |
| Object-level ownership on every guest/host/admin ID | SEC-01, SEC-02, G-21, H-09, H-15, H-22, H-36, BE-04, BE-05, ADM-P1-06 |
| Server-side session revocation on logout + 60-min access token + 30-min inactivity | G-03, G-04, P0-06, P1-01, P1-02, SEC-04 |
| **Deliverable: endpoint × role authorization matrix** (client asked for this explicitly) | — |

### W2 — Pricing engine ✅ **DONE · live 2026-08-29** · see `W2_PRICING_ENGINE_COMPLETION_2026-08-29.md`

`Aajoo Homes Pricing Architecture.pdf` is a redesign, not a fix:

- **3 price levels × 3 periods** per property: Min/Ideal/Max × Night/Week/Month (9 values).
  Today we store nightly + weekly + monthly rates — **not** the min/ideal/max triple.
- **Composite period maths**: 12 nights = 1 week + 5 nights, computed at each of the three levels.
- **Guest only ever sees Maximum/List.** Min and Ideal must never leave the server.
- **Advance Booking is a second booking mode** — no negotiation, a discount instead, **10% deposit
  after discount**, remainder later. This does not exist today at all.
- **One engine, two experiences.** Frontend must never compute the final price.

| Task | Finding IDs | Fix | Tested | Status |
|---|---|---|---|---|
| Schema: min/ideal/max × night/week/month + migration | LP-P0-09, H-11 | 4 tier columns on `property_pricing`; absent tiers derive by scaling the period Max by the nightly ratio, so no backfill | migration applied + columns verified on the live DB | ✅ Done |
| Server pricing engine returning a full breakdown; UI renders only | G-20, SEC-03, P-01 | `utils/pricingEngine.js` (pure, composite months→weeks→nights) + public `POST /pricing/quote` | `tests/pricingEngine.test.js` pins the document's own worked example (45,000/53,000/62,000); endpoint verified live | ✅ Done |
| Host Step 4 collects the 9 values with validation | LP-P0-09 | Weekly/monthly **prices** replace the inert percentage discounts; per-period min/ideal fields; `min ≤ ideal ≤ price` enforced server-side | `tsc -b` + production build; server rejects a tier for an unpriced package | ✅ Done |
| Guest APIs never expose min/ideal | N-02, LP §6 | Internal tiers live under an `internal` block no response builder touches; quote response is built field-by-field | `tests/pricingQuote.test.js` fails the build if the controller ever mentions it; live payload checked | ✅ Done |
| Negotiation threshold moved to the **ideal**; above-list refused server-side | (product decision) | `decideOffer` rewritten; dated offers judged against composite tiers for those dates; ledger snapshots the tiers used | `tests/negotiationEngine.test.js` 24/24; four decision branches verified against live data | ✅ Done |
| 10% deposit + remaining balance, its own payment states | P1-09 | On **every** booking (product decision, wider than the doc): deposit order, balance endpoint, check-in gate, payout held PENDING, refunds against money received, reminders at 7/3/1 days | `tests/bookingDeposit.test.js` 14/14; live deposit booking on production produced a ₹1,575 order on a ₹15,750 stay and a ₹15,750 balance order | ✅ Done |
| Advance Booking as a **separate discounted mode** | P1-09 (remainder) | Schema column + Step 4 field ship; nothing reads the discount yet | — | ⏸ Deferred — every future-dated booking already gets the deposit option |
| Property page renders the quote endpoint's numbers | G-20 | Checkout is server-authoritative; the property page still draws its own breakdown | — | ⏸ Deferred — must not blank a price if the endpoint hiccups |

> **Decision taken:** the 10% deposit shipped in *this* release, on every booking rather than only
> Advance Booking. Advance Booking as a separate discounted mode is deferred.

### W3 — Negotiation completion ✅ **DONE · live 2026-08-30**

| Task | Finding IDs | Fix | Tested | Status |
|---|---|---|---|---|
| Auto-accept without host action | N-03, P1-06 | Shipped in W2 Phase C — threshold is the **ideal**, not the minimum (your correction) | 24/24 engine tests; live on 29262 | ✅ Done |
| Below-threshold escalation → Accept/Counter/Decline | N-04, N-05 | Already existed; host mail now distinguishes below-target from below-floor | live | ✅ Done |
| Negotiated price as the authoritative booking price | N-06, P1-08, E2E-05 | Already existed — accepted price becomes a personal coupon, recomputed server-side at checkout | live | ✅ Done |
| Expiry honours the host's own window | N-07…N-10 | `pn_expiry_hours` was collected by Step 4 and read by nothing; every offer expired on one global 30-min timer | sweeper run live; 29262 now reads its real 24h window | ✅ Done |
| Duplicate offers | N-07…N-10 | One live offer per guest per stay; a host's unanswered counter also blocks a fresh offer | live: 2nd offer → 409 | ✅ Done |
| Attempt cap | H-32, H-33 | `pn_max_attempts` (default 3) was collected and never enforced — a guest could offer forever | live: 4th attempt → 429 | ✅ Done |
| Concurrency | N-07…N-10 | Guards + round number now come from one `FOR UPDATE` read of the thread; degrades rather than fails if that read errors | source-pinned | ✅ Done |
| Full audit with pricing snapshot | N-11, §10 Admin | `tbl_negotiation_log` was written from day one and **read by nothing**. New `GET /admin/negotiations/audit` + a decision-history panel under each negotiation | live: 31 events, snapshots intact | ✅ Done |
| "If Minimum not configured → negotiation OFF" | Pricing §17 | Still true, **and** the host's own `pn_enabled` switch is now honoured — it had been read only inside the no-minimum branch, which the pricing backfill made dead code | live: switch flips off and back | ✅ Done |

### W4 — Booking, payment, cancellation integrity `~1–1.5 weeks`

| Task | Finding IDs |
|---|---|
| One authoritative transaction: availability → booking → payment → verify → confirm | WEB-P0-04 |
| Idempotent payment verification; replay-safe webhooks | P-03, P-04, P-07, P0-09, E2E-10 |
| Availability race — two guests cannot book the same dates | G-19 |
| Cancellation: policy shown → **OTP** → server-side refund calc → state lock | WEB-P0-05, C-01…C-06, P1-04, P1-05 |
| Cancellation policy field on host form (Flexible/Moderate/Firm/Strict/Super Strict) | `Hii.docx` §8 |
| Refund/ledger reconciliation | E2E-02, DB-05 |

### W5 — Host listing 5-step + publish lifecycle ✅ **DONE · live 2026-08-30**

| Task | Finding IDs | Fix | Tested | Status |
|---|---|---|---|---|
| Server-enforced state machine Draft → Submitted → Approved → Live | LP-P0-01, LP-P0-02 | `utils/listingLifecycle.js` — one reader over the four columns the state actually lives in, one transition table. `adminReview` and `submitListing` both ask before they write | 18 tests; live: the two genuine empty drafts are now refused approval | ✅ Done |
| Backend completeness gate | LP-P0-01 | Readiness ≥ 70 was checked at submit only; it is now **re-checked at approval**, where it matters, since a listing can be edited for days in between | live: queue reports the score per row | ✅ Done |
| Verification checked server-side | LP-P0-08, LP-31…LP-37 | Host identity gate at submit already existed; approval now refuses an incomplete listing regardless of who is clicking | live | ✅ Done |
| Structured category attributes | LP-18, LP-19 | Already satisfied — `property_attributes` is key/value rows (`pa_group`/`pa_key`/`pa_value`), not a JSON blob, so search and SEO can filter on it | — | ✅ Already true |
| Category switch clears incompatible attributes | LP-P0-03, LP-13 | Attributes are stored per category (`pa_group`); switching now drops the other categories' groups and only those — `step3` shares the table and is left alone | 21 tests; live: no listing currently carries a stale group | ✅ Done |
| Capacity consistency + operational status rules | LP-P0-05, LP-P0-06, LP-P0-07, LP-27 | `utils/listingCapacity`: adults **plus children** against the total (infants excluded), a bed per bedroom, somewhere to sleep the guests advertised, no negatives. Seasonal properties must name their months — declared in the schema since it was written, enforced nowhere. Required photos were already covered by the readiness score | live: all 20 existing capacity rows pass; a 2-adult + 4-child party in a 2-guest place is refused | ✅ Done |
| Draft resume without duplicate properties | LP-11, LP-12 | Two halves: a shell carrying nothing (still "Untitled listing", never past step 1) is recycled instead of duplicated, and `GET /listing/my-draft` reports the open draft so the wizard can offer **Continue it / Start a new one**. A reader, not a redirect | live | ✅ Done |

**Behaviour changes to flag for your tester:**

- An admin can no longer approve a listing the host has never submitted, nor
  suspend one that is not on the site. The review panel shows only the
  decisions the listing's state accepts.
- Step 1 now refuses a capacity that does not add up, and a seasonal property
  with no months. Every listing already in the database passes these.
- Changing a listing's category **deletes** the previous category's answers.
  That is the point — they were invisible in the wizard and still being read by
  search and SEO — but it is not reversible from the form.
- A host opening the wizard with an unfinished listing is offered it rather
  than silently starting a second one.

### W6 — SEO on approval ✅ **DONE · live 2026-08-30**

| Task | Finding IDs | Fix | Tested | Status |
|---|---|---|---|---|
| **Trigger generation on Admin approval** | SEO-01, SEO-02, LP-P0-10, LP-40 | One `writeSeoFor` serves submit AND approval; approval regenerates from the state as it stands then, wrapped so a slug clash cannot leave a host approved-but-not-live | live: 29262 was stored as "Malhotra Villa in Karnal" while actually renamed "Test Villa Manali" — approval rewrote it | ✅ Done |
| Regenerate metadata + sitemap `lastmod` on edits to a live listing | SEO-12 | Checked rather than assumed, and already correct: the model writes `updated_at`, which is what the sitemap reads for `lastmod`, and a host editing a live listing re-runs the writer at submit | live | ✅ Already true |
| Fallback meta title/description — never blank/undefined | SEO-06 | A nameless listing produced the meta title `undefined in India \| Aajoo`; it now falls back to what the listing IS ("Cottage in Jibhi"). An empty slug or path used to collapse to `/` — the homepage — and now falls back to the property id | 13 tests; no stored row carried the bug | ✅ Done |
| Schema only from real data; no fabricated reviews/ratings | SEO-08 | Already clean — no `aggregateRating`, `ratingValue` or `review` anywhere in the generated schema. Pinned by a test so it stays that way | ✅ | ✅ Already true |
| Image ALT from category + property, ≤125 chars | SEO-09 | Images went out as a bare URL, unlabelled to a screen reader and to image search alike. Each now carries category · name · place, capped at 125 and cut on a word | tested | ✅ Done |
| Invalid property ID → real 404/410, never `undefined` in URL | WEB-P0-01, G-18 | Already handled: a missing or unpublished listing resolves as `noindex, follow` with its own copy rather than inheriting the homepage's title, and the page has a `loadFailed` state for people | live: id 9999999 → `found:false`, `noindex, follow` | ✅ Already true |

**Worth knowing:** three of the six were already correct. They are marked
"already true" rather than quietly ticked, because each was verified against
production before being called done.

### W7 — Admin control plane ✅ **DONE · live 2026-08-30**

| Task | Finding IDs | Fix | Tested | Status |
|---|---|---|---|---|
| Persistent mutation audit table | ADM-P0-05, DB-02 | `logAdminMutation` was called from **58 places** and wrote a log line and nothing else — on Render that stream rotates away. New `tbl_admin_audit`; adding it made all 58 durable with no call site changed. Admin name/role denormalised (looked up once, cached) so a row stays readable after the account is renamed or deleted. Snapshots clipped at 8k by the writer. The write never throws — a gap in the ledger beats a refused refund | live: a real admin property update landed with its full before-snapshot | ✅ Done |
| Finance: rejection reasons, void reasons, idempotency | §9 Finance | **Not one mutation in `adminFinance.controller` was audited**, in the file that handles payouts, refunds and voids. Voiding an invoice and rejecting a payout both took an `undefined` reason, answered "success" for an id that did not exist, and could be done twice — the second overwriting the first person's reason. Both now require a reason, check the record exists, are idempotent and are audited. A payout already **paid out** can no longer be rejected: the money has left, and marking it FAILED would make the ledger disagree with the bank | live: nonexistent invoice → "Invoice not found"; nonexistent payout → "Payout not found" | ✅ Done |
| Soft-delete consistency across admin + public queries | DB-04, E2E-12 | All three delete paths wrote `is_deleted` and left `is_active = 1`. Nothing was leaking — every reader checks the pair — but the row sat one half-written query from visible. All three now write both; two production rows normalised | 25/25 tests; a test pins all three paths | ✅ Done |
| Negotiation control plane: identity from ownership not last sender | §10 | Already correct — `adminNegotiationsList` decides guest/host by **who owns the property**, not who moved last, with a comment explaining that a haggle alternates. The W3 decision ledger sits under it now | ✅ | ✅ Already true |
| KPI ↔ list-screen population reconciliation | §8 Dashboard KPI | Users, hosts, properties and bookings were reconciled in an earlier pass — **verified against their list screens on production** rather than taken on trust: 26=26, 7=7, 29,245=29,245, 56=56. The fifth tile was wrong: "Pending review" counted `is_verify = 0`, a value that column never holds, so it was structurally always zero while the review queue had work in it. It now counts the queue's own population | live: tile reads 2, matching the queue | ✅ Done |
| Support/dispute separation from compliance flags | DB-03, §11 | The Disputes screen was backed **entirely** by `tbl_admin_flags` — KYC holds written by the verification flow, none of them a customer dispute — so "resolving a dispute" lifted a regulatory hold on a host, and the resolution note **overwrote** the reason the hold was raised. The two populations are now returned and rendered separately (`compliance_flag` / `support_ticket`) with their own counts, the screen is retitled "Compliance & moderation", and resolving appends rather than erases. No customer-dispute table was invented: nothing raises one yet, and an empty table would only hide the gap | live: 5 open holds, 1 support ticket, counted apart | ✅ Done |

**Behaviour changes to flag for your tester:**

- Voiding an invoice or rejecting a payout now requires a written reason (5+
  characters) and cannot be repeated; a **completed** payout cannot be rejected
  at all.
- Deleting a listing now also deactivates it.
- The "Disputes" screen is now "Compliance & moderation" and lists support
  tickets separately beneath the holds.
- The dashboard's pending-review tile now shows a real number (it was always 0).

**Still missing, and worth naming:** there is no customer-dispute feature at
all — no guest-facing way to raise one, and no table behind it. What existed
was a compliance queue wearing the word. Building disputes properly is its own
piece of work, not a W7 fix.

### W8 — Android APK ✅ **DONE · 2026-08-30**

| Task | Finding IDs | Fix | Status |
|---|---|---|---|
| Production config: no dev host, no `rzp_test_` in a release build | P0-01, P0-02 | `ApiConstants` collapsed to one value with `--dart-define=API_BASE_URL`. `PaymentConfig` now reports `isTestKey` / `usableForPayments` / `collectsMoney`, and all five checkout paths refuse to open a sheet that takes no money; `--dart-define=ALLOW_TEST_PAYMENTS=true` is the same escape hatch the backend uses | ✅ Done |
| Remove mock/stub behaviour from guest critical flows | P0-10, FE-10 | The checkout screen showed "Deluxe Suite" and "1 Adults" on every real booking. Room type now comes from the listing's category; the party size row does not render rather than inventing one | ✅ Done |
| Secure token storage | FE-11 | Already `FlutterSecureStorage` — verified, not assumed | ✅ Already true |
| **W2–W7 parity** | — | Two live regressions found and fixed: app cancellation was refused outright (missing OTP), and prebooking recorded stays at a tenth of their price. Plus balance display, capacity rules and seasonal months. Ledger: `WEB_MOBILE_PARITY.md` | ✅ Done |
| TLS validation, no-op buttons, stock images | FE-12…FE-18 | Swept: no empty `onPressed`/`onTap` handlers anywhere in the UI; the only asset images in guest flows are empty-states and a WhatsApp icon. One real dead control found and fixed — "View All" reviews was wired to an empty handler, now expands the list in place | ✅ Done |
| API path/versioning reconciliation with the spec | P1-11 | Audited: all **80** distinct API paths the app calls reconcile against the **370** routes the backend registers. No mismatches, so nothing to fix — recorded rather than assumed | ✅ Done |

**Live-verified:** the `cancel` OTP intent sends a code; a deposit booking through
the app's exact payload charged ₹1,995 on a ₹19,950 stay and recorded the room at
its real ₹19,000. `flutter analyze`: 0 errors.

### W9 — Cross-cutting verification ✅ **DONE · 2026-08-30**

Delivered as something that **runs**, not something somebody remembers doing:

```bash
node scripts/e2eVerify.js
```

**22 checks against the live platform — 22 passed, 0 failed, 0 skipped.**

| Group | Covers |
|---|---|
| E2E-01…E2E-13 | anonymous browse + quote · composite pricing against the doc's worked example · internal tiers never leaving the server · SEO noindex for missing listings · soft-delete invisibility · payment-replay guard · server-authoritative price · negotiation ceiling · deposit charging 10% of the taxed total · a draft that cannot be approved · an incomplete pricing grid refused · logout that ends the session · **the served title naming the listing it describes** |
| SEC-01…SEC-04 | absent/invalid token refused · audit ledger not public · private files not served by guessing · unknown origin denied CORS |
| DB-01…DB-06 | no sub-paisa drift in stored money · paid bookings reconcile (price + tax = total) · nothing over-credited · no half-deleted listing · every one of the 29,230 live listings has a complete pricing grid |

**It found a real bug**, which is the point of having it. W6 made approval
regenerate a listing's SEO into `property_seo` — but the resolver reads
`page_seo` first. Property 29262 was renamed and the live page went on
advertising its old name indefinitely. Checking the generated copy would have
passed; only asking the endpoint the public asks caught it. Fixed, and E2E-13
now guards it.

**Mobile web 320–412px:** homepage and property detail verified in a real
browser at 320px — no horizontal overflow on either.

**Data integrity, measured rather than asserted:** 14 money columns are
`DOUBLE(10,2)` rather than `DECIMAL`. That is the wrong type in principle, so
the harness measures the consequence instead of assuming one — today there is
**no drift**, every paid booking reconciles, and nothing is over-credited.
Migrating 14 columns on a live database mid-testing carries more immediate risk
than it removes; the recommendation is to do it in a quiet window, not now.

**Migrations from an empty database:** covered, and it found a real defect.

```bash
node scripts/migrateDryRun.js
```

There is no scratch database to run them against — the Clever Cloud user holds
ALL PRIVILEGES on one schema and cannot `CREATE DATABASE`, and the machine has
neither a local MySQL nor Docker. So the harness *executes* every migration's
`up()` against a queryInterface that keeps the schema in memory and answers
`describeTable` / `showAllTables` / `information_schema` from it, so guarded
migrations take the same branch they would take for real.

**It found `20250101120004-add-foreign-key-constraints`:** `addConstraintIfPossible`
called **itself** instead of `queryInterface.addConstraint`, and
`removeConstraintIfExists` had the identical fault. On a fresh database it
recurses until the heap dies — the set could not be replayed from zero at all.
On the live database it "succeeded" because every table was still missing when
it ran, so it is marked done and **added zero constraints**; the database has 2
foreign keys, none of them from this migration.

Fixed. Replay now: **136/136 migrations, 107 tables, 0 failures, 0 ordering
problems, all 11 core tables present.** 96 raw SQL statements are reported
UNVERIFIED rather than counted as passing.

**Foreign keys: decided and applied.** The orphan check ran first and found
three rows — two payments pointing at bookings that no longer exist, one
booking pointing at a deleted user. They were backed up, deleted, and the
deletion recorded in `tbl_admin_audit`.

The bigger finding was in the migration itself: **all 64 relationships were
`CASCADE`**. Deleting one user would have taken 29,248 properties and 36
payment rows with them, silently. Rewritten per table — `RESTRICT` for
anything financial or historical (43 of them), `CASCADE` only where the child
row has no meaning without its parent (21: join tables, derived rows, auth
sessions). `pay_bookId` was `TEXT`, which no key can reference; it is now
`VARCHAR(100)` with an index.

**39 constraints active on the live database**, the full E2E suite still
22/22 afterwards, and a real booking + payment written through them.

---

### W10 — Pay-at-property settlement ✅ **DONE · live 2026-08-30**

The gap: on a cash booking the guest hands the whole amount to the host at the
door, so **the platform collected nothing at all** — no commission, no GST on
it, and not the accommodation GST it is liable to remit either. 23 such
bookings already existed.

**The rule, and why it is the only defensible one:** the split does not change
between cash and online. Only the direction of the money does. A ₹27,000 stay
+ ₹1,320 GST leaves the host with ₹22,221 whichever way the guest paid —
identical, to the rupee, to what `splitBooking` credits on an online booking.
What changes is that on cash the host owes the difference back.

| What the host owes | On a ₹28,320 stay |
|---|---|
| Commission, 15% of the room subtotal | ₹4,050 |
| GST on that commission, 18% | ₹729 |
| Accommodation GST the platform must remit | ₹1,320 |
| **Due to the platform** | **₹6,099** |
| Host keeps | ₹22,221 |

**Endpoints** — `GET /host/dues` (what I owe and why, broken down per stay,
plus a settled history), `POST /host/dues/pay`, `POST /host/dues/verify`,
and `GET /admin/host-dues` behind the same finance gate as payouts.

**Recovery, which is the part that actually collects.** A host who ignores the
screen settles anyway: `approvePayout` withholds what they owe *before* the
payout row is claimed and before any money leaves. Oldest dues first, and
partial by design — a payout that cannot cover a due leaves it outstanding at
full value rather than marking it settled for less. Fully-offset payouts are
completed by the offset itself rather than sending a zero-rupee transfer no
provider would accept. Both paths are audited (`payout_offset`,
`payout_offset_in_full`).

**Refusals that matter.** The amount is always the server's own sum of stored
dues — nothing reads an amount from the request, or a host would decide what
they owe. The signature is checked before anything is marked settled. A
verified payment settles only that host's own `PENDING` rows, so it cannot be
replayed onto someone else's balance or the same balance twice. A cancelled
booking voids its due; a cash booking later settled online is not billed twice.

**Verified against production, not asserted:** backfill raised dues on all 23
existing cash bookings — **₹37,479.20 outstanding** across three hosts. The
host view returns ₹11,896.25 payable now and ₹10,465 upcoming over 17
bookings; the admin view agrees on the total. A rehearsed ₹5,000 payout
withheld ₹4,760.28, cleared 4 dues in full, left the 5th whole, and was rolled
back. `tests/hostDues.test.js` — 23/23.

**The screens, added the same day.** Web `/host/settlements` (beside Payouts),
web `/admin/finance/host-dues` (under Finance), and the app's host menu →
Settlements. All three lead with what is payable now, open each stay up to show
the three components, and say what the host keeps — the same rupees an online
booking of that value leaves them, because the fear the screen invites is that
taking cash costs more. The consequence is stated rather than buried: anything
unpaid comes out of the next payout.

Verified in a browser against production data: the host view reads ₹11,896.25
payable / ₹10,465 upcoming over 17 bookings, the admin view ₹37,479.20 across
three hosts, and both agree with the API. Checked at 375px. The app model is
pinned by `test/host_dues_test.dart`, which parses the payload the server
actually sent.

**And a payment was driven through it.** Razorpay test mode, real checkout, host
signed in: order `order_TW1vETzTqLVPe7` → payment `pay_TW1vgIgPR2Ogw4`, netbanking,
**captured**. Ten dues settled for ₹11,896.25; the host screen fell to ₹0 payable and
the admin total from ₹37,479.20 to ₹25,582.95. Replaying that payment settled 0, and
pointing its signature at another host's dues settled 0.

---

## 4. Sequencing

```
W0 hardening ──┬─> W1 RBAC ──┬─> W7 Admin ──┐
               │             │              │
               └─> W2 PRICING ─> W3 Negotiation ─> W4 Booking/Payment ─┼─> W9 E2E
                            └─> W5 Host listing ─> W6 SEO ────────────┘
W8 APK ─────────────────────────────────────────────────────────────────┘ (parallel)
```

**Rough total: 7–9 weeks of focused work**, less if W8 runs on a separate track. This is not a
"fix a list of bugs" exercise — W2 alone is a pricing redesign.

---

## 5. Decisions needed from the client — these block real work

| # | Question | Blocks |
|---|---|---|
| 1 | **Advance Booking (10% deposit) — this release or next?** New booking mode, new payment lifecycle. | W2, W4 |
| ~~2~~ | ~~**Delete the 29,226 seeded listings?**~~ — **the premise was wrong; fixed instead, 2026-08-30.** The coordinates were broadly sound; 7,653 of them were not, and in one specific way — the address was right and the coordinate was not ("ALMORA, Uttrakhand, 263601" pointed at Bihar). Repaired against OpenStreetMap coordinates for the town each listing names: **0 misplaced, median distance from own town 56km → 6km**. No listings deleted. | ~~W9~~ |
| 3 | **Live Razorpay credentials** — production must fail closed without them. | W0 |
| 4 | **Is monthly stay in scope, or removed from the UI?** Client's own doc says do not expose a misleading journey. | W2, W3 |
| ~~5~~ | ~~**Cash/pay-at-property collection**~~ — **done 2026-08-30**, see W10. The platform bills the host their commission + GST on cash bookings, recovers it from their next payout if unpaid, and the screens ship on web host, web admin and the app. Nothing outstanding. | ~~W4~~ |
| 6 | Is the **APK in this release candidate**, or web+admin first? | W8 |

---

## 6. What we owe the client

They asked for a specific artefact. Proposed format, one row per finding ID:

| Finding ID | Fix implemented | Developer tested | Status |
|---|---|---|---|
| ADM-P0-01 | RBAC applied to 27 finance routes | Role matrix, 4 roles × 27 routes | Fixed |
| … | … | … | Fixed / Partial / Deferred / Won't fix + reason |

Plus: web build SHA, backend commit, DB migration version, APK version, known remaining issues.

**Recommendation:** send W0 + W1 as an early partial response with the mapping filled in for those
IDs. It is the fastest way to convert "🔴 BLOCKED" into visible progress, and it is the half of the
pack that is cheapest to close.
