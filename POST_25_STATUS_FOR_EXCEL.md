# Post-25 Release — Status for the Excel sheet

> **Updated:** 2026-07-12 · Use this to fill the **"Post 25 release"** sheet in `_Web App Bugs (1).xlsx`.
> **Status key:** ✅ **Done** (shipped/live) · 🔷 **Pending** (P2, minor/cosmetic — not started) · 🔒 **Blocked** (needs client input) · 🟣 **Section-0** (folded into the rebrand SOW).
>
> **Tally:** **~48 Done** · 1 doable-P2 left (HOST-17, needs a BE field) · rest Blocked/Section-0. Every in-scope P0/P1 **and most P2** items are Done.

---

## Backend
| ID | Task | Status | What was done |
|----|------|--------|---------------|
| BE-1 | Double-booking prevention | ✅ Done | Overlap guard + 30-min pending hold; two guests can't book the same dates. |
| BE-2 | Host dashboard on real data | ✅ Done | Dashboard reads real earnings/listings/bookings aggregates. |
| BE-3 | Notifications not generated | ✅ Done | Renter bell now persists every notification (was skipped without a push token); host/admin get in-app alerts on booking, **payment**, and **cancellation**. |
| BE-4 | Socket messaging | ✅ Done | Backend chat verified (persists to DB); added JWT-verified socket identity + anti-spoofing. |
| BE-5 | Invoice PDF download | ✅ Done | Downloadable invoice for admin, host, and renter. |
| BE-9 | Field & validation audit | ✅ Done | Server returns all field errors at once; removed debug logging. |
| BE-11 | KYC auto-verify write-back | ✅ Done | DIDIT approval sets user "verified", activates host listings, notifies. |
| BE-10 | BotPenguin inbox auto-open / scoping | 🔷 Pending | Config-only (P2). |
| BE-6 | Category list in DB | 🟣 Section-0 | New category set is specified in Section-0; re-seed there. |
| BE-7 | Google sign-in (Firebase) | 🟣 Section-0 | Part of the Section-0 OTP/social auth upgrade. |
| BE-8 | Phone-number signup | 🟣 Section-0 | Part of the Section-0 OTP-first auth. |

## Admin dashboard
| ID | Task | Status | What was done |
|----|------|--------|---------------|
| ADM-1 | Add "Add Property" form in Admin | ✅ Done | Admin add-property form with the onboarding (H1) fields; verified live. |
| ADM-2 | Remove BotPenguin from admin | ✅ Done | Support widget no longer renders on `/admin` (or `/host`). |
| ADM-3 | Category management full list | 🟣 Section-0 | Tied to the Section-0 category re-seed. |
| ADM-4 | Premium icon set (admin) | 🟣 Section-0 | Part of the Section-0 Lucide icon migration. |

## Host dashboard
| ID | Task | Status | What was done |
|----|------|--------|---------------|
| HOST-1 | Property not submitted | ✅ Done | Root-caused (submit works → creates Pending); resolved by adding the listings page (HOST-4). |
| HOST-2 | Property edit anywhere | ✅ Done | Edit flow prefills the wizard + updates in place (fixed a duplicate-create bug). |
| HOST-3 | Ongoing page missing | ✅ Done | New Host "Ongoing" page. |
| HOST-4 | Host property list missing | ✅ Done | New "My Properties" page with Live/Pending/Rejected + Edit/View. |
| HOST-5 | Listing basics as icon selectors | ✅ Done | Type / booking-preference are icon cards, not dropdowns. |
| HOST-6 | Dynamic form by property type | ✅ Done | PG/Hostel shows its own fields. |
| HOST-7 | Current location at top + autofill | ✅ Done | Location actions moved to the top; "Use my location" auto-fills address/city/state. |
| HOST-8 | Pricing fields + suggested price | ✅ Done | Pricing inputs + on-screen price guidance. |
| HOST-9 | Amenities with icons | ✅ Done | Icon grid for amenities. |
| HOST-10 | Check-in/out placement + defaults | ✅ Done | Moved into Details; defaults 2 PM / 11 AM. |
| HOST-11 | Remove Couple-Friendly + Party | ✅ Done | Removed from the wizard. |
| HOST-12 | Host KYC via DIDIT | ✅ Done | Auto-opens DIDIT session, shows Verified, gates submit. |
| HOST-13 | "These buttons are not working" | ✅ Done | Host-Profile page audited — all buttons wired; no dead buttons. |
| HOST-14 | Inline validation | ✅ Done | On-blur field validation across the wizard. |
| HOST-15 | Host nav cleanup (remove Workspace) | ✅ Done | "Host Workspace" chip removed. (Blog nav = Section-0.) |
| HOST-16 | Replace "Total Spent" KPI | ✅ Done | Host dashboard shows Occupancy Rate (never had Total Spent). |
| HOST-19 | State Regulations page in host | ✅ Done | Added to host sidebar (`/state-regulation`). |
| HOST-17 | Host name + WhatsApp number | 🔷 Pending | Name already shown; WhatsApp needs a BE column to persist. |
| HOST-18 | Distinct host vs user colour | 🟣 Section-0 | Full re-theme is part of the rebrand. |

## Renter dashboard
| ID | Task | Status | What was done |
|----|------|--------|---------------|
| RENT-1 | Profile + profile picture not updating | ✅ Done | Picture now uploads + refreshes. |
| RENT-2 | Prebooking button not working | ✅ Done | Wired to the listing flow. |
| RENT-3 | Current location + autofill | ✅ Done | Geolocation autofills the address. |
| RENT-4 | Map filters not working | ✅ Done | Filters now apply (was a param-stripping bug). |
| RENT-5 | Show 4–5 listings on home + map | ✅ Done | Real listings populate. |
| RENT-6 | Renter nav cleanup | ✅ Done | Trimmed to intended items. |
| RENT-8 | Hide "choose file" once verified | ✅ Done | Upload hidden + Verified badge when KYC-verified. |
| RENT-9 | Support bot scoped to renter only | ✅ Done | Widget shows only on renter dashboard/account. |
| RENT-7 | Weather widget | 🔒 Blocked | Needs a weather API/provider + key. |

## Property detail / Booking
| ID | Task | Status | What was done |
|----|------|--------|---------------|
| BOOK-1 | Detail/booking dynamic (guests, beds, rating) | ✅ Done | Real fields + real average rating. |
| BOOK-2 | Meet-your-host dynamic + host number post-booking | ✅ Done | Host phone revealed only after the guest books (fail-closed). |
| BOOK-3 | Availability calendar | ✅ Done | Booked dates blocked in the picker. |
| BOOK-5 | Booking-page image slider dynamic | ✅ Done | Shows real property images; removed the hardcoded sample. |
| BOOK-6 | Host detail + cancellation-policy button | ✅ Done | Cancellation-policy action on the booking page. |
| BOOK-7 | Ongoing-page booking modal | ✅ Done | Fully data-driven; removed fake "Manali" placeholders. |
| BOOK-8 | Gallery: big hero + grid | ✅ Done | Desktop gallery is hero + grid (already implemented). |
| BOOK-9 | Map after reviews | ✅ Done | Map moved below the reviews. |
| BOOK-4 | Nearby places dynamic | 🔒 Blocked | Needs a data source (maps API or curated list). |

## Cross-cutting
| ID | Task | Status | What was done |
|----|------|--------|---------------|
| CC-1 | Loaders + skeleton loaders | ✅ Done | Reusable skeletons applied to listing, dashboard, detail. |
| CC-2 | One consistent date-picker | ✅ Done | `ThemedDatePicker` used across booking + signup + profile. |
| CC-3 | "Welcome back, {name}" | ✅ Done | On both host and renter dashboards. |
| CC-5 | Validation audit everywhere | ✅ Done | Server field errors (BE-9) + inline validation (HOST-14). |
| CC-4 | Premium icon set everywhere | 🟣 Section-0 | Part of the Section-0 Lucide migration. |

---

## Still needs the client (to unblock the remaining items)
- **Weather API** provider + key → unblocks **RENT-7**.
- **Nearby-places** data source (maps API or curated) → unblocks **BOOK-4**.
- **Real support WhatsApp number** → the ongoing-booking support button (currently a placeholder).
- **DIDIT dashboard webhook URL** → confirm it points at production.
- **Category list / brand assets / OTP+social auth** → these are now part of the **Section-0 rebrand** (BE-6/7/8, ADM-3/4, CC-4).

## Parked marketing-site UI (~55 rows in the sheet)
The purely-cosmetic marketing-page redesigns (Get-Started, About, Contact, Login/Signup restyle, luxury polish, etc.) are **out of the current contract** and are covered by the **Section-0 rebrand SOW** — mark those rows accordingly rather than as pending bug-fixes.
