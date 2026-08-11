# AajooHomes — Full Platform Completion Timeline (Web + Mobile)

> **Prepared:** 2026-06-17 (Wed) · **Author:** Sumit + Claude (full-time)
> **Scope:** EVERYTHING on the shared backend — Customer web, Admin, HMS, FMS **and** the Flutter mobile app (`aajoo_app_2026`), so **both platforms expose the same functionality**.
> **Web detail lives in:** `WEB_COMPLETION_TIMELINE.md` (this doc summarizes web and adds the mobile track + the joint cutover).
> **Companion trackers:** `REDESIGN_TASK_TRACKER.md` (Part B mobile), `TASK_TRACKER.md`, `FULL_DELIVERY_PLAN.md`.

---

## 0 · Headline dates

| Milestone | Date | What it means |
|---|---|---|
| **Web v1 functional (test mode), QA-clean** | **Wed 24 Jun 2026** | (from web doc) browse→filter→book→invoice + admin/HMS/FMS error-free. |
| **Web production go-live** | **Mon 29 Jun 2026** | (from web doc) live payments + KYC cutover. |
| **M-F1 — Full-platform v1 (web + mobile), our work complete + submitted** | **~Fri 4 Jul 2026** | Mobile renter + host flows verified on device (light + dark), wired to the same backend, live cutover done, **release build submitted to Google Play for review.** Buffer to **Tue 8 Jul** if the mobile audit surfaces large wiring gaps. |
| **Live on Play Store** | **M-F1 + Google review time** | Outside our control — see note below. |
| **Stabilization support complete** | **~Mon 4 Aug 2026** | Contract's 30-day post-go-live support window from M-F1. |

> **⚠️ Play Store review is additional time, not part of our delivery date.** We deliver our end of the work — the app built, tested on device, and **submitted to Google Play** — by **M-F1 (~Fri 4 Jul)**. We will complete and submit it for review as early as possible (ASAP), but **the actual go-live on the Play Store then depends on Google's review process, which can take additional days and is entirely outside our control.** Our commitment is the submission-ready build by the date; publication follows once Google approves.

**Assumptions:** full-time pace · client creds within ~1 week · **device + tester ready** for mobile QA (confirmed) · distribution method (store vs direct APK) TBD — store review adds calendar days **on top of M-F1** (see note above + §5).

---

## 1 · Definition of "full platform complete"

Everything in the web v1 bar (see `WEB_COMPLETION_TIMELINE.md §1`), **plus** on mobile:
- Renter can browse → filter → open detail → book → pay (test→live) → get invoice → see bookings, in **both light and dark themes**.
- Host can run the host flows (dashboard, add/update property, bookings, ongoing, payout, invoices, support, profile).
- Mobile consumes the **same backend** capabilities as web where they apply (KYC/DIDIT, notifications feed, support tickets, performance), so feature parity holds.

---

## 2 · Starting line — what's already DONE

**Shared backend:** see `WEB_COMPLETION_TIMELINE.md §2` — FMS/HMS/KYC/notifications/RBAC/email all deployed + verified. The same APIs serve mobile.

**Web:** redesign + funnel fixes + admin/HMS/FMS wiring done (see web doc).

**Mobile (`aajoo_app_2026`, Flutter):**
- Sand & Indigo redesign **B0–B5 committed and confirmed in the working tree** (`constants.dart` → `kprimaryColor = 0xFF1B2447`; light + dark themes migrated). The earlier "reverted" note is stale.
- `flutter build apk --debug` compiles; `flutter analyze` clean of new errors.
- Renter + host screens restyled (home, property, booking, payout, invoices, support, profile).

---

## 3 · PENDING — Mobile track (web pending is in the web doc)

| Item | Ref | Effort | Phase |
|---|---|---|---|
| **Mobile audit** — confirm which new backend capabilities the app already consumes vs gaps (notifications feed, DIDIT KYC gate, support tickets, performance, host payout/statements parity); confirm it runs on the test device | new | 1d | M0 |
| **Backend-parity wiring** — close the gaps found in M0 so mobile matches web (e.g. notifications polling, KYC create-session/return, support tickets, any new endpoints) | derived from M0 | 2–4d | M1 |
| **Device QA — renter**, light + dark (Home → Details → Checkout → Confirmation) | B3-20/21 | 1d (with fix loop) | M2 |
| **Device QA — host**, light + dark (all host screens) | B4-11, B5-04..07 | 1d (with fix loop) | M2 |
| **Revert mobile DEV-BYPASSES** (items 4–7, 9 in TASK_TRACKER §DEV-BYPASS: doc-upload skip, nullable id-doc, `int.tryParse` fallbacks, "Skip for now (dev)" button) | TASK_TRACKER | 0.5d | M3 |
| **Mobile live cutover** — Razorpay live + DIDIT on device, real payment + KYC smoke | with web W4 | 0.5d | M3 |
| **Release build** — signed APK / IPA (+ store submission if applicable) | new | 0.5d (+ store review) | M3 |

> **Key unknown the M0 audit resolves:** how much of the *new* FMS/HMS/KYC/notification surface the mobile app already calls. Mobile host screens (payout, invoices, support) pre-date the sprint, so some may use legacy endpoints. M0 turns the 2–4d M1 range into a firm number on **Fri 27 Jun**.

---

## 4 · Phased timeline (full-time, from Wed 17 Jun)

```
═══ WEB (detail in WEB_COMPLETION_TIMELINE.md) ═══
W1  Thu 18 → Sat 20 Jun   Booking loop + functional gaps
W2  Sun 21 → Wed 24 Jun   Full QA regression → Web v1 functional (test mode)  [Wed 24 Jun]
W3  Thu 25 → Fri 26 Jun   UI-polish batch → UAT-ready                          [Fri 26 Jun]
W4  Sat 27 → Mon 29 Jun   Live cutover → Web production go-live                 [Mon 29 Jun]

═══ MOBILE (starts as web QA winds down; one operator, so largely sequential) ═══
M0  Fri 27 Jun            Mobile audit — gap list + device run, firm up M1 size
M1  Sat 28 → Tue 1 Jul    Backend-parity wiring (notifications / KYC / support / parity gaps)
M2  Wed 2 → Thu 3 Jul     Device QA: renter + host, light + dark, with fix loop
M3  Fri 4 Jul             Revert mobile bypasses + live cutover + real payment + release build
                          → M-F1: Full-platform v1 (web + mobile, production)  [~Fri 4 Jul]

═══ SUPPORT ═══
    Fri 4 Jul → ~Mon 4 Aug   Contract 30-day stabilization / hypercare
```

---

## 5 · Critical path & risks

| Risk | Impact | Mitigation |
|---|---|---|
| **M0 audit finds large mobile↔backend wiring gaps** | M1 grows toward 4d → pushes M-F1 to ~Tue 8 Jul | Audit is the *first* mobile task precisely to convert this unknown into a date by 27 Jun. |
| **Google Play review** (and Apple review if iOS) | **Additional days after M-F1, outside our control** — our work (build + submission) is done by the date; Google's approval/publish time is separate | We complete + submit ASAP so Google's clock starts as early as possible; for UAT we can side-load a direct APK so testing isn't blocked on store approval. **This time is explicitly NOT included in our delivery date.** |
| Client creds slip | Delays both web go-live and mobile cutover (shared) | Both platforms run fully on **test mode** until then; cutover is one coordinated swap. |
| Device-only mobile bugs (theme, layout, payment SDK) | Extends M2 | Tester + device confirmed available; tight fix loop. |
| Mobile dev-bypasses reach a release build | Security/KYC integrity | M3 hard-gate revert (5 mobile bypass items tagged in TASK_TRACKER). |

---

## 6 · Sequencing note (why mobile mostly follows web)

Execution is **one operator (you) + Claude**, so the two tracks share a single throughput. Mobile is scheduled to begin (M0) as the web QA/polish phase winds down, rather than truly in parallel. If a second Claude account runs the mobile track concurrently (as in the June sprint's A/B split), **M-F1 can pull in toward ~Tue 1 Jul** — flag this if you want the parallel model.

---

## 7 · TL;DR for the client

- **Wed 24 Jun** — website fully working end-to-end (test mode).
- **Mon 29 Jun** — website live in production (real payments + KYC).
- **~Fri 4 Jul** — mobile app verified on device (renter + host, light + dark), on the same backend, live cutover done, **and submitted to Google Play** → **our end of the work is complete by this date**.
- **Play Store go-live** — we submit ASAP, but the actual publish date depends on **Google's review process, which takes additional days and is outside our control**. The 4 Jul date is our submission-ready delivery, not Google's approval date. (For UAT we can side-load a direct APK so your testing isn't held up by store review.)
- **~Mon 4 Aug** — end of the included 30-day support window.
- Single biggest lever on the mobile date is the **27 Jun audit** (sizes the wiring work); the Play Store review window is separate and additional.
