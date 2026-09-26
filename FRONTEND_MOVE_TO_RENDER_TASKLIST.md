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
| 0.2 | **Do NOT move DNS.** The nameservers are Vercel's and they hold the **MX records (GoDaddy), the SPF record, both Brevo DKIM CNAMEs**, and the `api` CNAME. Only the `www` record changes at cutover. | Vercel DNS stays free with nothing hosted on it. Moving DNS as part of this puts mail at risk for no benefit. |
| 0.3 | **Confirm with the client that SEO Phase 1 behaviour must survive the move**, in writing. | It was billed. If it silently regresses, that is the conversation nobody wants. |

---

## PHASE 1 — build it (Claude)

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
3. **DNS holds the mail.** MX, SPF and both Brevo DKIM records live in Vercel
   DNS. Touch only the `www` record.
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
