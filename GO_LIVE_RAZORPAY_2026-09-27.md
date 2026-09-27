# Taking Razorpay live — exactly what to change, and in what order

**27 September 2026.** Read from the running code and the live service, not from
memory.

---

## Where the key lives — there are three places, not one

This is the thing that makes it more than "paste the key into Render".

| | What it holds | Set where | When it takes effect |
|---|---|---|---|
| **Backend** | key id **and secret** — creates orders, verifies signatures, verifies the webhook | Render env | on restart |
| **Website** | key id only (public) | Render env, **baked in at BUILD time** | only on a rebuild |
| **Mobile app** | key id only (public) | `--dart-define` at **APK build time** | only in a new APK |

The secret exists in exactly one of those and must stay that way. It signs and
verifies orders; a browser or an APK has no business holding it.

## Where it is today

Measured on 27 September:

```
live website bundle   rzp_test_XUTODhUdMAshi6
APK build 117         rzp_test_XUTODhUdMAshi6
POST /webhooks/razorpay   503  {"message":"webhook not configured"}
```

On the Render service: `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` and
`ALLOW_TEST_PAYMENTS` are set. `RAZORPAY_WEBHOOK_SECRET` and
`VITE_RAZORPAY_KEY` are **not**.

`ALLOW_TEST_PAYMENTS` is the switch that lets a test key work on a production
deploy. While it is on, **a booking can complete and collect nothing** — which
is precisely the state the platform was in before that flag existed.

---

## A. Razorpay dashboard

1. Switch the dashboard to **Live mode** and take the **Key ID** and **Key
   Secret** from Settings → API Keys.
2. Settings → **Webhooks** → Add New Webhook:
   - **URL** — `https://api.aajoohomes.com/webhooks/razorpay`
   - **Secret** — invent a strong one and keep it; you will paste the same
     string into Render in step B5. Razorpay does not generate it for you.
   - **Active events** — `payment.captured` is the one that matters, and
     `payment.failed` is handled too and worth ticking. Nothing else is read.
3. Save, and keep the secret to hand.

> The webhook is how a payment that succeeds **after the guest closes the tab**
> still confirms the booking. Without it those bookings sit unconfirmed with the
> money taken.

## B. Render → `aajoo-api-singapore` → Environment

| | Variable | Action |
|---|---|---|
| B1 | `RAZORPAY_KEY_ID` | **change** to the live key id (`rzp_live_…`) |
| B2 | `RAZORPAY_KEY_SECRET` | **change** to the live secret |
| B3 | `VITE_RAZORPAY_KEY` | **add** — the same live **key id**, never the secret |
| B4 | `ALLOW_TEST_PAYMENTS` | **delete the variable** |
| B5 | `RAZORPAY_WEBHOOK_SECRET` | **add** — the string from step A2 |
| B6 | `VITE_API_BASE_URL` | **add** `https://api.aajoohomes.com` — optional, see below |

Then **Manual Deploy → Clear build cache & deploy**.

Three notes on that:

* **B3 only works because of a fix made today.** `VITE_RAZORPAY_KEY` was not a
  Dockerfile build argument, so setting it would have done nothing at all —
  silently. The checkout would have opened with the test key while the API
  created live orders, and every payment would have failed at the gateway on a
  page that looks entirely normal. Fixed in backend `325c39b`.
* **Clear the build cache**, because the website's key is baked in at build
  time. A cached layer would ship the old bundle.
* **B6 is optional.** The site currently reaches the API through a fallback in
  source, which is correct — but a fallback is not configuration, and the next
  person to read the service will not see the value anywhere.

## C. The mobile app — this one breaks on the hour you go live

**Every build up to and including 117 carries the test key.** The moment the
backend is live, those builds create test-key orders against a live API and
**every payment in the app fails**.

A new APK is required:

```
./tool/build_release.ps1 -ApiBaseUrl https://api.aajoohomes.com -RazorpayKey rzp_live_…
```

Do **not** pass `-AllowTestPayments`; the script refuses a `rzp_test_` key
without it, which is the guard working. Distribute that build before, or at the
same time as, step B — not after.

## D. Verify, in this order

1. `curl -X POST https://api.aajoohomes.com/webhooks/razorpay -d '{}'` — should
   stop answering **503 "webhook not configured"**. It will reject an unsigned
   body, which is correct; what matters is that it is no longer unconfigured.
2. The live bundle carries the live key:
   `curl -s https://www.aajoohomes.com/assets/index-*.js | grep -o 'rzp_[a-z]*_[A-Za-z0-9]*'`
   — must print `rzp_live_…` and **no** `rzp_test_`.
3. **One real booking, smallest possible amount, paid for real.** Then check it
   appears in the Razorpay dashboard under Live, and that the booking confirmed.
   A test-mode pass proves nothing about live keys.
4. Refund that payment from the Razorpay dashboard and confirm the refund lands
   on the ledger — refunds have been missed here before.

---

## What the code does if you get it wrong

Worth knowing, because none of these are silent:

* **No keys at all** — payment endpoints refuse with 503 and a plain message;
  browsing, login, host and admin screens keep working. The API does not fall
  over because a payment key is missing.
* **A test key on production without `ALLOW_TEST_PAYMENTS`** — payments refuse
  rather than complete. This is deliberate: a checkout that visibly refuses is
  recoverable in minutes; a month of bookings that collected nothing is not.
* **A test key with `ALLOW_TEST_PAYMENTS=true`** — payments complete and collect
  nothing, and the server log says so in those words on every boot.

The one combination with no guard is **live backend, test key in the app**,
which is why step C is not optional.
