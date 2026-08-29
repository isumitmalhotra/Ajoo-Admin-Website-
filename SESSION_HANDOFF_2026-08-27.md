# Session handoff — 27 August 2026

**Read this first in the next session.** Everything below is verified against
the running system, not remembered.

Subject: **SEO CMS Phase 1** — spec `AAJAO HOMES - CMS SEO FUNCTIONAL
REQUIREMENTS SPECIFICATION.docx` (in Downloads).

---

## 1. TL;DR

| | |
|---|---|
| **Tasks 0, 1 and 2 are DONE and LIVE** on www.aajoohomes.com | 3 of 11 |
| Both repos | **clean, committed, pushed, deployed** on `main` |
| Migrations | **2 applied to the live database** |
| Acceptance | 58/58 site · 27/27 API · 85 backend unit · 54 frontend unit |
| Phase 1 progress | ~95–110 of 224–280 hrs, roughly **40%** |
| Next | **Task 3** — redirects manager + `robots.txt` (the site has neither) |

Nothing is half-finished. There is no uncommitted work anywhere.

---

## 2. What shipped

### Task 0 — the SEO rendering layer

**The problem:** the site is a Vite SPA and `vercel.json` sent every URL to the
same `index.html`. All ~29,000 listings shared one `<title>` and one Open Graph
block pointing at the home page. Every link pasted into WhatsApp previewed as
the home page. `useDocumentMeta` fixed it in the browser — but Bingbot largely
doesn't run JS and no social scraper does at all.

**What was built:**

| Where | What |
|---|---|
| `aajaoBackend-render/utils/seoResolve.js` | Resolves any path to its `<head>`. Never throws. |
| `.../config/seoDefaults.js` | Static-page copy, **extracted** from the SPA's `cmsSchema.ts`, not retyped |
| `.../utils/seoCache.js` | 60s read cache (the MySQL pool allows 5 connections) |
| `.../routes/seo.routes.js` | `GET /seo/resolve?path=` |
| `.../middleware/rateLimiter.js` | `seoLimiter` — see §5 |
| `aajao-frontend-vercel/api/seo-render.ts` | The edge function |
| `.../api/_seoHead.ts` | The pure, testable half |
| `.../middleware.ts` | Routes `/` only — see §5 |
| `.../vercel.json` | `/((?!api/\|index\.html).*)` → the renderer |

### Task 1 — global SEO settings

`global_seo` (one row, 26 writable columns) + `/admin/seo` + `GET|POST
/admin/seo/global` + public `GET /seo/global`. Verification codes, default
metadata, title template, social defaults, branding, analytics IDs.

**Plus a cookie consent banner** (`src/redesign/lib/consent.ts`,
`components/CookieConsent.tsx`) which was not in the spec at all but without
which the analytics switch could never legally be turned on.

### Task 2 — page-level SEO

`page_seo` (one row per entity, 31 writable columns), **one canonical address
per listing and post**, and the reusable `<SEOPanel>` at `/admin/seo/page`.

---

## 3. Exact state

### Branches and commits — both repos on `main`, clean

**`D:\Projects\aajaoBackend-render`** (→ `nameeshPatiyal100/aajaoBackend`, Render auto-deploys `main`)

```
43eac5a feat(seo): the API behind the per-page SEO panel
d183aa7 feat(seo): per-page SEO, and one address per listing and post
787ae3f feat(seo): make the title separator actually change titles
666faf6 fix(seo): keep the admin cache-buster out of the canonical
54ec21f fix(seo): a settings form cannot save what it loaded an hour ago
69028a4 feat(seo): site-wide settings the SEO team can change themselves
db845f1 feat(seo): resolve per-path metadata so crawlers stop reading one title
```

**`D:\Projects\aajao-frontend-vercel`** (→ `nameeshPatiyal100/Aajao-Admin-WebSIite`, **a push to `main` deploys straight to PRODUCTION**)

23 commits, `2727233` → `572018c`. Two are reverts of a failed attempt — see §5.

Both PRs from earlier in the session are merged and their branches deleted.

### Migrations — APPLIED to the live database

```
up 20260827090000-global-seo.js
up 20260827140000-page-seo.js
```

Migrations do **not** run on deploy in this project. They were run by hand:

```bash
cd D:/Projects/aajaoBackend-render
npm install --no-save sequelize mysql2 sequelize-cli && npx sequelize-cli db:migrate
```

`page-seo` also added `tbl_blogs.blog_slug` and backfilled 16 slugs from titles,
and copied the 4 existing `property_seo` rows into `page_seo`.

### Production, verified minutes before this was written

```
https://aajaodev.onrender.com/seo/global      200
https://www.aajoohomes.com/about              200
https://www.aajoohomes.com/property?id=29262  301 → /property/malhotra-villa-karnal-haryana
```

---

## 4. How to verify anything

```bash
# Backend unit tests (85, no database needed)
cd D:/Projects/aajaoBackend-render && npm run test:seo

# Backend API round-trip (27, needs a running API — safe against production)
npm run test:seo:api -- --api https://aajaodev.onrender.com --property 29262

# Frontend unit tests (54, runs the real code against the real index.html)
cd D:/Projects/aajao-frontend-vercel && npm run test:seo

# Full site acceptance (58) — raw HTML, per crawler user agent
npm run seo:accept -- --origin https://www.aajoohomes.com --property 29262 --blog 16

# Global settings acceptance (10) — writes to production and RESTORES itself
npm run seo:accept:global -- --user <admin email> --pass <password>
```

`x-seo-render` on any response says which path it took: `render:property`,
`render:static`, `render:blog`, `render:unknown` (404), `skip:private`,
`skip:asset`, `redirect`, `fallback`, `shell-passthrough`.

---

## 5. Traps — read before touching anything

These each cost real time or caused a real outage.

### The 508 loop (a 12-minute production outage)

`middleware.ts` must match **`/` and nothing else**. The renderer fetches
`${origin}/index.html` to read the shell; matching that path made it ask itself,
forever, and `/` and `/index.html` returned `508 Loop Detected`.

**Three guards now, all required:**
1. `vercel.json` excludes `index.html` from the rewrite
2. the function refuses to fetch a shell when it is being asked *for* the shell
3. the retry branch validates the body before serving it

Mutation-tested: remove guard 2 and the loop test fails.

### Deployment order is not optional

**Frontend first, then backend.** The backend publishes slug canonicals, and
without the SPA's `/property/:slug` route those canonicals point at the 404
page. This was caught in a browser, not by a test.

### `tsc -b` can pass while the build fails

`@vercel/edge` was in `node_modules` but not in `package.json` (a revert had
removed it). The build machine installs from the manifest. **A local typecheck
only proves what a clean install would if the manifest and the disk agree.**

### Tests can share one module instance

The handler is imported from a `data:` URL built from bundled source. Node caches
ES modules by URL and the source is byte-identical every time, so every test
shared one instance *and its module-scope caches* — the loop test passed with the
guard removed. `freshHandler()` adds a unique marker per load.

### `stripUnknown` deletes undeclared fields, silently

`middleware/validation.js` validates with `stripUnknown: true`. A field added to
a form and a table but not to the yup schema **appears to save and never
persists**, with no error anywhere. Both round-trip tests walk every writable
field for exactly this reason.

### Icons that do not exist render as a bare circle

`image`, `save`, `loader` and `palette` are **not** in `src/redesign/lib/iconMap.ts`
(77 icons). `Icon.tsx` warns in the dev console. Three bad icons shipped past a
typecheck and full API tests, and `loader` only renders *while saving* so no test
could reach it. **Read the dev console when reviewing a screen**, and check:
`[...document.querySelectorAll('svg')].map(s=>s.getAttribute('class'))` for
`lucide-circle`.

### A patch that spans landmarks deletes what is between them

One slice took five functions with it — `getStaticPage`, `propertyImage`,
`safeJson`, `resolveProperty`, `resolveBlog`. Bound structural edits by brace
counting, and assert the span holds exactly one function.

### Shell heredocs mangle escapes

`<<'PYEOF'` turned `\n` inside a JS string into a real line break three separate
times, leaving unterminated strings. **Write patch scripts to a file** (the
`D:\aajoo_patch\*.py` pattern) instead.

### Git Bash rewrites leading-slash arguments

`curl -G --data-urlencode "path=/about"` became
`path=C:/Program Files/Git/about`. Set `MSYS_NO_PATHCONV=1`, but note it then
breaks `/tmp/...` output paths.

### Latency cannot be measured naively

This check gave three contradictory answers in one session. It must compare the
**same function** on a rendered path against a skipped one (isolating this layer
from Vercel's cost of running a function at all), and **interleave** the samples
(sequential batches drift). It is stable at ~0ms now.

---

## 6. Design decisions worth not re-litigating

**Analytics are never server-injected.** A script tag runs when the document
parses, before anyone has been asked anything. They load in the browser after
consent, and the IDs are fetched only then — a visitor who declines never
receives them. `analytics_enabled` defaults off.

**Copy is carried as authored, never truncated.** Clamping titles cut the home
page's to `...Across India |` and made the crawler read something the visitor
never saw. Enforcing the spec's 60/160 means *rewriting* copy to fit — Task 10.

**Precedence is `page_seo` > `property_seo` > derived.** An admin edit survives
the host re-saving the wizard: an override that regeneration undoes is not an
override.

**Robots are computed on the server** from spec 1.2's status table, and need
**three** entity states — `published`, `draft` (nofollow too), `hidden` (noindex
only). A boolean collapses the last two, which the spec distinguishes.

**Slugs need no backfill.** Only 4 of 29,000 listings have a stored one and the
rest are seed data due for deletion, so a listing without one derives
`name-<id>` — unique by construction and still findable if someone edits the
words in a shared link.

**`property_seo` is left in place** and still written by `listingStep5`. The
migration is additive; a rollback that dropped the only copy of a host's work
would not be a rollback.

---

## 7. Known gaps and open decisions

### Needs a decision from the client

1. **`analytics_enabled` is still off.** The consent banner exists, so it is now
   legal to switch on — it just needs the real GA4/GTM IDs.
2. **`website_title` is "Aajoo".** Task 2's template normalises the brand in
   every generated title to this value, so blog and 404 titles changed from
   `| Aajoo Homes` to `| Aajoo`. One field reverses it everywhere.
3. **The 29k seeded listings.** Still not deleted. Check indexing with
   `site:aajoohomes.com` and Search Console first; serve `410` not `404` if any
   are indexed; **delete before the sitemap ships (Task 4)**.

### Accepted limitations

- **CDN purge is impossible on this plan.** The Vercel project is on **Hobby**;
  cache-tag invalidation is Enterprise. Propagation is ~40s (CDN 30s + edge memo
  10s). The admin screen's "Check the live site" button exists because of this.
- **Body content is still client-rendered.** The `<head>` is fixed; body-text
  ranking still depends on Google's render queue. Full SSR is Phase 2.
- **The X Card Validator was retired in 2022.** Replaced with the checks it
  made, including fetching the image.

### Loose ends

- **`organization_name` / `organization_legal_name` are stored and unused.** The
  `Organization` schema is still hardcoded in `index.html`. Same class as the
  branding gap that was fixed — **belongs to Task 8, but it is live and
  misleading now.**
- **Breadcrumb columns exist in `page_seo` with no controls.** Deliberate — Task 5.
- **`npm test` in the backend has never worked**: `scripts/check-syntax.js` and
  `tests/admin/index.test.js` do not exist. A background task was spun off for
  this; its worktree `.claude/worktrees/suspicious-merkle-6aa564` is still
  present and **its outcome is unknown** — check it.
- **The local edge harness (`npm run seo:serve`) stopped binding reachably** in
  the agent shell late in the session. Verification fell back to production,
  which is backwards and is what caused the outage. **Worth fixing before Task 3.**

---

## 8. Next: Task 3

**URL management, redirects and `robots.txt` — 26–32 hrs.**

The site has **no `robots.txt` and no `sitemap.xml` at all**. Task 2 just created
the slug URLs a sitemap would list, so 3 → 4 is the natural order.

Scope:
- Slug editor with history, and a 301 created automatically on every change
- `seo_redirects` table with **loop and chain detection**, CSV import/export,
  hit counts
- `robots.txt` served dynamically from admin, with a typed confirmation before
  `Disallow: /` can be saved — one careless save de-indexes the whole site
- **Redirects must be served by the edge**, as real 301s, the same way Task 2's
  are

Remaining after that: **4** (sitemap), **5** (breadcrumbs), **6** (image SEO),
**7** (~6–8 hrs left), **8** (~10–12 hrs left), **9** (team enablement),
**10** (generator/templates).

---

## 9. Where everything is

| | |
|---|---|
| Full Phase 1 plan | `SEO_CMS_PHASE1_TASKLIST.md` (this repo) |
| Shareable plan | https://claude.ai/code/artifact/94178ce5-c02f-401f-831f-85cf73b245bb |
| Before/after walkthrough | https://claude.ai/code/artifact/fb5d8dab-e5ed-46c5-9c9b-adeb9722ec6f |
| Agent memory | `~/.claude/projects/D--Projects-ajoo-admin-website/memory/seo_cms_phase1.md` |
| Test accounts | admin `admin@mailinator.com` / `Admin@123` |
| Probe listing | property **29262** (Malhotra Villa) — has a real photo and a stored slug |
| Probe post | blog **16** (slug `test`); blog **14** is a **draft**, useful for robots checks |

Deploy topology, the live-DB migrate command and the other test accounts are in
`memory/repo_deploy_topology.md`.
