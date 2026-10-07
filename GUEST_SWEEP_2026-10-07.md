# Guest dashboard sweep — 2026-10-07 (live production)

Signed in as **R.Ashish Rahi** (user 13), who owns B871634: paid ₹3.15 on
04 Oct, host approval still outstanding, **check-in 07 Oct — today**.

Baseline from the live DB: 1 booking · 0 offers sent · 0 reviews ·
3 notifications (3 unread) · 0 support tickets.

16 guest screens driven. Every one rendered; the counts on Past Stays (0),
Saved Stays (0), Cancelled (0), Negotiations (0), Reviews (0), Messages (0),
Transactions (₹3.15) and Notifications (3 unread) all match the database, and
Profile shows this account's real details and its unfinished verification
correctly.

## GU1. Every guest surface said a paid, unapproved booking was "Confirmed" [DEFECT]

    dashboard card        "Confirmed"  ·  Paid  ·  ₹3.15
    Upcoming Stays        "Confirmed — you're all set for check-in."
    admin + host screens  "Awaiting approval"   (fixed earlier today)

`useBookings` and `useOngoing` feed every guest booking screen. Both called
`lifecycleLabel` with `ended` and `started` but **not** `paid`/`cod`, so the two
guards that separate an unpaid checkout from a paid-awaiting-approval booking
never ran. Both hooks read `b.book_is_paid` two lines below for the payment
badge, so the data was in hand the whole time.

The worst of it is the reassurance: a guest was told they were "all set for
check-in" for a stay beginning that day, on a booking no host had accepted.

**The correct copy already existed and was unreachable.** Upcoming Stays has a
branch for `b.status === "Awaiting approval"` that renders *"Waiting for the
host — they have a set time to answer; if they don't, your booking is confirmed
automatically."* It never fired because the status never said so.

**My earlier audit missed this.** It looked for callers passing NO options;
these pass some. Re-audited by parsing each call's full argument list — which
also turned up `host/HostDashboard.tsx`, where `relTag()` dropped the flag, so
a host's own dashboard called a paid request "Confirmed" on the one screen
where the approval is theirs to give.

## GU2. `getBookings` returned the Error object on failure            [DEFECT]

`models/tbl_bookings.js` ended `catch (error) { return error }`. All three
callers test `if (!booking)` to mean "no such booking", and an Error is truthy,
so a database failure was indistinguishable from a found row and the code read
`booking["book_host_id"]` off an Error (undefined) rather than stopping. One of
the three is the CANCELLATION path. Now propagates; all three callers already
sit in a try/catch that answers with an error.

## GU3. The guest was told the host confirmed a booking that is not confirmed [INVESTIGATE]

Notification #28, 05 Oct 01:31 IST: *"Your booking is confirmed — The host
confirmed your stay at Green Hills Kasauli. Booking B871634."*
`tbl_book_histories` has a matching row, `bh_status_id = 8`, title "booking
confirmed by host". Both come from the HOST path in host.controller.js, not the
auto-confirm service (whose wording differs).

**But `tbl_bookings.book_status` is still 1.** The handler updates the status
and inserts the history in ONE transaction, and the history committed — so the
status should be 8. The booking was written again at 20:19:42Z, 18 minutes
after the notification.

Ruled out: no admin status change in tbl_admin_audit; no code path writes
status back to 1; the auto-confirm service is not the author.

Not resolved, and not guessed at. It needs the Render logs for 2026-10-04
19:50–20:25Z. What is certain is the user-visible half: **the platform told a
guest their stay was confirmed, and every screen that reads book_status
disagrees** — including the host calendar and availability.

## GU4. The guest's refund is invisible to them                       [DATA, known]
Transactions reads: Total Spent ₹3.15 · Amount Paid ₹3.15 · **Refunds ₹0**,
and the one row shows "Paid". B871634 was refunded at the gateway on 05 Oct.
This is the guest-facing consequence of the un-replayed webhook — the guest's
own record of their money is wrong.

## Checked and cleared (not defects)
- Referral code "AJD" is correct by design: `"AJ" + base36(userId)`, user 13 → D.
  (Codes are therefore enumerable — already on the referral-farming risk list;
  the reward only credits on the referred user's first booking.)
- `tbl_book_history` "missing" was my own query error — Sequelize pluralises,
  the table is `tbl_book_histories`.
- Ongoing Stays empty with a forward-looking message, Explore rendering all 15
  categories, Support, Refer and Profile all correct.

---

# GU1 verified on screen, live

Render service header: **`d443869` — Live**. Driven as the same guest, on the
served build `index-C28YC9E_.js`.

**Upcoming Stays**

    before   Confirmed · Paid
             "Confirmed — you're all set for check-in."
    after    Awaiting approval · Paid
             "Waiting for the host — they have a set time to answer; if they
              don't, your booking is confirmed automatically. You'll be told
              either way."

**Account dashboard card**

    before   Green Hills Kasauli · 07 Oct — 09 Oct 2026 · Confirmed · Paid · ₹3.15
    after    Green Hills Kasauli · 07 Oct — 09 Oct 2026 · Awaiting approval · Paid · ₹3.15

The payment badge still reads "Paid", which is correct — the guest did pay. The
branch that produces the "Waiting for the host" wording had existed unused
since it was written; this is the first time it has rendered.

## A verification mistake worth recording

My first deploy watcher reported success before anything had shipped. I used
"Waiting for the host" as the signature — but that copy was ALREADY in the old
bundle, sitting in an unreachable branch, so it matched the build I was trying
to replace. The rule it broke is one already written down: grep the served
bundle for a string only the NEW commit can have.

The second attempt matched on the bundle hash my local build produced, which
also fails: Render builds independently and its hash differed
(`index-C28YC9E_.js` vs `index-xANhy8RJ.js`) despite identical source.

What actually settled it was the Render service header's Live commit, which is
the same thing that caught the earlier "Deployed 2min ago" timestamp dressed up
as a status. **For this project: the service header's Live SHA is the deploy
check; a copy string is only safe when the copy itself is new.**

## Not verifiable from here
`host/HostDashboard.tsx` was fixed in the same commit, but confirming it needs a
host sign-in. The guest and admin halves of the same defect are both confirmed.
