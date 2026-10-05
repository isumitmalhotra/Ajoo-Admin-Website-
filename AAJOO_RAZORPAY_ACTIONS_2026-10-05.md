# Aajoo — 3 actions needed on the Razorpay dashboard

**Date:** 5 October 2026 · **Time needed:** about 5 minutes · **Who:** whoever has access to the Razorpay account

---

## Why

When a refund was issued from the Razorpay dashboard, the booking on Aajoo still showed
**Paid / Confirmed** to the host and in the admin panel, and nobody was notified.

The cause: Razorpay was only set up to tell Aajoo about **payments**, not about **refunds**.
The refund happened at Razorpay and our system was never informed, so it had nothing to update.

The Aajoo side is now fixed and live. It will cancel the booking, return the money on our
records, stop the host payout and email both the host and the guest — **as soon as Razorpay
starts sending us refund events.** That last part can only be switched on from your dashboard,
which is what these three steps do.

---

## Step 1 — Tell Razorpay to send refund events ⬅ the important one

1. Log in to the **Razorpay Dashboard**
2. Make sure you are in **Live mode** (the Test/Live switch is at the top — a Test-mode webhook
   does nothing for real payments)
3. Go to **Settings → Webhooks**
4. Click the existing webhook for `https://api.aajoohomes.com/webhooks/razorpay`
5. Click **Edit**
6. Under **Active Events**, tick these three, in addition to whatever is already ticked:

   - [ ] `refund.processed` ← **required**
   - [ ] `refund.created`
   - [ ] `refund.failed`

7. **Save**

> Please do not untick `payment.captured` — that is the one that confirms bookings when a
> guest pays.

---

## Step 2 — Send a test webhook

Still on the same webhook screen:

1. Click **Send Test Webhook**
2. Note the response code it shows

**What good looks like:** `200` (or any 2xx).

If you see anything else, please send us the code and we will trace it from our side the same
day. The most common cause is the secret differing by one character between Razorpay and our
server.

---

## Step 3 — Replay the refund for booking B871634

This repairs the one booking that is currently showing the wrong status. It needs Step 1 done
first, or it will go nowhere.

1. In the Razorpay Dashboard, go to **Settings → Webhooks**
2. Open the webhook, then open its **Logs / Recent Deliveries** tab
   *(depending on your dashboard version this may be under **Account & Settings → Webhooks →
   View Logs**)*
3. Find the **refund** event for payment `pay_TjxFlf5FZRjO09` — booking **B871634**, ₹3.15
4. Click **Resend** (or **Retry**) on that event

Our system will then cancel that booking, record the refund, stop the payout and email both
sides automatically.

**If you cannot find a Resend option**, tell us — we can instead cancel that booking from the
Aajoo admin panel, which produces the same result. Please do not cancel it manually *and*
resend the event; either one is enough.

---

## What to send back to us

Once the three steps are done, please reply with:

1. **A screenshot of the Active Events list** on the webhook, so we can confirm the refund
   events are saved
2. **The response code** from Send Test Webhook (Step 2)
3. **Confirmation that you clicked Resend** on the B871634 refund event (Step 3) — or that you
   could not find the option

We will then check it from our side and confirm back to you:

- that the refund event reached our server
- that booking **B871634** now reads **Cancelled / Refunded** for the host and in the admin panel
- that the host and guest notification emails went out

---

## Quick reference

| | |
|---|---|
| Webhook URL | `https://api.aajoohomes.com/webhooks/razorpay` |
| Mode | **Live** |
| Events that must be ticked | `payment.captured`, `payment.failed`, `refund.processed`, `refund.created`, `refund.failed` |
| Booking to repair | **B871634** — payment `pay_TjxFlf5FZRjO09`, ₹3.15 |

**Please do not send us the webhook secret, your API keys or any password.** We do not need
them, and they should only ever exist in the Razorpay dashboard and on our server.
