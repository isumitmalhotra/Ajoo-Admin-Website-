# Aajoo Homes — the cutover

**Day 5 of `AWS_MIGRATION_PLAN_2026-09-11.md`.** Days 1–4 built a second
platform beside the live one. This day makes it the live one.

---

## What makes this day different

Everything built on Days 1–4 can be undone by deleting a resource. Nothing that
happened is irreversible, nothing that happened is visible to a guest, and
every mistake so far has cost time rather than data.

This day moves the database, and a database only moves one way.

---

## The rollback window is not seven days

The migration plan says **"Rollback is DNS. Render, Vercel and Clever Cloud
stay alive and paid for the full seven days."** That is true about the *stack*
and it is not true about the *data*, and the difference is the whole reason
this document has gates in it.

The moment the new platform accepts one write — one booking, one message, one
review, one password change — the two databases have diverged. Rolling DNS back
to Render then means going back to the old database **as it was at the freeze**,
and everything created on AWS since is either lost or has to be replayed by
hand against a schema that has moved on.

So there are two windows, not one:

| | Ends when | Cost of rolling back |
|---|---|---|
| **The free window** | the first write lands on AWS | nothing. DNS back, carry on. |
| **The seven-day watch** | seven days later | a reconciliation, by hand, of every row written since |

Which means the go/no-go decision happens **inside the freeze, before users are
let in** — not after a day of watching. Everything in Phase 3 before step 9 is
free to abandon. Everything after it is not.

---

## Facts this runbook is built on

Checked 2026-09-13, not assumed:

- **DNS is hosted at Vercel.** `aajoohomes.com` answers from `ns1.vercel-dns.com`
  / `ns2.vercel-dns.com`. The domain's DNS is controlled by one of the two
  vendors being migrated away from, which makes "decommission Vercel" a task
  with a hidden prerequisite. See Phase 5.
- **The zone's default TTL is already 600 seconds**, not an hour. Lowering it
  further is still worth doing, but the starting position is better than the
  plan assumed.
- **`api.aajoohomes.com` already exists and points at Vercel**, which answers
  `404 DEPLOYMENT_NOT_FOUND`. This record is *changed*, not created. Until it is
  changed, an APK built against it passes the app's own configuration check —
  which only asks for a well-formed `https://` URL — installs, opens, and fails
  every call.
- **Mail is not affected.** The API sends through the Brevo HTTP API on port
  443, not SMTP from its own IP, so the sending infrastructure does not change
  when the host does. MX stays on `secureserver.net`. Nothing in the cutover
  touches mail delivery. *(Separate, pre-existing, not a cutover item: SPF is
  `v=spf1 include:secureserver.net -all` and does not include Brevo.)*
- **The website's origin does not change.** It is `www.aajoohomes.com` before
  and after, so the Google Maps key referrer restrictions, the Firebase
  authorised domains and the API's `ALLOWED_ORIGINS` all keep working untouched.
  This is worth knowing precisely because it looks like it should need changing.
- **The database is ~43 MB.** The copy itself is seconds. The window is sized by
  the checks around it, not by the data.

---

## The trap that is not on the plan: installed APKs

`lib/data/ApiConstants.dart` compiles the API host into the binary through
`--dart-define=API_BASE_URL`. A release build has no fallback at all — the
constant folds to an empty string and the app refuses to start without the
flag. So **every APK already on a tester's phone has a hostname baked into it**,
and that hostname is `aajaodev.onrender.com`.

Decommissioning Render breaks all of them. Not degrades — every call fails.

Two things follow, and neither is a date:

1. A build pointed at the new host has to be distributed **before** Render
   stops answering, and testers have to actually install it.
2. Until then Render's hostname must keep answering. Running it as a 308
   redirect to `api.aajoohomes.com` covers the REST calls — Dio follows 308 and
   preserves the method and body — but **not Socket.io**, which does not follow
   redirects. Live chat and notifications go quiet on old builds. That is
   acceptable for a short tail and has to be said out loud rather than
   discovered.

The exit criterion for switching Render off is therefore **"no requests on the
Render hostname for 48 hours"**, read off Render's own logs. That is
measurable. "Seven days" is not.

---

## Phase 0 — T-7 days: everything that does not need a window

Nothing here is visible to a guest and nothing here is irreversible.

1. **The account is activated.** Everything below is blocked until it is — see
   `AWS_ACCESS_AND_ACTIVATION_2026-09-13.md`.
2. `terraform apply` the platform. Read the plan before confirming: the first
   apply creates a billable, durable database.
3. Add the ACM validation records from `terraform output acm_validation_records`
   and `cdn_acm_validation_records` to Vercel DNS. **The us-east-1 certificate
   for CloudFront is a separate certificate with separate records.** Wait for
   both to reach ISSUED; nothing serves HTTPS until they do.
4. `infra/scripts/put-parameters.sh .env.aws prod` — the secrets Terraform
   deliberately did not invent. Then confirm with `/health/env` that `missing`
   is empty. A placeholder counts as set; this is why Terraform does not write
   placeholders.
5. Bootstrap remote state — `infra/terraform/bootstrap`, then uncomment the
   backend in `versions.tf` and `terraform init -migrate-state`. Until this is
   done the platform's state is one file on one laptop.
6. Set the Actions variables and secrets in both repositories (see
   `infra/terraform/README.md` §Day 4), **including** `VITE_API_BASE_URL`. The
   website pipeline now refuses to build without it, on purpose: the fallback
   in `src/configs/apiConfigs.ts` points at Render, so an unset variable would
   ship a CloudFront site talking to the old database, and both halves would
   look healthy.
7. Confirm the SNS alarm subscription email. An unconfirmed topic delivers
   nothing.
8. **Soak staging.** `terraform workspace select staging`. Run the backend test
   suite, the live e2e checks, and `node scripts/seoAcceptance.mjs --origin
   https://<staging host>` against it. Socket.io through the ALB is exercised
   here, not on the day.
9. **Cut and distribute the new APK** against `https://api.aajoohomes.com` —
   but only after step 3 has made that host answer. Build through
   `tool/build_release.ps1`, which asks the endpoint whether it is alive before
   spending four minutes compiling against it.
10. Inventory the third-party dashboards and who can log into each (table below).

---

## Phase 1 — T-2 days: TTL

Lower every record being moved to **300 seconds**, in Vercel DNS:
`aajoohomes.com`, `www.aajoohomes.com`, `api.aajoohomes.com`.

Two days ahead, because lowering a TTL does not take effect until the *old* TTL
has expired everywhere. Lowering it an hour before the cutover means resolvers
are still holding the old value at the moment it matters.

Verify, do not assume:

```bash
dig +noall +answer www.aajoohomes.com @8.8.8.8
```

The TTL in the answer must be ≤300 and counting down.

---

## Phase 2 — T-1 day: the rehearsal

Run the real copy, against the real RDS, while the platform is still live.

```bash
cd infra/scripts && ./migrate-data.sh copy
```

```bash
cd infra/scripts && ./migrate-data.sh verify
```

The row counts **will** differ slightly — the source is still taking writes.
That is expected and it is not what the rehearsal is for. It proves:

- the source is reachable from inside the VPC and RDS is reachable from the task
- the `mysqldump` flags are right for this source's version
- `DEFINER` stripping works, so views and triggers actually restore
- the character set survives (the verify script checks this explicitly, because
  a database that silently arrives as `latin1` does not fail — it stores every
  Devanagari name as mojibake and nobody notices until a host cannot find their
  own listing)
- the whole thing takes the number of minutes you now know it takes

**Stop here if anything fails.** A rehearsal that fails on T-1 costs a day. The
same failure inside the freeze costs an outage.

---

## Phase 3 — the window

Pick the lowest-traffic hour. IST 03:00–05:00.

There is no maintenance mode in this platform, so a write freeze means the API
stops. The site stays up and every call fails. That is the cost of the window
and it is why it is short.

| # | Step | Reversible? |
|---|---|---|
| 1 | Announce the window. | — |
| 2 | **Freeze**: suspend the Render service. Writes stop. | yes |
| 3 | Confirm nothing is writing — Render logs quiet, and `SHOW PROCESSLIST` on the source shows no application session. | yes |
| 4 | `./migrate-data.sh copy` | yes |
| 5 | `./migrate-data.sh verify` — **must exit 0.** Any mismatch: stop, unfreeze, go home. | yes |
| 6 | Force a new API deployment so it starts against RDS, and wait for the service to stabilise. | yes |
| 7 | `/health/env` through the ALB — `missing` must be `[]`. | yes |
| 8 | **Smoke the new stack by ALB hostname, before DNS**: log in, open a listing, run a search, open a booking, send a chat message. | yes |
| 9 | **GO / NO-GO.** After this point a rollback costs data. | — |
| 10 | Move DNS (table below). | yes, at TTL |
| 11 | Watch resolution flip: `dig www.aajoohomes.com @8.8.8.8` until it answers CloudFront. | — |
| 12 | **Unfreeze**: the new stack is already serving. Leave Render suspended — it must not accept another write, ever. | — |
| 13 | Re-point the webhooks (table below). Each provider has a "send test" button; use it. | yes |
| 14 | Run `npm test` in the API repo, the live e2e checks, and `node scripts/seoAcceptance.mjs --origin https://www.aajoohomes.com`. | — |
| 15 | Delete the migration parameters, set `enable_data_migration = false`, apply. | — |

Step 12 is the one people get wrong. Render must stay **off**, not "off for
now" — a Render service that comes back up starts writing to the old database
again, and every row it writes is a row the platform will never see.

Step 15 in full:

```bash
aws ssm delete-parameters --names /aajoo/prod/migration/SOURCE_HOST /aajoo/prod/migration/SOURCE_PORT /aajoo/prod/migration/SOURCE_USER /aajoo/prod/migration/SOURCE_PASSWORD /aajoo/prod/migration/SOURCE_DB
```

---

## DNS: before and after

All in Vercel DNS. The `api` record is a change, not an addition.

| Record | Today | After | Type |
|---|---|---|---|
| `aajoohomes.com` | A → 64.29.17.65 (Vercel) | CloudFront | ALIAS |
| `www.aajoohomes.com` | Vercel | CloudFront | CNAME |
| `api.aajoohomes.com` | Vercel (404) | the ALB | CNAME |
| MX, SPF, `brevo-code`, `D8935362` | unchanged | unchanged | — |

The apex cannot be a CNAME. Vercel DNS supports ALIAS, so it does not need to
move for this — but see Phase 5.

---

## Third parties to re-point

| What | Where | New value |
|---|---|---|
| Razorpay webhook | Razorpay dashboard | `https://api.aajoohomes.com/…` |
| RazorpayX webhook | Razorpay dashboard | `https://api.aajoohomes.com/webhooks/razorpayx` |
| DIDIT webhook | DIDIT dashboard | `https://api.aajoohomes.com/webhooks/didit` |
| BotPenguin | BotPenguin dashboard | `https://api.aajoohomes.com/bp/handoff` |

A webhook that still points at Render reaches a suspended service. Razorpay
retries, so a missed payment webhook is recoverable — but only until the
retries run out, and a payment that never reconciles is the kind of thing found
by a guest, not by us. This is the step to do immediately after DNS, not at the
end of the day.

**Not on this list, and deliberately:** Google Maps, Firebase, Cloudinary and
`ALLOWED_ORIGINS` all key on `www.aajoohomes.com`, which does not change.

---

## Phase 4 — the watch

Seven days. Render, Vercel and Clever Cloud stay paid.

- The alarms from `alarms.tf` are the watch. `api-no-running-tasks` is the one
  that means "the platform is down".
- Check Render's request logs daily for traffic on `aajaodev.onrender.com` —
  that is the installed-APK tail, and it is the number that decides Phase 5.
- Check the RDS free-storage and connection alarms have not fired. A connection
  count that climbs rather than plateaus is a pool that is not releasing.
- Spot-check that bookings, payouts and notifications are landing.

---

## Phase 5 — decommission, on criteria rather than dates

Switch things off in this order, and only when each condition is true:

1. **Render** — when its logs show no requests for 48 hours. Until then it runs
   as a 308 redirect to `api.aajoohomes.com`.
2. **Clever Cloud** — not before a final dump has been taken and stored
   somewhere durable. It is the only copy of the business as it was before the
   move, and it is the thing a rollback would have needed.
3. **Vercel** — **not until DNS has moved off `*.vercel-dns.com`.** The domain
   answers from Vercel's nameservers, so cancelling the account before moving
   the zone takes the whole domain down: website, API and mail, because the MX
   records live there too.

Moving DNS to Route 53 is its own change with its own checklist, and it is the
prerequisite nobody writes down. Do it as a separate piece of work after the
platform is proven — every record copied first, verified against the live zone,
and only then the nameservers changed at the registrar.

---

## Rollback, by how far you have got

| You are at | Rollback | Cost |
|---|---|---|
| before step 9 | unfreeze Render. Nothing moved. | the window |
| after DNS, before the first write | DNS back, unfreeze Render. | the window |
| after the first write | DNS back, Render back, and reconcile by hand every row written on AWS. | hours, and possibly a guest-visible loss |
| the schema has moved | there is no rollback. Fix forward. | — |

The third row is why step 8 exists, and why the smoke test happens against the
ALB before DNS rather than against the domain afterwards.
