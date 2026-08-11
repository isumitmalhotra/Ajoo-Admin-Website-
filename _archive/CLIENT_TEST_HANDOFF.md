# AajooHomes — Test Handoff (Client)

> Test-mode build for full end-to-end testing of the website (renter, host, and admin).
> All accounts and credentials below are **verified working** as of **26 Jun 2026**.
> This is a **test environment** — no real money moves and no real emails/SMS are sent (see "Test-mode notes" at the bottom).

---

## 1. Where to go (live URLs)

| Area | URL | Who it's for |
|------|-----|--------------|
| **Customer website** | https://www.aajoohomes.com | Renters & hosts (browse, book, list properties) |
| **Admin panel** | https://www.aajoohomes.com/admin/login | Admin / staff (manage everything) |
| Backend API (info only) | https://aajaodev.onrender.com | Not for manual use |

> Note: the backend is on a free hosting tier and may take **20–40 seconds to "wake up"** on the first request after a period of inactivity. If the first page/login feels slow, retry once.

---

## 2. Test accounts (ready to use)

### 🛡️ Admin
- **Login page:** https://www.aajoohomes.com/admin/login
- **Email:** `admin@mailinator.com`
- **Password:** `Admin@123`
- Can manage: users, hosts, properties, **property verification/approval**, bookings, coupons, CMS, finance, payouts, reviews, FAQs.

### 🏠 Host (already approved)
- **Login page:** https://www.aajoohomes.com/auth/login
- **Email:** `aajoo.host1@mailinator.com`
- **Password:** `Host@12345`
- Phone: `9000000111`
- Use this to: list a new property (9-step wizard), manage bookings, view earnings/statements.

### 🧳 Renter / Guest
- **Login page:** https://www.aajoohomes.com/auth/login
- **Email:** `aajoo.renter1@mailinator.com`
- **Password:** `Renter@12345`
- Phone: `9000000211`
- Use this to: browse, negotiate, book a stay, leave reviews.

---

## 3. Registering a brand-new account (OTP + KYC)

When testing the **sign-up** flow at https://www.aajoohomes.com/auth/signup:

1. Fill the sign-up form (name, email, phone, password, ID document optional).
2. On the **OTP screen**, since no real SMS/email is sent in test mode, enter the **test OTP:**
   ### 👉 `0000`
   *(The OTP box is 4 digits. This verifies the account instantly.)*
3. After OTP, you'll be taken to **identity verification (KYC)**:
   - **To complete it:** click **Verify** → finish the DIDIT identity check → you'll return to the site marked **verified** (a verified renter is **not** asked to verify again at booking time).
   - **To skip for now:** click **"I'll do this later"** → goes straight to the dashboard. (You can still browse; verification can be done later.)

---

## 4. Suggested full-flow test (end to end)

**A. Host lists a property**
1. Log in as **Host** → go to **Add Property** → complete the 9-step wizard (details, photos, pricing, documents, identity) → submit.
2. The property is created in **Pending** status (not yet public).

**B. Admin approves it**
1. Log in as **Admin** → **Property Verifications** → open the pending property → review documents → **Approve** (or Reject with a note).
2. Approved → the property goes **live** and is searchable.

**C. Renter books it**
1. Log in as **Renter** (or register a new account using OTP `0000`).
2. Find the property → check dates/guests → (optionally negotiate) → **Book** → pay using the **test card** below → booking confirmed → invoice generated.
3. After the stay window, the renter can **leave a review**.

**D. Admin / Host follow-up**
- Admin sees the booking, payment, and can manage payouts/finance.
- Host sees the booking and earnings.

---

## 5. Test payment card (Razorpay test mode)

At checkout, the payment opens in **Razorpay test mode** — use:

| Field | Value |
|-------|-------|
| Card number | `4111 1111 1111 1111` |
| Expiry | any **future** date (e.g. 12/30) |
| CVV | any 3 digits (e.g. `123`) |
| Name/OTP | anything |

No real charge is made.

---

## 6. The chat assistant ("May I help you?")

- A chat widget appears bottom-right on the public pages.
- It is **hidden on the sign-up / login / verification screens** so it never blocks the forms.
- If you're **logged in**, it greets you without re-asking your phone number.

---

## 7. Test-mode notes (please read)

- **No real emails or SMS** are sent yet (no mail/SMS server connected). That's why the OTP is the fixed test code `0000`.
- ⚠️ **Don't use "Forgot Password"** in test mode — it sends a reset code by email, which won't arrive (no mail server). To get into an account, use the passwords above, or create a fresh account using OTP `0000`.
- **No real payments** — Razorpay is in test mode (use the card above).
- These test shortcuts (`0000` OTP, etc.) are **clearly marked in code and will be removed before the production go-live.**
- If a test account ever stops working or you want it reset, tell us and we'll refresh it.

---

*Prepared for client testing — AajooHomes web platform.*
