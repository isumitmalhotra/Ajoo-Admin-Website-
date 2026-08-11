# AajooHomes — Web Platform Completion Timeline (v1 Handoff)

> **Prepared:** 2026-06-17 (Wed) · **Author:** Sumit + Claude (full-time)
> **Scope of this doc:** Website only — Customer web + Admin dashboard + **HMS** (Host Management) + **FMS** (Finance Management). Mobile app is covered in the separate **`FULL_PLATFORM_COMPLETION_TIMELINE.md`**.
> **Companion live trackers:** `WEB_BUG_TASKLIST.md`, `SESSION_HANDOFF.md`, `TASK_TRACKER.md`, `FULL_DELIVERY_PLAN.md`.

---

## 0 · Headline dates

| Milestone | Date | What it means |
|---|---|---|
| **M-W1 — Functional v1 (test mode), QA-clean** | **Wed 24 Jun 2026** | Every flow works end-to-end with **no errors / no broken pages** across Customer, Admin, HMS, FMS. Payments on Razorpay **test** mode. This is your "first complete version" bar. |
| **M-W2 — Polished + UAT-ready** | **Fri 26 Jun 2026** | UI-polish batch done; client can run UAT. |
| **M-W3 — Web production go-live** | **Mon 29 Jun 2026** | Live Razorpay + DIDIT KYC cutover, dev-bypasses reverted, Cloudinary creds in, one real ₹1 payment verified. *(Assumes client creds land by ~24 Jun, per your estimate.)* |

**Assumptions baked in:** full-time "me + Claude" pace · test mode is acceptable for the v1 handoff · client provides Razorpay live + DIDIT + Brevo creds within ~1 week.

---

## 1 · Definition of "complete v1" (the acceptance bar)

A user can:
- Browse the homepage + listing, see **all** properties, open any property detail.
- Use **all filters** (price, state/destination, guests, search) on home **and** listing.
- **Book** a property end-to-end → pay (test mode) → **receive an invoice** → see it in My Bookings / Ongoing.

And, with **zero errors**:
- **Admin** can run every admin operation in the dashboard (CRUD, bookings, users, hosts, coupons, CMS, analytics, settings, notifications).
- **HMS** — host portal works for a host (dashboard, bookings, earnings, payout account, statements, support, performance, profile).
- **FMS** — all 15 finance pages render real data (dashboard, ledger, payouts, reconciliation, invoices, reports).

---

## 2 · What's already DONE (so the timeline is honest about the starting line)

**Backend (deployed to Render, authenticated-smoke verified — FMS 27/27, HMS 24/24, zero 500s):**
- FMS: 27 endpoints (ledger, payouts, schedules, reconciliation, invoices+PDF, reports).
- HMS: 24 endpoints (host dashboard/bookings/payout-account/statements/support/performance + admin host detail/KYC/payout panes).
- KYC (DIDIT) backend + webhook, Notifications feed, RBAC role claims, Brevo email transport — all **code-complete**, gated only on env-var creds.

**Admin web:** Settings, Notification Center, Host-management 4-tab dialog, all 15 FMS pages — wired to real backend.

**Customer web:** Sand & Indigo redesign complete (28 QA bugs fixed); this cycle shipped maps (pan-to-load / recenter / far-pan / price chips), search & filters (price/state chips, guest selector, autocomplete), wishlist, the **rewired booking flow** (createBooking → Razorpay order → verify → invoice), categories-from-admin, ongoing-booking popup + map.

---

## 3 · PENDING work by area (this is what the timeline burns down)

### 3.1 Customer web
| Item | Ref | Effort | Phase |
|---|---|---|---|
| Razorpay **TEST** payment verification (book → pay → invoice) — manual | SESSION_HANDOFF §A | 0.5d | W1 |
| Cancel-page redesign | bug 64 | 0.5d | W1 |
| **Become-a-host** page + onboarding form + wire (link exists, page missing) | GAP-01/02/03, P3-GST-02 | 1d | W1 |
| Forgot-password flow (public reset) | Common 5 / 88, INT-12 | 0.5d | W1 |
| Notification icon (customer) | Common 7 | 0.25d | W1 |
| Booking guards: no overlapping booking / one active POA (test-mode enforce) | bugs 67, 60, 61 | 0.5d | W1 |
| GST display alignment | — | **PARKED** (client decision pending) | — |

### 3.2 Admin
| Item | Ref | Effort | Phase |
|---|---|---|---|
| Full CRUD + module regression walk, fix any error surfaced | P5-QA | included in W2 | W2 |
| Cross-module KPI / reports-center polish | P3-ADM-01/02 | 0.5d | W3 |

### 3.3 HMS (Host)
| Item | Ref | Effort | Phase |
|---|---|---|---|
| Host portal end-to-end regression (dashboard→payout→statements→support→performance) | P3-HST-* | included in W2 | W2 |
| Host communication center — honest empty-state (messaging cut to tickets) | INT-08 / P3-HST-08 | already wired; verify | W2 |
| Announcement slider (host) | Host 3 | 0.5d (needs content) | W3 |

### 3.4 FMS (Finance)
| Item | Ref | Effort | Phase |
|---|---|---|---|
| Walk all 15 pages against real data; fix variance/edge-case display | P4-FMS-07/08 | included in W2 | W2 |
| GST/TDS invoice numbers vs displayed % reconciliation | tied to parked GST | with GST decision | — |

### 3.5 UI-polish batch (the "few more UI changes")
| Item | Ref | Effort | Phase |
|---|---|---|---|
| Announcement slider on home (4–5 colored) | Common 23 | 0.5d | W3 |
| Illustrations/SVGs, footer social responsive, Help-page social | 16/18/23 | 0.5d | W3 |
| About-Us redesign; Settings cleanup; sidebar redesign | 26/92/30/31/17 | 1d | W3 |
| Signup → multi-step; consistent Aajoo font | 7 / Common 3 | 0.5d | W3 |
| Document-upload UX + landscape enforcement; duplicate-page cleanup | 35/36/95 | 0.5d | W3 |
| Profile summary in top section | 20 | 0.25d | W3 |

### 3.6 Production-hardening (cutover gate — not optional for go-live)
| Item | Ref | Owner | Phase |
|---|---|---|---|
| Revert **9 DEV-BYPASSES** (OTP `000000`, KYC doc skip, Yup `.optional()`, validation skips) | TASK_TRACKER §DEV-BYPASS | dev | W4 |
| Add **Cloudinary** creds on Render | pre-prod checklist | client/ops | W4 |
| **Brevo** email/OTP cutover (`OTP_DEV_BYPASS=false`) | EMAIL-01..04 | client+dev | W4 |
| **Razorpay LIVE** keys + 1 real ₹1 payment | PAY-01/03 | client+dev | W4 |
| **DIDIT** KYC creds + webhook registration | KYC-BE | client+dev | W4 |

---

## 4 · Phased timeline (full-time, from Wed 17 Jun)

```
W1  Thu 18 → Sat 20 Jun   Booking loop + functional gaps
     • Razorpay test payment proven  • Cancel page  • Become-a-host + onboarding
     • Forgot-password  • Notification icon  • Booking guards
W2  Sun 21 → Wed 24 Jun   Full QA regression + fix loop (Customer / Admin / HMS / FMS)
     • Systematic walk of every module, log + fix every error
     • → M-W1: Functional v1 (test mode), QA-clean  [Wed 24 Jun]
W3  Thu 25 → Fri 26 Jun   UI-polish batch (P2)
     • Sliders, illustrations, About redesign, settings, signup steps, fonts, doc-upload
     • → M-W2: Polished + UAT-ready  [Fri 26 Jun]
W4  Sat 27 → Mon 29 Jun   Production cutover (after client creds, ~by 24 Jun)
     • Revert 9 bypasses  • Cloudinary  • Brevo live  • Razorpay live  • DIDIT
     • Real ₹1 payment + KYC smoke
     • → M-W3: Web production go-live  [Mon 29 Jun]
```

---

## 5 · Critical path & risks

| Risk | Impact | Mitigation |
|---|---|---|
| **Client creds slip past ~24 Jun** | Pushes M-W3 only (go-live), **not** M-W1/M-W2 | v1 (test mode) is fully usable + demoable without them; cutover is a 1-day swap whenever creds arrive. |
| QA regression surfaces deep bugs in Admin/HMS/FMS | Extends W2 | Backend already authenticated-smoke-clean; most risk is FE display/edge-case → low. |
| GST decision stays open | Blocks final invoice % correctness | Parked by you; doesn't block v1 functional handoff — flagged on the invoice as "subject to confirmation." |
| Dev-bypasses shipped to prod by mistake | Security/data integrity | W4 revert is a hard gate before go-live; all 9 are tagged `// [DEV-BYPASS]`. |

---

## 6 · TL;DR for the client

- **Wed 24 Jun** — fully working website you can click through end-to-end (browse → filter → book → invoice; admin/host/finance all functional), payments in test mode.
- **Fri 26 Jun** — polished + ready for your UAT.
- **Mon 29 Jun** — live in production with real payments + KYC (assuming your Razorpay/DIDIT/email creds reach us by ~24 Jun).
- Then the contract's **30-day stabilization support** window runs from go-live.
