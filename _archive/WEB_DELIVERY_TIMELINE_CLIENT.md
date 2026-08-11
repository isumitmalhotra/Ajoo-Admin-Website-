# AajooHomes — Website Delivery Timeline (Version 1)

**Prepared by:** Zyphex Technologies
**Prepared for:** AAJOO Homes Pvt. Ltd.
**Date:** 17 June 2026
**Scope:** Website — Customer site, Admin dashboard, Host Management System (HMS), and Finance Management System (FMS).

---

## 1. Headline dates

| Milestone | Date | What it means |
|---|---|---|
| **Functional Version 1 (QA-clean)** | **Wed, 24 June 2026** | Every flow works end-to-end with **no errors and no broken pages** across the Customer site, Admin, HMS, and FMS. Payments run on the gateway's secure **test mode**. This is the "first complete version." |
| **Polished & UAT-ready** | **Fri, 26 June 2026** | Final UI-polish items complete; ready for AAJOO Homes to run User Acceptance Testing. |
| **Production go-live** | **Mon, 29 June 2026** | Live payment gateway and KYC enabled, production security controls switched on, and a real transaction verified. |

**Assumptions:** dedicated full-time development · test mode is acceptable for the Version 1 handoff · the credentials AAJOO Homes provides (live payment keys, KYC provider, transactional email sender) reach us within ~1 week.

---

## 2. Definition of "complete Version 1"

A customer can:
- Browse the homepage and listings, view **all** properties, and open any property's detail page.
- Use **all filters** (price, destination/state, guests, search) on both the home and listing pages.
- **Book** a property end-to-end → pay → **receive an invoice** → see it under My Bookings / Ongoing.

And, with **zero errors**:
- **Admin** can perform every administrative operation in the dashboard (properties, bookings, users, hosts, coupons, content/CMS, analytics, settings, notifications).
- **HMS** — the host portal works fully for a host (dashboard, bookings, earnings, payout account, statements, support, performance, profile).
- **FMS** — every finance screen displays real data (dashboard, ledger, payouts, reconciliation, invoices, reports).

---

## 3. Current status — already delivered

**Backend (deployed and verified against the live environment):**
- **FMS** — complete finance suite: ledger, payouts, payout schedules, reconciliation, invoices with PDF, and reports.
- **HMS** — complete host suite: host dashboard, bookings, payout account, statements, support, performance, plus the admin-side host detail / KYC / payout panels.
- KYC verification, in-app notifications, role-based access control, and transactional email — all built and ready, pending only the live credentials.

**Admin website:** Settings, Notification Center, host-management screens, and all finance pages connected to live data.

**Customer website:** Full visual redesign complete. Recently delivered: interactive maps (pan-to-load, recenter / near-me, price markers), search & filters (price and destination chips, guest selector, destination suggestions), wishlist, the complete booking-and-invoice flow, admin-managed categories, and the ongoing-booking experience.

---

## 4. Remaining work

### 4.1 Customer site
| Item | Effort | Phase |
|---|---|---|
| Final payment-flow verification (book → pay → invoice) | 0.5 day | 1 |
| Booking-cancellation page redesign | 0.5 day | 1 |
| "Become a Host" page + onboarding form | 1 day | 1 |
| Forgot-password / password-reset flow | 0.5 day | 1 |
| Customer notification indicator | 0.25 day | 1 |
| Booking safeguards (prevent overlapping bookings; one active pay-on-arrival at a time) | 0.5 day | 1 |
| Invoice tax (GST) rate | *Pending confirmation from AAJOO Homes* | — |

### 4.2 Admin
| Item | Effort | Phase |
|---|---|---|
| Full module walkthrough and fix of any issue found | included in Phase 2 | 2 |
| Cross-module KPIs and reports-center refinement | 0.5 day | 3 |

### 4.3 Host Management System (HMS)
| Item | Effort | Phase |
|---|---|---|
| Host portal end-to-end walkthrough and fixes | included in Phase 2 | 2 |
| Host announcement slider (*needs content from AAJOO Homes*) | 0.5 day | 3 |

### 4.4 Finance Management System (FMS)
| Item | Effort | Phase |
|---|---|---|
| Validate all finance screens against live data; refine edge cases | included in Phase 2 | 2 |

### 4.5 UI-polish items
| Item | Effort | Phase |
|---|---|---|
| Home announcement slider | 0.5 day | 3 |
| Illustrations, responsive footer, Help-page social links | 0.5 day | 3 |
| About-Us redesign; Settings and sidebar cleanup | 1 day | 3 |
| Multi-step signup; consistent typography throughout | 0.5 day | 3 |
| Document-upload experience + orientation enforcement | 0.5 day | 3 |
| Profile summary section | 0.25 day | 3 |

### 4.6 Production hardening (required before go-live)
| Item | Owner |
|---|---|
| Switch on all production security controls (live OTP / email verification, mandatory KYC document checks, full input validation) | Zyphex |
| Configure production media storage | Zyphex / AAJOO Homes |
| Enable live transactional email (incl. OTP) | AAJOO Homes + Zyphex |
| Enable live payment gateway + verify one real transaction | AAJOO Homes + Zyphex |
| Enable live KYC verification + test | AAJOO Homes + Zyphex |

---

## 5. Phased timeline

```
Phase 1   Thu 18 → Sat 20 Jun   Booking flow completion + functional gaps
            Payment verification · cancellation page · Become-a-Host ·
            forgot-password · notification indicator · booking safeguards

Phase 2   Sun 21 → Wed 24 Jun   Full quality-assurance pass + fixes
            Systematic walkthrough of Customer / Admin / HMS / FMS,
            logging and fixing every issue
            → Functional Version 1 (test mode), QA-clean   [Wed 24 Jun]

Phase 3   Thu 25 → Fri 26 Jun   UI-polish items
            Sliders, illustrations, About-Us, settings, signup, typography
            → Polished & UAT-ready                          [Fri 26 Jun]

Phase 4   Sat 27 → Mon 29 Jun   Production cutover
            Production security controls on · media storage · live email ·
            live payment gateway · live KYC · real transaction test
            → Production go-live                            [Mon 29 Jun]
```

---

## 6. Key dependencies & risks

| Item | Impact | How we manage it |
|---|---|---|
| **Live credentials reach us later than ~24 June** | Affects **only** the go-live date — not the Version 1 (test mode) or UAT-ready milestones | Version 1 is fully usable and demoable without them; the live cutover is a one-day switch whenever the credentials arrive. |
| **QA surfaces deeper issues in Admin / HMS / FMS** | Could extend Phase 2 | The backend is already verified against the live environment, so remaining risk is mostly front-end display and edge cases — low. |
| **Tax (GST) decision stays open** | Affects final invoice tax percentage | Does not block the functional Version 1; the invoice notes the figure as subject to confirmation until AAJOO Homes confirms the rate. |
| **Production-hardening checklist** | Security and data integrity | Completing this checklist is a firm gate before go-live. |

---

## 7. Summary for AAJOO Homes

- **Wed 24 June** — a fully working website you can click through end-to-end (browse → filter → book → invoice; Admin, Host, and Finance all functional), with payments in secure test mode.
- **Fri 26 June** — polished and ready for your UAT.
- **Mon 29 June** — live in production with real payments and KYC, assuming your live payment / KYC / email credentials reach us by ~24 June.
