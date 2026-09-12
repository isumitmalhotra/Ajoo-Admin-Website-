# AWS — what is blocking the migration, and what only you can unblock

**13 September 2026** · Account **aajoo homes** · Region **ap-south-1 (Mumbai)**

This is a short list of things that can only be done by the account owner. The
migration work itself is written and waiting; none of it can run until the two
items in §1 and §2 are cleared.

---

## In one paragraph

The AWS account cannot yet launch the services the platform needs, and the
signed-in user cannot see why, because the two pages that would explain it are
closed to everyone except the account's root login. Both are owner-only fixes
and neither is technical work. Everything on our side — the full infrastructure
for the first three days of the migration — is already written and reviewed,
and sits waiting on them.

---

## 1. The account is still being verified by AWS — and it is overdue

Signing in and trying to use the account shows:

> *"Unable to create the environment. Your account verification is in progress.
> This may take up to two days for new accounts."*

**What we tested, so this is not a guess.** On 13 September we created one free
resource (a container registry) and deleted it immediately afterwards. It
worked. That tells us something useful:

| | |
|---|---|
| Container registry — created and deleted successfully | **Works** |
| CloudShell, which starts a small compute instance | **Blocked** |

So the account is **not** frozen across the board. The block is on the
**compute** family of services — and that is precisely the family the platform
needs: the database (RDS), the application containers (ECS Fargate) and the
load balancer.

**Why this is now overdue.** AWS's own guidance is that activation usually
takes a few minutes and up to 24 hours. This account was created on 9
September, so it is well past that. Waiting longer is unlikely to change
anything.

### What to do

**a) Check the usual causes first** (signed in as the **root** user):

1. **Payment method.** *Billing → Payment preferences.* AWS places a small
   verification charge on the card. In India this is the most common reason
   activation stalls — many cards need **international transactions** enabled,
   or an **e-mandate** approved in the bank's app, before that charge succeeds.
2. **The root account's mailbox.** AWS frequently emails asking to confirm
   identity, address or a phone number, and then simply waits. If that email is
   unanswered, nothing will move.
3. **Phone verification** completed at signup.

Any of those, fixed, often clears the account within the hour.

**b) If they are all in order, raise a case.** It is free, even on the Basic
support plan, and must be done from the **root** login:

> **Support → Create case → Account and billing → Service: Account →
> Category: Activation**

Include: the account ID, that the account was created on 9 September, that
CloudShell reports *"account verification is in progress"*, and that container
registry creation succeeds while compute does not. That last detail helps them
find it quickly.

---

## 2. Billing and account pages are closed to every user except root

The second blocker looks like a permissions bug and is not one. Opening
**Account** or **Payment preferences** shows:

> *"You don't have the `account:GetAccountInformation` and
> `billing:GetSellerOfRecord` permission required to view your account
> settings. Ask your administrator to add these permissions."*

**Adding permissions will not fix this.** We checked: the user already holds
`AdministratorAccess`, which includes those actions. AWS puts the billing and
account consoles behind a separate switch that **only the root user can turn
on**, and it is currently off.

Until it is on, nobody except root can see the account status, the payment
method, the bill, or set up a spending alert — which is also why nobody on this
side can tell you how the verification is progressing.

### What to do

Signed in as **root**:

> **Account menu (top right) → Account → "IAM user and role access to billing
> information" → Edit → tick Activate IAM Access → Update**

One switch, once. Nothing else changes.

---

## 3. Two more things worth doing in the same sitting

Neither blocks the migration; both are cheap now and awkward later.

**A spending alert.** The account carries promotional credits, and a budget
with an email alert is how an accident in a new account does not become a
surprise bill. It needs the switch in §2 first, which is why they are best done
together. *Billing → Budgets → Create budget*, monthly, with a figure you are
comfortable with.

**Multi-factor authentication on the day-to-day user.** MFA has now been added
to the root login — good, and the most important one. The working user
(`sumit`) still has console access without it, and that user holds full
administrative rights.

---

## What is already done and waiting

So that the position is clear: the delay is not on the build side.

- **Day 1** — network, security groups, container registries, MySQL database
- **Day 2** — certificate, load balancer, container cluster, the API service,
  and the environment-variable handling
- **Day 3** — the website service, the CDN, and a separate staging environment

All of it is written as code (Terraform), reviewed, and committed. It is
deliberately written rather than clicked together in the console, so that it
can be re-run, inspected, and handed over to whoever operates the platform
later. The moment AWS releases the account it can be applied in a single
session.

Three decisions are still open and will be needed around the same time:

1. **DNS** — whether `aajoohomes.com` moves to AWS Route 53 or stays with the
   current registrar. Either works; the first makes the switchover cleaner.
2. **Who owns the AWS console** after handover.
3. **Expected traffic in six months** — this sizes the database. At today's
   volumes the smallest instance is ample.

---

## Summary of actions

| # | Action | Who | Where |
|---|---|---|---|
| 1 | Confirm the payment card has authorised | Account owner | Root → Billing → Payment preferences |
| 2 | Check the root mailbox for an AWS verification request | Account owner | Email |
| 3 | Raise a free *Account and billing → Activation* support case | Account owner | Root → Support |
| 4 | Turn on **IAM access to billing information** | Account owner | Root → Account |
| 5 | Create a monthly budget with an email alert | Account owner | Billing → Budgets (after 4) |
| 6 | Add MFA to the working user | Either | IAM → Users |
| 7 | Answer the three open decisions above | Client | — |

Items 1 to 3 are the ones that unblock everything else.
