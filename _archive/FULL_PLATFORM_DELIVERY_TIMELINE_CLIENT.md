# AajooHomes — Full Platform Delivery Timeline (Web + Mobile)

**Prepared by:** Zyphex Technologies
**Prepared for:** AAJOO Homes Pvt. Ltd.
**Date:** 17 June 2026
**Scope:** The complete platform on the shared backend — Customer website, Admin dashboard, Host Management System (HMS), Finance Management System (FMS), **and** the mobile application — so that **both web and mobile offer the same functionality.**

*(The website portion is detailed in the companion document, "AajooHomes — Website Delivery Timeline (Version 1)". This document summarizes the web track and adds the mobile track and the joint go-live.)*

---

## 1. Headline dates

| Milestone | Date | What it means |
|---|---|---|
| **Website — Functional Version 1 (QA-clean)** | **Wed, 24 June 2026** | Browse → filter → book → invoice, with Admin / HMS / FMS error-free (test mode). |
| **Website — Production go-live** | **Mon, 29 June 2026** | Live payments and KYC enabled. |
| **Full platform — our work complete & submitted** | **~Fri, 4 July 2026** | Mobile renter and host flows verified on a device (light and dark themes), connected to the same backend, live cutover done, and the release build **submitted to Google Play for review.** Buffer to **Tue, 8 July** if the mobile readiness audit reveals larger integration work. |
| **Live on the Play Store** | **Above date + Google's review time** | Outside our control — see the note below. |

> **⚠️ Play Store review time is additional and is not part of our delivery date.**
> We deliver our end of the work — the app **built, tested on a device, and submitted to Google Play** — by **~4 July 2026**. We complete and submit it for review as early as possible, but the **actual go-live on the Play Store then depends on Google's review process, which can take additional days and is entirely outside our control.** Our commitment is the submission-ready build by the stated date; publication follows once Google approves.

**Assumptions:** dedicated full-time development · live credentials within ~1 week · a device and a tester are available for mobile QA (confirmed) · for UAT, the app can be shared directly (side-loaded) so testing is not held up by store review.

---

## 2. Definition of "full platform complete"

Everything in the website's Version 1 definition (see the companion website document), **plus** on mobile:
- A renter can browse → filter → open a property → book → pay → receive an invoice → view bookings, in **both light and dark themes.**
- A host can run the host flows (dashboard, add / update property, bookings, ongoing bookings, payout, invoices, support, profile).
- Mobile uses the **same backend** as the website, so the two platforms stay at feature parity (KYC, notifications, support, performance, etc.).

---

## 3. Current status — already delivered

**Shared backend:** the finance, host-management, KYC, notifications, access-control, and email systems are all built, deployed, and verified — and the same services power both web and mobile.

**Website:** redesign, customer-funnel work, and Admin / HMS / FMS integration complete (see the companion website document).

**Mobile application:**
- Full visual redesign complete and confirmed in the current build (consistent branding, light and dark themes).
- The app compiles successfully and the renter and host screens are restyled (home, property, booking, payout, invoices, support, profile).

---

## 4. Remaining work — mobile track

*(Website remaining work is in the companion website document.)*

| Item | Effort | Phase |
|---|---|---|
| **Mobile readiness audit** — confirm which backend capabilities the app already uses versus any gaps (notifications, KYC, support, performance, host payout/statements parity); confirm a clean run on the test device | 1 day | M0 |
| **Backend feature-parity integration** — close the gaps identified in the audit so mobile matches the website | 2–4 days | M1 |
| **On-device QA — renter**, light and dark (Home → Details → Checkout → Confirmation) | 1 day (with fixes) | M2 |
| **On-device QA — host**, light and dark (all host screens) | 1 day (with fixes) | M2 |
| **Final production hardening** (switch on production security controls in the app) | 0.5 day | M3 |
| **Live cutover on mobile** — live payments and KYC, verified with a real transaction on a device | 0.5 day | M3 |
| **Release build** — signed app package + **submission to Google Play** | 0.5 day (+ Google review) | M3 |

> The **readiness audit on 27 June** is the key step: it converts the "how much mobile integration remains?" question into a firm number and sizes the 2–4 day integration window precisely.

---

## 5. Phased timeline

```
═══ WEBSITE (detailed in the companion website document) ═══
  Thu 18 → Sat 20 Jun   Booking flow + functional gaps
  Sun 21 → Wed 24 Jun   Full QA pass → Website Version 1 (test mode)   [Wed 24 Jun]
  Thu 25 → Fri 26 Jun   UI polish → UAT-ready                          [Fri 26 Jun]
  Sat 27 → Mon 29 Jun   Live cutover → Website production go-live       [Mon 29 Jun]

═══ MOBILE (begins as the website QA/polish winds down) ═══
  M0  Fri 27 Jun           Mobile readiness audit — gap list + device run
  M1  Sat 28 → Tue 1 Jul   Backend feature-parity integration
  M2  Wed 2 → Thu 3 Jul    On-device QA: renter + host, light + dark, with fixes
  M3  Fri 4 Jul            Final hardening + live cutover + release build + Play Store submission
                           → Full platform: our work complete & submitted   [~Fri 4 Jul]

  Play Store go-live = ~4 Jul + Google's review time (additional, outside our control)
```

---

## 6. Key dependencies & risks

| Item | Impact | How we manage it |
|---|---|---|
| **Google Play review** (and Apple review if an iOS build is added) | **Additional days after our delivery date, outside our control** — our work (build + submission) is complete by the date; Google's approval and publishing time is separate | We complete and submit as early as possible so Google's clock starts sooner; for UAT we can share a direct build so your testing isn't blocked on store approval. **This review time is explicitly not included in our delivery date.** |
| **Mobile audit reveals larger integration work** | Could push the full-platform date toward ~8 July | The audit is the first mobile step precisely to firm up the date by 27 June. |
| **Live credentials reach us later than planned** | Affects both web go-live and the mobile cutover | Both platforms run fully on secure test mode until then; the live switch is one coordinated step. |
| **Device-only mobile issues** (theme, layout, payment SDK) | Could extend on-device QA | A device and tester are confirmed available, enabling a tight fix loop. |

---

## 7. Note on schedule

Web and mobile are scheduled largely in sequence, with the mobile track starting as the website quality-assurance phase winds down. With **additional parallel resourcing**, the mobile track can begin alongside the website work and pull the full-platform date earlier (toward ~1 July). We're happy to discuss this option if an earlier mobile date is a priority.

---

## 8. Summary for AAJOO Homes

- **Wed 24 June** — website fully working end-to-end (test mode).
- **Mon 29 June** — website live in production (real payments and KYC).
- **~Fri 4 July** — mobile app verified on a device (renter + host, light and dark), on the same backend, live cutover done, **and submitted to Google Play** → **our end of the work is complete by this date.**
- **Play Store go-live** — we submit as early as possible, but the publish date depends on **Google's review process, which takes additional days and is outside our control.** For UAT we can share the app directly so your testing isn't held up.
