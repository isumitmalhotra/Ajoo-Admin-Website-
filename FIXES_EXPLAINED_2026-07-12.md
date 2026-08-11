# AAJOO Homes — Fixes & Improvements Explained

> **Date:** 2026-07-12 · **By:** Zyphex Tech
> A plain-language record of every task completed in this work cycle — **what was wrong before, exactly what we changed, and how it behaves now.** Grouped by area. Backend = `aajaoBackend-render` (Render), Frontend = `aajao-frontend-vercel` (Vercel). Each item notes the deploy commit.

---

## At a glance

| # | Task | Area | Before | Now | Commit |
|---|------|------|--------|-----|--------|
| C-1 | OTP dev-bypass | Security | Code `0000`/`000000` logged anyone in — even in production | Only works locally behind an env flag; real OTP enforced in production | `ce0be2f` |
| C-2 | Hardcoded secrets | Security | DB/Razorpay/Cloudinary/Google keys hardcoded **and committed to git** | All read from environment variables; `.env` removed from git | `ce0be2f` |
| BE-3 | Renter notifications | Backend | Notification bell **always empty** for web users | Bell now shows booking/payment/cancellation events | `5399987` |
| BE-3 | Host/admin notifications | Backend | Only "new booking" appeared; payments & cancellations didn't | Payments & cancellations now notify host + admin | `91966ad` |
| BE-4 | Chat security | Backend | Anyone could join any user's chat room / send as someone else | JWT-verified socket identity + anti-spoofing | `5399987` |
| BE-9 | Validation | Backend | Debug noise in logs | Cleaned; field-level errors returned | `91966ad` |
| BE-11 | KYC write-back | Backend | *(verified already working)* | DIDIT approval flips the user to "verified" + activates listings | — |
| HOST-7 | Location entry | Host wizard | "Use my location" only set lat/lng; host retyped the address | One tap auto-fills address/city/state | `2691465` |
| HOST-10 | Check-in/out | Host wizard | Buried in "Rules", blank by default | In "Details" with 2 PM / 11 AM defaults | `2691465` |
| HOST-14 | Inline validation | Host wizard | Errors only on "Continue" | Errors show as you leave each field | `2691465` |
| BOOK-2 | Host phone privacy | Booking | Host's phone visible to **anyone** before booking | Revealed **only after** the guest books | `749388f` |
| BOOK-9 | Detail layout | Booking | Map appeared before reviews | Map now after reviews ("Where you'll be") | `749388f` |
| BOOK-5 | Booking images | Booking | Could show a hardcoded sample "Chennai apartment" | Shows the real property images; neutral fallback | `749388f` |
| BOOK-7 | Ongoing modal | Booking | Fake "Manali / cozy mountain views" placeholders | Real booking data only | `749388f` |

---

## 1. Security hardening (go-live gate)

### C-2 · Credentials moved out of the code
**Before:** The database, Razorpay, Cloudinary, Google, and mail credentials were written directly inside `config/db.config.js`, and that file — plus a `.env` containing secrets — was **committed to the git repository**. Anyone with repo access (now or in history) could read the live production keys. This also violated the contract's "no hardcoded credentials" clause.

**What we did:** Rewrote `db.config.js` so every value is read from **environment variables** (`process.env.*`) with a fail-fast check that refuses to boot if a required variable is missing. Removed `.env` from git tracking and added it to `.gitignore`. Provided the exact variable list to set in the Render dashboard.

**Now:** No secret exists in the source code. Production reads its credentials from Render's environment; local development reads them from a private, un-committed `.env`. The exposed keys were rotated by the client. If someone forgets to set a variable, the server fails immediately with a clear message instead of silently misbehaving.

### C-1 · OTP "dev bypass" can no longer reach production
**Before:** To make local testing easy, the signup OTP screen accepted the fixed codes `0000` / `000000` and logged the user straight in. That shortcut was **live in the deployed code** — a real account-takeover risk in production.

**What we did:** Put the shortcut behind an `OTP_DEV_BYPASS` environment flag. It only activates when that flag is explicitly set to `true` (which we do only on local machines, never on Render).

**Now:** On production the flag is unset, so the bypass is completely inert and **real one-time passwords are enforced**. Local testing still works with `0000` because developers set the flag on their own machines. Same for the identity-document rules: the account fields stay required, and there's a ready-to-enable switch to also require the ID photo in production.

---

## 2. Notifications, chat & identity (backend)

### BE-3 · The renter's notification bell now actually shows notifications
**Before:** This was the real cause behind "no notifications are coming." The function that records a notification (`sendNotification`) **wrote the database record only if the user had a mobile push token registered.** Web users don't have one, so the code exited early and **never saved the notification** — the bell was permanently empty even though bookings and payments were happening.

**What we did:** Reordered the logic so the **in-app notification record is always saved first**, and the mobile push (Firebase) is attempted afterward as a best-effort extra. A push failure or a missing device token no longer prevents the notification from being stored.

**Now:** Every renter sees their booking, payment, and cancellation notifications in the bell — on web and mobile — regardless of push setup. Mobile users additionally get the push pop-up if they have it enabled.

### BE-3 · Host & admin get notified on payments and cancellations too
**Before:** The host/admin notification bell only received a "New booking created" entry. When a guest **paid** or **cancelled**, nothing appeared — so hosts had to notice those events some other way.

**What we did:** Added in-app notifications at the payment-success and cancellation points in the booking controller, addressed to both the host and admin.

**Now:** Hosts and admins see "Payment received" and "Booking cancelled" in their bell as those events happen, not just the initial booking.

### BE-4 · Chat can no longer be impersonated
**Before:** The real-time chat let a client "join" a room by simply announcing a user id, and send messages tagged with **any** sender id it chose. Nothing verified the connection actually belonged to that user — so, in principle, someone could read another user's chat room or send messages as someone else.

**What we did:** Added a verification step to the socket connection. If the client presents its login token, the server verifies it and **pins the connection to that real user id**; chat and negotiation handlers then use the verified id for joining rooms and reject any message whose claimed sender doesn't match. We made it backward-compatible so the existing mobile app keeps working while it's updated to send its token.

**Now:** A connection that presents a token can only act as itself — no joining other people's rooms, no sending as someone else. (Final step: once the mobile app attaches its token, we flip the check from "verify if present" to "required," fully closing it.)

### BE-9 · Validation cleanup
**Before:** The request-validation middleware printed a stray debug line (`console.log(error,"kjiouycy")`) on every validation failure, cluttering the server logs.

**What we did:** Removed the debug line. Confirmed the middleware already returns **all** field errors at once (not just the first), so the frontend can show them inline.

**Now:** Clean logs; the API returns the full list of field errors on a 422 response.

### BE-11 · Identity verification write-back *(verified, already working)*
**Before/expectation:** When a host or guest finishes DIDIT identity verification, our system must record them as "verified" and let their listings/bookings proceed.

**What we found:** This is **already implemented correctly**. The DIDIT webhook is signature-verified, and on approval it sets the user to `verified`, stamps the expiry, flips the host's pending listings to active, and notifies them; declines and "needs review" cases raise admin flags.

**Now / action:** No code change needed. The only external step is confirming the DIDIT dashboard's webhook URL points at the production server.

---

## 3. Host listing wizard

### HOST-7 · "Use my current location" now fills in the address
**Before:** The location button sat in the middle of the form and only filled the latitude/longitude. The host still had to type the street, city, and state by hand.

**What we did:** Moved the location actions to the **top** of the Location step with a "start here" prompt, and made "Use my current location" **reverse-geocode** the coordinates — automatically filling address, city, and state (matching the state back to the dropdown).

**Now:** A host taps one button and the address block fills itself; they just review and continue.

### HOST-10 · Check-in/out are where they belong, with sensible defaults
**Before:** Check-in and check-out times were tucked into the "Amenities & Rules" step and started **blank**, so hosts often skipped them.

**What we did:** Moved them into the **Property Details** step (next to guests/beds/bathrooms) and pre-filled the **industry-standard 2:00 PM check-in / 11:00 AM check-out**.

**Now:** Times are presented logically and are correct by default; a host only changes them if their place differs.

### HOST-14 · Errors appear as you go, not all at the end
**Before:** Validation only ran when the host clicked "Continue," so a page full of mistakes was revealed all at once at the end.

**What we did:** Added **on-blur validation** — each required field (address, city, state, name, description, price, minimum price, contact, email) is checked the moment the host leaves it.

**Now:** Mistakes are flagged immediately next to the field, so the form is corrected as it's filled. (Server-side validation still enforces everything on submit — the inline check is a convenience, not the security boundary.)

### HOST-12 & HOST-13 · KYC flow and buttons *(verified, already working)*
- **HOST-12:** The DIDIT identity step already auto-opens the verification session (in a new tab that preserves the form, with live status polling), shows a "Verified" badge on completion, and blocks submission until verified. Working as intended.
- **HOST-13 ("these buttons are not working"):** The referenced screenshot is the **Host Profile** page. We checked every button there (Verify identity, Save, Reset, Retry), the header (Go to Homepage, notifications, account menu), and the dashboard quick-actions — all are wired to valid actions/routes. Save/Reset are intentionally disabled until you edit something; the "Host Workspace" pill is a decorative label. No dead buttons found.

---

## 4. Property detail & booking

### BOOK-2 · The host's phone number is now private until you book
**Before:** On the property page, "View Host Profile" showed the host's **phone number to anyone** — including people who hadn't booked. That exposes the host's personal contact and invites off-platform, un-protected deals.

**What we did:** Added a check for whether the logged-in guest actually has a booking for **this** property. The host's phone is shown only when that's true; otherwise the page shows "Host contact is shared after you book." The check is **fail-closed** — if we can't confirm a booking, the number stays hidden.

**Now:** Host phone numbers are protected pre-booking and revealed (as a tap-to-call link) once the guest has booked — on both the "Meet your host" card and the host-profile popup.

### BOOK-9 · Map moved below the reviews
**Before:** The location map appeared high up on the detail page, above the reviews.

**What we did:** Moved the map to a "Where you'll be" section **after** the Guest Reviews.

**Now:** The page reads in a more natural order — details, host, amenities, reviews, then location.

### BOOK-5 · The booking page shows the real property's photos
**Before:** If the booking page ever loaded without its data (e.g. a page refresh), it fell back to a **hardcoded sample "Luxury Apartment in Chennai" with a stock photo** — a completely different property.

**What we did:** Confirmed the real images already pass through from the property page, removed the misleading hardcoded sample, and added a neutral "No image available" panel for the rare no-data case.

**Now:** The slider always reflects the actual property; it never shows a random stock apartment.

### BOOK-7 · The ongoing-booking pop-up shows real details
**Before:** The pop-up that opens from the "Ongoing" bookings page used fake fallback text — "Aajoo Premium Homestay," "Manali, Himachal Pradesh," "Cozy stay with mountain views," and a stock photo — whenever a field was missing, which looked like the data wasn't real.

**What we did:** Removed those fake placeholders. The pop-up now shows the actual property name/location/summary/image, and simply hides a field (or shows a neutral image panel) when a value isn't present.

**Now:** The ongoing-booking pop-up is fully data-driven — no more misleading Manali homestay.

### BOOK-8 · Gallery *(verified, already a hero + grid)*
The property gallery already uses a large hero image plus a photo grid on desktop (with a "+N more" overlay), and a swipeable slider on mobile where a grid would be too cramped. No change required.

---

## Still open / needs client input
- **BOOK-4** — "nearby places" needs a data source decision (maps API or a curated list).
- **Support WhatsApp number** — the ongoing-booking support button currently points at a placeholder number; we need the real Aajoo support number.
- **DIDIT webhook URL** — confirm the DIDIT dashboard points at the production webhook.
- **Live end-to-end notification test** — deferred by client; to be run when convenient.

_See `MASTER_PENDING_TASKS.md` for the full remaining backlog._
