# Moving the website off Vercel, onto the Singapore service

**27 September 2026.** Decision: serve www.aajoohomes.com from the existing
Render Singapore service instead of Vercel, by folding the SEO renderer into
the backend that already answers its data.

---

## Why, honestly

**The money is the reason.** Vercel's Hobby plan is not licensed for commercial
use, so the real comparison is not "Vercel free vs Render $7" — it is:

| | |
|---|---|
| Stay on Vercel, licensed properly | **Vercel Pro, $20/month** (already item 3.7 on the go-live list) |
| Move into the Singapore service | **$0 extra** — the service is already paid for |
| Move to a separate Render web service | $7/month (a free one spins down, which for a public website means a cold start for whoever arrives first) |

**It will not make the site faster on its own, and may make it slightly
slower.** Today `api/seo-render.ts` declares `runtime: "edge"`, so it runs at a
Vercel PoP near the visitor — Mumbai for most of our traffic — and makes one
fetch to Singapore for the page's SEO record. After the move, everything comes
from Singapore.

* **HTML:** slightly better. The SEO lookup stops being a network hop and
  becomes an in-process call.
* **Static assets:** slightly worse. A 3.1 MB bundle served from Singapore
  rather than a Mumbai edge. **Mitigated by turning on Render's Edge Caching**
  (Settings → Edge Caching → Cacheable File Types) — without that, this
  regression is real and measurable.

Anyone selling this internally as a performance win will be wrong. It is a
cost and consolidation win with a performance cost that has to be bought back
with edge caching.

---

## What we are actually moving

This is **not** a static site, and that is the whole difficulty. `vercel.json`
rewrites every page request to a serverless function:

```json
{ "source": "/((?!api/|index\\.html).*)", "destination": "/api/seo-render" }
```

That function is SEO Phase 1 — a billed deliverable. It asks the API what each
URL's metadata should be and rewrites the `<head>` before the SPA boots.
Without it every page ships the shell's hardcoded head again: ~29,000 listings
share one title and one preview image, and every link pasted into WhatsApp
previews as the home page.

**Render Static Sites cannot run it.** So this is a port, not a hosting swap.

The good news: the function uses web-standard `Request`/`Response`, not
Vercel's own types, so the logic moves as-is. Only two things are Vercel's:

| File | Fate |
|---|---|
| `middleware.ts` (36 lines, `@vercel/edge`) | **Deleted.** It exists only because Vercel's filesystem check beats its rewrites for `/`. A normal server has no such problem. |
| `vercel.json` rewrites | **Deleted.** Becomes ordinary routing: serve a real file if it exists, otherwise render. |

---

## PHASE 0 — before any code (Sumit)

| # | Task | Why it is first |
|---|---|---|
| 0.1 | **Decide: same service, or its own?** Recommendation: same Singapore service. It already answers the SEO data, so the lookup becomes in-process and costs nothing. | Everything below assumes the same service. |
| 0.2 | **Do not move DNS in this change.** Only the `www` record changes at cutover. Moving the zone itself is a separate job for Phase 4 if we want it at all — see `DNS_ZONE_INVENTORY.md`, which lists all eleven records and the steps. | **Render has no DNS product**, so moving DNS consolidates nothing; it swaps Vercel for Cloudflare. And seven of the eleven records are mail — SPF, DMARC at `p=reject`, both Brevo DKIM CNAMEs, two MX. Every OTP on this platform is an email, so breaking them locks everyone out of the app. Do the two moves one at a time or a mail failure has two suspects. |
| 0.3 | **Confirm with the client that SEO Phase 1 behaviour must survive the move**, in writing. | It was billed. If it silently regresses, that is the conversation nobody wants. |

---

## PHASE 1+2 — DONE AND DEPLOYED, 27 September 2026

**The website is live on the Singapore service**, at `api.aajoohomes.com`,
serving alongside the API. `www.aajoohomes.com` is **still on Vercel** — no DNS
has changed, so this is Phase 2's "deploy it with nothing pointed at it", and
the cutover is still one record away.

**Corrected from the entry below: it is NOT a second $7 service.** The user
overruled that, rightly. The website is a **git submodule at `web/`** of the
backend repo; the Dockerfile builds it in its own stage and copies only `dist/`
and the renderer into the runtime image. **$0 extra.** Render checks out private
submodules under the same account without any extra configuration — confirmed
in the build log, which printed `building the website` rather than the
not-checked-out warning.

The cost is coupling, not money: a website change now needs a one-line commit
in the backend repo to move the pointer, and clones need `--recurse-submodules`.

Backend `8481e88` + `203c0b8` · website `820b6f6`.

### What running it found that no test did

* **`app.js` answered `/` with "Hello Backend!"**, registered long before the
  mount, so it won the home page outright — the one page on the site that would
  never render, failing with a cheerful 200. Every test asserted "API routes
  beat the website"; this is an API route named `/`. Fixed with
  `websiteIsMounted()`, and there is a test for it now.
* **Three files fell back to `https://aajaodev.onrender.com`** — the service
  suspended the same morning. `apiConfigs.ts`, `apis.ts` and the axios instance.
  Vite bakes the value in at build time, so any build without
  `VITE_API_BASE_URL` shipped an app where every request failed. Now
  `api.aajoohomes.com`, so an unset variable fails safe.
* A first attempt to verify that proved nothing: `.env.local` sets the variable
  to the dev proxy `/__api` and a real process env beats a `.env` file, so the
  bundle under test was a development one. Re-verified with the file moved
  aside.

### Verified after deploy

| | |
|---|---|
| Website on the service | `/` `/faq` `/about` `/delete-account` all 200 with their own titles; `/no-such-page` 404 |
| API unchanged | `/health` 200; `/common/categories` fingerprint `a1a4dda4140ad0ea`, identical to before the deploy |
| Vercel | `www.aajoohomes.com` still served by Vercel (`Server: Vercel`), untouched |

### What opening it in a BROWSER found, after curl said everything was fine

Every crawler check passed — right statuses, right titles — and the site was a
correct `<head>` above a **blank white page**. Two causes, both created by this
service starting to serve the website:

* **Every asset answered 500 with a JSON body.** A page loaded from
  `api.aajoohomes.com` sends that host as its `Origin` on module scripts and
  stylesheets. The allowlist held `www` and the apex, not the API's own name, so
  `cors` threw for a request that is by definition same-origin. **curl saw 200
  throughout, because curl sends no `Origin` header** — which is exactly why
  nothing caught it.
* **The first fix for that was inert.** It added the host to
  `PRODUCTION_ORIGINS`, but `configuredOrigins()` reads
  `fromEnv.length ? fromEnv : PRODUCTION_ORIGINS` — so on a deployment with
  `ALLOWED_ORIGINS` set, that list is never consulted. The deploy went green and
  nothing changed, and the only symptom was the one already being investigated.
  The host now lives in `SELF_ORIGINS`, appended after that branch, with a test
  that sets `ALLOWED_ORIGINS` to something excluding it.

Backend `e9c5cd4` (inert) then **`538676d`** (the real one). Verified after:
all three assets 200 with correct content types, a lookalike origin still
refused, categories fingerprint `a1a4dda4140ad0ea` unchanged, and the home page
renders.

### Google Maps needs one referrer added — **not a defect in this work**

`RefererNotAllowedMapError`, naming `https://api.aajoohomes.com/explore`. The
key is baked into the bundle correctly; it is **restricted by HTTP referrer** in
Google Cloud Console to `aajoohomes.com` and `www`. Maps will therefore work
the moment `www` points at this service — but not while testing on the API
hostname.

To test before cutover, add `https://api.aajoohomes.com/*` to that key's
referrer restrictions (Google Cloud Console → Credentials → the Maps key →
Website restrictions). Worth doing rather than waiting, since the point of this
phase is to find problems before the domain moves.

### Still to do

1. Set `VITE_GOOGLE_MAPS_KEY` on the Singapore service — **maps are broken on
   the Render copy until this exists**, because Vite needs it at build time.
   Then redeploy. (`VITE_API_BASE_URL` is no longer required thanks to the
   fallback fix, but setting it explicitly is better than relying on a default.)
2. Turn on **Edge Caching** — already on for this service, and it now serves the
   3.1 MB bundle, so it is doing real work.
3. Measure load times from India, before and after.
4. Phase 3: point `www` at the service, keep Vercel deployable for 48 hours.

---

## SUPERSEDED — the second-service plan, 27 September


Frontend repo `94d5cf1` + `424e91c`. Not deployed anywhere yet; Vercel is
untouched and still serving the site.

### The correction that changes the cost

Phase 0.1 assumed the website would fold into the Singapore API service for
**$0 extra**. **It cannot, cleanly.** That service is built from a Dockerfile
whose build context is the *backend* repo (`COPY . .`), and the frontend is a
different private repo. Folding them means a git submodule or a credentialed
clone inside the Docker build — and then every frontend change needs a backend
commit to bump the pointer, which is a bad trade for velocity.

So this becomes a **second Render web service, built from the frontend repo**:

| | |
|---|---|
| Cost | **$7/month** (Starter). A free instance spins down, and a 50-second cold start for whoever arrives first is not acceptable on a public site. |
| Saving vs Vercel Pro | $20 − $7 = **$13/month, ~₹13,900/year** — not the $240/year quoted in the client document, which assumed $0 |
| Custom domains | free — 1 of 15 used on the Pro workspace |
| Bandwidth | free — 898 MB of 25 GB used; the site adds ~2.6 GB |

**The in-process call (old task 1.2) is dropped and barely matters.** Both
services sit in Singapore, so the resolver call is a same-region hop of roughly
a millisecond rather than the cross-continent one it replaced.

### What was built

| | |
|---|---|
| `server.mjs` | The production server. No new runtime dependencies — `node:http`, gzip for text, content-hashed assets `immutable`, everything else short-TTL. Drains on SIGTERM. |
| `api/seo-render.ts` | Two changes only: a `setShell()` export, and the API_BASE fallback moved off `aajaodev.onrender.com` (suspended today — a default that answers 503 makes every page render untitled and reads as a resolver bug). |
| `package.json` | `esbuild` declared (`buildSeoHandler.mjs` always needed it and said so in its own comment; a production install would have dropped it). `build` left **byte-for-byte unchanged** because Vercel runs it; `build:web` is Render's. |
| `tests/theServerReadsItsShellFromDisk.test.mjs` | Boots the real server against a fixture and a stub API. 8 tests. |

### The two traps, closed by construction rather than guarded

* **The 508 loop is gone.** The shell is read from `dist/index.html` at boot.
  Nothing fetches it, so the stale-CDN shell, the Vercel-login-page-as-the-site
  and the loop are all unreachable. The test asserts the stub API is never asked
  for a shell — not that the source says the right thing.
* **No middleware.** `middleware.ts` existed only because Vercel's filesystem
  check beats its own rewrites. `/` is not a file, so it falls through to the
  renderer normally. Verified: the home page renders its real title.

### Verified against the LIVE API, and against live Vercel

Same status **and** same `<title>` as `www.aajoohomes.com` on every path
checked — `/`, `/faq`, `/about`, `/delete-account`, `/blog`, `/login`,
`/properties` and a missing path, including both 404s. `robots.txt` comes from
the API; assets serve from disk. 73/73 head-rewriting tests, 75/75 test files,
full build green.

One self-correction worth recording: the traversal test in that file originally
pointed the server at a temp directory with nothing beside it, so **it passed
with the guard deleted**. It now uses a sentinel file and was confirmed to fail
without the guard.

### Render service settings (Sumit)

| Setting | Value |
|---|---|
| Type | Web Service, **Singapore**, Node |
| Repository | `nameeshPatiyal100/Aajao-Admin-WebSIite`, branch `main` |
| Instance | Starter ($7) |
| Build command | `npm ci && npm run build:web` |
| Start command | `node server.mjs` |
| Env (**at build time** — Vite bakes them in) | `VITE_API_BASE_URL=https://api.aajoohomes.com`, `VITE_GOOGLE_MAPS_KEY=…` |
| Env (runtime) | `SEO_API_BASE_URL=https://api.aajoohomes.com` |
| After first deploy | turn on **Edge Caching → Common static files** (this service serves the 3.1 MB bundle; the API service's setting does not apply to it) |

Deploy it with **no custom domain attached** first — that is Phase 2.

---

## PHASE 1 — the original plan, for reference

| # | Task |
|---|---|
| 1.1 | Port `api/seo-render.ts` + `api/_seoHead.ts` into the backend as a route. They already use `Request`/`Response`; the adapter is thin. |
| 1.2 | Replace the `${API_BASE}/seo…` fetch with a **direct in-process call** to the same controller. This is where the HTML speed-up comes from. |
| 1.3 | Serve `dist/` ahead of the renderer: a real file wins, everything else renders. |
| 1.4 | **Never let the renderer fetch its own route.** It reads `/index.html` to get the shell; if that path routes back into the renderer, production dies with *508 Loop Detected*. This has already happened once on this project. Read the shell **from disk**, not over HTTP — which removes the trap entirely. |
| 1.5 | Move the frontend build into the deploy: `npm ci && npm run build` producing `dist/`, with `VITE_API_BASE_URL` and `VITE_GOOGLE_MAPS_KEY` **present at build time** (Vite bakes them in; setting them afterwards does nothing). |
| 1.6 | Tests: the head is rewritten, a real file is not intercepted, `/index.html` cannot loop, and a crawler gets 200 with the right `<title>`. |

---

## PHASE 2 — prove it before anyone sees it (Claude)

| # | Task |
|---|---|
| 2.1 | Deploy to the Singapore service's own `onrender.com` URL. Nothing points at it yet. |
| 2.2 | Crawler check on **at least a dozen URLs** — home, a listing, `/faq`, `/about`, `/delete-account`, a blog post, a 404: `curl -A "Googlebot" <url>` must return **200 and the correct `<title>`**. A page that renders fine and answers 404 is the trap this project has shipped four times. |
| 2.3 | `robots.txt` and `sitemap.xml` still served correctly — both are routes inside that function. |
| 2.4 | Compare byte-for-byte against the live Vercel response for the same URLs. Differences must be explainable. |
| 2.5 | Measure: TTFB and full load from India, before and after. If assets regress, enable **Edge Caching** and measure again. |

---

## PHASE 3 — cutover (Sumit + Claude)

| # | Task | Who |
|---|---|---|
| 3.1 | Add `www.aajoohomes.com` as a custom domain on the Singapore service | Sumit |
| 3.2 | Change the `www` record in **Vercel DNS** to Render's target | Sumit (or me, with your go-ahead) |
| 3.3 | Watch the crawler checks flip over; confirm the certificate issues | Claude |
| 3.4 | Confirm the apex (`aajoohomes.com` → `www`) still redirects | Claude |
| 3.5 | **Leave the Vercel project in place for 48 hours**, deployable, so a rollback is one DNS record | both |

---

## PHASE 4 — after 48 quiet hours

| # | Task |
|---|---|
| 4.1 | Delete `middleware.ts`, `vercel.json`, the `@vercel/edge` dependency and the `api/` folder from the frontend repo |
| 4.2 | Turn off the Vercel project (keep the account: **it is still the DNS host**) |
| 4.3 | Close go-live item 3.7 "Vercel on Pro" — it no longer applies |
| 4.4 | Update `MASTER_PENDING_TASKS.md` and the deploy topology memory: pushes to the frontend repo no longer deploy anything by themselves |

---

## Rollback

One DNS record. Point `www` back at Vercel; the project is still there and
still building from the same branch. Keep that true for 48 hours.

---

## The four traps

1. **The 508 loop.** `/index.html` must never route into the renderer. Reading
   the shell from disk instead of over HTTP removes the possibility.
2. **Vite bakes env vars at build time.** A variable added after the build is
   not in the bundle. This is how a site ends up silently pointing at the wrong
   API.
3. **DNS holds the mail.** MX, SPF, DMARC (`p=reject`) and both Brevo DKIM
   records live in Vercel DNS, and every OTP on this platform is an email.
   Touch only the `www` record. Full zone in `DNS_ZONE_INVENTORY.md`.
4. **A page can render perfectly and answer 404.** Status codes are checked
   with a crawler user-agent, not by looking at the page in a browser.

---

## Sequencing — read this before starting

Everything above is worth doing. **None of it is worth doing this week.**

Ahead of it on the critical path: Razorpay live activation, the listing wizard
that will not continue past Step 1, getting an iOS build onto TestFlight, and
the guest-side drive that is finally unblocked now that accounts exist. This
move touches the one layer that Google, every WhatsApp link and an App Store
reviewer all depend on — and a broken SEO layer is invisible for days and
expensive to notice.

Do it in the quiet week after go-live, not during it.
