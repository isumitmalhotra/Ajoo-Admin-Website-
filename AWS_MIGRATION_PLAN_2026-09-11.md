# Aajoo Homes — moving the platform to AWS

**Prepared** 11 September 2026 · **Supersedes nothing** — this is the execution plan for the
AWS option described in `Deployment_Options_2026-09-05.docx` §3 and §6.

> **Why now.** The client has an AWS account with an IAM user created, and the
> platform is deliberately still on Razorpay **test** keys. That combination is the
> right window: move hosting while money is still fake, so a hosting cutover and a
> payments cutover never land in the same week. Live keys go in afterwards, as an
> environment-variable change measured in minutes.

---

## 1. What we are moving

| Component | Today | On AWS |
|---|---|---|
| Website (React/Vite SPA + SEO renderer) | Vercel, auto-deploy on push | ECS Fargate container behind CloudFront |
| API (Node 20, Express, Sequelize, Socket.io) | Render **free tier**, single instance | ECS Fargate service behind an Application Load Balancer |
| Database (MySQL 8, 43 MB, 120 tables) | Clever Cloud | RDS MySQL 8, Mumbai (`ap-south-1`) |
| Images and documents | Cloudinary | **Unchanged** — stays on Cloudinary |
| Invoices | Written to container disk, emailed | **Unchanged** — see §2 |
| CI/CD | Push to `main` | GitHub Actions → ECR → ECS, via OIDC |

Everything else — Razorpay, RazorpayX, DIDIT, BotPenguin, Brevo, Firebase, Google
Maps/Places — keeps working. They only need their webhook URLs re-pointed once the
API has its new hostname.

---

## 2. What is already done (and what it saves)

This migration is materially cheaper than the September estimate because four of
the hard parts already exist in the repositories.

**Both repos ship production Dockerfiles.** The backend image runs as non-root
under `tini`, exposes 8080, and carries a `HEALTHCHECK` that hits `/health`
without touching the database — so a database blip restarts nothing. Its header
comment says it was built for the move off Render and names ECS and an ALB target
group. Nothing to write.

**The SEO renderer is already a container, not an edge function.** This was the
single biggest risk in the September comparison: Vercel's `api/seo-render.ts`
rewrites every HTML request to inject title, description, canonical and JSON-LD,
and serving `dist/` as plain static files would hand every crawler the shell's
hardcoded head. The frontend Dockerfile ships the SPA **and**
`scripts/seoRenderServe.mjs` as one image — the same server the SEO acceptance
tests run against. **No Lambda@Edge, no CloudFront Functions, no rewrite.**

**There is a formal environment contract.** `config/requiredEnv.js` lists 9
REQUIRED variables and the optional ones, and `presence()` reports which names are
set *without ever exposing a value*. It exists because moving secrets to
environment variables was attempted once before and took production down — the
code was switched to read `process.env` while the host had never had the variables
set. `/health/env` is how we prove the new environment is populated **before**
traffic depends on it.

**The test suites are the acceptance gate.** 107 backend test files and 289 app
tests, plus `scripts/seoAcceptance.mjs` for crawler responses and the live e2e
checks. These run against the new stack before DNS moves.

**One correction to the September document.** It lists "invoices are written to the
container's disk (wiped on deploy)" as a weakness requiring S3. It is not: the file
is written, attached to the confirmation email immediately, and never read again —
`downloadInvoice` **regenerates the PDF from the database** (invoice row, buyer,
booking, property). S3 for invoices is optional, not migration work.

---

## 3. Target architecture

```
                    Route 53 (or existing DNS)
                             │
                    ┌────────┴────────┐
                    │                 │
              CloudFront          ALB (HTTPS, ACM cert)
              (www.aajoohomes.com)  (api.aajoohomes.com)
                    │                 │
              ECS Fargate         ECS Fargate
              web container       api container
              SPA + SEO renderer  Node 20 + Socket.io
              (:8080)             (:8080)
                                      │
                                  RDS MySQL 8
                                  ap-south-1, private subnet
```

**Compute: ECS Fargate behind an ALB, not App Runner.** Two constraints decide this:

1. **Socket.io needs real WebSockets.** An ALB supports them and supports sticky
   sessions for the day there is more than one instance. App Runner's WebSocket
   support must be verified before it can be considered — if it is not there,
   negotiations degrade to long-polling.
2. **The API holds in-process state** — the rate limiter, the SEO cache, the
   scheduler and Socket.io all assume one process. So the API service runs at
   **exactly one task** (min 1, max 1) at launch. Redis is not needed until it
   scales past one, and that is a growth decision, not a launch one.

The ALB costs roughly $18–20/month. That is the price of the two constraints
above; it is not optional at this shape.

**Networking.** A VPC with public subnets for the ALB and private subnets for RDS.
To avoid a NAT gateway (~$32/month — the cost creep the September document warned
about), the Fargate tasks run in public subnets with public IPs and a security
group that allows inbound **only** from the ALB. RDS accepts connections only from
the tasks' security group.

**Secrets.** All 82 environment variables the backend reads go into SSM Parameter
Store (`SecureString`), injected into the task definition. None in the image, none
in git, none in chat.

---

## 4. Decisions needed from you

| # | Decision | Recommendation |
|---|---|---|
| 1 | **Region** | `ap-south-1` (Mumbai) — guests and hosts are in India |
| 2 | **API hostname** | `api.aajoohomes.com`. It currently resolves to Vercel and answers 404; it needs to point at the ALB |
| 3 | **DNS** | Move `aajoohomes.com` to Route 53, or keep the current registrar and add records. Cloudflare in front is optional but gives a 5-minute TTL for a clean cutover |
| 4 | **Who owns the console after handover** | Decides how much we automate now (Terraform) versus leave clickable |
| 5 | **Expected traffic in six months** | Decides RDS instance size. At today's volumes `db.t4g.micro` is ample |

---

## 5. Access — how to hand it over safely

**Please do not send AWS keys in chat, email or a message.** Two options, in order
of preference:

1. **GitHub OIDC (recommended).** GitHub Actions assumes a role in your account.
   No long-lived credentials exist anywhere — nothing to leak, nothing to rotate.
   We supply the trust policy; you create the role.
2. **IAM user access keys.** You place them directly into GitHub Actions secrets
   yourself. We never see the values.

The IAM user will need permissions for ECR, ECS, RDS, CloudFront, S3, ACM, SSM,
CloudWatch, ELB and IAM role creation. We can supply a scoped policy document.

---

## 6. The plan

Five working days: four to build, one to cut over, then a seven-day watch before
Render and Vercel are switched off.

### Day 1 — Foundations and the database

| Step | Owner | Time |
|---|---|---|
| Region, VPC, subnets, security groups; ECR repositories for both images | Us | ½ day |
| RDS MySQL 8 (`db.t4g.micro`, 20 GB gp3, 7-day automated backups, PITR on) | Us | ½ day |
| Dump and restore the 43 MB database; verify row counts against the source | Us | included |

The database moves in seconds at this size. This is a **copy**, not a cutover —
Clever Cloud keeps serving production throughout.

### Day 2 — The API

| Step | Owner | Time |
|---|---|---|
| All 82 environment variables into SSM; task definition; ECS service at one task | Us | ½ day |
| ALB, ACM certificate, target group, health check on `/health` | Us | ½ day |
| **Set `HEALTH_TOKEN`** and verify `/health/env` reports every REQUIRED variable present | Us | included |

`/health/env` is the gate: no traffic moves until it says the environment is
complete. This is the check that did not exist the last time secrets moved.

### Day 3 — The website and staging

| Step | Owner | Time |
|---|---|---|
| Build the web image **against the new API URL** — `VITE_*` are inlined at build time, so the image must be rebuilt, not reconfigured | Us | ½ day |
| CloudFront distribution, cache policy for the SPA, ACM certificate | Us | ¼ day |
| Run `scripts/seoAcceptance.mjs` against the new stack; verify crawler responses with a real user agent | Us | ¼ day |
| Staging as a second, half-size environment | Us | ½ day |

Staging is where every future UAT round and hosting change happens. It is the
thing the platform has never had.

### Day 4 — Pipelines and third parties

| Step | Owner | Time |
|---|---|---|
| GitHub Actions: build → ECR → ECS deploy, via OIDC | Us | ½ day |
| **Migrations as a deploy step** — they are run by hand today | Us | ¼ day |
| Re-point Razorpay, DIDIT and BotPenguin webhooks to the new API hostname | Us + your dashboards | ¼ day |
| Cut a new APK against the new API URL | Us | included |
| CloudWatch alarms; uptime and error monitoring | Us | ¼ day |

### Day 5 — Cutover

| Step | Owner | Time |
|---|---|---|
| Final database sync in a low-traffic window, verified dump-and-restore | Us | 1 hour |
| DNS switch (TTL lowered to 5 minutes the day before) | Us | minutes |
| Run the 107 backend test files, the live e2e checks and the SEO acceptance script against production | Us | 2 hours |
| Watch | Us | **7 days** |
| Decommission Render and Vercel | Us | after the watch |

**Rollback is DNS.** Render, Vercel and Clever Cloud stay alive and paid for the
full seven days. If anything is wrong, DNS goes back and the old stack is still
there with its data.

---

## 7. What changes in day-to-day work afterwards

- **Deploys** stay "push to `main`" — the pipeline changes, the habit does not.
- **Migrations run themselves** on deploy instead of being remembered.
- **There is a staging environment** that mirrors production at half size.
- **Cold starts disappear.** The keep-alive ping and its 30–50 second first
  request go away with the free tier.
- **Backups are automated**, with point-in-time recovery, on a database that is
  currently the only copy of the business.
- **Alarms exist.** We find out before a tester does.

---

## 8. Cost

| | Launch (today's volumes) | Growth (~50k monthly users) |
|---|---|---|
| ECS Fargate ×2 services | $25–35 | $60–90 |
| ALB | $18–20 | $20–25 |
| RDS MySQL | $15–25 | $80–150 |
| CloudFront + S3 + ECR + SSM | $5–15 | $30–60 |
| **Total** | **$65–95 / month** | **$190–325 / month** |

Slightly above the September estimate of $50–90 because the ALB is now explicit
rather than assumed away. Against today's Render + Vercel + Clever Cloud spend of
$35–60/month, the increase buys an India region, automated backups, staging,
no cold starts, and one bill instead of three.

**AWS Activate credits** can cover the first year. Worth applying before we
provision, not after.

---

## 9. Risks

| Risk | Likelihood | Handling |
|---|---|---|
| SEO renderer behaves differently behind CloudFront than on Vercel's edge | Low | `seoAcceptance.mjs` runs against the new stack on Day 3, before anything is pointed at it |
| A missed environment variable | Low | `/health/env` enumerates all 82 and reports what is absent, before cutover |
| Socket.io through the ALB | Low | ALB supports WebSockets natively; verified on staging on Day 3 |
| Webhook re-pointing missed for one provider | Medium | Each of the three is tested end to end on staging before DNS moves |
| Costs creep | Medium | No NAT gateway by design; billing alarm set on Day 1 |

---

## 10. What this plan does **not** include

- **Live Razorpay keys.** Deliberately out of scope — they go in after the move,
  as an environment change. RazorpayX (arriving in 2–3 days) is four more
  variables and needs no infrastructure.
- **Redis.** Not needed until the API runs on more than one instance.
- **S3 for invoices.** Not needed — see §2.
- **Terraform.** Optional; worth it only if nobody will own the console by hand.
  Decision 4 above settles it.
- **The six open defects** from the 11 September test run. Separate work, and two
  of them are guest-facing.

---

## 11. Summary

**Five working days of our work, then a seven-day watch.** Four of those days are
build; one is cutover. The database moves in seconds, the containers already
exist, the SEO renderer already runs as a container, and the environment contract
already knows how to prove the new home is correctly configured before anything
depends on it.

The one thing that must come from you before Day 1 is **access** — the OIDC role
or the GitHub secrets — plus the five decisions in §4.
