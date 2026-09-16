# How Aajoo Pays Its Hosts — The Options, and Which We Can Actually Get

**Prepared 16 September 2026** · supersedes the recommendation in *Razorpay Payroll for Host Payouts* (15 September) on one point, explained in §3

---

## 1. The short answer

We were told RazorpayX is closed to us because the company must show profit against total earnings, and Aajoo has not launched. That is a **bank's lending-style underwriting test**, not a Razorpay rule, and no pre-revenue company passes it.

While checking what to move to instead, a second and larger door turned out to be shut. **Razorpay Route — the marketplace split-settlement product this project recommended evaluating first on 15 September — now requires ₹40 lakh of domestic turnover.** That requirement is not Razorpay's. It comes from the **RBI Payment Aggregator Master Directions of 15 September 2025**, it applies to *every* payment aggregator's split product, and Razorpay's own FAQ states that **no business category has been exempted**. A new business may file a self-declaration of turnover, but the declaration still has to show the threshold — it does not waive it.

So the honest position is:

> **Every product that splits a customer's payment between Aajoo and a host is closed to us until Aajoo has ₹40 lakh of turnover. Shopping for a different payment gateway will not change this, because the rule is the regulator's, not the vendor's.**

What remains open is a different and simpler shape, and it is one Aajoo is already built for: **guest money settles to Aajoo's own account, and Aajoo pays each host as a vendor.** Products for that are called *payouts* or *disbursals*, they are not payment-aggregator activity, and their onboarding is ordinary business KYC rather than a turnover or profit test.

**Recommendation: Cashfree Payouts as the rail, with manual bank transfers from the admin queue as the bridge until it is live.** Reasons in §6, sequencing in §9.

**One caveat stated up front:** every provider below publishes onboarding requirements that are lighter than what an underwriter may ask a pre-revenue company for in practice. The only way to be certain is to apply. §10 gives the exact question to put to each, in writing, so we find out in days rather than after building.

---

## 2. Why RazorpayX said no, and whether it is fixable

RazorpayX today comes in one shape for a new customer. **RazorpayX Lite — the Razorpay-held balance that needed no bank — is no longer offered to new merchants.** What is left is a **Current Account provided by a partner bank**: ICICI, Yes Bank, Axis or RBL.

That matters because it locates the refusal. The account is the *bank's* product; Razorpay distributes it. The profitability test came from the bank's credit underwriting, which is why it reads like a lending criterion — because it is one.

Three consequences:

1. **It is not a Razorpay decision to appeal.** Asking Razorpay to reconsider will not move it.
2. **It may differ by bank.** Four partner banks underwrite separately. It is worth one email asking whether another partner bank will take us — but expect the same answer from all four, because none of them lends against a pre-revenue balance sheet.
3. **It resolves itself.** Once Aajoo has trading history, RazorpayX becomes available, and the code for it is already written and needs only four environment values. Nothing built is wasted.

---

## 3. The bigger finding — Route is closed too, and it is the regulator

This corrects the 15 September recommendation, and it is the single most important thing in this document.

On **15 September 2025** the RBI issued new Master Directions for Payment Aggregators (RBI/DPSS/2025-26/141). They divide merchants in two:

| | Threshold | What they may do |
|---|---|---|
| **Small merchant** | domestic turnover **≤ ₹40 lakh**, or export turnover ≤ ₹5 lakh | **May not** direct a payment aggregator to settle part of a customer's payment to a third party |
| **Large merchant** | domestic turnover **> ₹40 lakh**, or export turnover > ₹5 lakh | May direct settlement to another entity that interfaces directly with the customer |

Split settlement — a PA paying Aajoo its commission and the host the rest, out of one guest payment — is exactly the thing reserved for large merchants. Razorpay's Route FAQ states the criteria in the same terms, adds that services were **discontinued on 1 January 2026** for accounts that did not qualify, and says a business may reapply once it meets the turnover criteria in a later financial year.

Because the rule is in the RBI directions and not in a vendor's policy, **Cashfree's split product, PayU's, Easebuzz's and every other PA's are gated the same way.** There is no provider to switch to. This is worth stating plainly to anyone who suggests "try a different gateway".

Two further provisions in the same directions point the same way: a PA may **aggregate funds only for the merchant it has a direct relationship with**, and PAs are restricted from running marketplaces. Razorpay's direct relationship is with Aajoo, not with Aajoo's hosts. So the money is meant to reach Aajoo, and Aajoo is meant to pay the hosts.

**That is not a workaround. It is the shape the regulation now points at, and it is the shape our code already implements.**

---

## 4. What a host payout on Aajoo actually is

Any rail has to fit this. It is unchanged from the 15 September document and is repeated because it is the specification.

| The platform's fact | Where it lives |
|---|---|
| A payout is **per booking** — the host's share after commission and GST | `tbl_payouts`, the financial ledger |
| Released **after check-in**, on the host's chosen cycle: weekly, 15-day (default), or custom with admin approval | `property_settlement.pst_payout_cycle` |
| A cancellation before check-in **voids** it; a partial refund **reduces** it | `hostDues.service.voidFor`, the policy snapshot |
| Cash the host took at the door is a **due**, offset against the next payout | `tbl_host_dues` |
| Bank details collected once, **encrypted** (AES-256-GCM), **penny-drop verified** with a name match | `payoutAccount.service.js`, `utils/fieldCrypto.js` |
| Every transfer **idempotent**, status by **webhook**, ledger DEBIT on settlement only | `razorpayx.service.js`, `razorpayxWebhook.controller.js` |

**The important engineering point:** only the last row is provider-specific. The penny drop, the idempotency keys, the hold-until-check-in logic, the void-on-cancellation, the cash offset and the ledger are **ours and rail-agnostic by design**. Changing rails means rewriting one file and two call sites. That was deliberate, and it is why none of this is wasted.

---

## 5. The options, judged on whether we can actually get them

Ordered by how likely a pre-launch company is to be accepted.

| Option | What it is | Can we get it now? | Fit | Code cost |
|---|---|---|---|---|
| **Manual bank transfer from the admin queue** | Export approved payouts as a bank bulk-upload file; finance uploads it in net banking; UTRs keyed back | **Yes — certain.** Needs only the current account we already have | Works, at the cost of someone's time. Ledger stays honest if UTRs are recorded | **~1 day** — a CSV export and a "mark settled with UTR" action |
| **Cashfree Payouts** *(recommended)* | A virtual balance funded from our own current account; transfers by API to bank account, UPI or card; webhooks; bulk upload in the dashboard | **Very likely.** Standard business KYC, no published turnover or profit test | Same shape as the built RazorpayX code — beneficiary, verify, transfer, webhook | **~2–3 days** — one rail file, two call sites |
| **Zwitch (Open) Payout APIs** | Payout APIs over IMPS/NEFT/RTGS/UPI from a funded balance | **Likely.** Positioned for startups through to enterprise | Same shape | ~2–3 days |
| **Decentro** | API-first banking infrastructure; payouts over UPI/IMPS/NEFT/RTGS | **Likely.** Open to any Indian business entity | Same shape; strongest if we later want UPI-native features | ~2–3 days |
| **Bulkpe** | High-volume payout automation, no daily/monthly caps | **Likely.** Built for volume | Same shape; over-specified for our volume today | ~2–3 days |
| **A bank's own corporate API** (ICICI Connected Banking, Yes, Axis, HDFC) | Bulk transfers straight from our current account, by API | **Possible.** Depends on the bank relationship; often easier than a fintech for a plain current-account customer | Same shape; no third party holds our float | ~3–5 days, bank docs vary in quality |
| **RazorpayX Payouts** | Funded business account, payout API — **already built** | **No, today.** Partner-bank underwriting; Lite is closed to new merchants | Perfect — it is what the code does | **Zero** — four environment values |
| **Razorpay Route / any PA split product** | PA splits the guest's payment between Aajoo and the host | **No.** ₹40 lakh turnover, RBI rule, no category exempt | Would have been elegant | N/A |
| **Razorpay Payroll** | Salary processing | **No** — and it should not be used even if offered | Wrong product; see the 15 September document | N/A |

---

## 6. Why Cashfree Payouts is the recommendation

Not because it is technically better than Zwitch, Decentro or Bulkpe — for what Aajoo needs, all four do the same job. The reasons are practical:

- **The onboarding test is one we can pass.** A funded virtual balance topped up from our own account is not credit. Nobody is lending us anything, so nobody needs us to be profitable.
- **It is the closest match to code that already exists.** Beneficiary → validate → transfer → webhook is exactly the RazorpayX shape. The rewrite is one file.
- **It is a payments company with scale**, not a thin API layer, which matters when money stops moving on a Friday evening.
- **It does not lock us in.** If RazorpayX opens once Aajoo is trading, switching back costs the same one file — and that code is already written.

**Keep Razorpay Payments as the collection gateway.** None of this touches how guests pay. We are only choosing how money leaves Aajoo.

---

## 7. The one thing to get right before building

Under this model guest money lands in **Aajoo's own account**, and Aajoo then pays hosts. That raises a question with tax and legal consequences, and it is **not one I can answer for you**:

> **Is Aajoo the principal in the transaction — buying the stay and reselling it — or an agent collecting on the host's behalf?**

It matters because it decides how revenue is recognised, what GST is charged on, and what appears in Aajoo's turnover. It also interacts with two obligations that exist **whichever rail we choose**:

- **Income tax, section 194-O.** As an e-commerce operator, Aajoo must deduct **0.1%** of the gross amount paid to a resident host (**5%** without a PAN; exempt for an individual or HUF under ₹5 lakh a year who has given a PAN), deposit it and file it. **No rail does this for us.** It is ours to build: a per-host running total for the year, the rate decision at each payout, the deduction shown on the host's statement, and a quarterly figure for the accountant. It is bounded work, and it is already tracked as its own item.
- **GST as an e-commerce operator.** Section 9(5) makes the operator liable for GST on accommodation supplied through it by unregistered hosts; section 52 TCS applies to registered ones.

**Please put the principal-versus-agent question to the company's CA in writing before we build the 194-O logic**, because the answer changes what we compute. Everything else in this document can proceed in parallel.

There is also a quiet upside worth noting: reaching **₹40 lakh of turnover is what unlocks Route and, in time, RazorpayX.** How turnover is characterised therefore affects how soon those doors open — another reason to get the CA's answer on the record early.

---

## 8. What changes in the code, concretely

| Layer | Changes? |
|---|---|
| Bank detail capture, AES-256-GCM encryption, single store | **No** |
| Penny-drop verification and name match | **No** — unless the provider offers its own, which we would then prefer |
| Hold until check-in, void on cancellation, reduce on partial refund | **No** |
| Cash-at-door dues and payout offset | **No** |
| Idempotency keys, ledger DEBIT on settlement | **No** |
| The rail itself | **`razorpayx.service.js` → `cashfree.service.js`** |
| Webhook receiver | **`razorpayxWebhook.controller.js` → the provider's signature scheme and status vocabulary** |
| Admin approve action | Two lines — which service it calls |
| 194-O deduction | **New, and required regardless of rail** |

Estimated: **2–3 days** for the rail swap once an account is live, plus the separate 194-O piece. The manual-transfer bridge is about **a day** and can be built immediately, because it depends on no vendor at all.

---

## 9. Recommended sequence

1. **Now — build the manual bridge.** CSV export from the admin payout queue and a "mark settled with UTR" action. Depends on nobody, makes UAT payouts real and keeps the ledger honest. One day.
2. **Now — apply to Cashfree Payouts**, and to one other (Zwitch or Decentro) in parallel. Applying to two costs nothing and avoids a second wait if one declines. Use the wording in §10.
3. **Now — ask the CA** the principal-versus-agent question in §7.
4. **On approval — swap the rail.** Two to three days, behind the existing "Payouts are not configured" guard, so nothing half-built can move money.
5. **Then — build 194-O.** Required whatever happens.
6. **When turnover passes ₹40 lakh — revisit Route**, and RazorpayX once the bank will underwrite. Both are then a small change, and the RazorpayX code is already written.

---

## 10. What we need from the client

**Send this to each payout provider, in writing.** A precise question gets a fast, quotable answer, and tells us in days whether we are eligible:

> *We operate an accommodation marketplace in India (private limited company, GST registered, pre-launch). Guest payments are collected through a payment gateway and settle to our own current account. We then need to pay each host their share per booking — roughly [N] transfers a month, average [₹X] each — by API, with a webhook for status and bank account verification before the first transfer.*
>
> *Please confirm: (1) are we eligible for your Payouts product as a pre-revenue company, and what are the exact eligibility criteria; (2) what documents are required; (3) is there any minimum turnover, profitability or vintage requirement; (4) how is the balance funded and what is the settlement time; (5) pricing per transfer; (6) do you provide bank account verification (penny drop with name match); (7) does anything in the RBI Payment Aggregator Directions of September 2025 restrict this use case for us?*

Question (7) is the one to insist on an answer to. It is how we avoid building on a rail that is withdrawn later, which is exactly what happened with Route.

**And separately, to Razorpay:**

> *Please confirm in writing which criterion we failed for RazorpayX, whether it is Razorpay's or the partner bank's, and whether any other partner bank (ICICI, Yes, Axis, RBL) would consider us. Also confirm the turnover we would need to qualify for Route, and whether a self-declaration is accepted for a company in its first financial year.*

**Decisions needed from the client:**

1. **May finance run manual bank transfers during UAT?** If yes, we build the export this week and payouts work end to end regardless of vendors.
2. **Which provider do we apply to?** Our recommendation is Cashfree plus one other in parallel.
3. **The CA's answer** on principal versus agent, and confirmation that Aajoo is an e-commerce operator under 194-O and section 9(5).

---

## 11. What I verified, and what I did not

Stated plainly so nothing here is taken on more authority than it has.

**Verified against primary sources:** the RBI Master Directions of 15 September 2025 and the small/large merchant split-settlement distinction; Razorpay's own Route FAQ, including the ₹40 lakh threshold, the 1 January 2026 discontinuation, the self-declaration provision and the statement that no business category is exempt; that RazorpayX Lite is closed to new merchants and current accounts come from partner banks; that Cashfree Payouts works from a virtual balance funded by the merchant's own account.

**Not verified, and needing the provider's written answer:** whether any specific provider will accept **this** company today. Published criteria and underwriting practice are not the same thing, and a pre-revenue applicant is precisely where they diverge. That is why §10 exists and why I suggest applying to two.

**Outside my competence:** the principal-versus-agent characterisation and its tax treatment. That is the CA's call, and I have flagged where it changes the build rather than guessing at it.

---

## 12. Sources

- [RBI Payment Aggregator Directions, 15 September 2025 (RBI/DPSS/2025-26/141)](https://www.fidcindia.org.in/wp-content/uploads/2025/09/RBI-PAYMENT-AGGREGATORS-DIRECTIONS-15-09-25.pdf)
- [Razorpay Docs — Route FAQs (eligibility, ₹40 lakh threshold, 1 January 2026 discontinuation)](https://razorpay.com/docs/payments/route/faqs/?preferred-country=IN)
- [Razorpay Docs — Route](https://razorpay.com/docs/payments/route/?preferred-country=IN)
- [Ikigai Law — RBI Rewrites the Payment Aggregator Rulebook (small vs large merchant, split settlement)](https://www.ikigailaw.com/article/639/rbi-rewrites-the-payment-aggregator-rulebook)
- [IndiaCorpLaw — Decoding RBI's Overhaul of the Payment Aggregator Directions](https://indiacorplaw.in/2025/10/09/decoding-rbis-overhaul-of-the-payment-aggregator-directions/)
- [AuthBridge — RBI's Updated Guidelines for Payment Aggregators 2025](https://authbridge.com/blog/rbi-payment-aggregator-master-direction-2025/)
- [Razorpay Docs — RazorpayX Account Types (Lite unavailable to new merchants; partner banks)](https://razorpay.com/docs/x/account-types/)
- [Razorpay Docs — RazorpayX Payouts](https://razorpay.com/docs/x/payouts/)
- [Cashfree — Onboarding FAQs](https://www.cashfree.com/docs/help/onboarding-related/general-faqs)
- [Zwitch (Open) — Payouts](https://www.zwitch.io/payouts)
- [Decentro — Payouts documentation](https://docs.decentro.tech/docs/payments-direct-payouts)
- [Bulkpe — Best Payout APIs in India](https://bulkpe.in/blog/best-payout-apis-in-india2025)
- Income-tax Act section 194-O — 0.1% from 1 October 2024 (Finance (No. 2) Act 2024); 5% without PAN; ₹5 lakh threshold for individuals/HUF with PAN
- Aajoo's own code and documents: `PAYOUTS_SETUP.md`, `services/payouts/*`, `report-2026-09-15/RAZORPAY_PAYROLL_FOR_HOST_PAYOUTS.md`, `MASTER_PENDING_TASKS.md` §2.2
