  # AAJOO Homes — Master Delivery Task Tracker (Contract-Aligned)

> **Project:** AAJOO Homes – Platform, Finance & Host Systems Enhancements  
> **Client:** AAJOO Homes Private Limited  
> **Service Provider:** Zyphex Technologies  
> **Contract Source:** `AAJOO Homes_Zyphex Tech Contract Signed.pdf` (extracted + mapped)  
> **Total Investment:** ₹1,60,000 (all-inclusive)  
> **Contract Duration:** 10–12 weeks + 30-day post go-live support  
> **Contract Date:** 11 Feb 2026  
> **Tracker Updated:** 17 May 2026

---

## 1) Status Legend

| Symbol | Meaning |
|---|---|
| ✅ | Completed |
| 🔄 | In Progress / Partially Completed |
| ⬜ | Not Started |
| 🔴 | Blocked (dependency required) |

---

## 2) Contract Commitments Snapshot (from signed PDF)

## In-scope delivery
1. Platform enhancements across admin, web, backend integrations, testing, UAT, deployment.
2. Finance Management System (FMS): ledgers, payouts, reconciliation, reports, invoices.
3. Host Management System (HMS): onboarding/KYC, profile & payout account, performance, communication, statements.
4. End-to-end delivery including QA, UAT support, go-live, and 30-day stabilization support.

## Out of scope
1. Third-party subscription costs.
2. New external integrations not in agreed PRD.
3. Extended maintenance beyond included 30 days (optional paid plans).
4. Compliance consulting/certifications beyond implementation scope.

## Milestones (contract)
1. M1 Design sign-off (Week 2)
2. M2 Development build (Week 5)
3. M3 Specification complete (Week 7)
4. M4 UAT sign-off (Week 9)
5. M5 Go-live (Week 10)
6. M6 Support complete (Week 14)

---

## 3) Current Completion Snapshot (codebase reality)

| Area | Status | Evidence (paths) |
|---|---|---|
| Admin core CRUD + dashboard + auth | ✅ | `src/pages/admin/*`, `src/features/admin/*`, `src/App.tsx` |
| Finance module frontend implementation | ✅ | `src/pages/admin/finance/*`, `src/features/admin/finance/*`, `src/services/endpoints.ts` |
| Finance smoke + staging integration runners | ✅ | `scripts/financeSmoke.js`, `scripts/financeIntegrationStaging.js`, `SMOKE_TEST_REFERENCE.md` |
| Host routes and host portal foundation | 🔄 | `src/pages/host/*`, `src/features/host/*`, `src/App.tsx` |
| Admin host management KYC/detail foundation | 🔄 | `src/pages/admin/host-management/*`, `src/features/admin/userManagement/hostDetail.slice.ts` |
| Admin settings page | ⬜ | Route is stub: `src/App.tsx` |
| Become-a-host page | ⬜ | Link exists in `src/pages/user/home.tsx`; route/page missing |
| Admin notification center | ⬜ | Placeholder in `src/components/admin/adminNotification/AdminNotifySidebar.tsx` |
| User review submission route/page | ⬜ | Navigation exists (`/user/review/:id`) but page/route missing |
| Full backend integration verification | 🔴 | Backend deployment/access dependency |

---

## 4) Blocker Register (must clear first)

| ID | Blocker | Needed from | Status |
|---|---|---|---|
| BLK-01 | Staging backend deployment for full API validation | Backend/Ops | 🔴 |
| BLK-02 | Host portal endpoint completion + contract freeze | Backend | 🔴 |
| BLK-03 | RBAC claims in auth payload (admin/finance/host/support/guest) | Backend/Auth | 🔴 |
| BLK-04 | Notification backend channels (FCM/WebSocket/event feed) | Backend | 🔴 |
| BLK-05 | UAT environment + credentials + seeded test data | Ops/Client | 🔴 |

---

## 5) Detailed Task Tracker (decomposed by contract workstreams)

## A) Immediate product gaps (highest priority, fastest impact)

| ID | Task | Status | Owner | Dependency |
|---|---|---|---|---|
| GAP-01 | Create `/become-a-host` page shell and route | ⬜ | FE | None |
| GAP-02 | Implement host onboarding form UX (steps + validation) | ⬜ | FE | None |
| GAP-03 | Wire onboarding form to API contract (or mock adapter) | ⬜ | FE | BLK-02 |
| GAP-04 | Replace `/admin/settings` stub with real settings layout | ⬜ | FE | None |
| GAP-05 | Add settings sections: platform, notifications, security, integrations | ⬜ | FE | BLK-03/BLK-04 (partial) |
| GAP-06 | Replace admin notification placeholder drawer with typed notification list | ⬜ | FE | None |
| GAP-07 | Add notification read/unread, category chips, empty/error states | ⬜ | FE | None |
| GAP-08 | Wire notification center to backend stream/feed | ⬜ | FE | BLK-04 |
| GAP-09 | Build user review submission page + route (`/user/review/:bookingId`) | ⬜ | FE | None |
| GAP-10 | Connect review submit API and validation states | ⬜ | FE | Backend endpoint |

---

## B) Contract Phase 1 — Discovery & Solution Design

| ID | Task | Status | Owner | Notes |
|---|---|---|---|---|
| P1-01 | Consolidate signed contract scope + PRD into one requirements matrix | 🔄 | PM/BA | This tracker now aligned to contract |
| P1-02 | Build feature-to-screen mapping for admin/guest/host | 🔄 | FE/BA | Requires final API matrix sign-off |
| P1-03 | Build feature-to-endpoint mapping (request/response ownership) | 🔄 | FE/BE | Partially done in `endpoints.ts` |
| P1-04 | Finalize architecture sign-off notes for FMS/HMS integration | 🔄 | Arch/BE/FE | Needs backend alignment |
| P1-05 | Finalize RBAC matrix with route-level and action-level permissions | ⬜ | Arch/BE/FE | Blocked by auth claims |
| P1-06 | Produce security checklist sign-off (token, logs, PII, audit) | 🔄 | BE/Sec | backend optimization doc exists |

---

## C) Contract Phase 2 — Backend Development & Integrations

## C.1 Core backend contracts & readiness
| ID | Task | Status | Owner | Dependency |
|---|---|---|---|---|
| P2-API-01 | Publish OpenAPI spec for admin + FMS + HMS endpoints | ⬜ | BE | BLK-01 |
| P2-API-02 | Freeze payload contracts for host endpoints | ⬜ | BE | BLK-02 |
| P2-API-03 | Add versioning/error envelope conventions | ⬜ | BE | None |
| P2-API-04 | Add pagination/sort/filter consistency across all lists | 🔄 | BE | Partial in existing admin APIs |
| P2-API-05 | Add webhook/event contracts for real-time updates | ⬜ | BE | BLK-04 |

## C.2 FMS backend completion
| ID | Task | Status | Owner | Dependency |
|---|---|---|---|---|
| P2-FMS-01 | Ledger write triggers on booking/payment/refund/cancel events | ⬜ | BE | Core booking events |
| P2-FMS-02 | Payout scheduler + execution orchestration | ⬜ | BE | Banking/gateway integration |
| P2-FMS-03 | Reconciliation engine (booking/payment/payout/gateway variance) | ⬜ | BE | P2-FMS-01/02 |
| P2-FMS-04 | GST-ready invoice generation + PDF rendering | ⬜ | BE | Tax config |
| P2-FMS-05 | Financial audit log for all manual adjustments | 🔄 | BE | backend audit service documented |
| P2-FMS-06 | Finance KPIs query optimization for dashboard/report APIs | 🔄 | BE | performance tuning |

## C.3 HMS backend completion
| ID | Task | Status | Owner | Dependency |
|---|---|---|---|---|
| P2-HMS-01 | Host onboarding + KYC workflow APIs | 🔄 | BE | partial KYC actions exist |
| P2-HMS-02 | Host dashboard summary endpoint hardening | 🔄 | BE | endpoint exists; needs stable contract |
| P2-HMS-03 | Host statements search + download endpoints | ⬜ | BE | BLK-02 |
| P2-HMS-04 | Host support tickets CRUD APIs | ⬜ | BE | BLK-02 |
| P2-HMS-05 | Host messaging APIs + delivery statuses | ⬜ | BE | BLK-04 |
| P2-HMS-06 | Host performance analytics endpoints | ⬜ | BE | analytics pipeline |

## C.4 Security & auth
| ID | Task | Status | Owner | Dependency |
|---|---|---|---|---|
| P2-SEC-01 | RBAC claims in JWT for all target roles | ⬜ | BE/Auth | BLK-03 |
| P2-SEC-02 | Refresh token policy and secure session lifecycle | ⬜ | BE/Auth | None |
| P2-SEC-03 | Endpoint-level permission middleware enforcement | ⬜ | BE | P2-SEC-01 |
| P2-SEC-04 | Security logging and tamper-evident audit events | 🔄 | BE | partly implemented per optimization report |

---

## D) Contract Phase 3 — Frontend & Application Changes

## D.1 Admin product
| ID | Task | Status | Owner | Dependency |
|---|---|---|---|---|
| P3-ADM-01 | Admin dashboard enhancement with finance KPIs | 🔄 | FE | finance dashboard exists; cross-module KPIs pending |
| P3-ADM-02 | Admin reports center (download/export + filters) | 🔄 | FE | FMS report pages exist; unified reports entry pending |
| P3-ADM-03 | Admin settings full implementation | ⬜ | FE | GAP-04/05 |
| P3-ADM-04 | Admin notification center implementation | ⬜ | FE | GAP-06/07/08 |
| P3-ADM-05 | Admin host management: performance + payout panes | 🔄 | FE | details dialog exists; full integration pending |
| P3-ADM-06 | Admin host KYC actions end-to-end audit visibility | 🔄 | FE/BE | action UI exists; backend audit read API pending |

## D.2 Guest web
| ID | Task | Status | Owner | Dependency |
|---|---|---|---|---|
| P3-GST-01 | Preserve existing booking/payment stability | ✅ | FE/BE | already live |
| P3-GST-02 | Add become-a-host conversion journey | ⬜ | FE | GAP-01/02/03 |
| P3-GST-03 | Complete user review submission flow | ⬜ | FE | GAP-09/10 |
| P3-GST-04 | Validate notification UX consistency in user area | 🔄 | FE | API/event dependency |
| P3-GST-05 | Audit mobile responsiveness of high-traffic guest pages | 🔄 | FE | regression pass pending |

## D.3 Host portal (frontend)
| ID | Task | Status | Owner | Dependency |
|---|---|---|---|---|
| P3-HST-01 | Host route architecture + shell | ✅ | FE | `src/pages/host/layout/HostLayout.tsx` |
| P3-HST-02 | Host dashboard connected to stable API schema | 🔄 | FE | BLK-02 |
| P3-HST-03 | Host bookings search/filter/export full integration | 🔄 | FE | BLK-02 |
| P3-HST-04 | Host earnings and payout history full integration | 🔄 | FE | BLK-02 |
| P3-HST-05 | Host profile + payout account integration | 🔄 | FE | BLK-02 |
| P3-HST-06 | Host statements API integration (currently mock table) | ⬜ | FE | BLK-02 |
| P3-HST-07 | Host support ticketing integration (currently local mock) | ⬜ | FE | BLK-02 |
| P3-HST-08 | Host communication center integration (currently local mock) | ⬜ | FE | BLK-04 |
| P3-HST-09 | Host performance analytics integration (currently mock trends) | ⬜ | FE | BLK-02 |
| P3-HST-10 | Host role-safe guard + unauthorized redirects | ⬜ | FE | BLK-03 |

---

## E) Contract Phase 4 — Finance & Host Management Systems

## E.1 Finance Management System (FMS)
| ID | Task | Status | Owner | Dependency |
|---|---|---|---|---|
| P4-FMS-01 | Ledger UI workflows (admin) | ✅ | FE | delivered |
| P4-FMS-02 | Payout queue/schedules/actions UI | ✅ | FE | delivered |
| P4-FMS-03 | Reconciliation dashboards/lists UI | ✅ | FE | delivered |
| P4-FMS-04 | Invoice list/detail/download/void UI | ✅ | FE | delivered |
| P4-FMS-05 | Reports (revenue/commission/tax/cashflow) UI | ✅ | FE | delivered |
| P4-FMS-06 | India compliance helper layer (GST/TDS/GSTIN/FY/INR) | ✅ | FE | delivered |
| P4-FMS-07 | Staging E2E validation against live backend | 🔴 | FE/QA | BLK-01 |
| P4-FMS-08 | Variance handling workflows with real data | 🔄 | FE/BE | backend parity required |
| P4-FMS-09 | Production performance test for heavy datasets | 🔴 | QA/BE | BLK-01 + data seeding |

## E.2 Host Management System (HMS)
| ID | Task | Status | Owner | Dependency |
|---|---|---|---|---|
| P4-HMS-01 | Admin-side host list/detail/KYC action foundation | 🔄 | FE | exists but incomplete integration |
| P4-HMS-02 | Host onboarding/KYC full lifecycle | 🔄 | FE/BE | API and UX completion pending |
| P4-HMS-03 | Host profile + payout account management full flow | 🔄 | FE/BE | endpoint contract pending |
| P4-HMS-04 | Host performance metrics dashboards (admin+host) | ⬜ | FE/BE | analytics endpoints |
| P4-HMS-05 | Host payout visibility + statement downloads | ⬜ | FE/BE | statements endpoints |
| P4-HMS-06 | Host communication logs + notifications | ⬜ | FE/BE | event infra |

---

## F) Contract Phase 5 — QA, UAT, Deployment

| ID | Task | Status | Owner | Dependency |
|---|---|---|---|---|
| P5-QA-01 | Prepare master test plan mapped to contract deliverables | 🔄 | QA | docs available, consolidation pending |
| P5-QA-02 | Execute FMS staging integration checklist | 🔴 | QA/FE/BE | BLK-01 |
| P5-QA-03 | Execute HMS functional + integration regression matrix | 🔴 | QA/FE/BE | BLK-02 |
| P5-QA-04 | Security and auth regression (RBAC + session + audit) | 🔴 | QA/Sec/BE | BLK-03 |
| P5-QA-05 | Performance baseline generation | 🔴 | QA/BE | staging/prod-like env |
| P5-UAT-01 | UAT scripts handoff to client | ⬜ | PM/QA | after P5-QA-01 |
| P5-UAT-02 | UAT defect triage + closure | ⬜ | PM/FE/BE/QA | UAT start required |
| P5-DEP-01 | Deployment runbook finalization | ⬜ | DevOps/BE/FE | pre-go-live |
| P5-DEP-02 | Go-live checklist execution | ⬜ | DevOps/PM | after UAT sign-off |
| P5-DEP-03 | Hypercare communication protocol | ⬜ | PM/Ops | pre-go-live |

---

## G) Contract Phase 6 — Post-launch support & handover

| ID | Task | Status | Owner | Dependency |
|---|---|---|---|---|
| P6-01 | 30-day support rota and SLA tracking setup | ⬜ | PM/Ops | go-live |
| P6-02 | Daily incident log and weekly summary template | ⬜ | Ops/QA | go-live |
| P6-03 | Knowledge transfer sessions (codebase + runbook + ops) | ⬜ | FE/BE/PM | stabilized release |
| P6-04 | Final handover pack (docs, credentials, ownership transfer) | ⬜ | PM/Ops | payment and closure |

---

## 6) ASAP Execution Queue (recommended order)

1. **Queue-1 (Immediate FE fixes):** `GAP-01` to `GAP-10`
2. **Queue-2 (Host API readiness):** `P2-API-02`, `P2-HMS-02`..`P2-HMS-06`
3. **Queue-3 (RBAC + notifications backend):** `P2-SEC-01`, `P2-API-05`
4. **Queue-4 (Integration hardening):** `P4-FMS-07`, `P3-HST-06`..`P3-HST-10`
5. **Queue-5 (UAT & go-live):** `P5-*`
6. **Queue-6 (Post-launch):** `P6-*`

---

## 7) Completion gates (for “platform complete” declaration)

| Gate | Condition |
|---|---|
| G1 Functional Completion | All `GAP-*`, `P3-*`, `P4-*` are ✅ or accepted by change request |
| G2 Backend Integration Completion | All 🔴 blocked tasks from Section 4 are resolved |
| G3 QA/UAT Completion | `P5-QA-*` and `P5-UAT-*` closed with sign-off |
| G4 Go-live Completion | `P5-DEP-*` completed, production monitoring active |
| G5 Support Closure | `P6-*` completed and handover accepted |

---

## 8) Notes

1. This tracker reflects **current codebase reality** and signed contract obligations.
2. Where contract language and historical execution notes differ, delivery planning is aligned to client-visible commitments and production readiness.
3. Backend repo access/deployment remains the primary critical path for final completion.

