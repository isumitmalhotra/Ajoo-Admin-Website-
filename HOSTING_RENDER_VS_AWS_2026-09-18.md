# Hosting Aajoo Homes on Render — is it the right call, and what plan?

## 1. The question, and the short answer

AWS activation is still blocked on the account's payment card, and the question on the table is: **should Aajoo Homes run on Render with a paid ("Pro") subscription instead?**

**Yes — Render is a sound production home for the next 6–12 months, and it can be set up in two to three working days.** But two corrections to the framing matter, because they change what you would be paying for:

1. **"Pro" is not the lever.** On Render, the *workspace plan* (Hobby / Pro / Scale) governs team seats, previews and governance. It does nothing for speed. What makes the platform feel slow today is the *compute instance* the API runs on, the *region* it runs in, and where the *database* sits — three separate settings, each cheap to fix.
2. **Render has no India region and no managed MySQL.** Both are workable (Singapore is 60–90 ms from India; the database stays on a MySQL provider next door), but they must be decided, not discovered.

The recommended setup costs **about $80–95 a month (₹7,000–8,500)** all in — the same money as the AWS launch estimate ($65–95), with no server administration.

## 2. What runs where today — measured on 18 September

| Component | Where | State |
|---|---|---|
| Website `www.aajoohomes.com` | Vercel (global CDN, edge SEO renderer) | Fine — stays |
| API `aajaodev.onrender.com` | Render, **Free instance** (0.1 CPU, 512 MB), Render's default region — Oregon, USA (inferred from response times; the dashboard will confirm) | Sleeps after 15 min idle: **30–50 s cold starts**, hidden by a keep-alive ping. **Disk wiped on every deploy — invoices are written to it.** |
| Database (MySQL, 43 MB) | Clever Cloud, **Paris** | The **only copy**; backup schedule not yet confirmed |
| Images, documents | Cloudinary | Fine — stays |

Every request from a guest in India therefore travels **Delhi → Oregon → Paris → back**. Measured from Delhi today: the API's health check answers in **~470 ms**. After the changes below it should answer in **120–200 ms**, and nothing will sleep.

> Nothing here is a Render limitation. It is the free tier, the default region and a database chosen before the platform had users in India.

## 3. What Render actually sells (prices read from render.com/pricing on 18 September 2026 — verify before signing)

**Workspace plans** (a flat monthly fee, per workspace):

| Plan | Price | What it adds |
|---|---|---|
| Hobby | $0 | One team seat, single-service previews, 7-day logs, 5 GB bandwidth then $0.15/GB, 500 build minutes |
| **Pro** | **$25/mo** | Multiple team members, full-stack preview environments, horizontal autoscaling, enforced 2FA, more build minutes |
| Scale | $499/mo | SSO/SAML, audit logs, governance — not needed |
| Enterprise | custom | Support SLAs — not needed |

**Compute** (per service, billed by the second, on top of the workspace plan):

| Instance | Price | Fit for the Aajoo API |
|---|---|---|
| Free | $0 | Sleeps, 0.1 CPU, no disk — **where it is now** |
| 0.5 CPU / 512 MB | $7/mo | Removes the sleep; tight for Node + Socket.io + Sequelize |
| **1 CPU / 2 GB** | **$25/mo** | **The honest production size at launch** |
| 2 CPU / 4 GB | $85/mo | When the metrics ask for it, not before |

Other lines you may see: Render Postgres from $6 (we do not use Postgres), Key Value/Redis from $10 (needed only when the API runs on two or more instances), persistent disks at $0.25/GB, custom domains (two included).

Note the naming: in Render's older dashboard the **2 CPU / 4 GB instance was itself called "Pro"**. If "Render Pro" meant that instance, it is $85 a month and more than the platform needs today.

## 4. The recommended setup on Render

| Item | Choice | $/mo |
|---|---|---|
| API compute | **1 CPU / 2 GB**, a new service created in **Singapore** (a region cannot be changed on an existing service) | 25 |
| Database | Render cannot host MySQL. Two good options, both a 30-minute freeze for a 43 MB database: **(a)** the same Clever Cloud plan in their **Singapore** zone, or **(b) DigitalOcean Managed MySQL, Bangalore** — an India region with automated daily backups. **Not** a conversion to Postgres: 24+ tables and raw SQL to rework for no reward | 10–15 |
| Invoices | Stop writing them to the ephemeral disk. A 1 GB persistent disk ($0.25) immediately; object storage (Cloudflare R2 / DigitalOcean Spaces) properly, because a disk blocks zero-downtime deploys and autoscaling | ~1 |
| Workspace | **Pro ($25)**, for one reason that matters: **Hobby has a single seat.** The company, the development team and a future operator cannot share one login. Previews and autoscaling are a bonus | 25 |
| Website | Stays on Vercel. It should be on **Vercel Pro ($20)** — the free Hobby plan is not licensed for commercial sites | 20 |
| Redis, cron | Not needed at one instance | 0 |
| **Total** | | **≈ $80–95 (₹7,000–8,500)** |

Bandwidth is metered beyond the included allowance ($0.15/GB); the API serves JSON and the images live on Cloudinary, so expect a few gigabytes a month, not hundreds.

## 5. What Render cannot give — and whether it matters

| Limitation | Effect | Verdict |
|---|---|---|
| No India region (Oregon, Ohio, Virginia, Frankfurt, Singapore only) | Singapore is 60–90 ms from Mumbai; AWS Mumbai would be ~30 ms | Not noticeable to a person on a phone. Today's 470 ms is the problem, not 70 |
| No managed MySQL | Database lives with Clever Cloud or DigitalOcean, next door to Singapore | Fine; it is separate today already |
| Region is fixed per service | Moving means a **new service with a new `*.onrender.com` hostname** | This is why §6 comes first |
| Bills in USD via Stripe, with a **$1 card check** | The same Indian card that cannot clear AWS's ₹2 authorisation (international transactions / e-mandates disabled) will likely fail here too | **Fix the card before any paid plan** — see §9 |
| Data residency | Platform data would sit in Singapore | DPDP does not require localisation for this data; card data never touches our servers (Razorpay holds it) |

## 6. Two things to do whatever the hosting decision

1. **Give the API its own domain now: `api.aajoohomes.com`.** Every installed Android build has `aajaodev.onrender.com` compiled in. A new Render service in Singapore gets a *different* hostname, so that move — and every future one — breaks every tester's app unless the app points at a domain the company owns. The record already exists (it currently points at Vercel and answers 404); it needs to point at Render. Custom domains are free on Render. The next app build (103) is then made against `api.aajoohomes.com`, and the hosting provider stops being wired into phones.
2. **Confirm the database backups.** The Clever Cloud database is the only copy of every listing, booking and payment. Its backup schedule and retention must be read off the dashboard before anything else is touched, and whichever provider ends up holding it must take automated daily backups.

## 7. Render or AWS — the honest comparison

| | Render (recommended now) | AWS (plan written, blocked) |
|---|---|---|
| Region | Singapore, ~70 ms to India | Mumbai, ~30 ms |
| Who operates it | Nobody — deploy on push, managed runtime, dashboard | Needs an operator: Terraform, ECS, RDS, alarms, patching |
| Time to production | 2–3 working days | Unknown — blocked on card verification; then 1–2 weeks |
| Launch cost | ≈ $80–95/mo incl. database and website | ≈ $65–95/mo (our estimate) — plus someone's time |
| Growth (~50k monthly users) | ≈ $150–250/mo (bigger instance, second instance + Redis) | ≈ $190–325/mo |
| Database | MySQL with a second vendor | RDS MySQL, one bill |
| What is already built | The API is on Render today; the deploy pipeline works | Days 1–5 of the migration plan are written and committed (Terraform, workflows, cutover runbook) — it keeps |

**Recommendation:** go to Render now, as in §4. Keep the AWS work in the drawer; revisit it at roughly 50,000 monthly users, or if "data in India" becomes a company policy rather than a preference. For a pre-launch company without a DevOps person, a platform that needs nobody is the right platform.

## 8. The migration, day by day

Effort: about **2–3 working days** of development time; **one 30-minute freeze** for the database move; **no change** to Vercel, Cloudinary, Firebase, Google Maps or the BotPenguin bot beyond a URL.

**Day 1 — build the new home beside the old one (no user impact)**
- Create the database in the new region (Clever Cloud Singapore or DigitalOcean Bangalore); restore a dump; verify row counts table by table.
- Create the Render service in Singapore from the same repository and Dockerfile; copy every environment variable exactly (the field-encryption key in particular is copied, never regenerated); attach the disk; set the health check.
- Attach `api.aajoohomes.com` (DNS at Vercel: change the record from Vercel to Render) and test the full flow against the new service while the old one keeps serving.

**Day 2 — switch (the 30-minute freeze)**
- Final database dump and restore; point the **old** Oregon service at the **new** database, so every installed app keeps working on the same data (no split-brain).
- Point the website at `api.aajoohomes.com` (one Vercel setting, one redeploy).
- Update the Razorpay webhook URL and the BotPenguin webhook URL to the new host. Nothing else references the API hostname.

**Day 3 — apps, then decommission**
- Build 103 against `api.aajoohomes.com`; testers install it.
- Watch the old service's logs. When it has served no requests for 48 hours, delete it. Delete the Paris database only after the new one's first automated backup has been verified restorable.

## 9. What only the company can do

| # | Action | Why |
|---|---|---|
| 1 | **Fix the card** — enable international transactions and recurring/e-mandate on it, or use a different card | Render's $1 USD check and AWS's ₹2 check fail for the same reason |
| 2 | **Own the Render workspace** (create it on the company's email, upgrade to Pro, invite the development team as members) | Billing and control must sit with the company, not with a developer's login |
| 3 | Own the database account (Clever Cloud or DigitalOcean) the same way | Same reason — it holds the only copy of the data |
| 4 | Confirm the Vercel plan is Pro | Commercial use |
| 5 | Approve `api.aajoohomes.com` as the permanent API address, and build 103 against it | §6 |

## 10. Decisions needed to start

1. **Render now, AWS later?** — recommended: yes.
2. **Database home:** Clever Cloud Singapore (least change) or DigitalOcean Bangalore (India region, backups included) — recommended: **DigitalOcean Bangalore**, because the backups are the point.
3. **Workspace plan:** Pro ($25) for the seats, or Hobby ($0) if one login is acceptable for now — recommended: **Pro**.
4. **Who owns the accounts and pays** — recommended: the company, with the development team as members.

With those four answers and a working card, the platform is on its new footing within the week.

---

*Prices are Render's published list prices as read on 18 September 2026 and DigitalOcean's/Vercel's as of the same date; verify each on the provider's own page before purchasing. Rupee figures assume ₹84–90 per US dollar.*
