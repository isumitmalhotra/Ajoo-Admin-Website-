# Session Handoff — 2026-08-21

Successor to `SESSION_HANDOFF_2026-08-13.md`. That file is still accurate for
everything before it; **read it second** for the longer-running project
context. This file covers what changed since and what to do next.

> ## ⚠️ READ THIS FIRST — THE STATE IS NOT CLEAN
>
> **Three commits on the web repo are committed but NOT pushed and NOT
> deployed.** Production (`www.aajoohomes.com`) does not have any of this
> session's work. The user noticed this and asked about it directly.
>
> **Nothing in this session was verified in a browser.** The browser tooling
> (`claude-in-chrome`) disconnected partway through and never came back. Every
> change below was verified by TypeScript, the production build, and code
> inspection only. That is a real gap, not a formality — the work is
> substantial UI restructuring of the site-wide header.
>
> **A Vite dev server was left running** on `http://localhost:5173`
> (also `http://192.168.1.5:5173` for phone testing on the same Wi-Fi).
> It may or may not still be alive in your session. Restart with
> `cd "D:/Projects/aajao-frontend-vercel" && npm run dev -- --host`.
>
> **The single most useful thing you can do first: get eyes on the header.**

---

## 1. What this project is

Aajoo Homes — a negotiation-first stay marketplace for India. Guests browse
stays, can **negotiate the price with the host** before booking, and book
either online (Razorpay) or pay-on-arrival. Hosts list properties and get paid
out after checkout, minus commission. Admins verify listings, moderate, and run
finance.

### Three repos, three deploy targets

| Path | Repo | Deploys to | Push command |
|---|---|---|---|
| `D:\Projects\aajao-frontend-vercel` | `nameeshPatiyal100/Aajao-Admin-WebSIite` | **Vercel** → `www.aajoohomes.com` | **`git push origin HEAD:main`** |
| `D:\Projects\aajaoBackend-render` | `nameeshPatiyal100/aajaoBackend` (private) | **Render** → `aajaodev.onrender.com` | `git push origin HEAD:main` |
| `D:\Projects\ajoo admin website` | monorepo — holds `aajoo_app_2026/` (Flutter) + all docs | not deployed; app ships as APK | `git commit` (no push configured) |

> ⚠️ **The frontend push trap.** The local branch is `redesign/aajoo-2026`, not
> `main`. A plain `git push origin main` pushes the stale local `main` and is
> rejected non-fast-forward. Always `git push origin HEAD:main`.

> ⚠️ **Vercel: `git push` only builds a PREVIEW.** Production needs an explicit
> deploy, and `.vercel/project.json` pins a stale `orgId`, so the `--scope` flag
> is mandatory or you get "Not authorized" even though `whoami` succeeds:
> ```bash
> npx vercel deploy --prod --yes --scope nameeshpatiyal100s-projects
> ```

### Stack

- **Web**: React + Vite + TypeScript, Redux Toolkit. Redesigned surfaces live
  under `src/redesign/`; legacy pages under `src/pages/`.
- **Backend**: Node/Express/Sequelize/MySQL (Clever Cloud), on Render.
- **Mobile**: Flutter + GetX in `aajoo_app_2026/` (`com.aajoo.aajoohomes`).

---

## 2. Exact repo state at handoff

### Web — `D:\Projects\aajao-frontend-vercel`
Branch `redesign/aajoo-2026`. Working tree clean. **`origin` is at `2aee955`;
you are 3 commits ahead of it and 49 ahead of `origin/main`.**

| SHA | What | Pushed? | Live? |
|---|---|---|---|
| `6a7d6f1` | One search, expanded at top / collapsing on scroll | ❌ | ❌ |
| `88e96b7` | Drop HOMES from wordmark, retire nav link row | ❌ | ❌ |
| `40f870a` | Map markers open the property again + themed 404 | ❌ | ❌ |
| `2aee955` | (last pushed commit — phone home geolocation + search) | ✅ | ✅ |

Files touched across the three: `App.tsx`, `Footer.tsx`, `Logo.tsx`,
`MobileHome.tsx`, `NavSearch.tsx` (new), `TopNav.tsx`, `Explore.tsx`,
`Login.tsx`, `NotFound.tsx` (new), `aajoo-system.css`.
771 insertions, 213 deletions.

### Backend — `D:\Projects\aajaoBackend-render`
Branch `main`, **clean and fully pushed.** Last three commits are from earlier
sessions and are already live on Render:
`5b3b5f5` drafts status · `69519a5` app→host negotiation fix · `6c87133`
checked-in stay ordering.
**No backend work was done this session.**

### Flutter — `D:\Projects\ajoo admin website`
Branch `main`, last commit `eeb7bdf`. One stray deletion in the working tree:
a Excel lock file `~$_Web App Bugs — STATUS 2026-08-16.xlsx`. Harmless; commit
or restore it.
**No Flutter work was done this session** — so web and app are now out of
parity on the header/search work (see §7).

---

## 3. What happened this session, in order

### 3a. Themed 404 + a broken property link (`40f870a`)

The user zoomed the map, tapped a property marker, and got a broken page.

**Root cause:** the route is `<Route path="/property">` and `PropertyDetail`
reads its id from the query string (`sp.get("id")`), but `MobileHome`
navigated to `/property/${id}` — a path segment. No route matched, so it fell
through to the catch-all 404.

**Blast radius was wider than reported:** the client hit it via a map pin, but
**every stay card in all four rails on the phone home** used the same wrong
URL form. Both call sites fixed to `/property?id=${id}`.

**The 404 they landed on** was a pre-redesign MUI screen (full-bleed
`404.jpg` over `#EFE7D6`, navy button) and — because the catch-all sat *inside*
`CommonLayout` — it arrived wrapped in the legacy header and footer. Three
design languages on one page.

Replaced with `src/redesign/pages/NotFound.tsx`: redesign tokens, brings its
own chrome (TopNav + Footer on desktop, `PublicTabbar` on mobile), search box
as the primary control, four "ways on", and it prints the path the user
actually requested. It deliberately does **not** guess a listing from the URL —
no reliable mapping exists and a confident wrong guess is worse than an honest
dead end. The catch-all moved out of `CommonLayout` to be the last top-level
route (last of 144; React Router ranks by specificity anyway, so this is
belt-and-braces).

### 3b. Wordmark + nav rebuild (`88e96b7`)

**User:** *"Show only aajoo remove homes from here navbar Team asked me to
remove that"* and *"Remove the nav bar menu take reference of airbnb"*.

**Wordmark:** the lockup stacked `aajoo` over a letterspaced `HOMES`. Removed
in the shared `Logo` component rather than only the navbar, because the same
mark renders in the footer, both auth pages, Getting Started, Host Landing and
both dashboards — a header saying "aajoo" over a footer saying "aajoo HOMES"
is worse than either alone. `Footer.tsx` and `Login.tsx` keep their own copies
of the markup, so those were edited too.

**Deliberately kept:** the admin portal's `aajoo ADMIN` (a portal label, not
the brand, and the only thing distinguishing that header), and the company
name in copy/titles/accessible names. This is a change to the lockup, not the
name. **The `.logo .homes` CSS rule still exists and now serves only
AdminShell** — there is a comment on it saying so.

**Nav:** removed the six-link row (`Explore Stays`, `Pre-Booking`, `Become a
Host`, `About Us`, `Contact`, `Help Center`) plus `Getting Started`. Checked
Airbnb's actual current header rather than working from memory (via WebSearch
+ WebFetch — see Sources at the bottom). Its structure is three zones and,
crucially, **no top-level link row at all**: browsing lives in the search,
every destination lives in the account menu. So the six links went into a
single right-hand menu, grouped browse / company.

Also retired **GS-7's scroll-reveal**: an animation whose entire job was
hiding five of six links until you scrolled 64px, plus the `ResizeObserver`
that checked whether the page was tall enough for that to be safe.

### 3c. The correction — two searches on one screen (`6a7d6f1`)

**User came back with four Airbnb screenshots** and said the search was
*"something different and stuck up there"*, that there was a second
older search bar below it, and *"now we can't show 2 searches at one place"*.

Both complaints were correct and had one cause:

1. The pill I built in `88e96b7` was **always compact and static**. Airbnb's is
   **expanded at the top of the page and collapses to a pill on scroll.**
2. The Explore hero still carried **its own full search card** (Destination /
   Check-in / Check-out / Guests / Search / Browse-on-map) tucked under the
   banner. So the top of the homepage showed two searches keeping separate
   state.

**Fix:** the search is now one control with two shapes, in a new component
`src/redesign/components/NavSearch.tsx`.

| State | Shape | Trigger |
|---|---|---|
| at rest | full bar on its own row under the nav — `Where │ When │ Search` | `scrollY <= 120` |
| scrolled | pill in the nav row — `Anywhere · Any week ○` | `scrollY > 120` |
| reopened | full bar again | clicking the pill (scrolls to top, sets `reopened`) |

Collapse fires at **120px**, not the 8px that drives the header shadow — at 8px
a trackpad nudge flickers it between forms.

**The bar is real, not a link:**
- **Where** — live destination lookup. Typed queries hit
  `/public/geocode/search` debounced at 350ms via `searchPlaces()`. An empty
  field offers the top six destinations by **live inventory**
  (`getDestinations(6)`), so every suggestion leads to actual results rather
  than a hardcoded wishlist landing on an empty page.
- **When** — opens the existing `DateRangeCalendar`.
- Picking a destination auto-advances to dates, as the reference does.
- Submits to `/search?q=&from=&to=`.

**Explore's search card was deleted**, along with the now-dead `SearchField`
component, its calendar state, its outside-click handler, and the
destination/date reads in `go()` that nothing could set any more. `go()` now
only takes what tiles and rails pass in.

---

## 4. THE OPEN DESIGN DECISION — "Who / Add guests"

**This will come up. Have the answer ready.**

The client's screenshots show Airbnb's three segments — Where / When / **Who**
— including the guest stepper popover (Adults / Children / Infants / Pets).
**Our bar ships with two segments. There is no Who.**

Why, verified in code this session:

- `searchProperties()` in `src/services/customerApi.ts` posts to
  `/properties/search` and accepts exactly: `latitude`, `longitude`,
  `category`, `radius`, `isLuxury`, `limit`. **There is no guests parameter.**
- There is **no capacity field on a listing** to match a guest count against.
  `no_of_guests` exists on a *booking* (`src/redesign/lib/bookingDraft.ts`,
  `useBookings.ts`), not on a property.
- The guests field on the Search page (`Search.tsx:217`) is a `readOnly`
  placeholder reading "2 Guests, 1 Room" — decorative, and always has been.

So a Who segment would put a picker in front of people that changes nothing
about their results. **It needs a backend change first**: a capacity column on
the listing (the wizard may already collect it — check the 24 modular tables)
plus a `guests` filter on `/properties/search`.

**If the client insists**, that is a legitimate scoped task — but say plainly
it is backend-first, and don't ship a third segment that only decorates.

---

## 5. What to verify first (nothing here has been seen)

Start the dev server, then walk this list. Use a real phone on
`http://192.168.1.5:5173` for the mobile checks — better than devtools
emulation, and note that **`requestAnimationFrame` is frozen in a hidden
browser pane**, which silently kills smooth-scroll and Leaflet's animated
zoom in automated harnesses (a known trap from earlier sessions, not a bug).

1. **`/explore` at the top** — full search bar on its own row under the nav.
   One search only; the old Destination/Check-in card should be gone.
2. **Scroll down** — the bar collapses to a pill in the nav row at ~120px.
   Watch for flicker.
3. **Click the pill** — scrolls to top and reopens the bar.
4. **Where field** — click it: should show six real destinations with stay
   counts. Type "goa": geocode suggestions after ~350ms. Pick one → advances
   to When.
5. **When field** — calendar opens, range picks, closes.
6. **Search** → lands on `/search?q=…&from=…&to=…` with results.
7. **Phone width** — bar stacks vertically, button spans full width, popovers
   anchor to the viewport (a 340px panel would otherwise run past a 375px
   screen). **Check LUXE mode too** — the toggle reads "EXIT LUXE" there and
   eats ~110px of a 375px bar.
8. **The menu** (right side) — open it logged out *and* logged in
   (`sumit.m@zyphextech.com` / `Haryana@2706`). Top section changes; everything
   from the old link row should be there.
9. **Wordmark** — `aajoo` alone in header, footer, `/login`,
   `/getting-started`, host landing, dashboards. Admin should still say
   `aajoo ADMIN`.
10. **`/some-nonsense-url`** — the new 404, never seen either.
11. **Map marker tap on the phone home** → opens the property, not a 404.
    This is the live bug from `40f870a`.
12. **`/getting-started` and host landing** — they share the `.topnav` class
    with only two children. The 3-column grid is scoped to a `has-search`
    modifier specifically so those don't break, but confirm it.

Then: `git push origin HEAD:main` and deploy with the `--scope` flag from §1.

---

## 6. Technical notes worth keeping

### From this session

- **`.topnav` is shared.** `TopNav`, `GettingStarted` and `HostLanding` all use
  it. The Airbnb 3-column grid is on `.topnav.has-search` for that reason —
  a bare `.topnav{display:grid}` drops the other two pages' action clusters
  into the middle column.
- **`min-width:0` on `.nav-pill` is load-bearing.** The pill sits in a `1fr`
  grid track, and a grid track's automatic minimum is `min-content` — without
  it the nowrap label refuses to shrink and pushes the menu button off-screen.
- **`useStuck(threshold)`** (`src/redesign/lib/useStuck.ts`) is the scroll hook;
  it takes a px threshold and returns a boolean. Used twice in TopNav now: `8`
  for the shadow, `120` for the search collapse.
- **`sp.get("id")`** — property detail is `/property?id=N`, query string, never
  a path segment. Desktop Explore/Search always did this correctly; MobileHome
  was the outlier.

### Carried forward (still true, still bites)

- **CSS shorthand trap** — `padding: 44px 0` also sets `padding-left: 0`. This
  has caused two separate site-wide regressions (killed `.container`'s gutter
  via `.section`; killed every `.btn-lg`'s height). **Use `padding-block` /
  `padding-inline`.**
- **Stacking contexts** — `position:relative` with no z-index is *not* a
  stacking context. Leaflet's internal z-indexes (panes 400–700, controls
  800–1000) escaped and punched through a z-index 200 modal. Fixed with
  `isolation:isolate`.
- **`scroll-snap-type: x mandatory`** ignores `padding-left` when snapping —
  use `scroll-padding-inline` or rails self-scroll by the gutter.
- **`success: false` arrives as HTTP 200** on this API. Read the envelope, not
  the status code.
- **Booking dates are `DD-MM-YYYY`** on the backend; the server clock runs
  ahead. `/properties/search` nests results under `data.property`.
- **`/listing/draft/{id}`** returns DB rows with table prefixes (`pl_city`),
  not payload keys (`city`) — hydration needs prefix-stripping.
- **Flutter duplicate-file trap** — `map_screen.dart`, `property_page.dart`,
  `pre_booking_screen.dart`, `homescreen.dart`, `booking_controller.dart` all
  exist twice: legacy `lib/screens`|`lib/widgets` vs live `lib/ui`. Edit the
  `lib/ui` copy.
- **Bash heredocs break on apostrophes** in content — write to a file and
  append via Python instead.

---

## 7. Pending / next up

**Immediate (this session's own debt)**
1. Verify §5 in a browser.
2. Push and deploy the three commits.

**Parity gap opened this session**
3. The header/search rebuild is **web-only**. The standing rule (see
   `WEB_MOBILE_PARITY.md` and the memory note) is to fix renter/host bugs on
   both platforms in the same pass. The Flutter guest home has its own search
   surface — decide whether the two-state search applies there or whether the
   app's existing pattern already covers it. **The wordmark change almost
   certainly should be mirrored in the app.**

**Flagged but not actioned (from earlier sessions, still open)**
4. `/help-center` and `/terms-condition` don't use `.container`.
5. Notifications screen in the app still has a legacy teal AppBar.
6. Seed listings share a pincode, so map pins overlap.
7. `.vercel/project.json` has a stale `orgId` (hence the `--scope` flag).
8. Three historical over-asking negotiation offers — awaiting user's call on
   whether to clear them.
9. Test drafts left on host 100 from earlier testing (Cedar Ridge Villa, Pine
   Hollow Villa + 2 older).
10. **Payouts blocked on 4 env vars** — see `PAYOUTS_SETUP.md`.
11. **Render env is NOT correctly set** (verified in an earlier session);
    secrets cutover is blocked. See `RENDER_ENV_CHECKLIST.md`.
12. **Cloudinary account is shared/polluted** (704 assets) and may hold more
    PII after the seed-image incident. Not audited.

---

## 8. Working agreements with this user

- **Greenlight to test everything.** Verbatim: *"for android i am starting
  emulator and for web launch either the production site or local server to
  test as you wish as there are no real users anywhere for now only testing
  data and testing users are there so you have a greenlight to perform all the
  actions that you want on all the portals as well"*.
- **Quality bar, verbatim:** *"i don't want to redo everything again and again
  as i am spending my time and money over claude i expect best outputs not
  silly developers mistakes"*. Read the reference properly before building; a
  screenshot shows a state, not a behaviour. The `88e96b7` → `6a7d6f1`
  round-trip happened because the first pass copied a static shape instead of
  the interaction.
- **Standing security line I held and you should hold:** I do not type real
  bank account numbers or IFSC codes into forms. The Add Bank Account form was
  tested by submitting empty fields to check validation only.
- **Parity rule:** fix renter/host bugs on both platforms in the same pass.

### Test credentials

| Role | Login | Notes |
|---|---|---|
| Host | `aajoo.host1@mailinator.com` / `Host@12345` | user 100 |
| Admin | `admin@mailinator.com` / `Admin@123` | field is `username`, not email |
| Renter | `sumit.m@zyphextech.com` / `Haryana@2706` | user 126 |

Login payload fields are `user_email` / `user_password` / `isHost`.

---

## 9. Key files for the work in flight

| File | Why it matters |
|---|---|
| `src/redesign/components/NavSearch.tsx` | **New.** The two-shape search. Header comment explains the states and why there's no Who. |
| `src/redesign/components/TopNav.tsx` | Rewritten. Holds `searchOpen` / `reopened` state and the account menu. |
| `src/redesign/components/Logo.tsx` | Wordmark. Comment records the team's decision. |
| `src/redesign/pages/NotFound.tsx` | **New.** Themed 404 with its own chrome. |
| `src/redesign/pages/Explore.tsx` | Search card removed; the removal is documented in a comment where it used to sit. |
| `src/styles/aajoo-system.css` | `.nav-pill`, `.navsearch`/`.ns-*`, `.navmenu-*`, `.nf-*`, plus LUX overrides and the 820px mobile block. |
| `src/App.tsx` | Catch-all is the last top-level route, outside every layout. |

---

## 10. Reference

Airbnb's header, checked this session rather than recalled:
three zones (logo left · product tabs centre · host link + globe + account
menu right), with a pill-shaped Where/When/Who search that is full-width at
the top and collapses on scroll; below 744px the tabs hide behind a sheet and
the search becomes a single tappable pill.

**Not implemented:** the product-tab row (Homes / Experiences / Services). We
have one product, and the client asked about the *search* behaviour
specifically. Mention it only if they raise it.

- https://github.com/VoltAgent/awesome-design-md/blob/main/design-md/airbnb/DESIGN.md
- https://www.navbar.gallery/navbar/airbnb
