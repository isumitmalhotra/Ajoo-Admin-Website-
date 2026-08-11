# Payouts — what's built, and the four things only you can do

**2026-08-11.** The code is written, tested and deployed. It cannot move a
rupee until the four values below exist in the Render environment, and that is
deliberate: without them every path refuses with a clear message rather than
pretending to pay.

---

## 1. What "payouts don't move money" meant

`approvePayout` set the status to COMPLETED and wrote a ledger row saying the
host had been **disbursed**. No bank was ever contacted. The platform's books
said the host had been paid; their account never changed. The `TODO` admitting
it had been in the file since the sprint that wrote it.

So the button worked, the records looked right, and nothing arrived. That is
the worst shape a money bug can take, because everything downstream — reports,
balances, the host's own earnings screen — agreed with each other and all of
them were wrong.

**It is now a real transfer**, or an honest refusal.

## 2. Razorpay and RazorpayX are not the same product

This is the part that needs a commercial decision, so it's worth being plain:

| | Razorpay **Payments** | **RazorpayX** |
|---|---|---|
| Does | takes money **from** guests | sends money **to** hosts |
| Already set up | yes (`rzp_test_…`) | **no** |
| Keys | the ones you have | **different keys** |
| Needs | nothing more | an activated account, **funded** |

The existing key cannot make a payout. It is not a permissions setting — it is
a different product with its own dashboard and its own balance to draw from.

## 3. What was built

**The industry-standard flow**, the same shape Airbnb and Stripe Connect use:

```
Contact  →  Fund account  →  Penny-drop validation  →  Payout
(the host)  (their bank/UPI)  (₹1, bank returns the   (the transfer)
                                name on the account)
```

**Penny drop.** ₹1 goes into the account and the bank replies with the name it
holds against it. The account is marked verified only if the deposit landed
**and** that name matches the host's. This catches the two failures that
actually cost money — a mistyped account number (gone, unrecoverable) and an
account belonging to someone else.

Name matching is tolerant of how banks really write names — initials, dropped
middle names, `MR` prefixes, all-caps — but a single-word name never
auto-verifies. "R Sharma" would otherwise match any Sharma's account. Near
misses become **mismatch** and wait for a human, showing what the bank returned
so the admin can see why.

**Not paying twice.** This got the most care, because there is no unsend:

- an `X-Payout-Idempotency` key per payout, **stored before the call**, so a
  retry after a timeout returns the original transfer rather than making a new one
- the row is claimed with its status in the `WHERE` clause, so two admins
  clicking Approve at the same instant means exactly one `UPDATE` matches
- a `UNIQUE` index on the provider payout id, so a duplicate is a database
  error rather than a matter of the application getting it right
- the ledger DEBIT is written only on settlement, and only if one doesn't
  already exist — providers retry webhooks

**Encryption at rest.** Account numbers and UPI IDs are AES-256-GCM encrypted
before they touch the database, with a versioned envelope so the key can be
rotated later. The IFSC deliberately is not — it's a public branch code.
Writes **fail closed** without the key rather than quietly storing plaintext.
Masked on every read, including back to the host who owns the account.

**Status stops lying.** A transfer settles asynchronously — IMPS in seconds,
NEFT in batches — so approving records `PROCESSING`, and `/webhooks/razorpayx`
settles it to COMPLETED or FAILED with the bank's UTR.

---

## 4. The four values I need from you

### `FIELD_ENCRYPTION_KEY` — do this one first

Nothing can store a bank account until this exists. Generate it yourself and
paste it into Render; don't send it to me, and don't commit it.

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

⚠️ **If this key is lost, every stored account number is unrecoverable.** Keep a
copy wherever you keep the other production secrets.

### `RAZORPAYX_KEY_ID` and `RAZORPAYX_KEY_SECRET`

From the **RazorpayX** dashboard (not the Razorpay Payments one), under Settings
→ API Keys. The account has to be activated first, which is a KYC process on
Razorpay's side and takes a few days — worth starting now if you haven't.

### `RAZORPAYX_ACCOUNT_NUMBER`

The RazorpayX account money is sent **from** — shown on the RazorpayX dashboard,
usually starting `2323…`. **Not** a host's account number.

⚠️ **It must hold a balance.** RazorpayX pays out of this account; it is not a
credit line. Payouts are sent with `queue_if_low_balance`, so an underfunded
account queues them rather than failing, but nothing reaches a host until it's
topped up.

### `RAZORPAYX_WEBHOOK_SECRET`

In the RazorpayX dashboard → Settings → Webhooks, add:

```
https://aajaodev.onrender.com/webhooks/razorpayx
```

Subscribe to **`payout.processed`, `payout.failed`, `payout.reversed`** and
**`fund_account.validation.completed`, `fund_account.validation.failed`**. Set a
secret and put the same value in Render.

Without this, transfers still send but their status never settles — they sit at
PROCESSING forever, because nothing tells us the bank finished.

---

## 5. How to check it's live

```bash
curl -s https://aajaodev.onrender.com/health/env
```

Then, in the admin panel, open any payout. Before configuration the account
panel reads *"Payouts are not configured — missing RAZORPAYX_KEY_ID…"*. After
it, Approve performs a real transfer and the row shows a provider reference and
a UTR.

**Test with a small real payout first** — ₹1 to an account you control. Test
mode does not exercise the actual rails.

---

## 6. Decisions still open

1. **Who tops up the RazorpayX balance, and when?** Payouts queue when it runs
   dry. Someone needs to own that, or hosts silently stop being paid.
2. **Auto-approve, or always a human?** Right now every payout needs an admin to
   click Approve. Airbnb releases automatically 24h after check-in. Worth doing
   eventually; worth *not* doing until the first hundred transfers have been
   watched by a person.
3. **The three test payouts** (₹1,555 to Ashish Rahi, plus whatever the seeded
   bookings generate) — real transfers once this is live. Clear them first.
4. **Rotate the credentials in git history.** Still outstanding, still the thing
   I'd do before real money flows.
