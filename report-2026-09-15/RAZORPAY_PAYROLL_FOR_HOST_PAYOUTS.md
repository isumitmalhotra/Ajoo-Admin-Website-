# Razorpay Payroll for Host Payouts — Will It Work?

## 1. The short answer

**It can move rupees; it cannot be our payout rail.**

Razorpay Payroll will transfer money from a pre-funded wallet to an individual's bank account, so a one-off test would "work". Everything after that test does not:

- **Razorpay itself closed this door on 31 July 2025.** Its Payroll help centre says vendor payments through the Payroll wallet are discontinued from that date; the wallet now pays only *"freelancers, consultants, interns, or any part-time individual using a personal PAN"* under TDS section 194J or with no TDS, and may not *"pay vendors or entities with a business PAN"* or make *"payments that fall under non-194J TDS categories."* A host who lets a homestay is a vendor to the platform; a host who runs it through a firm has a business PAN. Both are outside what Razorpay says the product may pay.
- **It deducts the wrong tax, automatically.** A marketplace paying its sellers deducts under **section 194-O** (0.1% since 1 October 2024; 5% if the host gives no PAN; nothing for an individual under ₹5 lakh a year who has given a PAN). Payroll deducts under **194J** — professional fees, 10% — or nothing, and files the challan under that section without asking. Either a host loses 10% they do not owe, or the platform fails to deduct the 0.1% it does.
- **It cannot do the job's shape.** Payroll runs are monthly; our hosts chose weekly, 15-day or custom cycles. There is no "hold until check-in, then release" per booking, no status callback per transfer, no reversal on cancellation, no offset for cash a host collected at the door, no bank-account verification, and no API that creates a payout — the API it has is for HRMS partners to push salary additions into a pay run.

**What Razorpay recommends instead, in the same notice:** *"link a RazorpayX-powered Current Account to your Payroll setup"* — i.e. RazorpayX, the product the platform's payout code was written for. The other Razorpay product built for exactly this — splitting a guest's payment and settling a share to each host — is **Razorpay Route**, which runs on the ordinary Payments keys the platform already has.

The rest of this document is the detail: what our payouts actually need, where Payroll falls short on each point, what the alternatives are, and what is needed from the client to move.

---

## 2. What Razorpay Payroll is — and what "same keys" means

Razorpay Payroll (formerly Opfin / XPayroll) is **HR payroll software**: employees, salary structures, monthly pay runs, PF, ESI, professional tax, TDS under section 192, Form 16, payslips, leave, reimbursements. It has a wallet that is loaded from the company's bank account and drained by the monthly run.

It had a "Contractor Payments" module for paying non-employees from that wallet. On **31 July 2025** Razorpay renamed it **"Part-Time Employee Payments"** and narrowed it to the two cases above (194J with a personal PAN, or no TDS). The stated reason is *"to comply with evolving regulatory norms and banking guidelines."*

"Payroll has been configured and KYC verified, you can use same keys" (client, 12 September) most likely refers to the **Razorpay Payments** keys — the `rzp_…` pair the platform already uses to collect from guests. Those keys do not authenticate to Payroll (which has its own partner API at `payroll.razorpay.com`), and they do not authenticate to RazorpayX (which has its own keys and a funded account). They **do** authenticate to **Route**, which is a feature of Payments. If "same keys" is what was meant, Route is the product being pointed at.

---

## 3. What a host payout on Aajoo actually is

Before comparing products, this is the shape the platform already implements — the shape any rail has to fit.

| The platform's fact | Where it lives |
|---|---|
| A payout is **per booking**, for the host's share of what the guest paid (room after any deal, plus fees, minus commission and GST handled by the platform) | `tbl_payouts` (`po_amount`, `po_status` QUEUED → PROCESSING → COMPLETED / FAILED, `po_provider`, `po_provider_payout_id`), the financial ledger |
| It is released **after check-in**, on the cycle the host chose in step 5 of the listing wizard: **weekly**, **15-day (default)** or **custom (admin approval)** | `config/listingSchema.js` `payoutCycles`; `property_settlement.pst_payout_cycle` (a custom cycle waits in `pst_payout_cycle_requested` until an admin grants it) |
| A cancellation before check-in **voids** the payout; a partial refund **reduces** it | `hostDues.service.voidFor` and the cancellation policy snapshot on the booking |
| Money a host collected **at the door** (pay-at-property) is a **due** the host owes the platform, offset against their next payout | `tbl_host_dues`, recorded at check-in since 12 September |
| Bank details are collected once, **encrypted** (AES-256-GCM), and **verified by a penny drop** — ₹1 must land and the bank's registered name must match | `payoutAccount.service.js`, `utils/fieldCrypto.js`, one writer since 11 September |
| Every transfer is **idempotent** (the key is stored before the provider is called), the provider's status arrives by **webhook**, and the ledger DEBIT is written on settlement only | `razorpayx.service.js`, `razorpayxWebhook.controller.js`, `adminFinance.controller.js` |
| Nothing moves until four environment values exist; until then Approve refuses with "Payouts are not configured" | `PAYOUTS_SETUP.md` (11 August) |

And two obligations that belong to the platform **whichever rail is used**, because it is the e-commerce operator:

- **Income tax, section 194-O:** deduct 0.1% of the gross amount paid to a resident host (5% without PAN; exempt for an individual/HUF under ₹5 lakh a year who has given a PAN), deposit it, and file it. **This is not in the code today** — no rail does it for us, and it has to be built above whichever rail is chosen.
- **GST as an e-commerce operator:** section 9(5) makes the operator liable for GST on accommodation supplied through it by hosts who are not registered, and section 52 TCS applies where registered suppliers are paid through the platform. This is already the platform's affair on the collection side; it is mentioned here because Payroll's tax machinery is built for salaries and knows nothing of it.

---

## 4. Would Payroll do each of those? The checklist

| The need | Razorpay Payroll | Verdict |
|---|---|---|
| Pay a host who is a **company / LLP / firm** (business PAN) | Explicitly not allowed on the wallet since 31 July 2025 | **Blocked** |
| Pay an **individual** host | Allowed only as a "part-time employee" under 194J or no-TDS | **Wrong basis** — hosts are 194-O participants, not 194J professionals |
| Deduct TDS under **194-O** at 0.1% / 5% / nil-under-threshold | Deducts 194J (10%) or nothing; files challans under 194J | **Wrong tax, filed wrong** |
| Pay **per booking**, after check-in, on a weekly / 15-day / custom cycle | Monthly pay runs; ad-hoc payments are manual dashboard actions | **Does not fit** |
| **Hold** a payout until check-in, **void** on cancellation, **reduce** on partial refund | No notion of a booking, a hold or a reversal | **Absent** |
| **Offset** cash the host collected at the door | Salary deductions exist but are month-scoped HR deductions, not ledger offsets | **Absent** |
| **Verify** the bank account (penny drop, name match) | None; bank details are typed into an employee record and trusted | **Absent** |
| **Create a payout by API**, receive a **status webhook**, record the provider's id | Partner HRMS API: employees, additions/deductions before a run. No payout-creation endpoint, no per-transfer webhook | **Absent** |
| Keep **one** store of bank details | Payroll keeps its own employee bank record — a second store beside the encrypted one, the trap closed on 11 September | **Regression** |
| **Fund** the transfers | Wallet loaded manually from the company account (guest money settles to the bank first, then someone loads the wallet) | **Manual, two hops** |
| Pricing | Per employee per month (every host becomes a billable "employee"), not per transfer | **Scales the wrong way** |
| What the host receives | A payslip and, at year end, TDS paperwork as a part-time employee of Aajoo | **Mischaracterises the relationship** |

---

## 5. The challenges, in full

### 5.1 Razorpay's own rule (31 July 2025)

The Payroll help centre article *"Update on Contractor Payments being renamed to Part-Time Employee Feature"* is unambiguous: vendor payments via the module are discontinued; the wallet may pay individuals with a personal PAN under 194J or with no TDS; it may not pay entities with a business PAN or under non-194J TDS sections. Hosts are vendors of accommodation; the TDS section that applies to them is 194-O, a non-194J section. Using the wallet for them contradicts the product's terms as Razorpay has written them, and Razorpay has already tightened this product once — a rail that can be withdrawn by a policy notice is not a rail to put a marketplace on.

### 5.2 The wrong tax section, applied automatically

- **194-O** (what applies): the e-commerce operator deducts **0.1%** of the gross sale value at credit or payment, whichever is earlier; **5%** if the participant has not furnished a PAN; **no deduction** for an individual or HUF whose gross sales through the operator are under **₹5 lakh** in the year and who has furnished PAN/Aadhaar.
- **194J** (what Payroll applies): fees for professional or technical services, generally **10%**, deposited by the 7th of the following month; Payroll generates and files the challan itself.

Run hosts through Payroll and every host over the threshold has 10% taken where 0.1% was due; every host under the threshold has 10% taken where nothing was due; and the deductions land in the government's records under the wrong section, so the host's Form 26AS shows professional-fee TDS from an employer they never worked for. Unwinding that is a filing exercise per host per quarter.

### 5.3 The relationship is mischaracterised

Every host becomes a "part-time employee" in Aajoo's HR system: an employee id, a joining date, a payslip, a PAN on file as staff, year-end TDS certificates issued as to staff. Professional-tax and PF/ESI questions arise for people who are not staff. In the company's books, money that is a **pass-through** (the guest's payment, less commission) is recorded as **staff cost** — which overstates expenses and revenue alike, and is the wrong story to tell an auditor or an acquirer.

### 5.4 The cadence is monthly; the promise is not

Hosts were offered weekly, 15-day and custom payout cycles, and the platform's settlement logic releases a booking's payout after check-in. A payroll run happens once a month. A booking checked in on the 2nd is paid on the 30th, or somebody performs a manual ad-hoc payment from the dashboard for each one. There is no API to do that per booking, and no callback that tells the platform it happened.

### 5.5 No booking-level API, no webhook, no idempotency

The Payroll API that exists is for **HRMS and benefits partners**: read employees, push salary additions or deductions before a pay run, read tax regime and leave data. It is not a "create a payout of ₹X to beneficiary Y with idempotency key Z and call me back when it settles" API. Everything the platform already does around a payout — claim the row, store the key, call the provider, receive the webhook, write the ledger — would have no counterpart. Payouts would become a person in a dashboard and a spreadsheet of UTRs.

### 5.6 Onboarding and bank details

Each host would be created in Payroll as an employee with PAN, date of birth, joining date and bank account. Two consequences: the host's bank details, which the platform encrypts and verifies once, would be typed into a second system that does neither (Payroll has no penny drop); and every change (a host switches banks) has to be made twice. The platform spent 11 September removing exactly this — two stores of bank details that disagreed.

### 5.7 Money mechanics

The Payroll wallet is loaded from the company bank account. Guest payments settle from Razorpay Payments to that bank account on T+2 or so; someone then loads the wallet; then the run drains it. Two hops, both manual, both places where the balance can be short on payout day. A failed transfer (wrong IFSC, closed account) surfaces as an HR exception, not as a `FAILED` payout the admin queue can retry. A cancellation after the run has gone out is a clawback nobody has a button for.

### 5.8 Cost shape

Payroll is priced per employee per month. A marketplace's cost should track transfers, not headcount — a host with one booking a year is still an "employee" for twelve months. (The exact plan price is the client's to read from their agreement; the shape is the point.)

### 5.9 What we would inherit

TDS returns under 194J each quarter for every host, Form 16A generation, year-end reconciliation with hosts whose 26AS shows the wrong thing, and the conversation with each host about why Aajoo's payroll department is deducting 10% of their rent.

---

## 6. What would work

| Option | What it is | Fit | What it needs | What changes in the code |
|---|---|---|---|---|
| **Razorpay Route** (recommended to evaluate first) | A feature of Razorpay **Payments**: each host becomes a **Linked Account** (with its own KYC); a guest's captured payment is **split** by a Transfer API call; the host's share is **settled** to their bank on Razorpay's schedule; a transfer can be **put on hold** (until check-in) and released; refunds can be reversed against the linked account | The marketplace product. Same keys the platform already has. Hold-and-release matches "pay after check-in"; reversal matches cancellation | Route activation on the account (Razorpay approves the marketplace use case); each host completes linked-account KYC (PAN, bank, business type) | Contained: `razorpayx.service.js` → a `route.service.js` (create linked account, create transfer with `on_hold`, release, reverse); two call sites (`adminFinance.controller`, the webhook). Penny drop becomes Razorpay's KYC. The cash-at-door **offset** stays ours: a due reduces the amount transferred |
| **RazorpayX Payouts** (what is built) | A funded business account with a payout API: contact → fund account → penny-drop validation → payout, status by webhook | Exactly what the code does today; also what Razorpay's Payroll notice points to ("a RazorpayX-powered Current Account") | Eligibility. The client was told "not eligible" — ask Razorpay **which**: RazorpayX Lite (a Razorpay-held balance) or a partner-bank current account (Axis, RBL, Yes, IDFC). Then the four environment values in `PAYOUTS_SETUP.md` | None |
| **Another payout provider** (Cashfree Payouts, Decentro, a bank's corporate API) | Same shape as RazorpayX: beneficiary, verification, transfer, webhook | Fits; a second vendor relationship | KYC and a funded account with that provider | The rail file and two call sites, as above; the penny-drop, idempotency and ledger layer is provider-agnostic by design |
| **Manual NEFT from the company account** (interim) | The admin payout queue exports the day's approved payouts as a bank bulk-transfer file; finance uploads it in net banking; UTRs are keyed back | Works today, at the cost of a person's time; keeps the ledger honest if UTRs are recorded | Nothing from Razorpay | A CSV export and a "mark settled with UTR" action on the queue (small) |
| **Razorpay Payroll** | Above | Does not fit; contradicts Razorpay's own terms for the product | — | — |

**On tax, whichever rail:** 194-O deduction has to be built by us — a per-host running total for the year, the 0.1% / 5% / nil decision at each payout, the deduction shown on the host's payout statement, and a quarterly figure for the accountant to file. Neither Route nor RazorpayX nor Payroll does this for a marketplace. It is a bounded piece of work and it is listed in the master task list as its own item.

---

## 7. What we need from the client

1. **Ask Razorpay, in writing, one question:** *"We are an e-commerce operator paying accommodation hosts (TDS section 194-O). Which of your products should we use to pay them — Route, or a RazorpayX-linked current account — and what exactly made us ineligible for RazorpayX?"* The answer decides the rail; the reason for ineligibility (entity type, turnover, bank partner) tells us whether it is fixable.
2. **If Route:** activate it on the account and tell us; we will build the linked-account onboarding into the host's Payout settings so hosts complete their KYC in the app and on the website, and switch the rail. Hosts with a business PAN are fine under Route.
3. **If RazorpayX becomes available:** set the four environment values in `PAYOUTS_SETUP.md`; nothing else changes.
4. **Meanwhile:** say whether finance can run manual NEFT from the admin queue for the UAT period; the export is a day's work and keeps every payout honest in the ledger until the rail is live.
5. **Confirm the tax position with the accountant:** that Aajoo is an e-commerce operator under 194-O (and 9(5) for unregistered hosts' accommodation), so the deduction logic is built once, correctly.

---

## 8. Sources

- Razorpay / XPayroll Help Center — *Update on Contractor Payments being renamed to Part-Time Employee Feature* (the 31 July 2025 notice; the quoted passages are from it).
- Razorpay Docs — *RazorpayX Payroll: Integrations* and the partner API at `payroll.razorpay.com` (employee data, pay-run additions and deductions).
- Razorpay Docs — *Route*: Linked Accounts, Create Transfers from Payments, Modify Settlement Hold, Schedule Settlements.
- Income-tax Act, section 194-O — 0.1% from 1 October 2024 (Finance (No. 2) Act 2024), 5% without PAN, ₹5 lakh threshold for individuals/HUF with PAN.
- The platform's own code and documents: `PAYOUTS_SETUP.md` (11 August), `services/payouts/*`, `MASTER_PENDING_TASKS.md` §2.2.
