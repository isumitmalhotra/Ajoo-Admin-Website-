# Aajoo — Pre-Launch Plan: Host Onboarding Form + Chat Support

Covers the two docs in the repo:
1. **`LIST PROPERTY TYPE & CATEGORY.pdf`** → the **updated Host onboarding + property-listing form** (with DIDIT face/ID verification + **manual** admin property approval).
2. **`aajoo chat support flow updated.pdf`** → the **conversational support bot** to be built in **BotPenguin** (Guest + Host flows across WhatsApp / Website / App).

---

## PART 1 — HOST ONBOARDING & PROPERTY LISTING (Doc 2)

### What the doc asks for
A **13-section multi-step wizard** + a **state-wise legal/verification layer**:

| # | Section | Notable new requirements vs current form |
|---|---|---|
| 1 | Property Type & Category | **6 property types** (Homestay / Private Room / Shared Room / Flat / Villa-Farmhouse / PG-Hostel), **Standard vs LUX**, **Booking pref** (Instant vs Pre-booking) |
| 2 | Location | + Area/Locality, Landmark (we have name/address/city/state/map) |
| 3 | Property Details | + Bathrooms, Beds (type + count), Floor no. (we have guests/beds) |
| 4 | Photos & Media | **Min 5 (mandatory), max 12**, cover selection, optional video |
| 5 | Pricing | Weekend/peak price, extra-guest charge; **LUX: security deposit (mandatory)**, cleaning fee, min booking amount |
| 6 | Amenities | **Basic = mandatory** (WiFi/Hot water/Bed linen/Toiletries/Power backup/Parking) + Additional |
| 7 | House Rules | + Couple-friendly, Local-ID allowed, Quiet hours (we have in/out time, pets, smoking) |
| 8 | Party / Group | Allow gatherings, max people, party charges, loud music, end time |
| 9 | PG Mode (only if PG) | Room type, monthly rent, 10% deposit, food, gender pref, curfew, visitor policy, lock-in |
| 10 | Host Details | Name, **Mobile (OTP verify)**, Email, Address |
| 11 | KYC & Verification | Aadhaar/PAN upload + **self-declaration** → **DIDIT face + ID** (your requirement) |
| 12 | Bank Details | Holder, bank, account, IFSC, UPI |
| 13 | Review & Submit | Preview → **"Submit & Go Live → Status: Pending Admin Approval"** |

**Legal/verification layer** (Steps 2–8 of the doc): ownership type (Owner/Manager), base legal docs (Aadhaar/PAN/ownership proof/address proof + declaration), **dynamic state-wise rules** (HP strict → tourism reg; Punjab flexible; Chandigarh → rental-approval question; Haryana → RWA for Gurgaon/Faridabad), **verification tiers** (Verified / Partially Verified / Unverified → drives visibility), **admin approve/reject/override/flag**, and **risk logging** (declaration stored, doc logs, timestamp + IP, audit trail).

### Where we are today
- `HostAddProperty.tsx` is a **single-page** form: name, description, category chips, luxury toggle, price/miniPrice, guests/beds, location + map, amenities (now admin-DB driven), tags, in/out time, pet/smoke, contact, photos.
- **Critical mismatch:** host listings currently go **live immediately** (`is_active=1, is_verify=1`). The doc requires **Pending Admin Approval** → manual admin verification.
- DIDIT exists only for **guest** booking KYC (`VerifyButton context="guest_kyc"`). No **host** KYC step.
- Admin **Property Verification** page exists but is empty/unwired.
- Many fields (property type, booking pref, bathrooms, floor, security deposit, weekend price, party/PG settings, ownership, legal docs, verification status) **don't exist** in the schema yet.

### The 3 things you specifically called out
1. **Form must match the doc** → rebuild `HostAddProperty` into the multi-step wizard.
2. **After host details → DIDIT face + ID** → add a host-KYC step (reuse the existing DIDIT integration with a `host_kyc` context).
3. **Property verified manually by admin** → stop auto-go-live; submit as **Pending**, surface in admin **Property Verification**, admin **Approve/Reject** flips visibility.

### Plan — phased

**Phase H1 — Core wizard + DIDIT + manual approval (go-live critical)**
- Rebuild host listing as a **stepper**: Type/Category/Booking-pref → Location → Details → Photos (enforce min 5) → Pricing (deposit for LUX) → Amenities (basics required) → House Rules → Host Details (+ mobile OTP) → **DIDIT face+ID** → Bank → Review → Submit.
- Backend: add the new property columns + a `verification_status` + revert `addProperty` to **pending** (`is_verify=0`); keep it off the public site until approved.
- **Admin Property Verification page**: list pending properties, view details + docs + KYC result, **Approve / Reject / Request docs**; approve → `is_verify=1` (goes live).
- Host KYC via DIDIT (`host_kyc`) stored against the host; show KYC status in admin.
- Schema: `tbl_properties` new cols (property_type, category Standard/LUX, booking_pref, area, landmark, floor, bathrooms, security_deposit, weekend_price, extra_guest_charge, cleaning_fee, min_booking, video_url, couple_friendly, local_id_allowed, quiet_hours, verification_status); `tbl_property_documents` (doc_type, file, status); host bank details (table exists).

**Phase H2 — Legal layer, PG mode, party settings, tiers**
- State-wise dynamic legal flow (HP/Punjab/Chandigarh/Haryana rules + conditional doc uploads).
- Verification **tiers** (Verified / Partial / Unverified) → visibility weighting on the site.
- PG mode sub-form; Party/Group settings.
- Ownership type + base-legal doc uploads.
- Risk/audit: store declaration, doc logs, timestamp + IP, case-based audit trail; admin override/flag + smart-automation flags.

**Dependencies / blockers**
- **DIDIT live credentials** (currently the P4 KYC cutover is blocked on client keys). H1 can be built against DIDIT **test/sandbox** now and flipped to live when keys arrive.
- Mobile **OTP** for host details — reuse existing OTP infra (currently bypassed for testing).

---

## PART 2 — CHAT SUPPORT BOT (Doc 1, BotPenguin)

### What it is
A full **AI + human-hybrid** support assistant across **WhatsApp / Website / App** with: language select, Guest flows (Find&Book, Booking help, View/Modify/Cancel, Payment issue, Stay support incl. emergency, Refund, Invoice, AI Q&A), Host flows (Listing, Booking, Payments, Property support, Growth), a **global AI layer** (intent/sentiment/urgency → emergency auto-escalation), **human handover**, **SLA timers**, and **CRM + Excel/Sheets** logging.

### How the work splits
This is **mostly configured inside BotPenguin** (their no-code visual builder + WhatsApp + Sheets/CRM integrations) — **not** primarily codebase work. Our codebase role is to **expose the APIs the bot calls** and **embed the widget**.

**2a. Backend API readiness** (bot → our APIs). Mapping of the doc's "services" to what exists:

| Doc service | Status | Endpoint |
|---|---|---|
| `LISTINGS_SERVICE.search` | ✅ exists | `/properties/search` |
| `BOOKING_SERVICE.get_details / get_bookings` | ✅ exists | `/user/booking-history`, `/host/bookings/search`, booking detail |
| `OTP_SERVICE.send/verify` | ✅ exists | signup/forgot OTP infra |
| `PROPERTY_SERVICE.location / amenities` | ✅ exists | property detail, `/common/amenties` |
| `PAYOUT_SERVICE.get_payout_status` | ✅ exists | host earnings/payouts |
| `ANALYTICS_SERVICE.get_host_performance` | ✅ exists | `/host/performance` |
| `SUPPORT_SERVICE.create_case / get_case_status` | ⚠️ partial | tickets exist; need a **bot-facing case create/status** endpoint |
| `PAYMENT_SERVICE.check / refund_status` | ⚠️ gap | refund-status endpoint to add (or human-takeover initially) |
| `DOCUMENT_SERVICE.download` (guest invoice) | ⚠️ gap | invoice is admin-only today; add a guest-facing fetch |
| `ANALYTICS_SERVICE.get_recommendations` | ⚠️ gap | pricing suggestions (Phase 2) |
| `CAMPAIGN_SERVICE.trigger_drip` | ❌ external | marketing drip = BotPenguin/automation, not codebase |

**2b. Website widget** — embed the BotPenguin script on the site (small, fast).
**2c. WhatsApp** — connect BotPenguin to WhatsApp Business API (BotPenguin side; needs a WhatsApp number + Meta approval).
**2d. CRM / Google Sheets** — BotPenguin native integrations for lead/ticket logging.
**2e. Human handover & SLA** — configured in BotPenguin (live chat + timers).

### Plan — phased

**Phase C1 (go-live MVP)**: embed website widget + build the **core BotPenguin flows** (entry menu, Find&Book via LISTINGS search, Booking help/View via BOOKING_SERVICE, AI Q&A, Talk-to-team handover) against existing APIs; lead → Google Sheet.
**Phase C2**: add the gap endpoints (support case create/status, refund status, guest invoice), Payment-issue + Refund + Invoice flows, host flows, SLA timers.
**Phase C3**: WhatsApp channel, CRM, campaign drip / reminders, emergency auto-escalation, full sentiment/urgency AI layer.

---

## SEQUENCING (suggested)
1. **H1** (host wizard + DIDIT + manual admin approval) — biggest codebase effort; the real pre-launch blocker.
2. **C1** (BotPenguin website widget + core flows) — parallelizable; mostly platform config.
3. **H2** + **C2/C3** — post-launch hardening.

## DECISIONS I NEED FROM YOU
- **Host form scope for launch**: full doc (incl. state-legal + PG + party) now, or **H1 core (form + DIDIT + admin approval) first**, H2 after?
- **BotPenguin ownership**: do you have a BotPenguin account + WhatsApp Business number? Who builds the bot flows in BotPenguin — you/team (I provide the blueprint + APIs + widget), or is that out of my scope?
- **DIDIT keys**: are live DIDIT credentials available now, or build host-KYC against sandbox and flip later?
