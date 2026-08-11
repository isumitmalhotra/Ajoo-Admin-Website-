# Aajoo Web — Session Handoff (continue in a new chat)

Last updated: this session. Companion file: **`WEB_BUG_TASKLIST.md`** (live status of every bug).

---

## 1. Project topology & deploy flow (read first)

Three separate git repos on disk:

| Repo | Path | Role | Remote | Deploy |
|------|------|------|--------|--------|
| **Frontend** | `D:/Projects/aajao-frontend-vercel` | React/Vite customer + admin + host web | `nameeshPatiyal100/Aajao-Admin-WebSIite` | **Push `main` → Vercel auto-deploys** to www.aajoohomes.com |
| **Backend** | `D:/Projects/aajaoBackend-render` | Node/Express + Sequelize/MySQL | `nameeshPatiyal100/aajaoBackend` | **Push `main` → Render auto-deploys** (`aajaodev.onrender.com`). Start cmd `node app.js` — **does NOT auto-run migrations**. |
| **Monorepo (dev)** | `D:/Projects/ajoo admin website` | Original combined repo + docs/trackers + Flutter apps | `Ajoo-Admin-Website-` | Not deployed. Has ~800 uncommitted files (mobile apps etc.) — **frontend/backend fixes are NOT synced back here** (drift). |

**All website + backend fixes this session were made directly in the two deploy repos** (aajao-frontend-vercel, aajaoBackend-render), not the monorepo.

**Deploy verification:** I use gstack's headless browser (`~/.claude/skills/gstack/browse/dist/browse`) to drive the live site. Vercel/Render deploys take ~40s–2min; poll the live behavior.

**Backend DB migrations** (live Clever Cloud MySQL): from `aajaoBackend-render`, deps aren't installed by default — run:
`npm install --no-save sequelize mysql2 sequelize-cli && npx sequelize-cli db:migrate`
(`.sequelizerc` → `config/sequelize-cli.config.js` → `config/db.config.js` = live DB. `ADD COLUMN` is safe.)

---

## 2. Test accounts (all working)

| Role | URL | Email | Password |
|------|-----|-------|----------|
| Admin | `/admin/login` | `admin@mailinator.com` | `Admin@123` |
| Host | `/auth/login` → Host tab | `aajoo.host1@mailinator.com` | `Host@12345` |
| Renter | `/auth/login` → Renter tab | `aajoo.renter1@mailinator.com` | `Renter@12345` |

(Host + renter were created this session via signup → OTP bypass `000000` → admin activate. Renter has 2 test pay-on-arrival bookings.)

---

## 3. What was shipped this session (all live + verified unless noted)

**Auth & portals**
- Host/renter **login form** wired (was static markup); admin **logout** wired; admin login confirmed working.
- **GuestRoute** role-aware: customer "Sign In" never opens the admin dashboard — host→/host/dashboard, renter→/user-dashboard, admin/staff or none→sign-in screen.
- Backend: **public** `GET /properties/:id` + `/properties/host/:hostId` (were 401 for guests); **host login role** fix (`loginUser` now selects `user_isHost`).
- Host profile endpoint corrected (`GET /host/profile/get` + `PUT /host/profile/update`); host messages 404 silenced.

**Finance (admin)**
- Blank Finance dashboard + all 4 report pages (revenue/commission/tax/cashflow) fixed — React hooks-after-early-return crash (#300) + report response shape `data.items` vs `data`.

**Branding / nav**
- Real logo image (`/favicon.jpeg`) in header/footer/admin+host sidebars; logo → `/` on customer, → own dashboard on admin/host; **"Go to Homepage"** button in admin navbar + host header.
- Header shows **"Hi, &lt;name&gt;"** + account menu when signed in (renter→dashboard lands correctly).

**Maps (P0 #1)** — home pan-to-load + recenter/near-me; listing far-pan refetch; place-search recenter; **unified price-chip markers** (shared `priceMarker.ts`).

**Search & filters (P0 #2)** — wired the previously-dead price filter; price chips + popular-destination **state chips** on listing; **Airbnb-style guest selector** (adults/children); destination **autocomplete** datalist.

**Wishlist (P0 #3)** — functional heart on cards + property-detail "Save" (login-guarded; was hitting the 401→home trap); saved list works.

**Booking integrity (P0 #4) + booking flow**
- Home **OngoingFloat** popup → richer card + "View All" (verified live).
- **CRITICAL FIX:** checkout never created a booking (RazorpayPayment was client-only — no `/booking/create`, no order, no verify) + date format mismatch. **Rewired:** createBooking (DD-MM-YYYY) → Razorpay order → `/create/payment-verify` → invoice; "Reserve & pay later" = POA. Booking-create verified from UI.
- **Nearest-booking map (66)** in ongoing modal (+ backend now returns property coords in the ongoing query); ongoing empty-state illustration.

**Categories (P1 / Common 24)** — backend `cat_icon` migration (applied to live DB) + admin Cloudinary upload endpoint + public exposure; admin category form icon picker; home chips render the icon. Verified end-to-end.

**Property detail (P1)** — confirmed already-implemented: gallery lightbox, "Explore places nearby", Cancellation Policy modal button; sizing fine post-redesign. Home "Find Your Stay" section header added.

**Deliverables produced**
- `bugs (2) - status updated.xlsx` in Downloads (client status sheet).
- `WEB_BUG_TASKLIST.md` (this repo) — prioritized P0/P1/blocked.

---

## 4. NEXT STEPS (start here in the new chat)

### A. The one manual verification owed
- **Complete a Razorpay TEST payment** (backend is in test mode): log in as renter → book a property with future dates → **Pay now** → test card `4111 1111 1111 1111`, any future expiry/CVV, choose **Success** on the OTP screen → confirm booking + invoice created and it shows in My Bookings / Ongoing. (gstack can't drive the Razorpay iframe; this is a human step.)

### B. Quick wins / cleanups
- **GST mismatch:** checkout displays **18%** GST but the backend order uses **~12%** tax. The amount charged is the backend's order amount (authoritative). Align the displayed % with the backend (or fix backend tax rate).
- **Cancel-page redesign (64)** — not done this session.

### C. Remaining P1 (need design direction)
- Sticky category/rating on scroll (mobile, item 41); host announcement slider (Host 3).

### D. Blocked — needs client inputs
- **Razorpay LIVE keys** + **DIDIT KYC credentials** (gate real payments + host KYC). Render currently falls back to the bundled Razorpay **test** key.

### E. Hygiene
- **Monorepo drift:** none of this session's fixes are synced into `D:/Projects/ajoo admin website`. Decide whether to sync (it has 800+ unrelated uncommitted changes — was paused early in the session).

---

## 5. Gotchas / learnings (save time next chat)
- **Booking dates must be `DD-MM-YYYY`** for `/booking/create` (backend `parseCustomDate` is day-first). Frontend pickers use `YYYY-MM-DD` → convert.
- **Server clock runs ahead** of the harness "today" — `/booking/create` rejects near-term dates as "in the past"; use clearly-future dates when testing via curl.
- **`/properties/search`** returns results under **`data.property`** when there are matches, but `data: []` when none (frontend `searchProperties` handles both).
- **Test data is sparse + clustered near Delhi** (28.61, 77.21) — maps/search look empty elsewhere; that's data, not a bug.
- **401 → home redirect trap:** the customer axios (`src/axios/axios.ts`) redirects to origin on 401. Guard authed fetches on global components + login-check before authed actions.
- **gstack + MUI:** `fill` often doesn't update MUI/React controlled state — use real `type`, the native value-setter, or `form.requestSubmit()`. gstack `console` misses uncaught React errors (use a `window.onerror` trap or check `#root` length for silent crashes).
- **Reaching the Leaflet map instance** for tests: walk the React fiber from `.leaflet-container` to find an object with `setView`/`panBy`, then call it to fire a real `moveend`.
