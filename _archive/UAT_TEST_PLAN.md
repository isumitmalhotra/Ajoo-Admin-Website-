# AajooHomes — v1 Live UAT Test Plan (Test Mode, real money-trail)

> **Goal:** one continuous live test — create a property, list it, book + pay (test mode), and confirm the **same booking + money** flows correctly into the **Host, Finance, and Admin** dashboards. All dashboards now start **empty** (demo/mock data removed) and populate only from your actions.

---

## 0 · Setup

**URLs:** Customer `https://aajoohomes.com` · Admin login `https://aajoohomes.com/admin/login` · Host: customer **Login → Host** tab.
> Hard-refresh first — latest deploys: FE `0a627af`, BE `c23ca7a`.

**Accounts**
| Role | Login | Password |
|---|---|---|
| Admin | `admin@mailinator.com` | `Admin@123` |
| Host | `aajoo.host1@mailinator.com` | `Host@12345` |
| Renter | `aajoo.renter1@mailinator.com` | `Renter@12345` |

**Test-mode behavior (expected, not bugs):** OTP = `000000` · **Razorpay test payment → use UPI: type `success@razorpay` as the VPA → instant success** (cards like `4111 1111 1111 1111` are rejected as "international card" by this test account — don't use cards; UPI or Netbanking→Success works) · KYC "Verify identity" is bypassed · Admin → Settings is display-only.

### GST / commission model (now implemented)
- **Accommodation GST (guest pays, on top of the stay):** by **per-night tariff** — **≤ ₹7,500/night → 5%**, **> ₹7,500/night → 18%**.
- **Platform commission:** **15%** of the stay subtotal.
- **GST on commission:** **18%** of the commission.
- **Host payout (net)** = subtotal − 15% commission − 18% GST on that commission.
- **TCS** for registered hosts: not in this build (deferred).

**Worked example A (> ₹7,500/night → 18%):** ₹8,000/night × 2 nights = **₹16,000 subtotal**; GST 18% = **₹2,880**; **guest pays ₹18,880**. Commission 15% = ₹2,400; GST on commission 18% = ₹432; **host net = ₹13,168**.
**Worked example B (≤ ₹7,500/night → 5%):** ₹5,000/night × 2 = **₹10,000 subtotal**; GST 5% = **₹500**; **guest pays ₹10,500**. Commission ₹1,500; commission-GST ₹270; **host net = ₹8,230**.

### Property creation — now in the host portal
Hosts can now create + list a property directly from the **Host portal → Add Property** (`/host/add-property`) — the listing goes **live on the site immediately**. (An admin can also create one via Admin → Properties → Add and assign a host.)

---

# PART 1 · The live money-trail test (do this first, in order)

### Step 1 — Host creates + lists a property (as Host)
1. Log in via **Login → Host** as `aajoo.host1` → Host portal → **Add Property** (sidebar, `/host/add-property`).
2. Fill the form: name, description, **category** (pick one+), **price per night** (pick a value to test a GST slab — e.g. **₹8,000 → 18%**, or **₹5,000 → 5%**), minimum price, **city + state**, address, then **"Locate from address"** (or "Use my current location") to set the map pin; optionally amenities + photos.
3. **List property**.
- **Expected:** "Property listed! It's now live on the site"; you return to the host dashboard.
- **Note the property name + nightly price** — you'll need them.
- *(Alternative: an Admin can create it via Admin → Properties → Add and assign the host.)*

### Step 2 — Confirm it's live on the site (as guest/renter)
1. Go to `https://aajoohomes.com` → **Find Your Stay / Homes** → search the property's city (or zoom the map to its location).
2. Open the property detail.
- **Expected:** the property is listed and its detail page loads with your price/photos.

### Step 3 — Renter books + pays (test mode) (as Renter)
1. Log in as renter → open the property → pick **check-in/out** (future, within ~3 months) + guests → **Book Now** → checkout.
2. **Check the price breakdown:** subtotal = nightly × nights; **GST shows 5% or 18% based on the nightly price** (per the model above); total = subtotal + GST.  ← *verify the GST % + amount match the worked example.*
3. **Pay now** → Razorpay → choose **UPI** → enter `success@razorpay` → **Success** (do *not* use a card — they're blocked as international on this test account; Netbanking→Success also works).
- **Expected:** "Booking confirmed"; you land on the confirmation; the booking shows under **Account → Bookings / Ongoing** with an invoice.

### Step 4 — Verify in the HOST dashboard (as Host)
1. Log in via **Login → Host** as `aajoo.host1`.
2. **Bookings:** the new booking appears.
3. **Earnings:** earnings reflect the booking (host **net** after commission + commission-GST).
- **Expected:** the booking + host net earning are visible.

### Step 5 — Verify in the FINANCE dashboard (as Admin → Finance)  ← the key check
1. **Finance Overview:** **Total Revenue** = the total guest paid; **Platform Commission** = 15% of subtotal; **Pending Payouts** includes the host net.
2. **Ledgers:** 4 new entries for this booking — **GUEST_PAYMENT** (total), **PLATFORM_COMMISSION** (15%), **HOST_EARNING** (net), **TAX_COLLECTED** (accommodation GST).
3. **Invoices:** a new **BOOKING_RECEIPT** invoice — subtotal, tax (GST), rate (5/18), total.
4. **Payouts → Queue:** a **QUEUED** payout to the host for the net amount.
- **Expected:** every number ties back to Step 3 (revenue = guest total; commission = 15%; tax = the GST you saw at checkout; payout = host net).

### Step 6 — Verify in the ADMIN dashboard (as Admin)
1. **Bookings:** the booking appears with the right user/property/amount/status (Paid).
2. **Dashboard:** Total Bookings KPI +1.
- **Expected:** the booking is visible and consistent with Host + Finance.

### Step 7 — (Optional) Booking guards + cancellation
- Try booking the **same property + overlapping dates** again → rejected ("These dates are already booked…").
- From Account → Ongoing → **Cancel** the booking → branded cancellation page with the booking reference.

> **The whole point of Part 1:** the *same* booking and its money appear consistently across Renter, Host, Finance and Admin, with correct Indian GST + 15% commission + host net. Note any number that doesn't tie out.

---

# PART 2 · Screen-by-screen checks (condensed)

> For each, mark PASS/FAIL/PARTIAL + a note. (Finance/HMS rows beyond your test booking will be sparse now that demo data is removed — that's expected.)

### Customer site
- **Home** — hero, **announcement slider**, search bar + Prebooking/Luxury, categories, featured, footer (social icons, no 404s).
- **Listing** — state/price chips, **Airbnb category bar**, **Sort** (price asc/desc), **All filters → Search** applies, map pan reloads.
- **Property detail** — gallery lightbox, amenities, host card, cancellation-policy modal, booking box recalculates price.
- **Wishlist** — heart saves (login-guarded) → appears in Account → Saved.
- **Auth** — signup 3 steps (portrait ID rejected; OTP `000000`); login Renter/Host; forgot-password (OTP `000000` → reset).
- **Become a Host** — 3-step form; logged-in submit works; logged-out stashes draft → sign-in.
- **Account** — profile-summary sidebar; Dashboard KPIs; Profile edit + **Change Password** + **Delete Account** (confirm dialog — don't delete the shared acct); Bookings/Ongoing/Transactions/Saved; **notification bell**.
- **Static** — About, Contact, Help (social row + WhatsApp), FAQ, Terms, Privacy.

### Admin
- **Dashboard** — 5 KPIs (incl. Pending Properties) + **Reports Center** cards + charts + latest tables.
- **Users / Host mgmt / Properties / Verification / Categories+Tags+Amenities / Reviews / Bookings / Status** — lists load, search/filters/CRUD work.
- **Settings** — 4 tabs render (display-only). **Notifications** bell works.

### Host (HMS)
- **Dashboard** (+ announcement slider), **Bookings, Earnings, Performance, Statements**, **Support** (raise a ticket → appears), **Communication**, **Profile** (identity + banking, Save persists).

### Finance (FMS)
- **Overview, Ledgers, Payouts (queue/schedules/history), Reconciliation, Invoices, Reports (Revenue/Commission/Tax/Cash Flow)** — pages load; your test booking's rows appear (see Part 1 Step 5).

---

## Results template (fill + send back)

| Step / Screen | PASS/FAIL/PARTIAL | Notes (numbers seen / error + screenshot) |
|---|---|---|
| P1-1 Admin create+list property | | |
| P1-2 Property live on site | | |
| P1-3 Renter book + **GST %/amount at checkout** | | |
| P1-3 Pay (test card) → confirmed + invoice | | |
| P1-4 Host: booking + earnings | | |
| P1-5 Finance: ledger / invoice / payout / commission | | |
| P1-6 Admin: booking + KPI | | |
| P1-7 Guards + cancellation | | |
| P2 Customer screens | | |
| P2 Admin screens | | |
| P2 Host screens | | |
| P2 Finance screens | | |

> Most valuable: **P1-3 (GST at checkout)** and **P1-5 (Finance numbers tie out)** — those validate the GST + commission + money-trail wiring end to end.
