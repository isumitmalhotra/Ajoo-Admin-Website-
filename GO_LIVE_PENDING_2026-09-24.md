# What is left before production — 24 September 2026

Measured against `GO_LIVE_RUNBOOK_2026-09-19.md` §8, corrected for what has
actually happened since. **§1 and most of §2 are done.** Everything below is
what remains.

The §8 checklist's own numbers are now stale: it says "125 tables, 2,109
reference rows" and "build 106/107". The real figures are **127 tables, 2,114
rows** (four migrations landed 21–22 September) and **build 111**.

---

## Done

| | |
|---|---|
| §1 | Fresh database on PlanetScale Singapore — 127 tables, 39 FKs, 2,114 reference rows in 26 tables, 101 empty, `SequelizeMeta` 173 so migrations are a no-op. Verified. |
| §2.1 | `aajoo-api-singapore` — Docker, Singapore, 1 CPU / 2 GB, health check `/health` |
| §2.2 | Environment filled. `ready: true`, `dbCutoverSafe: true`, all five `dbChecks` **match** — the July set-but-stale `DB_HOST` shape is positively excluded. |
| §2.4 (part) | Read-only drive: 14 public endpoints, **13 identical to production**, the 14th being `/properties/destinations` 0 against 8 — the absence of data, which is the point. No 500s, no schema drift. |

---

## A. Hard blockers — a real launch is not possible without these

None need code. All take days and all belong to the company.

| # | What | Why it blocks |
|---|---|---|
| **3.1** | **Razorpay LIVE activation** — business KYC on the Razorpay dashboard | Every payment is test-mode. `collectsMoney: false` today. The platform cannot take a rupee. |
| **3.2** | **SMS provider + DLT registration** (MSG91 or Fast2SMS: sender id, operator-approved OTP template) | Phone OTP is dormant — every SMS variable is unset. A real user cannot sign in by phone. |
| **3.4** | **The company's own Cloudinary account** | The current one is **shared** and has held other people's records. Guest ID photographs and listing images must live in an account the company controls. This is a privacy exposure, not a tidiness issue. |
| ~~3.3~~ | ~~Email domain authenticated~~ **ALREADY DONE — verified 24 Sep** | DKIM is published under Brevo's `brevo1`/`brevo2._domainkey` CNAME selectors (both resolve to valid RSA keys) and Brevo reports the domain **Authenticated**. DMARC is `p=reject` and passes on DKIM alignment. An earlier note in this file claimed mail was being rejected; that was wrong — it checked `mail._domainkey`, which is not the selector Brevo uses. |

**Client decisions, 24 September:** SMS (3.2) is **dropped** for now — email
carries every OTP, which is fine because 3.3 turns out to be already done.
Cloudinary (3.4) **stays as it is**; the client settled that on 13 September.
Razorpay live keys are **held back deliberately** and go in after a live test.

That leaves **one** hard blocker, and it is sequencing rather than process:
the live Razorpay keys must be in before the public arrives, because a test
key plus `ALLOW_TEST_PAYMENTS=true` lets a real guest complete a booking
without paying.

The only open item on SPF is optional: the record is
`v=spf1 include:secureserver.net -all` and does not include Brevo, so Brevo
mail fails SPF and passes DMARC on DKIM alone. Adding `include:spf.brevo.com`
would make both mechanisms pass and give a fallback if the DKIM CNAMEs are
ever removed. Not urgent; DKIM is the mechanism that survives forwarding
anyway.

---

## B. Security still open — the runbook puts these BEFORE infrastructure

| # | What | State |
|---|---|---|
| 0.2 | Make `isumitmalhotra/Ajoo-Admin-Website-` private | **Still PUBLIC.** Seven commits of infrastructure documentation are held back locally because of it. |
| 0.1 | Rotate the Razorpay **test** key | The old secret is in that repository's git history. Going private does not un-leak it. |
| 0.3 | Change the passwords of test accounts 100 and 101 | They were in repo docs |
| new | **Rotate the PlanetScale password** | It appeared in a screenshot on 23 September and was not rotated — the value in `.env.planetscale` is still that one, and it is now also on the Render service. |
| new | **Rotate `HEALTH_TOKEN`** | ~40 characters of it were pasted into a terminal error. Low stakes — it gates a read-only diagnostic — but free to change. |
| new | **Delete `.env.planetscale`** | Once no more scripts need to run against the database from this laptop. |

---

## C. Finishing the move

| # | What | Who |
|---|---|---|
| 2.3 | Attach `api.aajoohomes.com` to the Singapore service; point the Vercel DNS `api` record at Render's CNAME | Sumit — dashboard |
| 2.4 | **Create one guest and one host account** on the new stack, our own, never 100/101 | Sumit or a tester — a session must not create accounts or type passwords |
| 2.4 | Then: list a property through all five wizard steps, search it, book to the Razorpay sheet, admin screens, notifications | a session, once the accounts exist |
| 3.1b | Register the payment webhook in Razorpay **live** mode and set `RAZORPAY_WEBHOOK_SECRET` | Sumit. The test-mode one (21 Sep) does not carry over; live is a separate list. |
| — | `SAFETY_ALERT_EMAIL` | Sumit. An SOS currently emails nobody. |

### §4 — the switch itself. Two gates, not one.

1. **The client's explicit word.** From that moment the test data is behind
   everyone: the site shows zero properties and no existing account can sign
   in. 4.1 is *tell the testers first* so they can save what they want.
2. **Live Razorpay keys.** Cutting over on a test key puts the website on a
   stack that refuses every payment.

The switch is 30 minutes: tell testers → Vercel `VITE_API_BASE_URL` → three
webhooks (Razorpay, DIDIT, BotPenguin) → **repoint the Oregon service at
PlanetScale too** (4.4 — or the installed APKs keep writing to the old database
and people are on two systems at once) → smoke as our own accounts.

---

## D. Apps

| # | What | Gated on |
|---|---|---|
| 5.1 | **Build 112** against `https://api.aajoohomes.com` — the last dependency on `onrender.com` | 2.3 |
| 3.9 | **Play Console**: developer account, `com.aajoo.aajoohomes`, Play App Signing with a **production** upload key — today's `aajoo-testing.jks` is a testing key | company |
| 5.2 | **The production build**: live key, **no** `-AllowTestPayments`, production signing; verifier must report the live key and no test flags | 3.1 + 3.9 |
| 3.10 | **Apple Developer account** + the eight iOS actions (`aajoo_app_2026/IOS_READINESS.md` §3); Sign in with Apple still to build | company |

---

## E. A good launch rather than merely a live one

| # | What |
|---|---|
| 3.5 | DIDIT on a paid plan; webhook moved to `api.aajoohomes.com/webhooks/didit` |
| 3.6 | Google Cloud billing + budget alert on `aajoo-bdb20`; restrict the Android Firebase key |
| 3.7 | Vercel on Pro, owned by the company |
| 3.8 | Payout bank file column order from the bank; **TDS §194-O** answer from the accountant — it changes the amount actually sent |
| 3.11 | Final legal text: Terms, Privacy, Cancellation, Host Agreement version |
| §7 | External uptime monitor (UptimeRobot / Better Stack, free) on `/health` and the website, alerting the company |
| §7 | **One PlanetScale backup restored into a branch and counted** — before Clever Cloud is deleted |
| §6 | Admin passwords reset on day one (the four carried hashes are the old ones) |

---

## F. Only after everything above

- Delete the Oregon service — after 48 hours with no requests on it
- Delete the Clever Cloud database — **only** after a PlanetScale backup has
  been restored and counted, **and** the client confirms nothing from the test
  period is wanted back

---

## The honest summary

Infrastructure is no longer the blocker. The database and the Singapore service
are built, verified and behaving identically to production on everything that
does not need a login.

What stands between here and a real launch is **four company gates** — Razorpay
live, SMS/DLT, Cloudinary ownership, mail authentication — none of which need a
line of code from us, and all of which take days of somebody else's process.
3.1 and 3.2 in particular cannot be hurried: both are third-party KYC.

The sensible order is to start those four **today**, finish §2.3 and §2.4 while
they run, and let the cutover wait for whichever finishes last — the client's
word or the live keys.
