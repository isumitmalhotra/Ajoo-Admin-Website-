# The website's hosting: stay on Vercel, or move it to Render?

## 1. The question, and the short answer

The proposal on the table is to move `www.aajoohomes.com` off Vercel and onto
the Render service that already runs the API, so that everything sits with one
provider and the Vercel bill goes away.

**It is a sound move, and it should not be made this month.** Three findings
shape that answer, and the third one changes the question entirely:

1. **The move is a software port, not a hosting change.** The website is not a
   folder of files. A piece of server-side code rewrites every page's SEO
   information before the page loads, and Render's free static hosting cannot
   run that code. Moving means rebuilding that piece inside the API. Two to
   three working days, and it touches the one layer that Google, WhatsApp link
   previews and an App Store reviewer all depend on.

2. **It will not make the site faster.** It saves money and removes a vendor.
   Anyone presenting it as a speed improvement is mistaken — the honest
   expectation is "the same, with one part slightly better and one part
   slightly worse". Section 6 sets out both sides.

3. **The current Vercel plan does not permit this website to exist on it.**
   Vercel's free "Hobby" plan is for non-commercial personal use. Aajoo Homes
   matches **three** of the five examples Vercel gives for prohibited
   commercial use. This is not a future risk to manage; it is today's status,
   and the published remedy is that Vercel pauses the deployment.

**The recommendation** is therefore in two steps: put Vercel on a paid plan now
to end the licensing exposure, which takes minutes and no engineering, and do
the Render move in the quiet fortnight after go-live, then close the Vercel
subscription. The bridging cost is roughly **$40–60 (₹3,500–5,300) in total**.

---

## 2. What is live today — read from both dashboards on 27 September 2026

### On Vercel

| | |
|---|---|
| Account | `nameeshpatiyal100's projects`, **Hobby (free)** |
| Live project | `aajao-admin-web-s-iite-epy6` — serves `www.aajoohomes.com`; the bare `aajoohomes.com` redirects to it |
| Built from | `nameeshPatiyal100/Aajao-Admin-WebSIite`, connected 23 August 2025; every push to the main branch deploys automatically |
| Framework | Vite, with **no custom build settings at all** |
| Configuration | **Two environment variables**, both production-only: `VITE_API_BASE_URL` and `VITE_GOOGLE_MAPS_KEY` |
| Databases / file storage on Vercel | **None** |
| Third-party integrations | **One** — Entri Connect, a domain-setup helper |
| Certificates | Two, renewing automatically in late November 2026 |
| Also hosted here | **The domain's entire DNS zone — 17 records**, ten of which carry email |

Usage over the last thirty days, against the free plan's ceilings — nothing is
under any pressure:

| Meter | Used | Included |
|---|---|---|
| Function CPU time | 34m 42s | 4 hours |
| Function invocations | 10,000 | 1,000,000 |
| Edge requests | 38,000 | 1,000,000 |
| Data transfer | 2.57 GB | 100 GB |
| Build storage | 403 MB | 10 GB |

Two housekeeping items surfaced while reading this:

* A **second, abandoned Vercel project** (`aajao-frontend-vercel`) is still
  serving a build from 17 August. It has no code repository connected, no
  configuration, and no domain. It should be deleted.
* **Neither environment variable is set for preview builds.** Every pull-request
  preview is therefore built with no API address and no Maps key baked in, which
  means a preview link is not a valid way to check a fix. A five-minute change.

### On Render

| | |
|---|---|
| Workspace plan | **Pro**, billed to AAJOO HOMES PRIVATE LIMITED |
| Live API service | `aajoo-api-singapore` — Singapore region, **1 CPU / 2 GB, $25 per month** |
| Serving | `api.aajoohomes.com`, deploying automatically from `nameeshPatiyal100/aajaoBackend` |
| Load over the past 48 hours | **CPU close to 1%. Memory under 10%.** One instance. |
| Custom domains | **1 used of 15 included** |
| Bandwidth | **898 MB used of 25 GB included** |
| Charges this month | $9.93 to date, projected $16.15 for September — a part month, because the Singapore service is only days old |

**The Singapore machine is almost entirely idle**, and the plan already
includes fourteen unused custom domains and 24 GB of unused monthly bandwidth.
This is the single strongest fact in favour of the move: the capacity to serve
the website has already been bought and is sitting unused.

> **Two old services are still running in Oregon.** `aajaodev` and `aajooHomes`
> are both live, the second untouched for two years. They cost nothing — they
> are on free instances — but `aajaodev` still answers requests and still
> redeploys on every backend commit, which makes it a stale copy of the API
> that could be reached by mistake. These should be suspended. It is unrelated
> to the decision in this document and can be done this week.

---

## 3. The licensing problem, which is the real reason to act

Vercel's Hobby plan is free because it is not for businesses. Vercel's fair use
guidelines restrict Hobby accounts to non-commercial personal use, and define
commercial use as any deployment serving the financial gain of anyone involved
in any part of producing the project — explicitly including a paid consultant
writing the code.

Vercel lists five examples. **Aajoo Homes matches three of them:**

| Vercel's example | Aajoo Homes |
|---|---|
| Requesting or processing payment from visitors of the site | The Razorpay checkout |
| Advertising the sale of a product or service | Property listings and bookings |
| Receiving payment to create, update, or host the site | Zyphex Tech is engaged to build it |

There is no interpretation under which this is a personal project. The site is
not currently over any usage limit, so nothing has been flagged — but the
published remedy for a policy breach is that Vercel pauses the account or the
deployment, and a pause takes `www.aajoohomes.com` offline without notice.

**Reading this changed our recommendation.** Before it, the choice was between
$0 and a two-to-three-day migration, and waiting looked free. It is not free —
staying on Hobby is carrying an outage risk that has nothing to do with traffic
and cannot be planned around.

There is a second, quieter consequence. The Hobby plan has no team
collaboration, so the entire production website sits inside one personal
account with no second owner and no way to grant anyone defined access. A paid
plan fixes that as a side effect.

---

## 4. The four options

| | Cost | Engineering | Verdict |
|---|---|---|---|
| **A. Stay on Hobby** | $0 | none | **Not viable.** Prohibited use of the plan; the remedy is a pause |
| **B. Vercel Pro** | $20/mo ≈ ₹1,780 | none | Viable and instant. Also buys team seats, spend controls and a day of logs instead of an hour |
| **C. A second Render web service** | **$7/mo ≈ ₹620** | 2–3 days | **The destination.** Custom domains and bandwidth are already paid for on the workspace; only the instance is new |
| **D. Fold into the existing API service** | $0 extra | 2–3 days | **Not available in practice** — see below |

**Why D is not the free lunch it appears to be.** The API service is built
from a Dockerfile whose build context is the *backend* repository, and the
website lives in a different one. Sharing them means either a Git submodule or
a credentialed clone inside the Docker build — and from then on every website
change needs a backend commit to point at it. That couples two codebases that
have no reason to be coupled, and slows down the faster-moving one, to save $7
a month.

An earlier draft of this document recommended D at **$0 extra**. Building the
port established that it does not work cleanly, so the figure has been
corrected rather than left flattering.

**A further option does not exist at all, though it looks like it should.**
Render's static site hosting is genuinely free and would be the obvious home for a
website — but Render's own documentation is explicit that a static site cannot
run server-side code. Our SEO layer is server-side code. Choosing it would mean
silently giving up SEO Phase 1, which was commissioned and delivered. That is
covered next.

---

## 5. What moving actually takes

The website is a Vite application, which does produce a folder of static files.
If that were all, this would be a half-day job.

It is not all. Every page request is currently routed through a piece of
server-side code (`api/seo-render.ts` and a supporting file, about 970 lines
between them). It asks the API what that specific URL's title, description and
preview image should be, and rewrites the page's `<head>` before the browser
renders anything. That is SEO Phase 1.

**Without it, every page ships the same generic information.** Around 29,000
listings would share one title and one preview image, and every link pasted
into WhatsApp would preview as the home page.

So the work is:

| | Task |
|---|---|
| 1 | Rebuild the SEO renderer as a route inside the API service. Both files already use web-standard code rather than Vercel-specific code, so the logic transfers; it is the wiring that is new |
| 2 | Replace its network call to the API with a direct internal call — this is where the one genuine speed gain comes from |
| 3 | Serve the website's files ahead of the renderer: a real file wins, everything else gets rendered |
| 4 | Move the website build into the deployment, with both environment variables present **at build time** — Vite writes them permanently into the files it produces, so setting them afterwards does nothing |
| 5 | Delete the two Vercel-specific configuration files, which exist only to work around Vercel behaviour |
| 6 | Automated tests covering each of the above |

Then, before anything is pointed at it: deploy to Render's own address while
nothing uses it, and check a dozen real URLs with a search-engine crawler —
home page, a listing, FAQ, About, the account-deletion page, a blog post, a
missing page — confirming each returns the correct status **and** the correct
title. A page can look perfect in a browser and still tell Google it does not
exist; that specific fault has occurred on this project before.

Then the switch itself is one DNS record, and reversing it is the same record.
The Vercel project stays deployable for 48 hours so that rollback stays real.

**One known hazard, named so it cannot be stumbled into.** The SEO renderer
reads the page shell over the network. If that request is allowed to route back
into the renderer, the site fails with an infinite loop. This has taken this
site down once before. The port reads the shell directly from disk, which
removes the possibility rather than guarding against it.

---

## 6. What changes for speed

Today the SEO renderer runs on Vercel's edge network, at a location near the
visitor — Mumbai, for most Indian traffic — and makes one call to Singapore for
the page's data. After the move, everything is served from Singapore.

| | Effect |
|---|---|
| **Page HTML** | **Slightly better.** The SEO lookup stops being a network round trip and becomes an internal call |
| **Images, scripts, styling** | **Slightly worse.** A 3.1 MB bundle travels from Singapore rather than from a Mumbai edge location |

The second effect is real and measurable, and there is a specific fix: Render's
**Edge Caching**, which serves static files from locations near the visitor.
It was switched off; it was **turned on for the API service on 27 September**
using the "Common static files" profile, which caches images, scripts and
stylesheets but deliberately **not** HTML or JSON — caching per-visitor JSON at
an edge would be a data-protection problem, not an optimisation. The new web
service will need the same setting turned on after its first deploy, and we
would measure load times from India before and after rather than assume.

Net expectation: **broadly unchanged**, provided edge caching is enabled. We
would rather say that plainly now than present a saving as a performance win.

---

## 7. What it costs, side by side

Converted at roughly ₹89 to the dollar. Vercel prices exclude GST.

| | Now | Year 1 | Each year after |
|---|---|---|---|
| **A. Hobby** | $0 | $0 | $0 — but prohibited, and pausable without notice |
| **B. Vercel Pro** | $20/mo | **$240** ≈ ₹21,400 | $240 ≈ ₹21,400 |
| **C. A second Render service** | $7/mo | **$84** ≈ ₹7,500 | $84 ≈ ₹7,500 |
| **D. Fold into the API service** | $0 | $0 | $0 — but couples the two codebases; not recommended |

**The saving from moving is about $156 (₹13,900) a year** — $20 a month on
Vercel against $7 on Render. It is worth being clear-eyed about that figure: it
is real and it recurs, but it is smaller than two to three days of engineering
time in the first year. The move pays for itself from year two onward.

Both services sit in Singapore, so the website's call to the API is a
same-region hop of about a millisecond. That is why running them as two
services costs almost nothing in speed.

**The stronger arguments for moving are not financial:**

* One provider, one dashboard, one bill, one place where both the website and
  the API live.
* One fewer account whose terms are currently being breached.
* Capacity already purchased and sitting at 1% utilisation.

**And the strongest argument against moving *right now* is sequencing.** Ahead
of it are Razorpay live activation, the host listing wizard fault, and getting
an iOS build onto TestFlight. This work touches the layer that search engines,
shared links and app-store reviewers all see, and a break in that layer is
invisible for days and expensive to discover late.

---

## 8. The recommendation

**Move the website to Render — after go-live, not during it.**

| When | Step | Who | Cost |
|---|---|---|---|
| **This week** | Upgrade Vercel to Pro. Ends the licensing exposure immediately, requires no engineering, and can be cancelled any month | Client — billing details | $20/mo |
| ~~This week~~ **Done 27 Sep** | Both old Oregon services suspended; Edge Caching enabled on the API service | Zyphex | $0 |
| ~~After go-live~~ **Done 27 Sep** | **The port is built and tested.** It answers with the same status and the same page titles as the live site on every URL checked, including the 404s | Zyphex | — |
| **This week** | Add the two environment variables to Vercel preview builds; delete the abandoned Vercel project | Zyphex | $0 |
| **After go-live** | Deploy the new service and verify it on Render's own address, with no domain pointed at it | Zyphex | half a day |
| **Then** | Switch one DNS record; keep Vercel deployable for 48 hours | both | $0 |
| **48 hours later** | Turn off the Vercel project and cancel the Pro subscription | Client | back to $0 |

Total bridging cost, assuming two to three months on Pro: **$40–60
(₹3,500–5,300)**. Vercel also offers a Pro trial, which may reduce this further
— worth checking at the point of upgrading.

**What we are explicitly not recommending:** starting the migration this month
to avoid two months of subscription. Saving $40 by putting a high-consequence
change onto the go-live critical path is a poor trade.

### One thing that should not move with it

The domain's DNS — all 17 records — currently lives at Vercel. It is tempting
to move it at the same time so that nothing is left behind.

**Render does not offer DNS hosting at all**, so there is no "move it to
Render" option; the realistic destinations are the domain registrar or
Cloudflare. More importantly, ten of those records carry email, and every
one-time passcode on this platform is sent by email — signup, sign-in, password
reset. A mistake there locks everyone out of the site and the apps, and looks
exactly like a software fault.

If the zone is moved at all, it should be a separate change made after the
website move has been stable for two days — never in the same window, or a mail
failure has two possible causes and no way to tell them apart. A full record
inventory and a safe procedure are documented separately and are ready when
that decision is taken.

---

## 9. Decisions needed from you

1. **Approve the Vercel Pro upgrade** — $20/month, cancellable, ends the
   licensing exposure this week. This is the only item that cannot wait.
2. **Confirm the migration is wanted** at roughly two to three days of
   engineering, scheduled for after go-live, saving about ₹13,900 a year
   thereafter. **The port itself is already built and tested** (27 September);
   what remains is the deployment and the cutover.
3. **Confirm SEO Phase 1 behaviour must be preserved** through the move. We
   assume yes; it was commissioned and delivered, and it is the reason the
   cheaper static-hosting route is not available.

---

*Prices read from Vercel's and Render's published documentation and from both
live dashboards on 27 September 2026. Usage figures are the last thirty days as
reported by each provider. The Vercel plan restrictions quoted are from
Vercel's own fair use guidelines.*
