# AajooHomes — Weekend Delivery Plan (Website + FMS + HMS + Admin)

> **Owner:** Sumit Malhotra · **Drafted:** 2026-06-09 (Tue) · **Target ship:** by EOD Sat 2026-06-13 / Sun 2026-06-14
> **Working window:** ~4–5 working days
> **Source of truth:** this file (consolidates `TASK_TRACKER.md`, `MASTER_TASK_TRACKER.md`, `INTEGRATION_TASK_TRACKER.md`, `REDESIGN_TASK_TRACKER.md`, `HMS_SPRINT_PLAN.md`, `FMS_PLAN.md`, and the signed contract `AAJOO Homes_Zyphex Tech Contract Signed.pdf`).
>
> **Scope:** Website (customer-facing web app) + Finance Management System (admin) + Host Management System (admin + host portal) + Admin portal sync. **Mobile/Flutter is out of weekend scope** — it has its own track (see `MASTER_TASK_TRACKER.md`).

---

## 0 · TL;DR for the weekend

**What ships:**
- ✅ Website (customer-facing) — already shipped; one 30-min responsive polish + manual walk.
- ✅ FMS admin frontend — already shipped on `main`; weekend is hardening + mock-flag QA + browser walk + endpoint contract doc handoff.
- 🔄 HMS admin + host portal — frontend pages exist; weekend job is closing the 4 mock-only pages (Statements, Support, Comms, Performance), wiring Profile/Earnings/Bookings to backend where endpoints exist, and locking the contract for the rest.
- 🔄 Admin portal sync — Settings stub, notification center placeholder, and user review submission page must be built. ~1.5 days.

**What does NOT ship by weekend (and why):**
- 🔴 Real FMS backend endpoints (`/admin/finance/*`) — **client/backend blocker** (BLK-01). FE has mocks + contract doc.
- 🔴 Host portal real integration (statements, support, messages, performance, KYC approve/reject) — **backend blocker** (BLK-02, BLK-04). FE has mock fallback + endpoint contract doc.
- 🔴 RBAC claims (admin/finance/host/support/guest) — **backend blocker** (BLK-03).
- 🔴 Live Razorpay swap, real OTP email, Didit KYC live — all gated on client-side credentials.

**Definition of "Weekend Complete":** browser walk of every listed flow renders without errors, build is green, lint ≤ 205 baseline, mock fallback is consistent across FMS + HMS, and a single API-contract handoff doc lists every endpoint the backend team needs to deliver for FE to flip from mock → real. Real-backend cutover is a **separate milestone** that lands when BLK-01/02/04 resolve.

---

## 1 · Reality snapshot — what's actually in the code vs what trackers claim

Five tracker docs exist; they disagree because each was written for a different track. Resolution below.

### 1.1 Tracker → reality map

| Tracker | Scope it actually covers | Verdict |
|---|---|---|
| `MASTER_TASK_TRACKER.md` | Mobile app (Flutter) + shared backend + KYC. **No FMS / HMS sections.** | Authoritative for mobile + KYC. **Not authoritative for this weekend's scope.** |
| `TASK_TRACKER.md` | Contract-aligned (FMS / HMS / admin / web). | **Authoritative for this weekend.** Most aligned to the signed contract. |
| `INTEGRATION_TASK_TRACKER.md` | Backend integration + auth history (mobile-focused). | Historical detail only. Superseded by MASTER. |
| `REDESIGN_TASK_TRACKER.md` | Sand & Indigo redesign phases A + B. | Done — Phase A1–A7 ✅ (web), B0–B5 ✅ (mobile). |
| `HMS_SPRINT_PLAN.md` (Apr) | HMS sprints 0–5. | Largely superseded by `TASK_TRACKER.md § E.2`. Read for HMS sprint shape; ignore status. |
| `FMS_PLAN.md` (Mar) | FMS architecture + 27 tasks. | Architecture still valid. Backend strategy section still aligns with what's needed. |
| Contract PDF | Signed scope: ₹1,60,000, FMS + HMS full implementation, ~10–12 weeks. | Source of truth for **what** must be delivered. Weekend is partial against this. |

### 1.2 Track-by-track — code reality vs claims

#### Website (customer-facing, `src/pages/user/*`, `src/components/frontend/*`)

| Item | TASK_TRACKER says | Code reality | Action |
|---|---|---|---|
| Sand & Indigo redesign (Part A) | ✅ A1–A6 + A7 QA sprint done | ✅ Commits `6496c68`, `8fa1c1a`, `b383d2e`, `ce89858`, `749537e`. Lint -5 below 205 baseline. | Manual walk only. |
| Become-a-Host page | ⬜ GAP-01..03 pending | ✅ Connected 2026-06-03 (Obs #789). Route `/become-a-host` → `BecomeHost`. | Verify form fields render; check responsive. |
| User review submission `/user/review/:bookingId` | ⬜ GAP-09/10 | ⬜ No route; nav exists pointing to it. **Real gap.** | **Build this weekend.** |
| Mobile responsive (A2.5-42) | ⬜ partial | Nav 14/20, grid 2-col, hero hide ✅; full sweep ⬜ | 1-hr polish pass + 375px walk. |
| Funnel walk Home → Listing → Detail → Checkout → Confirmation | ⬜ A3-10, A6-04 | Last gstack walk 2026-06-06 surfaced 28 bugs — all fixed. | One fresh walk Saturday. |

#### FMS (Finance Management System — admin)

| Item | TASK_TRACKER says | Code reality | Action |
|---|---|---|---|
| All 15 FMS pages | ✅ P4-FMS-01..05 delivered | ✅ All 15 `.tsx` files in `src/pages/admin/finance/`, line counts 184–536 — substantive, not stubs. | None — just walk. |
| 17 Redux slices | ✅ | ✅ All present in `src/features/admin/finance/`. | None. |
| Routes wired | ✅ | ✅ `App.tsx:172–187` — 15 routes under `/admin/finance/*`. | None. |
| Sidebar entries | ✅ | ✅ `AdminSidebar.tsx:53,92` — Finance group with 5 sub-items. | None. |
| India compliance helper (GST/TDS/INR) | ✅ P4-FMS-06 | ✅ `src/pages/admin/finance/utils/`. | None. |
| Mock-vs-real data flow | (not tracked) | DEV mocks gated by `VITE_USE_FINANCE_MOCKS=true`; slices call `fetchFinanceDashboard` etc. | **Verify the toggle works in both modes; document for backend handoff.** |
| Smoke + staging runners | ✅ `scripts/financeSmoke.js`, `scripts/financeIntegrationStaging.js` | ✅ files exist. | Run smoke once. |
| Backend `/admin/finance/*` endpoints | 🔴 P4-FMS-07/08/09, INT-03 (BLK-01) | 🔴 Backend has not implemented these yet. | **Not weekend scope** — author API contract doc instead. |

**FMS verdict:** frontend is **complete**; weekend job is QA + handoff doc, not new code.

#### HMS (Host Management System)

**Host portal frontend** (`src/pages/host/*`)

| Page | Slice? | Wired to backend? | Mock indicators in file | Action |
|---|---|---|---|---|
| `dashboard.tsx` | ✅ `hostDashboard.slice` | ✅ `fetchHostDashboard` | `RECENT_ACTIVITY` hardcoded list of 3 fake items | Replace hardcoded list with empty state or wire to a real endpoint. |
| `HostBookings.tsx` | ✅ `hostBookings.slice` | ✅ | 0 mock strings | Verify endpoint match (TASK_TRACKER INT-04 says path mismatch — fix or document). |
| `HostEarnings.tsx` | ✅ `hostEarnings.slice` | 🔄 | 3 mock indicators | Verify; expose with mock-flag pattern same as FMS. |
| `HostProfile.tsx` | ✅ `hostProfile.slice` | 🔄 | 3 indicators | Verify save flow; check INT-05 path alignment for payout account. |
| `HostStatements.tsx` | ❌ no slice | ❌ pure mock | 3 indicators | **Wire to a slice; add mock fallback; document endpoint contract.** |
| `HostSupport.tsx` | ❌ no slice | ❌ pure mock | 2 indicators | Same as Statements. |
| `HostCommunication.tsx` | ❌ no slice | ❌ pure mock — `INITIAL_THREADS` literal | 0 (but obvious) | Same as Statements. |
| `HostPerformance.tsx` | ❌ no slice | ❌ pure mock | 0 (UI shell only) | Same as Statements. |

**Admin-side HMS** (`src/pages/admin/host-management/`)

| File | Status |
|---|---|
| `HostManagementPage.tsx` | ✅ exists |
| `HostTable.tsx` | ✅ exists |
| `HostActions.tsx` | ✅ exists |
| `HostDetailDialog.tsx` | ✅ exists (HMS-0002 closed) |
| `HostHeader.tsx` | ✅ exists |
| KYC approve / reject backend wiring | 🔴 INT-11 — backend endpoints not aligned |
| Host performance pane | 🔴 P3-ADM-05 — backend `/admin/host/performance/summary` missing |
| Host payout pane | 🔴 backend `/admin/host/payout/*` missing |

**HMS verdict:** ~50% frontend done. 4 host-portal pages are pure-mock and need scaffolding (slice + mock + contract). Admin-side detail dialog done; performance/payout panes need backend.

#### Admin portal (the gaps tracked under GAP-01..10 and P3-ADM-*)

| GAP | Title | Code reality | Action |
|---|---|---|---|
| GAP-01..03 | `/become-a-host` | ✅ done Jun 3 | Verify. |
| GAP-04 | Replace `/admin/settings` stub | ⬜ `App.tsx:189` literally `<h1>Settings</h1>` | **Build this weekend.** |
| GAP-05 | Settings sections (platform / notifications / security / integrations) | ⬜ | **Build basic shell; back with mocks; flag for real wiring.** |
| GAP-06 | Replace admin notification placeholder drawer | ⬜ `AdminNotifySidebar.tsx` is a stub | **Build typed notification list this weekend.** |
| GAP-07 | Add notification read/unread + categories + empty states | ⬜ | Bundled with GAP-06. |
| GAP-08 | Wire notification center to backend stream | 🔴 BLK-04 | **Not weekend scope** — mock fallback only. |
| GAP-09 | User review submission page | ⬜ Nav exists; route + page missing | **Build this weekend.** |
| GAP-10 | Wire review submit API | 🔄 endpoint exists (`/review/user/*` per mobile work) | Reuse mobile endpoint; one POST with mock fallback. |

---

## 2 · Contract scope check (what we owe vs what we'll ship)

From `AAJOO Homes_Zyphex Tech Contract Signed.pdf` § 2.2 + 4.2:

> *"Finance & Host Systems (FMS & HMS — Full Implementation in This Phase)"* — both must be **designed, built, tested, deployed** under the ₹1,60,000 fixed fee. Milestone M5 (Week 10) = production go-live.

Reality vs commitment:

| Contract obligation | What we ship by weekend | Gap to contract |
|---|---|---|
| FMS admin frontend, fully working | ✅ All 15 pages + slices + routes + sidebar | No FE gap. **Backend FMS endpoints (BE side) is the gap** — owned by backend team. |
| HMS host-facing portal | 4/8 pages backend-wired, 4/8 mock-only | Mock-only pages must be flipped post-weekend when endpoints land. |
| HMS admin-side moderation + KYC + payout | List + detail dialog done; KYC actions partial; performance/payout panes pending | Endpoints + UI for performance/payout panes deferred. |
| Platform enhancements (website + admin) | Sand & Indigo redesign ✅; settings + review + notification gaps to close | After weekend, only backend-blocked items remain (notifications stream, RBAC). |
| QA + UAT support | Browser walks scheduled Sat | UAT formally starts when backend endpoints are real. |
| Production deploy + 30-day support | N/A — backend not deploy-ready for FMS/HMS | Triggered by client milestone M5. |

**Bottom line:** the FE half of the contract is **~90% done** when this weekend's gap-closure ships. The remaining ~10% is backend-coupled and cannot be delivered without BE work + client credentials.

---

## 3 · Weekend execution plan (4 working days)

> Each day groups tasks. Each task references a tracker ID where one exists (so updates flow back). Estimates are honest "if nothing breaks" times.

### Day 1 — Tue 2026-06-09 (today, evening) + Wed 2026-06-10 — Admin gap closure

**Goal:** close the 4 admin/website gaps that are pure-frontend and need no backend coordination.

| # | Task | Tracker ID | Est. | Acceptance |
|---|---|---|---|---|
| 1 | **Admin Settings page** — replace `<h1>Settings</h1>` at `App.tsx:189` with a real layout. 4 tabs (Platform · Notifications · Security · Integrations). Use existing MUI tab pattern from `src/pages/admin/properties`. Each tab renders a read-only "stub" panel with a `// TODO(BE)` marker and the env-var / endpoint it will consume. | GAP-04, GAP-05 | 4h | Route loads; tabs switch; build clean; no console errors. |
| 2 | **Admin Notification Center** — turn `AdminNotifySidebar.tsx` placeholder into a typed list. Card per notification: icon + title + timestamp + read indicator. Filter chips (Bookings / Users / Hosts / System). Empty state. Data: mock array gated by `VITE_USE_NOTIFY_MOCKS=true` (same pattern as FMS); real fetch from `/admin/notifications/search` (not yet implemented — document). | GAP-06, GAP-07 | 4h | Drawer opens, renders mock items, filters work, marks read locally. |
| 3 | **User Review Submission Page + Route** — new `src/pages/user/review/SubmitReview.tsx`. Form: 1–5 star (use existing star widget), free-text textarea, submit button. Route `/user/review/:bookingId` in `App.tsx` inside `CommonLayout`. POST to existing backend `/review/user/save-review` (already live, used by mobile). Show success + redirect to `/user-dashboard`. | GAP-09, GAP-10 | 3h | Page loads from booking history "Write Review" CTA; submit succeeds; error shows toast. |
| 4 | **Verify `/become-a-host`** | GAP-01..03 | 30m | Page renders end-to-end; form fields validate; mobile breakpoint OK. |

**EOD check:** `npm run build` clean. Manual smoke of 4 new surfaces. Commit message: `feat(admin+web): close GAP-04/05/06/07/09/10 — settings, notifications, review submit`.

### Day 2 — Thu 2026-06-11 — HMS host-portal hardening

**Goal:** make the 4 mock-only host pages pass a browser walk with a documented backend contract.

| # | Task | Tracker ID | Est. | Acceptance |
|---|---|---|---|---|
| 5 | **HostStatements** — add `hostStatements.slice.ts` (thunks: `fetchHostStatements`, `downloadStatement`); convert page to slice + DEV mock fallback (`VITE_USE_HOST_MOCKS=true`); empty/loading/error states. | P3-HST-06 | 2h | Page renders 3 mock statements when flag on; renders empty state when flag off + endpoint 404; download CTA console-logs the booking id. |
| 6 | **HostSupport** — `hostSupport.slice.ts` (`fetchTickets`, `createTicket`, `replyToTicket`); same mock-flag pattern. | P3-HST-07 | 2h | Ticket list renders; new-ticket form validates; mock returns optimistic update. |
| 7 | **HostCommunication** — `hostCommunication.slice.ts` for thread list + messages. Replace `INITIAL_THREADS` literal with slice + mock fallback. | P3-HST-08 | 2h | Threads list, click opens detail, send pushes a local optimistic message. |
| 8 | **HostPerformance** — `hostPerformance.slice.ts` for occupancy / revenue / cancellations / ratings. Wire existing chart components with mock series. | P3-HST-09 | 2h | All 4 charts render with mock data; no console errors. |
| 9 | **HostDashboard RECENT_ACTIVITY** — replace the 3 hardcoded items at `dashboard.tsx:30` with empty state when `data.recentActivity` is empty, OR with the slice's `recentActivity` when populated. | P3-HST-02 | 30m | No hardcoded sample data left in the dashboard. |
| 10 | **HostBookings + HostEarnings + HostProfile** — verify INT-04/05/06 endpoint paths; either fix the FE path or note the mismatch in the contract doc. | INT-04, INT-05, INT-06 | 1.5h | Each page does its primary fetch; on path mismatch, document the FE-expected path vs BE-current path in section 5 below. |

**EOD check:** all 8 host pages load without errors with mock flag on AND off. Commit: `feat(host): close P3-HST-06/07/08/09 + INT-04/05/06 — mock-fallback fully wired`.

### Day 3 — Fri 2026-06-12 — FMS QA + responsive + admin-side HMS

| # | Task | Tracker ID | Est. | Acceptance |
|---|---|---|---|---|
| 11 | **FMS mock-flag verification** — toggle `VITE_USE_FINANCE_MOCKS` true/false; walk all 15 FMS pages; document any page that errors when flag is off. | (new — FMS-QA-01) | 1h | Walk report appended to section 7 below. |
| 12 | **FMS smoke runner** — `node scripts/financeSmoke.js` against the deployed staging backend (returns expected envelope shapes). | P4-FMS-07 (partial) | 30m | Smoke log captured; failures filed against backend in section 5. |
| 13 | **Admin host-management Performance pane** — add a stub panel inside `HostDetailDialog.tsx` that calls `fetchHostPerformanceSummary` thunk (new slice `adminHostPerformance.slice.ts`) with mock fallback. Endpoint `/admin/host/performance/summary?hostId=`. | P3-ADM-05 | 2h | Dialog has a Performance tab; tab renders mock KPIs; loading + error covered. |
| 14 | **Admin host-management Payout pane** — same pattern. Endpoint `/admin/host/payout/history?hostId=` + `/admin/host/payout/{hold,release}` actions. | P3-ADM-05 | 2h | Payout tab in dialog; mock list + hold/release buttons fire console actions. |
| 15 | **Mobile responsive A2.5-42** — pass at 375px across customer-facing surfaces + admin login + host login. Fix anything that breaks. | WEB-RED-A2.5-42 | 1h | gstack screenshots at 375 + 1440 for 6 surfaces, no horizontal scroll bugs. |

**EOD check:** build + lint clean. Commit: `feat(admin+fms): host detail performance/payout panes + FMS mock-flag QA + A2.5-42 polish`.

### Day 4 — Sat 2026-06-13 — Final walk, contract doc, commit hygiene

| # | Task | Tracker ID | Est. | Acceptance |
|---|---|---|---|---|
| 16 | **End-to-end browser walk** with gstack: Customer funnel (Home → Listing → Detail → Checkout → Confirmation), Auth (Login + Signup + Forgot + Verify), Admin (Login → Dashboard → Bookings → Users → Hosts → Properties → Finance/* → Settings → Notifications), Host (Login → Dashboard → all 8 pages). | P5-QA-01 | 2h | Each surface screenshotted at 1440×900; bugs filed in `WEB_QA_BUGS.md` v2. |
| 17 | **API contract handoff doc** — produce `API_CONTRACT_HANDOFF.md` listing every endpoint FE expects but BE has not delivered, grouped by FMS / HMS / Notifications / Reviews / Settings, with request/response sample. This unlocks backend work to flip mock → real after weekend. | INT-01..13, P2-API-01..05 | 3h | One markdown file; each endpoint has Method + Path + Request body + Response body. |
| 18 | **Update trackers** — flip the rows we closed (GAP-04/05/06/07/09/10, P3-HST-06..09, P3-ADM-05, WEB-RED-A2.5-42, A6-04) from ⬜ to ✅ in `TASK_TRACKER.md`. Add a "Weekend Sprint" log entry. Update `MASTER_TASK_TRACKER.md § Section D + § Section E` for the web items. | (housekeeping) | 30m | Trackers reflect new reality. |
| 19 | **Final commit + push** | — | 30m | Branch `main` is green; PR or direct push per repo policy. |

**Stretch (Sun 2026-06-14 if available):**
- Real `/admin/notifications` backend stub if a backend engineer is available — turn GAP-08 from 🔴 to 🔄.
- KYC-WEB-01..04 (Didit web gates) if Didit console creds arrive before Sat — ~3h.

---

## 4 · Out-of-weekend backlog (blocked + why)

These are real obligations to the contract, but **cannot land this weekend**. Each entry names the blocker, the unblocker action, and who owns it.

| ID | Item | Blocker | Unblocker | Owner |
|---|---|---|---|---|
| BLK-01 | Staging backend with real `/admin/finance/*` endpoints | Backend hasn't implemented FMS endpoints (P2-FMS-01..06) | Backend dev cycle ~5–8 BE days against the contract delivered in section 5 below | Backend team |
| BLK-02 | Host portal real endpoints `/host/{bookings,earnings,profile,payout-account,statements,support,messages}/*` | Backend hasn't implemented or paths don't match FE expectations (INT-04..09) | Either backend builds to FE spec OR FE adjusts to backend path; decide in tri-party call | Backend + FE leads |
| BLK-03 | RBAC claims in JWT (admin / finance / host / support / guest) | Auth payload lacks role claim | Backend auth team adds claim → FE reads it for route guards | Backend / Auth |
| BLK-04 | Notification backend channel (FCM / WebSocket / event feed) | No backend infra | Backend defines channel + FE swaps mock for stream | Backend |
| BLK-05 | UAT environment + seeded test data | Ops/Client | Provision a UAT subdomain + seed script | Ops + Client |
| PAY-01 | Live Razorpay credentials | Client KYC pending | Client completes Razorpay business KYC, hands `rzp_live_*` + secret | Client |
| EMAIL-01 | Brevo or Resend account + sender domain | Client decision | Client picks provider + verifies domain SPF/DKIM | Client |
| KYC-SETUP-01..05 | Didit Business Console workflow IDs + webhook secret | Console work | Sumit completes in Didit dashboard | Sumit |
| KYC-QA-01..04 | E2E KYC verification (mobile + web) | Needs KYC-SETUP-* + test device | After console setup arrives | QA |

---

## 5 · API Contract — endpoints backend must deliver (to be split into `API_CONTRACT_HANDOFF.md` on Day 4)

> Draft list. Final doc on Day 4 will have request/response samples per endpoint.

### FMS — `/admin/finance/*` (BLK-01)

| Method | Path | Used by FE page |
|---|---|---|
| POST | `/admin/finance/ledger/search` | LedgerList |
| GET | `/admin/finance/ledger/:ledgerId` | LedgerDetailDrawer |
| POST | `/admin/finance/ledger/host/:hostId` | HostLedger |
| POST | `/admin/finance/ledger/user/:userId` | GuestLedger |
| POST | `/admin/finance/ledger/export` | LedgerList export |
| POST | `/admin/finance/payout/search` | PayoutQueue + PayoutHistory |
| GET | `/admin/finance/payout/:payoutId` | PayoutDetail |
| POST | `/admin/finance/payout/initiate` | Manual payout |
| PUT | `/admin/finance/payout/:payoutId/approve` | PayoutQueue |
| PUT | `/admin/finance/payout/:payoutId/reject` | PayoutQueue |
| POST | `/admin/finance/payout/schedule/search` | PayoutSchedules |
| PUT | `/admin/finance/payout/schedule/:scheduleId` | PayoutSchedules |
| POST | `/admin/finance/payout/schedule/create` | PayoutSchedules |
| POST | `/admin/finance/invoice/search` | InvoiceList |
| GET | `/admin/finance/invoice/:invoiceId` | InvoiceDetail |
| GET | `/admin/finance/invoice/:invoiceId/download` | InvoiceDetail PDF |
| POST | `/admin/finance/invoice/void/:invoiceId` | InvoiceDetail |
| POST | `/admin/finance/reconciliation/search` | ReconciliationList |
| GET | `/admin/finance/reconciliation/:reconId` | ReconciliationDashboard |
| PUT | `/admin/finance/reconciliation/:reconId/resolve` | ReconciliationList |
| POST | `/admin/finance/reconciliation/run` | ReconciliationDashboard |
| GET | `/admin/finance/dashboard` | FinanceDashboard |
| POST | `/admin/finance/reports/revenue` | RevenueReport |
| POST | `/admin/finance/reports/commission` | CommissionReport |
| POST | `/admin/finance/reports/tax` | TaxSummary |
| POST | `/admin/finance/reports/cashflow` | CashFlowReport |
| POST | `/admin/finance/reports/export` | All reports |

### HMS host portal — `/host/*` (BLK-02)

| Method | Path | Used by FE page | Conflict |
|---|---|---|---|
| GET | `/host/dashboard/summary` | dashboard | — |
| POST | `/host/bookings/search` | HostBookings | BE currently `/host/booking-history` (INT-04) |
| GET | `/host/bookings/detail/:id` | HostBookings | INT-04 |
| GET | `/host/earnings/summary` | HostEarnings | — |
| GET | `/host/payout/history` | HostEarnings | BE currently `/payout/history` (INT-06) |
| GET | `/host/profile/get` | HostProfile | — |
| PUT | `/host/profile/update` | HostProfile | — |
| GET | `/host/payout-account/get` | HostProfile | BE currently `/payout/account/*` (INT-05) |
| PUT | `/host/payout-account/update` | HostProfile | INT-05 |
| POST | `/host/statements/search` | HostStatements | new |
| GET | `/host/statements/download/:id` | HostStatements | new |
| POST | `/host/support/tickets/search` | HostSupport | new (INT-07) |
| POST | `/host/support/tickets/create` | HostSupport | new |
| POST | `/host/support/tickets/reply` | HostSupport | new |
| GET | `/host/messages/list` | HostCommunication | BE has threads/conversation paths (INT-08) |
| POST | `/host/messages/send` | HostCommunication | INT-08 |
| GET | `/host/performance/occupancy` | HostPerformance | new |
| GET | `/host/performance/revenue` | HostPerformance | new |
| GET | `/host/performance/cancellations` | HostPerformance | new |
| GET | `/host/performance/ratings` | HostPerformance | new |
| POST | `/host/onboarding/submit` | BecomeHost | INT-10 |

### HMS admin-side — `/admin/host/*` (BLK-02)

| Method | Path | Used by |
|---|---|---|
| GET | `/admin/host/detail/:hostId` | HostDetailDialog |
| GET | `/admin/host/kyc/detail/:hostId` | HostDetailDialog KYC tab |
| POST | `/admin/host/kyc/approve` | HostActions (INT-11) |
| POST | `/admin/host/kyc/reject` | HostActions (INT-11) |
| GET | `/admin/host/performance/summary?hostId=` | HostDetailDialog Performance tab |
| GET | `/admin/host/payout/history?hostId=` | HostDetailDialog Payout tab |
| POST | `/admin/host/payout/hold` | HostDetailDialog Payout tab |
| POST | `/admin/host/payout/release` | HostDetailDialog Payout tab |

### Admin shell — new endpoints

| Method | Path | Used by |
|---|---|---|
| GET | `/admin/notifications/search` | AdminNotifySidebar (GAP-06) |
| PUT | `/admin/notifications/:id/read` | GAP-07 |
| GET | `/admin/verify-token` | AdminProtectedRoute (INT-02) |

### Reviews

| Method | Path | Used by | Status |
|---|---|---|---|
| POST | `/review/user/save-review` | SubmitReview (GAP-10) | ✅ exists (mobile uses it) |

### Auth

| Method | Path | Used by | Note |
|---|---|---|---|
| POST | `/user/update/forget-password` | ForgotPassword | INT-12 — currently auth-gated, should be public |

---

## 6 · Definition of "Weekend Complete" — acceptance gates

Each track gets the green tick only when **all** rows pass.

### Website
- [ ] `npm run build` exits 0
- [ ] `npm run lint` ≤ 205 issues (baseline)
- [ ] Funnel walk Home → Listing → Detail → Checkout → Confirmation passes at 1440 + 375
- [ ] `/become-a-host` form submits (mock OK)
- [ ] `/user/review/:bookingId` submits a review against the live backend endpoint
- [ ] No console errors on any page
- [ ] Sand & Indigo palette unbroken (no purple/pink regressions — grep `881f9b|C14464|AD1457` returns zero in `src/`)

### FMS
- [ ] All 15 FMS routes load without runtime errors with `VITE_USE_FINANCE_MOCKS=true`
- [ ] All 15 FMS routes load gracefully (empty state, no crash) with the flag off
- [ ] `financeSmoke.js` runs; results captured
- [ ] API contract doc lists every FMS endpoint backend must deliver
- [ ] Sidebar Finance group routes to every FMS page

### HMS
- [ ] All 8 host-portal pages load with mock flag on AND off
- [ ] Each page has loading + empty + error states
- [ ] Admin HostDetailDialog has Detail / KYC / Performance / Payout tabs (last 3 rendering mock data)
- [ ] Each unwired endpoint is named in the contract doc with FE-expected request/response

### Admin
- [ ] `/admin/settings` renders 4 tabs (not `<h1>Settings</h1>`)
- [ ] `AdminNotifySidebar` renders mock notification list with filter chips + read marker
- [ ] All existing admin CRUD pages (bookings, users, properties, categories, tags, amenities, reviews, host-management) still load
- [ ] Admin sidebar matches website route structure (no orphan or dead nav items)

---

## 7 · Open questions for the user before Day 2 kicks off

Light-touch decisions that affect scope. Default answers are pre-filled.

1. **Settings page contents** — for the 4 tabs, are stub panels with `// TODO(BE)` markers acceptable, or do you want any of them to be functional this weekend (e.g., "Change admin password" wired to existing `/user/update-password`)? *Default: stub panels.*
2. **Notification center** — mock-only is fine for the weekend, real channel later? *Default: yes, mock-only.*
3. **Admin Performance + Payout panes (HostDetailDialog)** — do you want them as new tabs inside the existing dialog, or as separate routes? *Default: tabs in the dialog (cheaper, one mount point).*
4. **API contract doc format** — is one big `API_CONTRACT_HANDOFF.md` ok, or do you want it split per area (one for FMS, one for HMS)? *Default: one file.*
5. **Mobile redesign track** — the mobile app still has B3-17/20/21, B4-11, B5-04..07 (device walkthroughs) plus KYC plus Cluster B cleanup pending. Out of weekend scope per your "website, FMS, HMS, admin" framing — confirm? *Default: yes, out of scope; tracked in `MASTER_TASK_TRACKER.md`.*

---

## 8 · Tracker housekeeping after weekend (do this last)

When this plan finishes, flip the following rows from ⬜ → ✅ in the **correct** tracker:

**In `TASK_TRACKER.md`:**
- GAP-04, GAP-05, GAP-06, GAP-07 (admin settings + notification center mock)
- GAP-09, GAP-10 (review submit page + wiring)
- P3-ADM-05 partial (performance + payout panes — mock side complete)
- P3-HST-06, P3-HST-07, P3-HST-08, P3-HST-09 (mock-side complete; BE wiring still 🔴)

**In `MASTER_TASK_TRACKER.md`:**
- WEB-RED-A2.5-42 (responsive polish)
- WEB-RED-A3-10 and WEB-RED-A6-04 (manual funnel walks done)
- New rows for the items above (e.g., `WEB-FEAT-05 Settings page`, `WEB-FEAT-06 Notification center`).

Add a new section `§ Weekend Sprint 2026-06-09..13` under "Recently Completed" in `MASTER_TASK_TRACKER.md` with the final summary + commit hashes.

Leave `INTEGRATION_TASK_TRACKER.md` and `REDESIGN_TASK_TRACKER.md` alone — they're historical.

---

## 9 · Risk register for the weekend

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Backend ships an FMS endpoint mid-weekend with a different shape than our mocks | Low | Med | Slice already in place; one-line type tweak. Contract doc reduces likelihood. |
| Lint baseline creeps up | Med | Low | Run `npm run lint` after each commit; fix on the spot. |
| Mock-flag-off mode reveals a runtime crash | Med | Med | Day 3 task 11 specifically tests this; gate every `data.foo` with `?.` and provide `[]` defaults. |
| New routes break existing CSP / CORS | Low | Med | All new pages reuse `CommonLayout`/`AdminLayout`; no new origin calls. |
| Settings page scope expands ("can we also add billing details?") | Med | Med | Section 7 question 1 nails this down before Day 1 ends. |
| Conflicting commits with backend track | Low | Low | Backend lives in `aajooBackend-2026/`; web work is in `src/` — no overlap. |

---

*End of plan. Update this file as Day 1 starts; flip checkboxes in section 6 as gates pass.*
