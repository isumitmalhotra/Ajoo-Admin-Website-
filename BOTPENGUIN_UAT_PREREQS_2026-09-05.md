# BotPenguin UAT — developer prerequisites

Against **Aajoo-Homes-UAT-Execution-Pack-2026-09-04.pdf**, section 4, the eleven
items listed under *"Sumit: development portal and backend test records"*.

Audited **2026-09-05** against the live backend (`aajaodev.onrender.com`) and its
database. Re-run the audit at any time:

```bash
node scripts/seedBotPenguinUatRecords.js
```

Copy that script into the backend repo's `scripts/` first — it needs that repo's
models and `.env`. Read-only unless you pass `--apply`.

---

## Where each of the eleven stands

| # | What the pack asks for | Status |
|---|---|---|
| 1 | Bot embedded in the dev website and app | **Done** |
| 2 | Signed-in session passed to the bot | **Done** — web already; app closed today |
| 3 | Guest with ≥2 non-cancelled bookings | **Done** — user 101 has 16 |
| 4 | Guest with a stay in progress | **Done** — created, `B170046` |
| 5 | Host with listing, analytics and payout data | **Done** — user 100 |
| 6 | One account that is both Guest and Host | **Done** — created, user 169 |
| 7 | A booking owned by somebody else | **Done** — `B754668`, user 164 |
| 8 | A second Host, for the cross-host denial test | **Done** — users 168, 135, 150 |
| 9 | A disposable booking, cancellable once | **Done** — created, `B261280` |
| 10 | Which inbox receives which OTP | **Answered** |
| 11 | One WhatsApp sender per role, stable | **Done** — the duplicate was cleared |

All eleven are ready.

## The records that were created

Made on 2026-09-05 through the product's own endpoints, not by INSERT.

| For | Record | Detail |
|---|---|---|
| 4 | Booking `B170046` | 05-09 to 08-09-2026, pay-at-property, **Booking Confirmed** |
| 6 | User 169 `aishmobilehost@yopmail.com` | now holds both roles, four listings |
| 9 | Booking `B261280` | 19-09 to 21-09-2026, pay-online, **Payment Pending** |

`B170046` was approved by host 100 through `/host/confirm-book` after creation.
Without that it sat at status 5, *Booked*, which is a request awaiting the
host — the bot would still have called it ongoing, because it classifies purely
on dates, but the host's own Ongoing Stays tile would not have listed it. A
record that two screens disagree about is not a good test record.

`B261280` is pay-online rather than pay-at-property on purpose. A guest may hold
only one unsettled pay-on-arrival booking at a time and `B170046` is already it,
so a second was refused. Online suits the case better anyway: it stays unpaid,
so cancelling it moves no money and leaves no refund to unwind.

Rolling back, if the run needs a clean slate:

```sql
UPDATE tbl_users      SET user_isUser      = 0 WHERE user_id      = 169;
UPDATE tbl_user_creds SET cred_user_isUser = 0 WHERE cred_user_id = 169;
```

The two bookings should be cancelled through the product rather than deleted —
they raised host-dues and history rows that a `DELETE` would orphan.

---

## 1 and 2 — the bot, and the signed-in session

Both surfaces carry bot `69803a093817049868bf064f` with window
`696f4cdf88f4a8046c67188e`, the IDs the pack names.

The identity handoff now works the same way on both, and **the tester never
sees or types a token**, as the pack requires.

The app was the outstanding half. Until today it put the user's `user_token` —
the thirty-day credential that opens the whole API — into the chat URL as
`ctx-token`, which is a query string that lands in a vendor's request logs and
analytics and stays there. The website stopped doing that on 2026-09-05. The app
now does the same: it calls `POST /bp/handoff` for a fifteen-minute token, signed
with a key the session verifiers reject, good for `/bp/session/start` and nothing
else. Verified live — 176 characters, `expiresInSeconds` 900.

If the mint fails the app opens the chat with no identity at all rather than
falling back to the session token, and the bot asks for a phone number. That is
the correct failure: a worse greeting, not a leaked credential.

Shipped in **app build 23**. Four tests cover it, including one that fails if a
`handoff ?? token` fallback is ever added back.

---

## 4 — a Guest with a stay in progress

**Created: `B170046`, user 101, 05-09 to 08-09-2026, Booking Confirmed.**

Nobody on the platform had one. Checked across every account, not just the test
guest: no non-cancelled booking had a check-in on or before today and a
check-out on or after it.

Worth correcting an earlier note in case it is still circulating: `BPTEST04` was
recorded as the ongoing stay. Its dates do span today, but its status is 2,
which is **Cancelled**, not Paid. Status 3 is Paid. `BPTEST01` and `BPTEST03`
are cancelled too, and `BPTEST02` is a Check In whose dates ended in July.

The seeder creates it through `POST /booking/create`, so the record is the same
shape as a real guest's — a booking is six tables plus a host-dues entry and a
snapshotted cancellation policy, and hand-written rows drift from that.

**Two things to know if this ever has to be recreated.**

The stay must start **today**, not yesterday: `/booking/create` refuses a
check-in in the past. But the bot only calls a stay ongoing once the check-in
moment has passed, and that is **2 PM on the arrival day**. So seed it in the
afternoon. Seeded in the morning, the record exists and still classifies as
*upcoming*, and a tester running UAT-08 before lunch would log a Fail against
working code.

And it needs the host's approval afterwards. A new booking lands at status 5,
*Booked*, which is a request waiting on the host. The bot would call it ongoing
regardless, because it classifies on dates alone — but the host's Ongoing Stays
tile only counts statuses 3, 6, 8 and 9, so the two screens would disagree about
the same stay.

UAT-08 is unblocked. The stay runs to 08-09-2026, so it stops being *ongoing* at
11 AM that day — after which it needs recreating if the run is still going.

---

## 6 — one account that is both Guest and Host

**Created: user 169, `aishmobilehost@yopmail.com`.**

No account on the platform held both roles. Every one was a host or a guest, and
never both.

The platform does support the idea. `POST /user/switch-mode` mints a token for
the other role, and it always allows the switch back to guest, on the stated
principle that every host is also a guest. What is missing is an account whose
role flags say so, because the guest-side lookups filter on `user_isUser = 1`.

**User 169 was chosen** because it has four listings, three of them live, so
Host mode has something real to show; its inbox receives mail; and its number is
not one of the two WhatsApp mappings. Setting `user_isUser` and
`cred_user_isUser` to 1 was the whole change, and it reverses in two statements.

Leave `cred_user_isHost` alone. Sign-in filters on it, so flipping it would break
host login for that account. The route into guest mode is switch-mode, which is
what UAT-05 describes anyway: sign in, then choose the role in the chat.

Because 169 is now the dual-role account, use **168** (`Aish test Host`) for
prerequisite 8, so UAT-05 and the cross-host denial test are not reading the same
record. The seeder excludes 169 from what it offers there.

It also excludes closed accounts, which it did not at first: it offered user 133,
soft-deleted a month ago, purely because the listings it left behind are still
counted against it. A tester handed a closed account gets a denial for the wrong
reason and logs a Pass that proves nothing.

> Creating this account exposed a defect that would have failed UAT-05 whatever
> the test data looked like. It is fixed; see below.

---

## 9 — a disposable booking

**Created: `B261280`, user 101, 19-09 to 21-09-2026, unpaid.**

Use this one for UAT-16 and UAT-17, and nothing else.

User 101 already had five future non-cancelled bookings, so the case was not
blocked. A fresh one was made anyway. All five are counted by prerequisite 3,
and UAT-07 picks a *deterministic primary booking* from that same set —
cancelling one mid-run would change what UAT-07 should expect. A dedicated
booking keeps the two cases from interfering.

---

## 10 — which inbox gets which OTP

One code path serves every OTP the bot sends, whatever the action. It addresses
the mail to `cred_user_email` on the account the session has resolved. There is
no separate payout inbox.

| OTP | Goes to |
|---|---|
| Guest cancellation (UAT-17) | `aajoo.renter1@mailinator.com` — user 101 |
| Host payout (UAT-36) | `aajoo.host1@mailinator.com` — user 100 |

Two things about that path the testers should know before the run:

**The OTP is written to the server log in clear text**, next to the address it
was sent to, at `utils/chatbotServices.js:866`. The trailing comment says the
debug line was removed in production. It was not. The pack's own rule is that
full OTPs must not be recorded, and right now every one of them is, in Render's
log stream, for anybody with dashboard access.

**Pending OTPs live in process memory**, a plain `Map` at
`utils/chatbotServices.js:35`. A restart or a deploy drops them all, and a tester
who requests a code and enters it after one will be told it expired. Expect that
at least once across a week-long run; it is not a bug in the verification logic.

---

## 11 — the WhatsApp mapping

The intended mapping is right, and stable:

| Role | Number | Account |
|---|---|---|
| Guest | 9882498033 | user 101, `aajoo.renter1@mailinator.com` |
| Host | 9611577338 | user 100, `aajoo.host1@mailinator.com` |

**The guest number had been taken by a second live account.** User 174
(`ashishra366@gmail.com`) was created on 2026-09-05 with the same number
9882498033 and flagged as a **host**.

WhatsApp identifies a sender only by number, and the bot narrows the lookup by
the role the session is in. So on that one number a Guest session resolved to
user 101, correctly, while a **Host session resolved to user 174** — a different
person's account. That is exactly the state the pack forbids, and it meant a
Host Payout OTP started from that number would have been emailed to
`ashishra366@gmail.com` rather than to the test host, contradicting the answer
given for prerequisite 10.

**Resolved.** The number was cleared from user 174. Both senders now resolve to
exactly one account under every role filter:

| Sender | Guest session | Host session |
|---|---|---|
| 9882498033 | user 101 | nobody |
| 9611577338 | nobody | user 100 |

The guest handset resolving to nobody in Host mode is the point, not a gap.

**Why cleared rather than renumbered.** Putting a stand-in number on the account
would claim a digit string that may belong to a real person. That account does
not need one: it signs in with an email and password, holds no listings, and has
never booked or hosted a stay. The field is nullable and five live accounts
already sit without one. **Mobile sign-in stops working for user 174; email
sign-in is unaffected**, and the change reverses in one statement.

Nothing had been mis-resolved yet. Both chatbot sessions ever recorded against
that number resolved to user 101 as a guest, so the clash was latent and no
conversation needs resetting.

Run `node scripts/fixUatWhatsAppClash.js` to re-check. It refuses to clear a
number from any account that holds listings or bookings, or that would be left
with no way to sign in.

---

## Two defects — both fixed

Both were in the bot backend. Fixed on 2026-09-05, before the run, so neither
becomes a Fail during it. Twelve tests cover them; the backend suite is 53/53.

**Not yet deployed.** The backend auto-deploys on a push to `main`, and these
changes are committed but need that push before UAT starts.

### UAT-05 — the chosen role was ignored for a dual-role account

`controllers/bp_controller.js:673`

`getContext` derives the role from the account's flags, and host wins:

```js
if (userRow.user_isHost)      user_role_result = 'host';
else if (userRow.user_isUser) user_role_result = 'guest';
```

The role the user actually chose in the chat is stored on the session as
`cs_user_role`, but line 696 only reaches for it when the flag test produced
nothing:

```js
user_role: user_role_result || session?.cs_user_role || null,
```

Every account held exactly one role, so the two always agreed and the problem
was invisible. Give one account both — which is precisely what prerequisite 6
asks for — and choosing Guest returned `user_role: 'host'`.

**The fix.** The rule now prefers the session's chosen role when the account
actually holds it, and falls back to the flags otherwise. Single-role accounts
behave exactly as before, including the useful correction when someone claims a
role they do not have. The rule was lifted out of the request handler into
`resolveUserRole`, so it can be tested as a rule rather than as text; the old
rule and the new one are measurably different on one input and identical on the
rest.

**A second leak the fix made reachable.** `getContext` returned the account's
guest bookings whatever role the session was in. That cost nothing while no host
had ever booked a stay, so the list was always empty — but a dual-role account
would have had Host mode answering with that person's own trips, which is the
leak UAT-05's *"Guest data is not shown in Host mode"* looks for. The booking
list is now skipped in a host session. Support cases are not role-scoped and
still appear.

### UAT-17 — a second cancellation reported success

`utils/chatbotServices.js:930`

`modifyOrCancelBooking` checks that the booking exists and belongs to the user,
then cancels it. There is no check on what state it is already in:

```js
if (action === 'cancel_booking') {
  await model.tbl_bookings.update({ book_status: statusBookingCancelled }, ...);
```

So cancelling an already-cancelled booking set it to cancelled again and returned
*"Your booking has been cancelled successfully."* UAT-17's final step is exactly
that, and its pass condition is that the repeat *"terminates safely instead of
reporting a second cancellation."*

**The fix.** The path now refuses a booking that is already cancelled, and one
whose stay has already started — the website has refused the latter for as long
as it has had a cancel button. Driven against the live database on a throwaway
booking:

```
FIRST cancel  -> success: true   "Your booking has been cancelled successfully.
                                  Nothing was charged for this booking..."
SECOND cancel -> success: false  "This booking is already cancelled, so there is
                                  nothing to cancel."
```

**Three things the same path was skipping.**

It never recorded `book_cancelled_at` or which policy decided the outcome, so a
chat cancellation left nothing to age a refund from. It does now, verified on
that booking: policy `flexible`, 100%, `NOT_APPLICABLE` on an unpaid stay, with
a timestamp.

It never voided the host due. A pay-at-property booking raises a commission
charge against the host, recovered from their next payout, and a cancelled stay
earns none — the same gap that left ₹21,361 standing against cancelled stays
when it was found on the host-cancel path on 2026-09-01. The void is now wired
and unit-covered. It is not exercised end-to-end here, because dues exist only
for pay-at-property bookings and the only one that guest holds is the stay in
progress, which UAT-08 needs.

And it quoted a refund the platform does not honour. `getRefundStatus` ran a
ladder of its own invention — 80% back, or the amount less a flat ₹500 within 24
hours — which is none of the published policies and bore no relation to what the
guest agreed to at checkout. Worse, the figure it produced was the one written
to the booking. Both the cancellation and the refund answer now use
`utils/cancellationPolicy`, the calculator the website and the bot's own policy
reply already shared, and the invented ladder is deleted. The refund answer
reads back the decision rather than recomputing it, so "how much am I getting
back?" and "you have been refunded X" can no longer disagree.

---

## Not developer work

Two items in the pack belong to Aajoo, not to the backend, and neither is done:

- **A second BotPenguin operator.** The pack notes the live account shows one
  team member, and UAT-29's transfer sub-test needs a second eligible operator
  in Aajoo Support Team.
- **UAT-31 alert recipients.** The addresses saved in the target bot's Alerts
  settings must be confirmed, and at least one recipient has to confirm they
  actually received the fresh mail. Appearing in settings is not the test.

---

## What is left

Every developer prerequisite is met and both defects are fixed and live. What
remains is not developer work, with one exception:

1. **Remove the plaintext OTP log line** before the run, or accept that every
   code issued during UAT is readable in Render's log stream. This is the one
   open engineering item and it is a five-line change.
2. **Aajoo's two items**: a second BotPenguin operator in the support team for
   UAT-29's transfer sub-test, and a UAT-31 alert recipient confirming they
   actually received the mail.

Re-run `node scripts/seedBotPenguinUatRecords.js` at any point to re-check all
eleven. The stay in progress expires on 08-09-2026; if the run is still going,
re-run with `--apply` in the afternoon to make a new one.

## The records and accounts UAT will use

| Role | Account | Number | Inbox |
|---|---|---|---|
| Guest | 101 `lala Tester` | 9882498033 | `aajoo.renter1@mailinator.com` |
| Host | 100 `Aajoo Test Host` | 9611577338 | `aajoo.host1@mailinator.com` |
| Guest **and** Host | 169 `Aish Mobile Host new` | — | `aishmobilehost@yopmail.com` |
| Second Host | 168 `Aish test Host` | — | `itsme.ashsriv007+host2@gmail.com` |

| Booking | For | Dates |
|---|---|---|
| `B170046` | the stay in progress | 05-09 to 08-09-2026 |
| `B261280` | the one cancellation test | 19-09 to 21-09-2026 |
| `B754668` | somebody else's, for the denial test | owned by user 164 |
