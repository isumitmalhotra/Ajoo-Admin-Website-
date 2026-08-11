# SMS / Mobile Messaging — what we need to switch it on

**Prepared for Aajoo Homes · 11 August 2026**

Aajoo Homes currently sends every one-time code by **email only**. The platform
has no SMS capability at all — not partially built, not broken: never set up.

The code for it is now written and deployed. It cannot send anything until an
SMS account exists in Aajoo's name, because the sender identity is legally the
business's, not the developer's. This document covers what to choose, what it
costs, and what to send back.

---

## 1. What switching this on unlocks

| Feature | Status today | With SMS |
|---|---|---|
| **Password reset by mobile number** | email only | a guest who signed up with a phone can reset without remembering which email they used |
| **Phone number verification at signup** | not possible | confirms the number is real and reachable — the number staff and hosts actually call |
| **Mobile OTP as the primary login** | not possible | **this is what the Section 0 specification asks for** — OTP-first login is the default method in the spec, with email/password as the secondary |
| **Booking and payment alerts by SMS** | email only | delivered even when a guest does not check email |

The third row is the significant one. The Section 0 direction specifies mobile
OTP as the **default** way to sign in, for both guests and hosts. Until an SMS
provider exists, that part of the specification cannot be built at all.

---

## 2. The part that is not optional: DLT registration

India requires this. It is a TRAI regulation, it applies to every business
sending transactional SMS to Indian numbers, and **no provider can bypass it** —
including international ones.

Registration happens on a telecom operator's DLT portal (Jio, Airtel,
Vodafone Idea and BSNL each run one; registering on any one propagates to the
rest). There are three steps, in order:

**1 · Entity registration** — registers Aajoo Homes as a sender.
Needs: business PAN, GST certificate, certificate of incorporation, address
proof, and an authorised signatory with a letter of authorisation.
*Typically 1–3 working days.*

**2 · Header (Sender ID)** — the 6-character name that appears as the sender,
for example `AAJOOH`. Transactional headers must be alphabetic.
*Typically 1–2 working days.*

**3 · Template registration** — the exact text of each message, with variables
marked. The message we send must match the approved template **character for
character**, or the operator drops it silently.
*Typically 1–2 working days.*

**Only Aajoo can complete these.** They require the company's statutory
documents and an authorised signatory. A development partner cannot register on
a client's behalf.

> **Plan for roughly a week end to end**, and start it before it is needed —
> rejections at any step add another round trip. This is the long pole, not the
> integration.

### The templates we will need approved

Register these three at minimum. Exact wording can be adjusted; the variable
count and structure should not be.

```
1. Password reset
   {#var#} is your Aajoo Homes password reset code. It expires in {#var#}
   minutes. Do not share it with anyone.

2. Signup / login verification
   {#var#} is your Aajoo Homes verification code. It expires in {#var#}
   minutes. Do not share it with anyone.

3. Booking confirmation
   Your Aajoo Homes booking {#var#} is confirmed for {#var#}. View details in
   the app.
```

---

## 3. Choosing a provider

All three below are already supported by the code — the choice is commercial,
not technical. Switching later is a configuration change, not a rebuild.

| | **MSG91** | **Fast2SMS** | **Twilio** |
|---|---|---|---|
| **Best for** | *Recommended* — built for exactly this | smallest setup effort | already-international teams |
| Indian SMS cost | **low** (paise per message) | **low** | **high** — roughly 15–25× the Indian providers |
| Dedicated OTP product | **yes** — handles retries and verification | no | yes (Verify, priced separately) |
| DLT handling | guided in-dashboard | guided | you manage it yourself |
| Support timezone | India | India | US, paid tiers for priority |
| Deliverability in India | very good | good | good, but routed internationally |

**Our recommendation: MSG91.** It is built for Indian transactional SMS, its DLT
workflow is handled inside the dashboard rather than left to you, and it has a
purpose-built OTP endpoint that manages resends and expiry. On the volumes a
platform like this generates, the cost difference against Twilio is the
difference between a rounding error and a line item.

**Choose Twilio only if** Aajoo expects meaningful international guest traffic
soon and wants one provider for every country. For an India-first marketplace it
is hard to justify on price.

### Indicative cost

At roughly ₹0.15–₹0.25 per transactional SMS with an Indian provider:

| Codes sent per month | Indicative monthly cost |
|---|---|
| 1,000 | ₹150 – ₹250 |
| 10,000 | ₹1,500 – ₹2,500 |
| 50,000 | ₹7,500 – ₹12,500 |

These are indicative and move with volume and route. **Confirm current rates
with the provider before committing** — treat the table as a sense of scale, not
a quotation. Twilio for the same volumes runs several times higher.

Most providers sell credit up front rather than billing monthly, so the account
needs a balance in the same way the payouts account does. **Messages silently
stop when credit runs out**, so someone should own topping it up.

---

## 4. What to send back

Once the account is open and DLT registration is approved, we need these values.
They are secrets — please send them through a password manager or a secure
channel, not email or chat.

**If MSG91 is chosen:**

| Value | Where to find it |
|---|---|
| `MSG91_AUTH_KEY` | Dashboard → Settings → API keys |
| `MSG91_SENDER_ID` | your approved 6-character DLT header, e.g. `AAJOOH` |
| `SMS_OTP_TEMPLATE_ID` | the DLT template id for the verification message |

**If Twilio is chosen:** `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM`
(the purchased number).

**If Fast2SMS is chosen:** `FAST2SMS_API_KEY`, plus the approved sender ID.

---

## 5. What happens once we have them

1. We add the credentials to the server configuration — no code change; the
   integration is written and deployed already.
2. **Password reset by mobile starts working immediately.**
3. Phone verification at signup follows — a small piece of work, since the
   sending mechanism is the part that was missing.
4. Mobile-OTP-first login (the Section 0 requirement) can then be scheduled as
   its own piece, as it changes the sign-in journey rather than adding to it.

We will test with a small number of real messages to a phone Aajoo controls
before anything reaches guests.

---

## 6. Summary of the decision

| | |
|---|---|
| **Decide** | which provider — MSG91 recommended |
| **Do** | open the account; complete DLT entity, header and template registration |
| **Send** | the API credentials, securely |
| **Own** | keeping the account topped up — messages stop when credit runs out |
| **Expect** | around a week, mostly waiting on DLT approvals |
| **Cost** | ₹150–₹2,500/month at realistic early volumes, plus provider minimums |

Until this is in place, password reset by mobile shows an honest message
directing the guest to reset by email instead — nothing is broken or misleading
in the meantime, the feature is simply unavailable.
