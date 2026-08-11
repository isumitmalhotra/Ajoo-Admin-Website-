# AAJOO Homes — Timeline Impact & Execution Plan

**Prepared by:** Zyphex Technologies · **For:** AAJOO Homes Pvt. Ltd.
**Date:** 14 June 2026

> **Purpose:** Document the impact of the delayed codebase delivery and post-signing scope additions on the original timeline, and present a clear, realistic plan and ownership for completing the project.

---

## 1 · The original agreement

| Item | Value |
|---|---|
| Contract signed | **11 Feb 2026** |
| Investment | ₹1,60,000 (all-inclusive) |
| Duration | **10–12 weeks** build + **30-day** post-go-live support (≈ **2.5 months**) |
| Original go-live target | ≈ **end of April 2026** |
| Scope at signing | Platform enhancements (admin/web/backend), FMS, HMS, QA/UAT, go-live |

---

## 2 · What actually happened

### 2.1 Critical dependency arrived ~2 months late
The project depended on AAJOO providing the working base codebase (website + app + backend) to build upon. That codebase was **shared on ~20–21 May 2026** — roughly **two months after** the plan required it. The 10–12 week clock could not meaningfully start until then.

### 2.2 Scope grew substantially after signing
Significant work was **added after the original agreement**, including (non-exhaustive):
- Full **Sand & Indigo design system** + redesign of the **entire customer website** (and mobile direction).
- Rebuilding the customer site from **mock/static data to a live, data-driven product** (home, search, map, listing, property detail, account area).
- Redesign of **all 9 content/marketing pages**.
- Smart onboarding (location autofill, real state/city data, themed calendar, validation UX), in-app directions, WhatsApp host chat, checkout redesign, and more.

### 2.3 The expectation compressed to ~3.5 weeks
Despite the late start and added scope, the expectation became **full delivery by 15 June 2026** — i.e., **~3.5 weeks** after the codebase was received.

---

## 3 · The impact (the numbers)

| Measure | Reality |
|---|---|
| Normal effort already delivered | **≈ 13–16 person-weeks** (Doc 1) |
| Window it was delivered in | **~3.5 weeks** (20–21 May → 15 June) |
| Remaining scope to full launch | **≈ 7.5–10 person-weeks** (Doc 2) |
| Original effort + additions (normal pace) | **≈ 21–26 person-weeks (~5–6 months)** |
| Time available before the 15 June expectation | **~3.5 weeks** |

**Conclusion:** A scope that is realistically **5–6 months** of normal-paced engineering — enabled by an input that arrived **~2 months late** — cannot be fully delivered in a **~3.5-week** window. The volume already shipped only happened through sustained parallel execution and heavy compression; the remaining ~7.5–10 weeks of work cannot be compressed the same way without serious risk to quality, the money path, and launch stability.

### 3.1 Impact on AAJOO's business
- **Already live & working:** the customer website, browse→book funnel, admin + host portals, and shared backend are deployed and data-driven — AAJOO has a usable product today, not a delayed start.
- **Risk if forced into 15 June:** the **money path** (live payments, booking persistence, payout/reconciliation, GST invoices) and **host KYC** need careful, tested implementation. Rushing these is the highest business risk (financial correctness, compliance, guest/host trust). A phased launch protects revenue and reputation.

### 3.2 Impact on Zyphex's load
- Delivered ~13–16 weeks of work in ~3.5 weeks = a multiple of normal capacity, absorbed by the team.
- The remaining finance engine (FMS), host systems (HMS), RBAC, KYC, and mobile work is genuine, testable engineering that needs realistic time — it is not absorbable into days.

---

## 4 · Execution plan going forward (phased, realistic)

> Dates assume the **four client blockers (§6) are cleared this week**. Each day of blocker delay shifts the dependent phase day-for-day.

### Phase A — Website production launch (P0 money + safety)
**Target: ~20–24 June 2026** · Razorpay live, booking persistence, transactional emails, revert dev-bypasses, seed purge, CORS hardening, support contacts → **soft-launch the customer website + real bookings**.
*Blocked on: live Razorpay keys + support numbers.*

### Phase B — Finance & host systems (contract core)
**Target: ~3.5–4 weeks (mid-July)** · FMS engine (ledger triggers, payout scheduler, reconciliation, GST invoices), HMS backend (statements, tickets, messaging, performance), RBAC/JWT claims, **host KYC via DIDIT** + updated registration form.
*Blocked on: DIDIT creds + host form spec.*

### Phase C — Mobile app
**Target: ~2–3 weeks (can overlap Phase B; late July)** · Sand & Indigo pass, KYC gates, on-device QA.
*Needs: a human device tester.*

### Phase D — UAT, go-live, stabilisation
**Rolling** · E2E walks, client UAT, production verification, then the contracted 30-day support window.
*Needs: client UAT availability + seeded test data.*

**Realistic full-delivery target with blockers cleared now: late July 2026.** A working **website + booking soft-launch is achievable in the 3rd–4th week of June.**

---

## 5 · Ownership

| Area | Owner |
|---|---|
| Website (customer/admin/host), backend FMS/HMS, KYC, RBAC, mobile, QA | **Zyphex Technologies** (engineering) |
| Razorpay live keys, DIDIT creds, host form spec, support numbers, UAT availability + sign-off, content/data decisions | **AAJOO Homes** (client) |
| Phased timeline approval, scope prioritisation | **Joint** (this meeting) |

---

## 6 · Asks for the meeting (to keep us on the critical path)

1. **Approve a phased, realistic timeline** (Phase A website launch first; full delivery late July) in place of a single 15 June date.
2. **Acknowledge the revised baseline** = original scope + post-signing additions, with the build clock starting ~20 May (codebase receipt).
3. **Clear the four blockers now:** (a) live **Razorpay** keys, (b) **DIDIT** creds + updated host form, (c) real **support** numbers, (d) **UAT** environment + availability.
4. **Agree scope vs. timeline trade-offs** if 15 June must hold for any piece (e.g., website-only soft launch on 15 June, finance/KYC/mobile to follow).

---

*Reference: Doc 1 (Work Delivered) and Doc 2 (Pending Tasks & Timelines). Live product: https://www.aajoohomes.com · backend: https://aajaodev.onrender.com.*
