# Razorpay: the three things we need from your dashboard

Only you can do these — the Razorpay portal is in your name. It takes about ten
minutes. Everything after this is ours.

---

## Before you start

**Live mode only appears once Razorpay has approved your KYC.** If you open
Settings and see no Live option, activation is still pending and nothing below
will work yet — tell us and we will wait.

Make sure the dashboard is switched to **Live**, not Test. There is a toggle at
the top of the screen. Every screen below looks identical in both modes, and the
keys are completely different, so this is worth checking twice.

---

## 1. The Live API keys

**Settings → API Keys → Generate Live Key**

You will be shown two values:

| | |
|---|---|
| **Key ID** | begins `rzp_live_` — this one is public and goes on the website |
| **Key Secret** | a long random string — this one is private |

**The Key Secret is shown once.** Copy it before closing the box. If you lose
it the only option is to generate a new pair, and the old one stops working the
moment you do — so do not regenerate later "to check", because that will switch
off payments.

If a live key already exists and you do not have the secret, generate a fresh
pair and send us both. Tell us you have done it, because the old key will stop
working immediately.

---

## 2. The webhook

This is what tells us a payment succeeded **after the customer has closed the
page**. Without it, a guest who pays and then shuts the tab has taken money out
of their account with no confirmed booking at our end.

**Settings → Webhooks → Add New Webhook**

| Field | What to enter |
|---|---|
| **Webhook URL** | `https://api.aajoohomes.com/webhooks/razorpay` |
| **Secret** | **You choose this.** Any long random string — 20+ characters, letters and numbers. Razorpay does not generate one for you. Write it down; you cannot read it back later. |
| **Active Events** | tick **`payment.captured`** and **`payment.failed`** |
| **Alert Email** | your own address, so Razorpay tells you if it ever stops working |

Leave every other event unticked. We only read those two.

Save it. It will show as **Active**.

---

## 3. Send us three values

1. the **Key ID** (`rzp_live_…`)
2. the **Key Secret**
3. the **Webhook Secret** you chose in step 2

**Please do not put these in a WhatsApp group or a forwarded email.** Two of the
three can move money. A direct message to one person, or a phone call for the
secrets, is enough — and once we have entered them you can delete the message.

---

## What happens next

We put them into the server, switch off the test-payment setting, and rebuild
the website and the app so everything is on the live key at the same time.

Then we make **one real booking for the smallest possible amount and pay for it
properly**, check it appears in your Razorpay dashboard, and refund it. A test
payment cannot prove live keys work; only a real one can.

**One thing to expect:** the mobile app currently carries the test key, so the
app on your phone will stop taking payments the moment we go live until you
install the new build we send at the same time. The website is not affected.
