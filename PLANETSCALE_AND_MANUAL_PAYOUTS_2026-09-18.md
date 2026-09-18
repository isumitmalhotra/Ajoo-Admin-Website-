# PlanetScale for the database, and manual host payouts

## 1. The two questions, and the short answers

Two items came from the client on 18 September:

1. *"For MySQL, check PlanetScale."*
2. *"For payouts, check the system for manual payouts."*

**PlanetScale — yes, with three small adjustments.** It is MySQL-compatible, has a Mumbai region and a Singapore region, and its smallest cluster is $25 a month for a primary plus two replicas across three zones. Our database is small and plain MySQL, and moves in minutes. The one thing that matters more than the vendor is *which region*: the database must sit next to the API, not next to the users.

**Manual payouts — the system is nearly ready for them.** The queue, the ledger, the encrypted bank details, the audit trail and the host's payout history are all built. What is missing is a way to move the money without a payment provider: today "Approve" refuses because RazorpayX is not configured, and bank accounts cannot be verified because verification *is* RazorpayX. About two days of work closes that, and it is described in section 4.

## 2. What the database actually is — read from the live system on 18 September

| Fact | Value | Why it matters |
|---|---|---|
| Engine | MySQL 8.0.43 | Same major version everywhere we could move it |
| Tables | 128, every one with a primary key | Every managed MySQL provider accepts this shape |
| Size | 21 MB of data and indexes (43 MB on disk) | A move is a dump and a restore, minutes not hours |
| Foreign keys | 39 | The one PlanetScale setting to switch on (below) |
| Triggers, events, stored procedures | None | Nothing exotic to port |
| Where it lives today | Clever Cloud, **Paris** | Every request from India crosses to Europe and back |

## 3. PlanetScale, checked on their site today

**What it is.** PlanetScale runs Vitess — MySQL with a layer on top that gives sharding, branching and zero-downtime schema changes. It is the database behind some very large products, and it is over-engineered for a 21 MB database; that is not a reason against it, as long as the price is right and the quirks are known.

**Price and regions (planetscale.com/pricing, 18 September 2026).** The smallest Vitess cluster, **PS-10** (1/8 vCPU, 1 GB memory, 10 GB storage, one primary and two replicas across three availability zones), came to **$25 a month** in **AWS ap-south-1 (Mumbai)**; **ap-southeast-1 (Singapore)** is also offered. Backups are included. There is no free tier.

**Three things to settle before saying yes — none of them large:**

| Point | What it means for us |
|---|---|
| Foreign key constraints are **off** on a new PlanetScale database | One checkbox in the database settings ("Allow foreign key constraints"); our 39 constraints then work as they do today. |
| `INSERT … ON DUPLICATE KEY UPDATE` is refused on a table that has foreign keys | We use that statement in exactly one place (notification preferences). A ten-minute rewrite, done before the move. |
| "Safe migrations" blocks a direct `ALTER TABLE` on the main branch | Either switch it off on the main branch — reasonable at our size — or adopt PlanetScale's deploy-request flow. Our existing migration tool keeps working with it off. |

Also true, and fine: connections must use TLS (a setting on our side); the primary is a small slice of a CPU, which is more than a 21 MB database with a few hundred users needs.

**The region decision — read this before choosing Mumbai.** A page on Aajoo runs five to ten database queries. If the API is in Singapore (Render's nearest region, see the hosting document) and the database in Mumbai, *each query* pays 40 ms across the sea — 200–400 ms a page, more than the 70 ms a user in India pays once to reach Singapore. **Put the database in the same region as the API.** If the API goes to Render Singapore, choose PlanetScale **Singapore**. If the platform later moves to AWS Mumbai, the database follows (a 21 MB database moves in an afternoon; PlanetScale offers Mumbai for that day).

**Alternatives, for completeness:**

| Option | Region | $/mo | Compatibility | Verdict |
|---|---|---|---|---|
| **PlanetScale** PS-10 | Mumbai or Singapore | 25 | Three adjustments above | **Recommended** — HA at this price, the client's preference |
| DigitalOcean Managed MySQL | Bangalore | 15 (single node) / ~30 with standby | Plain MySQL 8, zero changes | The zero-friction alternative; no Singapore region |
| Clever Cloud (today's vendor) | Singapore zone | ~10 | Zero changes | "Move nothing" option, not India |
| Aiven for MySQL | Mumbai | ~70 | Zero changes | Good product, three times the price |
| AWS RDS | Mumbai | ~25–40 | Zero changes | Blocked on the account's card verification |

## 4. Manual payouts — what exists, what is missing, what changes

### 4.1 What the system has today (live numbers, 18 September)

- **A payout queue that fills itself.** Every paid booking queues the host's net share (room subtotal less 15% commission and the GST on it). Live: **18 payouts queued, ₹1,66,549 in total**; 4 marked failed, correctly, for cancelled stays.
- **Bank details, encrypted** (AES-256-GCM) with a single writer, masked in every screen.
- **A ledger, an audit trail** (every finance change needs a reason and is logged with who and when), **host statements and invoices**, and the pay-at-property offset — money a host owes the platform from a cash booking is withheld from their next payout automatically.
- **A host payout history** on the web and in the app.
- **RazorpayX integration**, complete and dormant: contact and fund-account registration, the ₹1 penny-drop verification, the transfer, the webhook. Blocked because the company is not eligible for RazorpayX (see the payout-rails document of 16 September).

### 4.2 Why nothing can be paid right now

- "Approve" on a queued payout **refuses** unless RazorpayX credentials are present — deliberately, because the earlier version marked payouts "paid" without any money moving.
- A host's bank account can only be **verified by RazorpayX's penny drop**. Live: **2 host accounts on file, 0 verified, 0 registered.** An unverified account is not payable, so every queued payout is stuck behind verification.

### 4.3 The changes

| # | Change | Where |
|---|---|---|
| 1 | **A payout mode switch** — `manual` (default whenever RazorpayX is not configured) or `razorpayx`. Nothing is removed; the automatic path stays for the day the company qualifies for a provider | Backend |
| 2 | **Verification without a provider** — an admin with the finance role reveals the host's bank details (masked until revealed; every reveal audited), sends a **₹1 test transfer from the company account**, and marks the account *Verified* with the bank reference. Replaces "not registered with the payment provider" | Backend, admin web |
| 3 | **A payout run** — the admin selects queued payouts, grouped **one transfer per host** (today's 18 rows are a handful of hosts), downloads a **bank bulk-transfer file** (beneficiary, account, IFSC, amount, narration), pays through the company's net banking, then **records the run**: UTR per host, method (NEFT / IMPS / UPI), date, amount sent. Recording marks the payouts complete, writes the ledger, applies the pay-at-property offset and notifies each host | Backend, admin web |
| 4 | **The host sees the real thing** — *Paid by bank transfer · 18 Sep · UTR …* on the web and in the app, in place of a bare status | Host web, app |
| 5 | **Guards** — a UTR cannot be recorded twice; a payout on hold cannot be put in a run; two admins cannot pay the same host twice; every step carries a reason into the audit log | Backend |

**Effort:** about two working days across backend, admin, host web and app, with tests. **What the company needs:** a bank account with bulk-transfer (NEFT/IMPS) on net banking, and a named person with the finance role who runs payouts on a fixed day each week.

### 4.4 One item for the company's accountant, not for us

As an e-commerce operator, Aajoo Homes most likely has to **deduct TDS under section 194-O** (0.1% of the gross amount) on host payouts and collect each host's PAN, with the usual threshold for individual hosts. The system can hold a TDS line per host and print it on the statement once the accountant confirms the rule and the rate. We would rather build that on an answer than on a guess.

## 5. Decisions needed

1. **PlanetScale — go ahead?** Recommended: yes. **Region:** the same as the API — Singapore if the API is on Render Singapore.
2. **Who owns the PlanetScale account** — recommended: the company, with the development team invited.
3. **Manual payouts — build as described in 4.3?** Three defaults unless told otherwise: one transfer per host per run; verification by a ₹1 test transfer; no TDS deduction until the accountant answers 4.4.

With those, the database moves in a day and manual payouts are live within the week.

---

*PlanetScale prices and regions are as read on planetscale.com on 18 September 2026; DigitalOcean, Clever Cloud and Aiven figures are their list prices as of the same date — verify each on the provider's page before purchasing. Live database and payout figures were read from the production system on 18 September 2026.*
