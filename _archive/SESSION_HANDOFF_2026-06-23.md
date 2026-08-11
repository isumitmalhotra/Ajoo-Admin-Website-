# AajooHomes — Session Handoff (2026-06-23)

> v1 live UAT prep. Test mode. 3 repos, auto-deploy on push to `main`
> (FE → Vercel, BE → Render). DB = Clever Cloud (via Render).

---

## TL;DR — where we are
Everything needed for a **host-first, end-to-end live money-trail test** is built, pushed,
and deployed. Next action is **yours**: run the UAT in [UAT_TEST_PLAN.md](UAT_TEST_PLAN.md)
on production and send back the results table.

**Latest deploys**
| Repo | HEAD | Note |
|---|---|---|
| Frontend `aajao-frontend-vercel` | `46fd152` | footer key fix (tip) · `68e5240` host Add Property · `0a627af` GST checkout |
| Backend `aajaoBackend-render` | `19ddb92` | host property creation · `c23ca7a` GST + FMS wiring · `b10e682` booking guards |
| Monorepo `ajoo admin website` | (docs, uncommitted) | UAT + timeline docs live as working files |

---

## What we did this session

### 1. Delivery timeline + task docs (client-ready)
- [WEB_DELIVERY_TIMELINE_CLIENT.md](WEB_DELIVERY_TIMELINE_CLIENT.md) and
  [FULL_PLATFORM_DELIVERY_TIMELINE_CLIENT.md](FULL_PLATFORM_DELIVERY_TIMELINE_CLIENT.md) —
  client-facing, **no mention of AI/internal tooling**, Play-Store review time noted as
  external/outside our control, "stabilization support" line removed.
- Internal versions: [WEB_COMPLETION_TIMELINE.md](WEB_COMPLETION_TIMELINE.md),
  [FULL_PLATFORM_COMPLETION_TIMELINE.md](FULL_PLATFORM_COMPLETION_TIMELINE.md).
- Consolidated task list built from all docs + pipeline.

### 2. Live bug fixes (the 3 from screenshots)
- **Fake "Sort: Recommended"** → real sort (price asc/desc) + **Airbnb-style category bar**
  (`PageHeaderWithCategories.tsx`, `PropertyListing.tsx`).
- **Filters drawer SEARCH did nothing** → wired apply (`SidebarFilters.tsx`, `MapandFilter.tsx`).
- **Hero search bar overlapping Prebooking/Luxury buttons** → spacing fixed.

### 3. Phase 3 UI polish (all shipped)
Announcement sliders (home + host dashboard, placeholder content), profile-summary sidebar,
Change Password + Delete Account wiring, ID-upload UX (landscape enforce + dedupe),
admin Reports Center, real social icons, cancel-result page, become-a-host wiring,
**forgot-password real 3-call flow**, footer link fixes.

### 4. Indian GST model (correct slabs) — `c23ca7a` / `0a627af`
- **Accommodation GST by per-night tariff:** ≤ ₹7,500 → **5%**, > ₹7,500 → **18%**
  (`utils/methods.js calculateBookingtax(amount, perNightTariff)`; FE `FinalBookingPage` matches).
- **Commission 15%**, **GST on commission 18%**, host net = subtotal − commission − commissionGST.
- TCS deferred.

### 5. Booking → Finance wiring — `c23ca7a`
- New `utils/financeRecorder.js`: on verified payment writes **4 ledger rows**
  (GUEST_PAYMENT / PLATFORM_COMMISSION / HOST_EARNING / TAX_COLLECTED), a
  **BOOKING_RECEIPT invoice**, and a **QUEUED payout**. Best-effort, post-commit, never throws.
- Verified live against the DB, then cleaned up.

### 6. Mock/demo data removed
- DB demo seed `--clean`ed (ledger/payouts/invoices/recon emptied).
- Frontend mock flags env-gated/inert. Dashboards now populate **only from real actions**.
- Fixed finance render bugs exposed by this: `FinanceStatusChip` null-safe; list slices read
  `data.items`; `financeContracts.ts` normalizers read **raw columns** (`fl_*`, `po_*`, `inv_*`, `rr_*`).

### 7. Booking safeguards — `b10e682`
`/booking/create` rejects (1) date-overlapping booking on a property with an active reservation,
(2) a 2nd active pay-on-arrival booking per user. Fail-open; toast on 400.

### 8. ⭐ Host "Add Property" — the headline build — `68e5240` (FE) / `19ddb92` (BE)
- New page `src/pages/host/HostAddProperty.tsx` at **`/host/add-property`** (HostRoute), host
  sidebar link repointed (was the admin-only form that bounced hosts).
- Full form: details + description, category chips (live), luxury, pricing (GST hint) + capacity,
  location (address geocode / current location / lat-lng), amenities, rules, contact, multi-photo.
- Posts multipart to `POST /properties/add` with host token.
- Backend: `addProperty` now sets `is_active` + `is_verify` → **listings go live immediately**;
  schema given optional pass-throughs (category/tag/amenities/contact/email/inTime/outTime/etc.)
  so the validation middleware doesn't strip them.
- **Verified live:** host token → created property → appeared in Goa search → cleaned up.
  Form renders for a host.

### 9. UAT plan
[UAT_TEST_PLAN.md](UAT_TEST_PLAN.md) rewritten around the live money-trail; **Part 1 Step 1 is now
host-driven** (host creates + lists from the portal). Also: [GO_LIVE_CHECKLIST.md](GO_LIVE_CHECKLIST.md).

---

## Current state / what's running
- All three flows wired: **host creates property → renter books + pays (test) → shows in
  Host + Finance + Admin** with correct GST + commission + host net.
- Test accounts (shared — don't break): admin `admin@mailinator.com / Admin@123`,
  host `aajoo.host1@mailinator.com / Host@12345`, renter `aajoo.renter1@mailinator.com / Renter@12345`.
- Test mode: OTP `000000`, Razorpay card `4111 1111 1111 1111`, KYC bypassed.

---

## NEXT SESSION — pick up here

### Immediate (yours)
1. **Run the UAT** (`UAT_TEST_PLAN.md`) on production, host-first. Most valuable checks:
   **P1-3 GST at checkout** and **P1-5 Finance numbers tie out**. Send the results table back.

### Then (driven by UAT results)
2. Fix whatever the UAT surfaces (esp. GST display / Finance ledger consistency).
3. Decide TCS for registered hosts (currently deferred).

### Blocked until client provides creds (do NOT do for test-mode v1)
4. **Phase 4 production cutover** — revert dev bypasses + swap live creds. Tracked in
   [GO_LIVE_CHECKLIST.md](GO_LIVE_CHECKLIST.md) (DEV-BYPASS inventory: OTP bypass, doc-verify
   bypass, signup doc fields optional). **Running these now breaks testing** — only at real go-live.
5. **DIDIT KYC + live Razorpay keys** — blocked on client (see [KYC_DIDIT_INTEGRATION.md](KYC_DIDIT_INTEGRATION.md)).
6. **Email OTP delivery** — see [EMAIL_OTP_DELIVERY_PROPOSAL.md](EMAIL_OTP_DELIVERY_PROPOSAL.md).

### Known constraints / gotchas (so next session doesn't re-trip)
- Booking dates → backend wants `DD-MM-YYYY`; must be future **and within ~3 months**.
- Server clock runs ahead of harness "today".
- `/properties/search` nests under `data.property`.
- Validation middleware strips any field not in the Yup schema — add pass-throughs.
- `/properties/delete` + `/properties/inactive` use a different id field than `propertyId`
  (cleanup via DB if needed).
- Don't do a real password reset / account delete / 2nd booking on shared test accounts.

---

## Key files touched (reference)
**BE:** `utils/methods.js`, `utils/financeRecorder.js` (new), `controllers/booking.controller.js`,
`controllers/property.controller.js`, `schema/properties.schema.js`.
**FE:** `src/pages/host/HostAddProperty.tsx` (new), `src/App.tsx`,
`src/components/layout/HostSidebar.tsx`, `src/pages/user/FinalBookingPage.tsx`,
`src/services/financeContracts.ts`, `src/components/admin/finance/FinanceStatusChip.tsx`,
`src/components/layout/Footer.tsx`, 6 finance list slices.
