# Razorpay: one last thing we need from your dashboard

Everything else is done. The live keys are in and the website is running on
them. **The only outstanding item is the webhook**, and only you can create it —
the Razorpay portal is in your name. It takes about five minutes.

---

## What a webhook is, in one paragraph

When a guest pays, Razorpay tells the browser and the browser tells us. That
works — as long as the guest keeps the page open. If they pay and then close the
tab, switch apps, or lose signal at the wrong moment, **the money leaves their
account and nothing tells us**. The booking stays unconfirmed and the guest has
paid for nothing.

The webhook is Razorpay telling our server directly, regardless of what the
guest's phone did. It is the difference between "usually confirms" and "always
confirms".

---

## What to do

Make sure the dashboard is switched to **Live**, not Test — there is a toggle at
the top. The screens look identical in both modes.

**Settings → Webhooks → Add New Webhook**

| Field | What to enter |
|---|---|
| **Webhook URL** | `https://api.aajoohomes.com/webhooks/razorpay` |
| **Secret** | **You make this up.** Any long random string — 20 or more characters, letters and numbers, no spaces. Razorpay does **not** generate one for you, and this is the step people get stuck waiting on. |
| **Active Events** | tick **`payment.captured`** and **`payment.failed`** — nothing else |
| **Alert Email** | your own address, so Razorpay tells you if it ever stops working |

Save. It should then show as **Active**.

> **Write the secret down before you save.** Razorpay will not show it to you
> again afterwards. If it is lost, the webhook has to be deleted and made again.

---

## Then send us one value

Just the **secret** you chose. Nothing else — we already have the keys.

It is not quite a password, but it is what proves a message really came from
Razorpay, so please send it in a direct message rather than a group chat. You
can delete the message once we confirm it is in.

---

## What happens after that

We add it to the server, which takes a minute. Then we make **one real booking
for the smallest amount and pay for it properly**, check it appears in your
Razorpay dashboard, and refund it — because a test payment cannot prove live
keys work.

**One thing to expect:** the app currently on your phone was built with the old
test key, so payments in the app will not work until you install the new build
we send you at the same time. The website is unaffected.
