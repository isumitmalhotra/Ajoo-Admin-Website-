# AAJOO Homes — Pending Tasks & Realistic Timelines

**Prepared by:** Zyphex Technologies · **For:** AAJOO Homes Pvt. Ltd.
**Date:** 14 June 2026

> **Purpose:** The full remaining scope to reach a complete, production-grade launch, with realistic effort and clear dependencies. Effort is in **person-days at a sustainable pace**. Items marked **🔑 Client** are blocked on something only AAJOO can provide.

---

## Legend
- **Effort** = engineering person-days (testing included).
- **🔑 Client** = blocked on a client-provided input (keys, credentials, form spec, sign-off).
- Estimates assume the current 2-engineer team.

---

## 1 · P0 — Launch-critical (money + safety path)

| # | Task | Blocker | Effort |
|---|------|---------|--------|
| P0-1 | **Razorpay live integration** — create-order → checkout → verify against backend, wire into booking | 🔑 Live Razorpay keys | 2–3 d |
| P0-2 | **Booking persistence** — checkout creates a real booking record; flows into "Ongoing"/"My Bookings" | Depends on P0-1 (payment path) | 3–4 d |
| P0-3 | **Transactional emails** — booking confirmation, payment receipt, welcome-after-signup (OTP email already live) via Brevo | Depends on P0-2 for booking/payment triggers | 2–3 d |
| P0-4 | **Revert dev bypasses** — re-enforce KYC document requirement + real OTP (currently bypassed for testing: signup doc optional, master OTP `000000`) | None | 1 d |
| P0-5 | **Seed/demo data purge** — remove all mock/demo records before go-live | None | 0.5 d |
| P0-6 | **CORS hardening** — lock allowed origins to production domains | None | 0.5 d |
| P0-7 | **Support contact wiring** — real WhatsApp/phone/email behind "Support"/"Chat with host" (placeholders in code today) | 🔑 Real support numbers | 0.5 d |

**P0 subtotal: ≈ 9–12 person-days** (much of it gated on **live Razorpay keys + support numbers**).

---

## 2 · Host onboarding & KYC (DIDIT)

| # | Task | Blocker | Effort |
|---|------|---------|--------|
| H-1 | **Updated host registration form** — rebuild "Become a Host" to the agreed spec | 🔑 Updated form spec from client | 2–3 d |
| H-2 | **DIDIT ID verification** — real host ID verification + capture of all host details | 🔑 DIDIT credentials | 3–4 d |
| H-3 | Admin host **KYC approve/reject** end-to-end (INT-11) | None | 1–2 d |

**HMS onboarding subtotal: ≈ 6–9 person-days** (gated on **client form spec + DIDIT creds**).

---

## 3 · FMS — Backend completion (finance engine)

> The finance **frontend + read APIs** are done. The **write/automation engine** is the remaining build.

| # | Task | Effort |
|---|------|--------|
| F-1 | Ledger write-triggers on booking/payment/refund/cancel events | 3–4 d |
| F-2 | Payout scheduler + execution orchestration | 3–4 d |
| F-3 | Reconciliation engine (booking ↔ payment ↔ payout ↔ gateway variance) | 3–4 d |
| F-4 | GST-ready invoice generation + PDF rendering | 2–3 d |
| F-5 | Financial audit log for manual adjustments + KPI query optimisation | 2 d |

**FMS subtotal: ≈ 13–17 person-days (~2.5–3.5 weeks).**

---

## 4 · HMS — Backend completion (host systems)

| # | Task | Effort |
|---|------|--------|
| M-1 | Host statements search + download endpoints | 2 d |
| M-2 | Host support tickets CRUD APIs | 2 d |
| M-3 | Host messaging APIs + delivery statuses (REST; socket.io chat deferred) | 2–3 d |
| M-4 | Host performance analytics endpoints | 2–3 d |

**HMS subtotal: ≈ 8–10 person-days (~1.5–2 weeks).**

---

## 5 · Security / RBAC

| # | Task | Effort |
|---|------|--------|
| S-1 | RBAC claims in JWT for all roles (admin/finance/host/support/guest) + FE route guards | 3–4 d |
| S-2 | Refresh-token policy + secure session lifecycle | 2 d |

**Security subtotal: ≈ 5–6 person-days (~1 week).**

---

## 6 · Mobile app (Flutter)

| # | Task | Effort |
|---|------|--------|
| MA-1 | Sand & Indigo design pass on the app | 5–6 d |
| MA-2 | KYC gates + flows aligned with backend/DIDIT | 3–4 d |
| MA-3 | On-device QA (needs human tester + devices) | 3–4 d |

**Mobile subtotal: ≈ 11–14 person-days (~2–3 weeks).** Requires a human device-tester.

---

## 7 · QA, UAT & go-live

| # | Task | Blocker | Effort |
|---|------|---------|--------|
| Q-1 | End-to-end test walks (guest book→pay→stay→review; host onboard→list→payout; admin finance) | UAT env + seeded data | 3–4 d |
| Q-2 | Client UAT support + fixes | 🔑 Client UAT availability | 3–5 d |
| Q-3 | Go-live + production verification + release notes | None | 1–2 d |
| Q-4 | 30-day post-go-live stabilisation support (per contract) | — | (ongoing) |

**QA/UAT subtotal: ≈ 7–11 person-days (~1.5–2 weeks).**

---

## 8 · Nice-to-have / deferred (not launch-blocking)

| # | Task | Effort |
|---|------|--------|
| N-1 | Exhaustive India city dataset (current = curated major cities) | 1 d |
| N-2 | WebSocket/real-time chat & notifications (polling ships now) | 3–5 d |
| N-3 | Performance optimisation sweep beyond essentials | 2–3 d |

---

## 9 · Totals & dependency summary

| Bucket | Effort (person-days) | Launch-critical? |
|---|---|---|
| P0 launch path | 9–12 | ✅ Yes |
| Host onboarding & KYC | 6–9 | ✅ Yes |
| FMS backend completion | 13–17 | ✅ Contract scope |
| HMS backend completion | 8–10 | ✅ Contract scope |
| Security / RBAC | 5–6 | ✅ Yes |
| Mobile app | 11–14 | Contract scope |
| QA / UAT / go-live | 7–11 | ✅ Yes |
| Nice-to-have | 6–9 | ❌ Optional |
| **Total (excl. nice-to-have)** | **≈ 59–79 person-days** | |

**≈ 7.5–10 person-weeks of engineering remain.** With the current 2-engineer team running in parallel, that is roughly **4–6 calendar weeks** of focused work **once client blockers are cleared**.

### 🔑 Items we need from AAJOO to unblock (critical path)
1. **Live Razorpay keys** (gates payments + booking persistence + payment emails).
2. **DIDIT credentials + updated host registration form spec** (gates host KYC).
3. **Real support contact numbers** (WhatsApp/phone/email).
4. **UAT environment availability + sign-off windows.**

Every day these are delayed pushes the dependent tasks day-for-day.
