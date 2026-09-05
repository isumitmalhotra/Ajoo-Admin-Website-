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
| 4 | Guest with a stay in progress | **Gap** — nobody has one today |
| 5 | Host with listing, analytics and payout data | **Done** — user 100 |
| 6 | One account that is both Guest and Host | **Gap** — none exists |
| 7 | A booking owned by somebody else | **Done** — `B754668`, user 164 |
| 8 | A second Host, for the cross-host denial test | **Done** — users 168, 133, 135 |
| 9 | A disposable booking, cancellable once | **Usable, but spend a fresh one** |
| 10 | Which inbox receives which OTP | **Answered** |
| 11 | One WhatsApp sender per role, stable | **Gap** — the guest number is on two live accounts |

Items 3, 5, 7, 8 and 10 needed nothing. Four items need action and they are
described below.

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

Nobody on the platform has one today. Checked across every account, not just the
test guest: no non-cancelled booking has a check-in on or before today and a
check-out on or after it.

Worth correcting an earlier note in case it is still circulating: `BPTEST04` was
recorded as the ongoing stay. Its dates do span today, but its status is 2,
which is **Cancelled**, not Paid. Status 3 is Paid. `BPTEST01` and `BPTEST03`
are cancelled too, and `BPTEST02` is a Check In whose dates ended in July.

**To create one:** a three-night pay-at-property booking for user 101 starting
**yesterday**. The seeder does it through `POST /booking/create`, so the record
is the same shape as a real guest's — a booking is six tables plus a host-dues
entry and a snapshotted cancellation policy, and hand-written rows drift from
that.

Yesterday rather than today on purpose. The bot calls a stay ongoing only once
the check-in moment has passed, and that is 2 PM on the arrival day. A booking
made this morning for today would still read as *upcoming* until the afternoon,
and a tester running UAT-08 before then would log a Fail against working code.

Until it exists, **UAT-08 is Blocked - Client test data.**

---

## 6 — one account that is both Guest and Host

No account on the platform holds both roles. Every one is a host or a guest, and
never both.

The platform does support the idea. `POST /user/switch-mode` mints a token for
the other role, and it always allows the switch back to guest, on the stated
principle that every host is also a guest. What is missing is an account whose
role flags say so, because the guest-side lookups filter on `user_isUser = 1`.

**Recommendation: user 169** (`aishmobilehost@yopmail.com`). It has four
listings, three of them live, so Host mode has something real to show; its inbox
receives mail; and its number is not one of the two WhatsApp mappings. Setting
`user_isUser` and `cred_user_isUser` to 1 is the whole change, and it is
reversible in two statements the seeder prints.

Leave `cred_user_isHost` alone. Sign-in filters on it, so flipping it would break
host login for that account. The route into guest mode is switch-mode, which is
what UAT-05 describes anyway: sign in, then choose the role in the chat.

If 169 becomes the dual-role account, use **168 or 133** for prerequisite 8, so
UAT-05 and the cross-host denial test are not reading the same record.

> **This will not pass UAT-05 as the code stands.** See the defects below.

---

## 9 — a disposable booking

User 101 has five future non-cancelled bookings, the earliest `B811224` on
07-09-2026, so the case is not blocked.

Spend a fresh one anyway. All five are counted by prerequisite 3, and UAT-07
picks a *deterministic primary booking* from that same set — cancelling one
mid-run changes what UAT-07 should expect. The seeder creates a dedicated
pay-at-property booking a fortnight out, so nothing else is disturbed and no
refund has to be unwound.

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

**But the guest number is on two live accounts.** User 174 "Ashish Kumar"
(`ashishra366@gmail.com`) was created on 2026-09-05 at 01:50 with the same number
9882498033, and it is flagged as a **host**.

WhatsApp identifies a sender only by number, and the bot narrows the lookup by
the role the session is in. So on that one number:

- a Guest session resolves to user 101, which is correct;
- a **Host session resolves to user 174**, a different person's account.

That breaks two things. It is exactly the state the pack forbids — *"Do not map
the same WhatsApp sender as Guest and Host at the same time"* — and it means a
Host Payout OTP started from that number would be emailed to
`ashishra366@gmail.com` rather than the test host, which contradicts the answer
given for prerequisite 10.

The fix is to move user 174 off 9882498033. That is a decision about whose number
it is, so the seeder reports it and changes nothing. Until it is resolved,
**UAT-35 and UAT-36 are unsafe to run from that number.**

---

## Two defects that will fail their cases

Both are in the bot backend, both are small, and both are worth a decision
*before* the run rather than a Fail during it.

### UAT-05 will fail — the chosen role is ignored for a dual-role account

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

Today every account holds exactly one role, so the two always agree and the
problem is invisible. Give one account both — which is precisely what
prerequisite 6 asks for — and choosing Guest returns `user_role: 'host'`.

The fix is to prefer the session's chosen role when the account actually holds
it, and fall back to the flags otherwise. That keeps today's behaviour exactly
for single-role accounts, including the useful case where someone claims a role
they do not have.

Related, and worth knowing: `getContext` returns the guest's bookings regardless
of role. Role scoping is enforced per endpoint — host listings, analytics and
payout are separate calls — so UAT-05's *"Host data is not shown in Guest mode"*
is tested there, not here.

### UAT-17 will fail its last step — a second cancellation reports success

`utils/chatbotServices.js:930`

`modifyOrCancelBooking` checks that the booking exists and belongs to the user,
then cancels it. There is no check on what state it is already in:

```js
if (action === 'cancel_booking') {
  await model.tbl_bookings.update({ book_status: statusBookingCancelled }, ...);
```

So cancelling an already-cancelled booking sets it to cancelled again and returns
*"Your booking has been cancelled successfully."* UAT-17's final step is exactly
that, and its pass condition is that the repeat *"terminates safely instead of
reporting a second cancellation."*

The same path also skips what the website's cancellation does: it never records
`book_cancelled_at`, never snapshots the refund fields, and never voids the host
dues the booking raised. On a pay-at-property booking that leaves the host still
billed for a stay that is not happening — the same class of problem as the
host-cancel gap fixed on 2026-09-01.

Using a pay-at-property booking for UAT-16/17, as recommended above, keeps the
money side of that out of the run.

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

## What is left, in order

1. Move user 174 off 9882498033, or accept that UAT-35/36 cannot run from it.
2. Decide on the two defects above — fix before the run, or accept two known
   Fails and log them.
3. Run `node scripts/seedBotPenguinUatRecords.js --apply` from the backend repo
   to create the stay in progress, the disposable booking and the dual-role
   flags. It needs `UAT_GUEST_EMAIL` and `UAT_GUEST_PASSWORD` in the
   environment for the two bookings.
4. Re-run the audit with no flag and confirm every line reads `ok`.
