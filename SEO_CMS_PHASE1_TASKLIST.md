# Aajao Homes — SEO CMS, Phase 1 Task List

Source: `AAJAO HOMES - CMS SEO FUNCTIONAL REQUIREMENTS SPECIFICATION.docx`, Phase 1
(spec lines 11–1105). Spec budget: **200–300 dev hours, Months 1–2, priority CRITICAL**.

Written 2026-08-26. Scope covers three repos:

| Repo | Role |
|---|---|
| `aajao-frontend-vercel` | Public site (Vite SPA) + admin UI |
| `aajaoBackend-render` | Node/Express + Sequelize API, MySQL |
| `ajoo admin website` | This repo — planning/tracking docs |

> **Revision 2 — 27 Aug 2026.** Two facts changed the scope after the first
> draft: (a) the ~29,000 seeded listings under host 100 are test data and will
> be **deleted** before real onboarding, and (b) `utils/listingSeo.js` **already
> auto-generates** the full SEO record for every listing at submission time.
> Phase 1 drops from 252–312 hrs to **224–280 hrs**. See
> [Scope revision](#scope-revision). **Task 0 is unchanged** — it is a fixed
> cost that has nothing to do with how many listings exist.


---

## Scope revision

### What the listing count does and does not affect

Task 0 is a **fixed cost**. The edge function does a per-request lookup, so it
behaves identically with 5 listings or 5 million — there is no per-page build
step. The 29,000 figure only ever mattered in two places in the first draft:
it is why build-time prerendering (Option B) was rejected, and it is what made
the bulk backfill tooling in Tasks 6 and 9 large.

Deleting the test dataset therefore removes **backfill** work. It does not
touch the **rendering** blocker, and the rendering blocker is what decides
whether any of this reaches a crawler at all.

### What already exists — more than the first draft credited

`utils/listingSeo.js` derives the entire SEO payload from data the host already
entered, and `listingStep5.controller.js` runs it at submission time for every
listing. Since the 5-step wizard is now the only property form on both web and
app, this covers 100% of new listings automatically. It currently produces:

| Output | Shape |
|---|---|
| `slug` | `pine-valley-cottage-jibhi-kullu-himachal-pradesh`, uniqueness-checked |
| `urlPath` | `/state/district/city/village/property-name` — already hierarchical |
| `metaTitle` | `{name} in {place} \| {category} \| Aajoo` |
| `metaDescription` | Booking line + top views/amenities/experiences + negotiation hook |
| `primaryKeyword` + `secondaryKeywords` | Up to 8, derived from category, views, region |
| `structuredData` | Full `LodgingBusiness` JSON-LD — address, geo, offer, images, `amenityFeature` |
| `internalLinks` | village → district → state → experience → host |

**So the model asked for — "every new property automatically creates everything
the SEO team needs" — is already built on the backend.** It has been running on
every wizard submission and reaching nothing, because no public endpoint reads
`property_seo` and no crawler can see the SPA's head.

Three gaps in the generator, all small:

1. `metaTitle` is truncated at 255 chars and `metaDescription` at 500. The spec
   wants **60** and **120–160**. Fixing the limits is a one-line change per
   field; making the copy read well *within* those limits is the real work.
2. It covers properties only — blog posts and static pages have no equivalent.
3. It has no OG/Twitter, robots, canonical, breadcrumb or date fields yet.

### The shift this creates for the SEO team

The first draft assumed the SEO team would author metadata page by page and
needed bulk tooling to survive 29,000 of them. With the seed data gone and
generation automatic, the job changes shape:

- **They own the templates, not the pages.** They define the title and
  description patterns once; every new listing inherits them at publish.
- **They hand-edit only exceptions** — flagship listings, landing pages, and
  anything a health report flags as weak.
- **Coverage is 100% by construction.** A listing cannot go live with no
  metadata, because generation is part of publishing.

This is how large marketplaces actually operate, and it is a better outcome
than the first draft's plan — not merely a cheaper one. It does add one task
(Task 10) to make the templates editable rather than hardcoded.

### Revised totals

| | First draft | Revised | Δ |
|---|---|---|---|
| Phase 1 total | 252–312 hrs | **224–280 hrs** | **−28 to −32** |
| Task 0 (the blocker) | 32–40 hrs | 32–40 hrs | **unchanged** |

About a 10% saving. Deliberately not more, because the work the test data
inflated (bulk backfill) was never the expensive part — the rendering layer
was, and that is unaffected.

### One risk to check before deleting

Deleting ~29,000 rows that a search engine has already indexed creates soft-404s
at scale. In our case they are very likely **not** indexed — there is no
sitemap, no per-page meta, and the SPA serves them all as the homepage — so
deletion is probably safe. Confirm with a `site:aajoohomes.com` query and a
Search Console coverage check first. If any are indexed, serve `410 Gone`
rather than letting them 404. Delete **before** the sitemap goes live (Task 4),
never after.

---

## 0. Read this first — the blocker

**The site cannot currently serve per-page SEO to any crawler, and no amount of
CMS work changes that on its own.**

Verified in the codebase today:

- `aajao-frontend-vercel` is a **Vite SPA**. Build is `tsc -b && vite build`. There
  is no SSR, no static generation, no prerender step.
- `vercel.json` is `{"rewrites":[{"source":"/(.*)","destination":"/"}]}` — **every
  URL on the domain returns the identical `index.html`**, with one hardcoded
  `<title>`, one `og:title`, one `og:description`, one `og:url`
  (`https://www.aajoohomes.com/`).
- `src/redesign/lib/useDocumentMeta.ts` does set title / description / canonical /
  `og:*` — but **at runtime, in JavaScript, after hydration**.

Consequences as the site stands:

| Consumer | Runs JS? | Sees our per-page meta? |
|---|---|---|
| Googlebot | Yes, deferred render queue | Eventually, unreliably |
| Bingbot | Largely no | **No** |
| Facebook / WhatsApp / LinkedIn / Twitter card scrapers | **No** | **No** |

So every one of our ~29,000 property pages currently shares one title and one
social preview, and every link shared to WhatsApp previews as the homepage.

Sections 1.1, 1.2, 1.7 and 1.8 of the spec all describe **head output**. Building
their admin forms without fixing rendering produces database columns nobody reads.
**Task 0 must land before or alongside Task 1.** It is not in the spec's hour
budget; it is added here.

### Recommended approach for Task 0

Three options were considered:

| Option | Effort | Verdict |
|---|---|---|
| A. Migrate to Next.js | Weeks — ~100 route files | Correct long-term, not Phase 1 |
| B. Build-time prerender (react-snap / vite plugin) | Days | Fails: cannot prerender 29k property pages; content edits need a redeploy |
| C. **Vercel Edge Middleware meta injection** | ~1 week | **Recommended** |

**Option C**: a single edge function intercepts every HTML request, looks up that
path's SEO record from the backend, and string-injects `<title>`, meta, canonical,
robots, OG/Twitter and JSON-LD into `index.html` before responding. Users still get
the SPA unchanged. Crawlers get a correct, per-page head.

Why it fits us specifically:
- Scales to 29k listings — per-request lookup with edge caching, not a build step.
- CMS edits go live immediately, no redeploy. This matters for the SEO team.
- Zero changes to the ~100 existing route components.

**Honest limitation to state up front:** Option C fixes the `<head>`. The page
**body** is still JS-rendered, so body-content ranking still depends on Google's
render queue. Full SSR remains a Phase 2+ decision. For metadata, social previews,
canonicals, robots directives and schema — which is all of Phase 1 — Option C is
complete.

---

## Task inventory

| # | Spec | Task | Status | Was | Now |
|---|---|---|---|---|---|
| 0 | — | SEO rendering layer (edge meta injection) | **DONE** | 32–40 | **32–40** |
| 1 | 1.1 | Global SEO settings | **DONE** | 20–24 | 20–24 |
| 2 | 1.2 | Page-level SEO configuration | **DONE** | 40–48 | 26–32 |
| 3 | 1.3 | URL management, redirects, robots.txt | Net-new | 32–40 | 26–32 |
| 4 | 1.4 | XML sitemap manager | Net-new | 24–30 | 16–20 |
| 5 | 1.5 | Breadcrumb management | Net-new | 12–16 | 12–16 |
| 6 | 1.6 | Image SEO optimisation | Extend | 24–30 | 14–18 |
| 7 | 1.7 | Open Graph & social SEO | Extend | 16–20 | 16–20 |
| 8 | 1.8 | Schema markup (basic) | Extend | 28–34 | 16–20 |
| 9 | added | SEO team enablement | Added | 24–30 | 26–32 |
| 10 | added | Generator + template engine | **New** | — | 20–26 |
| | | **Total** | | 252–312 | **224–280** |

Dependency order: **0 → 1 → 2 → (3, 4, 5, 6, 7, 8 in parallel) → 9**.

---

## Task 0 — SEO rendering layer

**Status: BUILT and verified 2026-08-27. Committed, not deployed.**

| | |
|---|---|
| Backend | `feat/seo-phase1-task0` · commit `92e04c8` |
| Frontend | `redesign/aajoo-2026` · commit `1cf07a9` |
| Tests | 43 backend · 25 frontend · 49 end-to-end acceptance — all green |
| Measured overhead | **1.7 ms** at p95 (budget was 50 ms) |

### What shipped

| File | Role |
|---|---|
| `utils/seoResolve.js` | Resolves any path to its `<head>`. Never throws. |
| `config/seoDefaults.js` | Global + static-page copy, extracted from `cmsSchema.ts` so server and page cannot disagree |
| `utils/seoCache.js` | 60s read cache — the MySQL pool is capped at 5 by the host |
| `routes/seo.routes.js` · `controllers/seo.controller.js` | `GET /seo/resolve?path=` with ETag |
| `middleware/rateLimiter.js` | `seoLimiter` — see below |
| `api/seo-render.ts` · `api/_seoHead.ts` | The edge function and its pure, testable half |
| `vercel.json` | `/((?!api/).*)` → the renderer |
| `useDocumentMeta.ts` | Adopts the injected record on the entry URL |

### Verified end to end, against a real build

Facebook, WhatsApp, X, LinkedIn, Bing, Google and Slack each receive the
listing's **own** title, description and cover photograph in raw HTML, with no
JavaScript. Exactly one `<title>` and one of each `og:`/`twitter:` tag.
`/account/*` skipped and left `noindex`; `/become-a-host` still indexable; an
unrouted path answers a real `404` rather than a soft `200`; a crawler and a
visitor receive byte-identical documents.

```bash
npm run seo:accept -- --origin <origin> --property <id>
```

### Two decisions worth knowing about

**Copy is carried as authored, never truncated.** An earlier draft clamped
titles to the spec's 60 characters. That cut the home page's to
`...Across India |` — a dangling separator — and made the crawler read a
different title from the visitor, which is the exact mismatch this layer
exists to prevent. Enforcing 60/160 means *rewriting* copy to fit, which is
Task 10.

**A dedicated rate limiter.** The caller is Vercel's edge network, so every
request arrives from a handful of IPs and would have shared one 600-per-15-min
bucket for the whole world. That is a few minutes of ordinary traffic, after
which every page renders with no title.

### Still outstanding

Two acceptance criteria need a public URL, because the tools fetch it
themselves: **Facebook Sharing Debugger** and **X Card Validator**. Everything
else is verified.

---

## Task 0 — reference


**Status: net-new. Blocker for 1, 2, 7, 8. 32–40 hrs — unaffected by listing count.**

### 0.1 Backend: SEO resolver endpoint
- `GET /seo/resolve?path=/property/goa-villa-with-pool-29262`
- Returns the merged SEO record for that path: page-level values, falling back to
  global defaults, falling back to derived values (property name, blog title).
- Single query per path. Response includes `Cache-Control` and an `ETag`.
- Must resolve all four path families: static pages, `/property/*`, `/blog/*`,
  search/category landing pages.
- Returns `404` semantics (not an error) for unknown paths so the edge can fall
  back to global defaults rather than blanking the head.

### 0.2 Edge middleware
- `middleware.ts` at the frontend repo root (Vercel Edge runtime).
- Matches HTML document requests only — skip `/assets/*`, `/api/*`, files with
  extensions, and any authenticated `/account/*` or `/host/*` route (those are
  `noindex` anyway and must not hit the resolver).
- Fetches `/seo/resolve`, injects into `index.html`:
  `<title>`, `meta[name=description]`, `link[rel=canonical]`,
  `meta[name=robots]`, all `og:*`, all `twitter:*`, `<script type="application/ld+json">`,
  and `link[rel=alternate][hreflang]`.
- Injection is replace-if-present, append-if-absent — must not leave the hardcoded
  `index.html` tags duplicated alongside the injected ones. Duplicate `og:title`
  tags are worse than none; scrapers pick arbitrarily.
- HTML-escape every injected value. A property title containing `"` or `<` must not
  break the document or open an injection vector.

### 0.3 Caching and invalidation
- Edge cache keyed on path, TTL 5 min, `stale-while-revalidate`.
- Saving any SEO record in admin purges that path's edge cache immediately —
  the SEO team must be able to edit, save, and re-run Facebook's debugger within
  seconds, not wait out a TTL.

### 0.4 Keep `useDocumentMeta` in sync
- Client-side meta stays (it drives the tab title during in-app navigation).
- It must read the **same** resolved values so a crawler and a user never see
  different titles — a real, penalised discrepancy.

### Acceptance criteria
- [ ] `curl -A "facebookexternalhit/1.1" https://www.aajoohomes.com/property/<slug>`
      returns that property's own title, description and `og:image` in the raw HTML.
- [ ] Same for Bingbot, Twitterbot, LinkedInBot, WhatsApp user agents.
- [ ] Facebook Sharing Debugger and Twitter Card Validator both render a correct,
      page-specific preview for: homepage, a property, a blog post, a static page.
- [ ] `view-source:` on any page shows exactly one `<title>` and one of each `og:*`.
- [ ] Logged-in `/account/*` pages are untouched and still `noindex`.
- [ ] Edge adds < 50 ms p95 to TTFB.

---

## Task 1 — Global SEO settings (spec 1.1)

**Status: COMPLETE and live on production, 2026-08-27. Acceptance 58/58.**

Every criterion met, including the two that needed more than the spec described:
a cookie consent banner (so analytics can legally be switched on at all) and a
replacement for the X Card Validator (retired in 2022).

| | |
|---|---|
| Table | `global_seo`, one row, 26 writable columns — migration applied to the live DB |
| Admin | `/admin/seo`, linked from Settings → Search & SEO |
| API | `GET`/`POST /admin/seo/global`, public `GET /seo/global` |
| Output | Verification tags, theme colour and branding render on every page |

Proven end to end against www.aajoohomes.com: a verification code pasted into
the admin screen appears on every page **with no deploy**, and clearing it
removes it. `npm run seo:accept:global -- --user <email> --pass <pw>` re-runs
it; it restores whatever the settings were before.

### What closing the last five items required

**A cookie consent banner, and moving analytics out of the server render.** The
switch could not be turned on because nobody could decline. Building the banner
exposed something more fundamental: a script tag in the document runs the moment
the document parses, which is before any visitor has been asked anything — so
server-injecting analytics is incompatible with consent by construction. They
load in the browser now, after acceptance, and the IDs are fetched only at that
point. A visitor who declines never receives them.

**The caches stopped compounding.** Three sat in series — the CDN at 60s, the
edge memo at 60s, and the runtime's own fetch cache silently honouring the API's
`max-age=60`, which nobody chose. Worst case was about two minutes; it is about
forty seconds now. It cannot be instant: on-demand CDN purge needs cache-tag
invalidation, which Vercel offers on Enterprise and **this project is on Hobby**.
That is a plan limit, not an engineering gap, and it is why the admin screen has
a "Check the live site" button.

**The separator now changes titles**, by stripping a trailing brand and
recomposing it. One visible consequence: the brand follows `website_title`, so
titles ending "| Aajoo Homes" now read "| Aajoo". One field reverses it.

**The X Card Validator no longer exists** — retired 2022 — so the criterion was
re-expressed as the checks that tool performed, including fetching the image,
which is the commonest reason a card silently renders as a bare link.

### Three things that came out of building it

**Analytics are built, gated, and must stay off.** GA4, GTM, Meta Pixel and
Hotjar rendering all work and are switched by `analytics_enabled`, which
defaults to off. The site has **no cookie consent banner at all** — turning
these on would begin tracking every visitor with no way to decline, which under
the DPDP Act is the site's problem rather than a marketing preference. The IDs
save today; the switch waits for a banner. The admin card says exactly this.

**The title template applies only to titles that do not already carry the
brand.** Almost every title we ship does — *About Aajoo Homes | Our Story* — so
appending the site name would produce `… | Aajoo | Aajoo`. Changing the
separator therefore moves very little today. It starts mattering after Task 10
rewrites the generator to fit 60 characters without the brand.

**The site default description is nearly invisible.** Every routed public page,
the 404 route included, sets its own. Only signed-in paths and a database
failure fall back to it. It is a real safety net, but editing it will not change
pages — worth knowing before someone spends an afternoon wondering why.

---

## Task 1 — reference


**Status: net-new.** No `global_seo` table exists.

### 1.1 Database — `global_seo` (single row)
Per spec:

| Column | Type | Notes |
|---|---|---|
| `website_title` | VARCHAR(60) | Brand name in title templates |
| `tagline` | VARCHAR(160) | |
| `default_meta_title` | VARCHAR(60) | Fallback when page has none |
| `default_meta_description` | VARCHAR(160) | Fallback |
| `title_separator` | VARCHAR(5) | `\|` `-` `—` |
| `title_template` | VARCHAR(120) | e.g. `{page} {sep} {site}` |
| `gsc_verification_code` | VARCHAR(255) | Google Search Console |
| `bing_verification_code` | VARCHAR(255) | |
| `yandex_verification_code` | VARCHAR(255) | |
| `pinterest_verification_code` | VARCHAR(255) | |
| `ga4_id` | VARCHAR(50) | |
| `gtm_id` | VARCHAR(50) | |
| `fb_pixel_id` | VARCHAR(50) | |
| `hotjar_id` | VARCHAR(50) | |
| `default_og_image_url` | VARCHAR(500) | 1200×630 |
| `default_og_type` | VARCHAR(50) | |
| `twitter_card_type` | VARCHAR(50) | |
| `twitter_site_handle` | VARCHAR(50) | |
| `logo_url`, `favicon_url`, `apple_touch_icon_url` | VARCHAR(500) | |
| `organization_name`, `organization_legal_name` | VARCHAR(255) | Feeds Task 8 |
| `updated_by`, `updated_at` | | Audit |

Migration: `migrations/2026XXXX-global-seo.js`, seeded with the values currently
hardcoded in `index.html` so nothing regresses on first deploy.

### 1.2 API
- `GET /admin/seo/global` — admin read.
- `PUT /admin/seo/global` — admin write, yup-validated.
  **Watch the `stripUnknown` trap**: undeclared fields are silently deleted by our
  yup config. Every column above must be declared in the schema or it will never
  persist, and the failure is silent.
- `GET /seo/global` — public read for the edge function.

### 1.3 Admin UI
- New page `src/redesign/pages/admin/SEOGlobal.tsx`, grouped into the spec's six
  cards: Website Identity · Search Engine Verification · Default Metadata Fallbacks
  · Analytics & Tracking · Default OG & Social · Logo & Branding.
- Live title-template preview showing a rendered SERP snippet.
- Character counters with the spec's limits (60 title / 160 description), amber at
  90%, red past limit — warn, do not block.
- Add to admin nav under a new **SEO** group.

### 1.4 Public output
- Verification meta tags rendered into `<head>` by the edge function.
- GA4 / GTM / Pixel / Hotjar injected only when an ID is present, and gated behind
  the existing cookie-consent state.
- Favicon and apple-touch-icon served from the configured URLs.

### Acceptance criteria
- [ ] SEO team pastes a GSC verification code, saves, and verifies the property in
      Google Search Console without a developer or a deploy.
- [ ] Clearing a page's meta title falls back to `default_meta_title`, visible in
      view-source.
- [ ] Changing `title_separator` updates every page's title.
- [ ] GA4 fires on page views once consent is granted; nothing fires before.
- [ ] All values survive a save/reload round-trip — the `stripUnknown` check.

---

## Task 2 — Page-level SEO configuration (spec 1.2)

**Status: DONE and live on production, 2026-08-27. Acceptance 58/58 + 27/27.**

| | |
|---|---|
| Table | `page_seo`, migration applied; the 4 `property_seo` rows carried in |
| URLs | `/property/<slug>` and `/blog/<slug>` canonical; `?id=` and numeric blog URLs 301 |
| Panel | `/admin/seo/page`, reachable from every Properties and Blog row |
| API | `GET`/`POST /admin/seo/page` — 31 fields, all round-tripped |

**Verified on production:** `/property?id=29262` → 301 →
`/property/malhotra-villa-karnal-haryana`; `/blog/16` → 301 → `/blog/test`; a
draft post serves `noindex, nofollow` and a published one `index, follow`;
dates survive a redirect; a hand-mangled slug still finds its listing.

### The parts worth knowing

**Slugs needed no backfill.** Only 4 of 29,000 listings have a stored slug and
the rest are seed data due for deletion, so a listing without one derives
`name-<id>` — unique by construction, stable, and still findable if somebody
edits the words in a shared link, because the id is the part that matters.

**Deployment order is not optional.** The frontend must land first. The backend
publishes slug canonicals, and without the SPA route for them those canonicals
point at the 404 page — which is what happened in a browser check before the
route was added.

**Robots needed three entity states, not a boolean.** Spec 1.2 makes a draft
`nofollow` because its author has not finished, and a withdrawn page `noindex`
alone because its outbound links are still good. A boolean collapsed them.

**The panel leads with what the site serves today.** Most listings have no
overrides, so an empty form would invite an editor to replace generated copy
they had never seen with something worse.

---

## Task 2 — reference


**Status: partially exists — extend. Revised 40–48 → 26–32 hrs.**

What is already there:
- `property_seo` table with `pse_slug`, `pse_url_path`, `pse_meta_title`,
  `pse_meta_description`, `pse_primary_keyword`, `pse_secondary_keywords`,
  `pse_structured_data`, `pse_internal_links`. Written by
  `controllers/listingStep5.controller.js` and `utils/listingMirror.js`.
- **It is never read by any public endpoint** (verified: no reference in
  `property.controller.js` or `routes/`). Hosts have been filling in SEO fields
  that have never reached a single page.
- `tbl_blog` has **no** slug, meta title, meta description, canonical, or author
  entity. Blog routes are `/blog/:id` — numeric IDs, not slugs.

### 2.1 Database — `page_seo`
One table covering every indexable entity, keyed by `(entity_type, entity_id)`
where `entity_type ∈ {static, property, blog, category, location}`.

Columns per spec 1.2:
- **Metadata**: `meta_title` (60), `meta_description` (120–160), `focus_keyword`
- **Keywords**: `primary_keyword`, `secondary_keywords` (JSON array)
- **Canonical**: `canonical_url`, `alternate_languages` (JSON, hreflang)
- **Robots**: `robots_index`, `robots_follow`, `robots_snippet`, `robots_archive`
  (spec calls for all four as independent booleans)
- **Dates**: `published_at`, `modified_at`, `content_status`
  (`draft|review|scheduled|published|archived`), `scheduled_publish_at`
- **Social**: `og_title`, `og_description`, `og_image_url`, `og_type`, `og_url`,
  `twitter_card_type`, `twitter_title`, `twitter_description`, `twitter_image_url`,
  `twitter_creator`
- **Author**: `author_name`, `author_bio`, `author_image_url`, `author_url`
- **Breadcrumb** (Task 5): `breadcrumb_title`, `breadcrumb_parent_id`,
  `custom_breadcrumb_path`
- **Schema** (Task 8): `schema_type`, `schema_json`

Migrate the existing `property_seo` rows into `page_seo` rather than abandoning
them — hosts' entered data carries over.

### 2.2 Status → robots rules (spec-mandated, enforce server-side)
| Content status | robots |
|---|---|
| Draft | `noindex, nofollow` |
| Review | `noindex, nofollow` |
| Scheduled | `noindex` until `scheduled_publish_at`, then auto-flip |
| Published | `index, follow` |
| Archived | `noindex` |

These must be computed on the server, not merely defaulted in the form. A draft
that ships `index,follow` because someone edited the field by hand is the exact
failure this rule exists to prevent.

### 2.3 Blog gap closure
- Add `blog_slug` (unique), wire `/blog/:slug` with a permanent redirect from
  `/blog/:id`.
- Add author fields, `published_at`, `modified_at` to `tbl_blog`.
- `modified_at` updates on every edit — it feeds `<lastmod>` in the sitemap and
  `dateModified` in Article schema.

### 2.4 Property URL gap closure
- Property links are built as `/property?id=${id}` in at least 6 components
  (`PropertyRail.tsx:166`, `MobileHome.tsx:394`, `Blog.tsx:196`,
  `BookingReview.tsx:167`, `Cancelled.tsx:30`, `Negotiations.tsx:90`).
- Query-string URLs are weak SEO targets and cannot carry a keyword.
- Move to `/property/:slug` using `pse_slug`, keeping `/property?id=` working via
  301 forever — existing shared links, WhatsApp history and any indexed URLs must
  not break.

### 2.5 Admin UI — the SEO panel
- Reusable `<SEOPanel entityType entityId />` component, mounted on the property
  editor (`PropertyForm.tsx`), the blog editor (`Blogs.tsx`) and a new static-pages
  editor. One component, not three copies.
- Collapsible sections matching the spec's grouping.
- Live Google SERP preview (desktop + mobile) and character counters.
- Keyword-in-title / keyword-in-description / keyword-in-slug indicators.

### Acceptance criteria
- [ ] SEO team sets a unique meta title on one property; view-source on that
      property alone shows it; every other property is unaffected.
- [ ] A draft blog post serves `noindex, nofollow` and is absent from the sitemap.
- [ ] A scheduled post flips to `index, follow` automatically at its publish time
      with no human action.
- [ ] `/property?id=29262` 301-redirects to `/property/<slug>`.
- [ ] `/blog/12` 301-redirects to `/blog/<slug>`.
- [ ] Editing a post updates `modified_at`, and `<lastmod>` in the sitemap moves.
- [ ] Existing host-entered `property_seo` values are visible in the new panel.

---

## Task 3 — URL management & redirects (spec 1.3)

**Status: DONE and shipped 2026-08-28.** Backend `68f234e`, frontend `b0217e9`; migrations `20260828100000-robots-txt` and `20260828110000-seo-redirects` applied to the live database.

> Deploy order for this task **inverts Task 2's**: migration → backend → frontend. Deploying the backend against an un-migrated database breaks the whole `/admin/seo` screen, because the model selects columns the table does not have yet.

### 3.1 Slug editor
- Auto-generate from title: lowercase, hyphens (never underscores), strip stop
  words and special characters.
- Uniqueness enforced at the DB level, not just in the form.
- Validation per spec: must start with `/`, no trailing slash, no special chars.
- **Changing a slug auto-creates a 301** from the old path. Non-optional.
- Slug history table: every past slug, the date it changed, and its redirect —
  viewable and editable.

### 3.2 Redirect manager — `seo_redirects`
`source_path` (unique, indexed), `destination_path`, `redirect_type` (301/302/410),
`is_active`, `hit_count`, `last_hit_at`, `created_by`, `notes`.

- Admin CRUD with search, bulk CSV import, bulk export.
- **Loop and chain detection on save.** A → B → A must be rejected outright; a
  chain A → B → C should warn and offer to flatten to A → C.
- `hit_count` tells the SEO team which redirects are live and which are dead weight.
- Served by the edge middleware (Task 0) before the SPA loads, so redirects are
  real HTTP 301s, not client-side `<Navigate>`.

### 3.3 Robots.txt manager
- Editable from admin, served dynamically at `/robots.txt`.
- Syntax validation and a live preview before save.
- Auto-appends the sitemap URL.
- **Guardrail:** a `Disallow: /` on the production host requires a typed
  confirmation. One careless save here de-indexes the entire site, and it is a
  well-known way to lose months of ranking overnight.
- Sensible seeded default: disallow `/account/`, `/host/`, `/admin/`, `/booking/`.

### Acceptance criteria
- [x] Renaming a slug creates a working 301; the old URL resolves to the new one
      with a real `301` status code, checked with `curl -I`.
- [x] A redirect loop is rejected at save time with a clear message.
- [x] `/robots.txt` returns the admin-edited content.
- [x] `Disallow: /` cannot be saved accidentally.
- [x] CSV import of 100 redirects works and reports per-row errors.

---

## Task 4 — XML sitemap manager (spec 1.4)

**Status: DONE and shipped 2026-08-28.** Backend `1aa27ee`, frontend `15435ab`; migration `20260828120000-sitemap` applied to the live database.

> **The seed data is still there, and it shaped this task.** Counted before building: 29,230 listings are live and **29,226 belong to host 100** — four belong to real hosts. `sitemap_exclude_hosts` therefore ships defaulting to `100`. That is not a substitute for deleting the seed listings; it is what makes the sitemap correct while that decision is outstanding. **Clear it once they are gone.**

> Two deviations from the spec, both deliberate: "regenerate on a schedule" is a one-hour cache TTL rather than a cron job (there is no cron in this project), and there is **no ping button** because Google retired that endpoint in 2023 — the screen links to Search Console instead.

### 4.1 Generation
- `/sitemap.xml` as an index; children split at **50,000 URLs / 50 MB** per the
  standard. With ~29,000 listings plus blog and static pages we will be near the
  boundary — split by type from day one: `sitemap-properties.xml`,
  `sitemap-blog.xml`, `sitemap-pages.xml`.
- Auto-regenerate on a schedule (daily/weekly, configurable) **and** on demand.
- Include only `content_status = published` and `robots_index = true`. A page that
  is `noindex` must never appear in the sitemap — the contradiction wastes crawl
  budget and is a common audit finding.
- `<lastmod>` from `page_seo.modified_at`.
- Per-page `<priority>` and `<changefreq>`, editable, with sane defaults by type.

### 4.2 Image and video sitemaps
- Image sitemap entries per spec (`<image:image>`, `<image:loc>`, `<image:title>`,
  `<image:caption>`), fed by Task 6.
- Video sitemap support where property video exists.

### 4.3 Management dashboard
- Total URLs, number of child sitemaps, added since last run, removed since last
  run, last generated timestamp, generation duration.
- Manual "Regenerate now" button.
- One-click ping to Google and Bing after generation.

### Acceptance criteria
- [x] `/sitemap.xml` validates against the sitemaps.org schema.
- [x] URL count reconciles with published entities (verify against a DB count).
- [x] A newly published listing appears within one generation cycle.
- [x] An unpublished or `noindex` listing disappears from the sitemap.
- [ ] Google Search Console accepts the sitemap without warnings. **Needs a human with GSC access, and should wait until the seed listings are deleted.**
- [x] Generation completes without timing out — measured at 21 URLs with host 100 excluded. **Not exercised at 29k**, because the whole point is that those listings are never in it.

---

## Task 5 — Breadcrumb management (spec 1.5)

**Status: net-new.**

- `breadcrumb_title` and `breadcrumb_parent_id` on `page_seo` (Task 2.1).
- Custom breadcrumb path override for pages whose natural hierarchy is wrong.
- Visible breadcrumb UI on public pages — property, blog, category, static.
- `BreadcrumbList` JSON-LD emitted alongside (feeds Task 8).
- Cycle detection on parent assignment.
- Sensible auto-derivation so the SEO team is not hand-building 29,000 trails:
  `Home › Stays › Goa › Anjuna › <property>` from existing location data.

### Acceptance criteria
- [ ] Breadcrumbs render on all four public page types.
- [ ] `BreadcrumbList` JSON-LD passes Google's Rich Results Test.
- [ ] Breadcrumbs appear in a Google SERP preview for a test URL.
- [ ] A parent loop is rejected.

---

## Task 6 — Image SEO optimisation (spec 1.6)

**Status: net-new for metadata; delivery partially exists (Cloudinary). Revised 24–30 → 14–18 hrs** — no 29k backfill; ALT text is captured at upload from day one.

### 6.1 ALT text and metadata
- `image_seo` table keyed on the attachment record: `alt_text` (required),
  `title_text`, `caption`, `seo_filename`.
- ALT text **required** on upload for any public-facing image. Enforce in the
  listing wizard and the blog editor.
- Filename normalisation on upload: lowercase, hyphens, keyword-bearing —
  `goa-villa-private-pool.jpg`, not `IMG_2049.jpg`.

### 6.2 Format and delivery
- WebP variants generated automatically; AVIF optional per spec.
- Cloudinary already handles transformation — this is mostly wiring `f_auto,q_auto`
  and correct `srcset`/`sizes` rather than new infrastructure.
- Lazy-loading below the fold; `fetchpriority="high"` on the LCP hero image.

### 6.3 Bulk tooling — required for our scale
- A "missing ALT text" report across all 29k listings.
- Bulk ALT editor with a template (`{property_name}, {city} — {room_type}`) so the
  SEO team can fill thousands of gaps in a sitting rather than one at a time.
  Without this, 1.6 is technically complete and practically unusable.

> **PII precedent — read before running any bulk image job.** Seeded listings once
> published a real person's CV as a property photo (fixed 2026-08-03), and the
> Cloudinary account is shared and polluted (704 assets, may hold more PII). Any
> bulk pass over the image library must include a human review gate before
> anything new becomes publicly indexable. Making images *more* discoverable to
> Google Images raises the cost of that mistake considerably.

### Acceptance criteria
- [ ] Uploading a listing image without ALT text is blocked with a clear message.
- [ ] Uploaded filenames are normalised.
- [ ] WebP is served to supporting browsers; original to others.
- [ ] The missing-ALT report returns an accurate count, reconciled against the DB.
- [ ] Bulk ALT apply updates N records and is reversible.
- [ ] Images appear in the image sitemap with title and caption.

---

## Task 7 — Open Graph & social SEO (spec 1.7)

**Status: partial — `useDocumentMeta` sets `og:title`/`og:description`/`og:url`
client-side only, which no social scraper executes.** Depends on Task 0.

- Full `og:*` and `twitter:*` sets from `page_seo` (fields defined in Task 2.1).
- Fallback chain per spec: page OG image → featured image → first content image →
  `global_seo.default_og_image_url`. Never emit an empty `og:image` — a link with
  no preview underperforms one with a generic preview.
- **Live social preview in admin** for Facebook, Twitter/X, LinkedIn and WhatsApp,
  updating as the SEO team types.
- Buttons that open Facebook Sharing Debugger and Twitter Card Validator
  pre-filled with the current URL.
- OG image dimension validation on upload: warn if not 1200×630 / 1.91:1.

### Acceptance criteria
- [ ] Pasting a property URL into WhatsApp shows that property's image and title.
- [ ] Same for Facebook, LinkedIn, Twitter/X, Slack.
- [ ] Admin preview matches what the real platforms render.
- [ ] A page with no OG image set still previews using the global default.

---

## Task 8 — Schema markup, basic (spec 1.8)

**Status: partial. Revised 28–34 → 16–20 hrs** — `listingSeo.js` already emits full `LodgingBusiness` JSON-LD per listing; this task wires it out and adds the other types. Depends on Task 0.

### 8.1 Types required in Phase 1
| Type | Applies to |
|---|---|
| `Organization` | Site-wide, from `global_seo` |
| `WebSite` + `SearchAction` | Homepage — enables sitelinks search box |
| `Article` / `BlogPosting` | Blog posts |
| `LocalBusiness` / `LodgingBusiness` | Property pages |
| `BreadcrumbList` | All (Task 5) |
| `FAQPage` | FAQ pages — `tbl_faqs` already exists |

`LodgingBusiness` is the correct type for our listings and should carry `address`,
`geo`, `priceRange`, `starRating`, `amenityFeature` and `aggregateRating` — all of
which we already store.

### 8.2 Generation and validation
- Auto-populate from existing data; allow per-page override via `schema_json`.
- **Server-side validation on save** — reject malformed JSON-LD before it can ship.
- JSON-LD preview panel in admin.
- "Test with Google" button → Rich Results Test, pre-filled.

### 8.3 Rating honesty guardrail
`aggregateRating` must only be emitted where genuine reviews exist. Emitting a
rating on a listing with no reviews is a manual-action risk with Google and should
be blocked at the generator, not left to editorial discipline.

### Acceptance criteria
- [ ] Every public page type emits valid JSON-LD, confirmed by Rich Results Test.
- [ ] Schema Markup Validator reports zero errors on a sample of each type.
- [ ] Malformed hand-edited JSON is rejected at save.
- [ ] `aggregateRating` is absent on zero-review listings.
- [ ] Organization schema reflects `global_seo` values.

---

## Task 9 — SEO team enablement (added, not in spec)

The spec defines fields. This task is what makes those fields usable by a
non-developer SEO team on day one — the user's stated goal of "complete
functionality to do their work".

### 9.1 SEO role and permissions
- New `seo_manager` role in the existing RBAC system.
- Access to: all SEO screens, blog, CMS pages, redirects, sitemap.
- **No** access to: bookings, payments, payouts, user PII, host KYC.
- The SEO team must not need a super-admin login to change a meta description.

### 9.2 SEO health dashboard
Landing screen answering "what needs my attention?":
- Pages missing meta title / description
- Titles over 60 chars, descriptions outside 120–160
- Duplicate titles and duplicate descriptions across pages
- Pages with no canonical
- Images missing ALT text
- Orphan pages (no internal links in)
- Broken internal links and redirect chains
- `noindex` pages currently sitting in the sitemap

Each row links straight to the editor for that item.

### 9.3 Bulk operations
At 29,000 listings, per-page editing is not a workable interface. Required:
- Bulk edit meta title / description via template variables
  (`{property_name} in {city} — Book from ₹{price} | Aajao`)
- Bulk robots changes with a preview of affected count before applying
- CSV export of all SEO fields → edit in a spreadsheet → re-import with a diff
  preview. This is how SEO teams actually work.

### 9.4 Change log
- Every SEO field change recorded: who, what, before, after, when.
- Filterable, exportable, with one-click revert.
- Non-negotiable when several people can change what Google sees.

### Acceptance criteria
- [ ] An SEO user logs in, edits metadata, and cannot reach bookings or payments.
- [ ] Health dashboard counts reconcile against direct DB queries.
- [ ] Bulk template edit updates 1,000 listings correctly and is revertible.
- [ ] CSV round-trip preserves every field.
- [ ] Change log shows before/after for a test edit.

---

## Task 10 — Generator & template engine (added)

**Status: extend `utils/listingSeo.js`. 20–26 hrs.**

This is the task that turns "SEO is generated automatically" from an
implementation detail into something the SEO team controls.

### 10.1 Fix the generator's limits and copy
- `metaTitle` → 60 chars, `metaDescription` → 120–160, per spec. Truncating at
  255 and 500 today means the generated copy was never written to fit a SERP.
- Rewrite both patterns to read well inside the real limits, with graceful
  degradation when a property name is long.

### 10.2 Extend it to the spec's remaining fields
- OG and Twitter sets, derived by default from meta title/description and the
  first listing image.
- Canonical, robots (from content status), breadcrumb title and parent,
  `published_at` / `modified_at`.

### 10.3 Editable templates
- A `seo_templates` table: one row per entity type, holding the title and
  description patterns with variables — `{property_name}`, `{city}`,
  `{district}`, `{state}`, `{category}`, `{price}`, `{top_amenity}`.
- Admin editor with a live preview rendered against a real sample listing, and
  a character counter on the rendered output rather than the raw pattern.
- Validation: reject a template that cannot fit 60 chars for a realistic worst
  case, and warn on one that produces identical output across listings (mass
  duplicate titles are a ranking problem, not just an aesthetic one).

### 10.4 Regeneration
- Regenerate a listing's SEO record when the listing is edited — already the
  behaviour at step 5, extend it to post-publish edits.
- Regenerate **in bulk when a template changes**, as a queued job with a
  preview of the affected count and a dry-run diff before applying.
- Never overwrite a field an editor has manually overridden. Overrides need an
  explicit "revert to template" action.

### 10.5 Blog and static page equivalents
- The same generator shape for blog posts (from title, excerpt, category) and
  for static pages (from a per-page template).

### Acceptance criteria
- [ ] A brand-new listing published through the wizard has a complete, valid
      SEO record with no human input, and its page serves correct meta and
      JSON-LD to a bot user agent.
- [ ] Generated titles are ≤ 60 chars and descriptions 120–160 across a sample
      of 50 listings with varied name lengths.
- [ ] SEO team edits the title template; a dry run reports the affected count;
      applying it updates all non-overridden listings.
- [ ] A manually overridden title survives a template change.
- [ ] "Revert to template" restores the generated value.
- [ ] A blog post published with no SEO input still gets valid metadata.

---

## Cross-cutting requirements

**Data integrity**
- Every SEO write goes through yup with all fields explicitly declared —
  `stripUnknown` silently drops anything undeclared, and the failure is invisible.
- Slug and `source_path` uniqueness enforced by DB constraint, not app logic.

**Performance**
- Edge SEO lookup must not regress TTFB by more than 50 ms p95.
- Sitemap generation over 29k listings must run without timeout — batch it.
- The health dashboard's aggregate queries need supporting indexes.

**Verification discipline (repo-specific)**
- Web deploys run `tsc -b`. `tsc --noEmit -p tsconfig.json` **misses errors** and
  has previously let a commit ship that never published. Verify with `tsc -b`.
- Check `git status` in all three repos before blaming a deploy — finished work has
  sat uncommitted here before.
- Backend migrations run against the live DB; write the rollback path first.

**Testing**
- Backend unit tests for slug generation, redirect loop detection, robots
  computation, sitemap inclusion rules, schema generation.
- One end-to-end crawler test per page type, asserting on raw HTML fetched with a
  bot user agent — not on the rendered DOM. Testing the DOM would pass while the
  actual product stays broken, which is precisely the Task 0 failure mode.

---

## Open questions for the client / SEO team

1. **Task 0 approach** — confirm Option C (edge injection). Option A (Next.js
   migration) is architecturally cleaner but is a multi-week rewrite and would
   push Phase 1 well past the Months 1–2 window.
2. **Task 0 hours** — the rendering layer is not in the spec's 200–300 hour
   budget. Confirm the total moves to ~250–310, or confirm what drops.
3. **Property URL migration** (Task 2.4) — moving `/property?id=` to
   `/property/:slug` is the single highest-value SEO change available to us, and
   it touches shared links and any indexed URLs. Confirm we should proceed with
   permanent redirects.
4. **`hreflang`** — spec mentions alternate languages. Is a non-English version
   actually planned? If not, we build the field and leave it empty rather than
   building the full multi-language pipeline.
5. **Who owns content status?** — if the SEO team can set pages to `archived`
   (`noindex`), that is a live-traffic-affecting action. Confirm whether it needs
   an approval step.
6. **Image bulk pass** — given the prior PII incident, confirm the human review
   gate before any bulk image-indexing work (Task 6.3).

---

## Suggested sequencing

| Weeks | Work |
|---|---|
| 0 | **Delete the seed dataset** — after an index check, before anything ships |
| 1–2 | Task 0 (rendering) + Task 1 (global settings) |
| 3–4 | Task 2 (page-level) + Task 3 (URLs/redirects) |
| 5–6 | Task 4 (sitemap) + Task 8 (schema) |
| 7 | Tasks 5, 6, 7 (breadcrumbs, images, social) + Task 10 (generator/templates) |
| 8 | Task 9 (enablement) + full QA pass |

Tasks 0 and 1 in week 1–2 mean the SEO team can verify Search Console and see real
per-page metadata almost immediately, rather than waiting until week 8 to find out
whether any of it reaches a crawler.
