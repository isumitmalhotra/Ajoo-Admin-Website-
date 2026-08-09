# Web ⇄ Mobile Parity

Every renter/host fix on the web has to land on mobile too, or the same bug
gets found twice and fixed twice. This is the ledger for that.

**The rule:** when you fix something in `aajao-frontend-vercel` that touches
renter or host behaviour, add a row here and close it on `aajoo_app_2026`
before calling the fix done. Backend fixes are shared automatically — they
only need a row if the *client* has to change to benefit.

Legend: ✅ done both sides · ⚠️ web only · — not applicable to mobile

---

## Shared backend (both clients benefit automatically)

| Fix | Notes |
|---|---|
| ✅ Host cancel threw `validate` undefined | Wrong schema module; also broke `/host/booking/no-show`. |
| ✅ Cancellation writes ran outside the transaction | `{transaction}` passed as the 3rd arg to `Model.update`, which ignores it. |
| ✅ Cancellation notice + refund narrative | In-app notification + email, both clients. |
| ✅ `un_payload` double-encoded JSON | Readers unwrap up to 3×; fixing only the writer would have regressed the listing endpoint. |
| ✅ OTP: bypass removed, 6 digits, 5-attempt lockout, 10-min expiry | Same `/user/verify-otp` for web and mobile. |
| ✅ Unverified signup can resume instead of "User already exists" | Backend returns `{needsVerification, userId}`. **Neither client read it** — both showed the raw message as an error while a fresh code sat in the inbox. Fixed on both. |
| ✅ Email via Brevo (OTP, welcome, booking, cancellation, invoice) | Transport-level, both clients. |
| ✅ A14 category re-seed to the spec's 9 | Both read `tbl_categories`. |
| ✅ `/user/switch-mode` | Added so mobile could stop storing the password. |

## Client-side logic — must be ported deliberately

| Fix | Web | Mobile |
|---|---|---|
| **Stay clock** — 2 PM check-in / 11 AM IST check-out | ✅ `redesign/lib/stayClock.ts` | ✅ `lib/utils/stay_clock.dart` + unit tests |
| "Currently Staying" after checkout had passed | ✅ | ✅ ongoing widget + dashboard count now filter on the real window |
| Property search: wide-radius fallback when nothing is nearby | ✅ `useProperties` | ✅ `getProperties` retries at 20000 |
| Radius sent as a number, omitted when blank | — | ✅ mobile-only bug (string radius failed the request) |
| Category row driven by the API, not a hardcoded list | ✅ | ✅ |
| Google Sign-In | ✅ | ✅ |
| Password never persisted on the device | — | ✅ |
| Notification tap opens the right screen | ✅ `notificationLink.ts` | ✅ `lib/utils/notification_link.dart` + unit tests |
| Resume an unverified signup instead of erroring | ✅ `signupUser` returns `resumed` | ✅ `SignupResponse.needsVerification` → the code screen |
| Signup requires a real ID type + number | ✅ | ✅ the "Skip for now (dev)" button that wrote a fake Aadhaar is gone |
| Referral code the user typed is actually sent | ✅ | ✅ was hardcoded to `"0000"`, discarding every real code |
| Profile completion tracker | ✅ | ⚠️ not on mobile |
| Search empty state names the place + suggests real cities | ✅ | ⚠️ mobile search has no equivalent |
| Map recentres on the searched place | ✅ | ⚠️ mobile map not audited |
| Scroll reveal / motion vocabulary | ✅ `motion.ts` | ✅ `lib/ui/motion/aajoo_motion.dart` — guest screens **and** host dashboard + bookings |

## Web-only by nature (no mobile equivalent needed)

CMS editor · SEO meta / JSON-LD / canonicals · Newsletter signup ·
Knowledge Center page · admin portal · Getting Started marketing page.

---

## What the first full audit turned up (2026-08-09)

Four defects that existed only on mobile, plus one that turned out to be on
both. Each is closed; they are listed because they show the shape of what this
ledger is for.

1. **A stay stayed "current" past checkout.** `/booking/ongoing` returns stays
   at date granularity and its own comment says the client derives the rest.
   The web does. Mobile did not → `lib/utils/stay_clock.dart` + tests.
2. **A "Skip for now (dev)" button on signup step 3** submitted
   `doc_number: 000000000000` as an Aadhaar number. Real accounts were being
   created with fabricated government-ID data. Removed; the type and number are
   required and format-checked, exactly as on the web. The ID *scan* stays
   optional on both.
3. **Every signup sent `user_ref: "0000"`** — a hardcoded placeholder that
   overwrote whatever the referral screen collected. No mobile signup has ever
   been attributed to a referrer, and the screen asking for the code was
   decorative.
4. **Notifications went nowhere.** The in-app list navigated only for rows with
   "negotiation" in the title *and* a propertyId; everything else was marked
   read and dropped. Push taps returned early unless the payload carried both
   `route` and `type` (most carry neither), routed on `type` alone — the field
   the web proved lies — and otherwise handed the stored path to `Get.toNamed`.
   Those paths are the web's (`/messages`, `/bookings`) and are not routes here,
   so a tap landed on the unknown-route page.
5. **Neither client read `needsVerification`.** Fixed on both — see above. The
   ledger previously claimed the web handled it; it did not.

## Known open parity gaps

1. **No messages inbox on mobile.** The only conversation surface is the
   per-property negotiation thread, so a chat notification can only be opened
   when the payload names a property. Without one it lands on home rather than
   a route that does not exist.
2. **Search empty state and map recentring** have no mobile equivalent.
3. **Profile completion tracker** is web-only.
4. **Two classes named `AuthController`** (`lib/controller/` and
   `lib/ui/screens_common/auth/`). `Get.find` keys on the name, so importing the
   wrong one hands back the live instance typed as a class it is not — one file
   was already doing this. The legacy tree is dead and should be deleted.
