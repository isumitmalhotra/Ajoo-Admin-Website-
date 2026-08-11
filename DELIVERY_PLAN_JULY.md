# AAJOO Homes — Delivery Plan: Redesigned Platform (Web + Mobile), Fully Wired & Testable

> **Target delivery: 31 July 2026** *(with a contingency buffer of up to 1 week — see Section 6b)*
> **Prepared by:** Zyphex Tech · **Date:** 13 July 2026 · **For:** Client review

---

## 1. Objective

Deliver the **complete redesigned AAJOO Homes platform — web and mobile — on the new UI**, with **all backend functionality connected to that new UI**, so that by **31 July 2026** the client can **test every function directly on the latest design**, across renter, host, and admin.

Because the **backend is shared** across web and mobile and the **design system, components, and flows are common**, both applications are built and wired from the same foundation — allowing us to complete web and mobile in parallel within the same window.

---

## 2. What "done" means (definition of delivery)

By 31 July, the platform will meet all of the following:

1. **Every screen uses the new design** — web (renter, host, admin) and the mobile app (guest + host).
2. **Every screen is connected to the live backend** — real listings, bookings, payments (test mode), KYC, payouts, invoices, notifications, and finance/admin data. No placeholder/mock data remains.
3. **The client can test end-to-end on the new UI:**
   - **Guest:** browse → negotiate → book → pay → manage stays, on web and mobile.
   - **Host:** list → manage bookings → calendar → earnings/payouts → KYC, on web and mobile.
   - **Admin:** manage users, hosts, properties, bookings, and the full Finance Management System.
4. **Deployed and testable** — web on a live/staging environment, mobile as an installable Android build, with UAT accounts and a test guide provided at handover.

---

## 3. Current progress (starting point)

The redesign is already well underway — the foundation and the majority of the guest and host web experience are built on the new UI:

| Segment | New UI | Backend wiring |
|---|---|---|
| Guest web — discovery, property, search, auth | ✅ Built | In progress |
| Guest web — account & booking | ✅ Built | In progress |
| Host web — portal | ✅ 14 of 17 pages | In progress |
| Admin web — portal (incl. Finance) | To build (18 pages) | To wire |
| Mobile app (Flutter) | To reskin + wire | Shares the same live backend |

The backend is already built and running in production (bookings, payments, KYC, payouts, Finance/FMS, notifications). This delivery is about **completing the new UI on both web and mobile and connecting them to that existing backend** — not building new backend systems.

---

## 4. Remaining work

**A. Finish the new web UI**
- Host portal: 3 remaining pages (add-property, register, landing).
- Admin portal: 18 pages (dashboard, analytics, reports, users, hosts, properties, bookings, payments, negotiations, reviews, disputes, boost, refer, coupons, CMS, settings, roles, logs).

**B. Rebuild the mobile app on the new UI (Flutter)**
- Apply the shared design system (colours, typography, icons, components) to the app.
- Reskin guest screens (getting-started, login, explore, property detail, dashboard, bookings, ongoing, negotiate, saved, profile) and host screens (dashboard, properties, add-property, bookings, messages, profile) to the new mockups.
- Parity with web: in-app KYC (DIDIT), updated add-property fields, verification status display, invoice download, availability calendar, refreshed splash.

**C. Connect all backend functionality to the new UI (web + mobile)**
- Wire every redesigned screen to the existing live services / data layer, replacing all placeholder data — guest, host, and admin (including the Finance Management System: ledgers, payouts, reconciliation, reports, invoices).
- Role-based routing and auth guards; make the new UI the primary experience.

**D. Stabilize & make testable**
- End-to-end QA across renter, host, admin — on web and mobile.
- Responsive / device testing, bug-fix, security & environment hardening.
- Deploy web + produce the Android build; provide UAT accounts and a test guide.

---

## 5. The plan — three sprints to 31 July

Web and mobile run as **parallel workstreams** on the shared backend and design system, converging on integrated QA in the final sprint.

### Sprint 1 — 13–19 July · *Build + wire the core*
- **Web:** finish the 3 remaining host pages; build the admin shell + first set of admin pages (dashboard, users, hosts, properties, bookings, Finance); wire the guest journey (search → property → negotiate → book → pay → confirmation, invoices, notifications) and host core (dashboard, properties, bookings, availability, KYC).
- **Mobile:** apply the new design system; reskin the guest core screens and wire them to the shared backend.
- **Milestone:** guest booking journey + host core running on the new UI against real data — on both web and mobile.

### Sprint 2 — 20–26 July · *Complete + connect everything*
- **Web:** complete all remaining admin pages; wire the full admin portal + **Finance Management System**; wire remaining host pages (earnings, payouts, negotiations, messages, performance, profile) and guest account pages (transactions, reviews, notifications, settings, refer, support); switch the new UI to primary with role-based routing.
- **Mobile:** reskin host screens + remaining guest screens; complete parity items (KYC, add-property fields, verification status, invoice, availability); wire to controllers.
- **Milestone:** entire platform — web (renter/host/admin) and mobile (guest/host) — on the new UI and connected to the backend. Feature-complete for testing.

### Sprint 3 — 27–31 July · *Integrate, QA, stabilize, hand over*
- Full end-to-end QA across all roles on both web and mobile; bug-fix.
- Responsive / device pass; security & environment hardening; live end-to-end verification (booking → payment → notification → payout → invoice).
- Deploy web; produce the Android build; prepare UAT accounts + test guide.
- **Delivery (31 July):** redesigned, fully wired, stabilized web + mobile platform — the client tests every function on the latest UI.

---

## 6. Effort & staffing

| Workstream | Estimate (dev-days) |
|---|---|
| Finish host web UI (3 pages) | ~2.5 |
| Build admin web UI (18 pages) | ~9 |
| Wire web to backend (guest + host + admin/FMS) | ~14 |
| Mobile reskin + parity + wiring | ~16 |
| Routing / auth / new UI primary | ~2 |
| QA, responsive, security hardening, deploy (web + mobile) | ~7 |
| **Total** | **~50 dev-days** |

Delivered in parallel by a **web pair + a mobile developer (~3 developers)** across the available working days, converging on QA in Sprint 3 — this schedule hits **31 July**.

---

## 6b. Contingency buffer (please note)

The **31 July** target is a firm, committed plan. However, this is an intensive delivery covering the full web and mobile platform in parallel, and — as with any project of this size — **unforeseen issues can surface** during integration and testing (e.g. edge cases discovered in QA, device-specific mobile behaviour, or delays in the client inputs listed in Section 7).

To account for this, we are formally advising a **contingency buffer of up to 1 week**. In the event that unforeseen issues arise, delivery may extend to **on or before 7 August 2026**. We will flag any such risk **as early as it is identified**, not at the deadline, so there are no surprises. Barring these, our plan and intent remain to deliver by **31 July**.

---

## 7. What we need from the client (inputs)

You have confirmed these will be provided as required. Supplying them **early in Sprint 1** keeps every screen fully live at delivery:

| # | Input | Enables |
|---|---|---|
| 1 | Final brand assets — logo set, favicon / app icons | New-UI visual finish (web + mobile) |
| 2 | WhatsApp number + social profile links | Contact / footer / support |
| 3 | SMS / OTP provider credentials | OTP-first login (web + mobile) |
| 4 | Google (+ Apple) OAuth credentials | Social sign-in |
| 5 | Weather API key · nearby-places data source | Renter weather + property "nearby" |
| 6 | DIDIT dashboard — confirm production webhook URL | Final KYC auto-verify in production |
| 7 | Change-order sign-off for the redesign SOW | Commercial cover for this delivery |

---

## 8. Delivery & UAT

At handover on **31 July**, the client receives:
- The **redesigned web platform** on a testable environment (renter, host, admin).
- The **redesigned mobile app** as an installable Android build.
- **UAT test accounts** (renter, host, admin) and a **function-by-function test guide** so every capability can be verified on the new UI.

---

## 9. Summary

- **Target: 31 July 2026** — the full redesigned platform, **web + mobile**, with **all backend functionality connected to the new UI**, fully testable on the latest design.
- **Contingency:** a buffer of **up to 1 week** (delivery on or before **7 August 2026**) is noted for any unforeseen issues; any such risk will be flagged early, not at the deadline.
- **Why it fits:** the backend is shared and the design system, components, and flows are common — web and mobile build and wire from one foundation, in parallel.
- **Path:** Sprint 1 build + wire the core → Sprint 2 complete + connect everything → Sprint 3 QA, stabilize, deliver.
- **Client inputs** (Section 7) in the first week keep every screen live at launch.

---

*Plan built from the current codebase and pending-task trackers on 13 July 2026.*
