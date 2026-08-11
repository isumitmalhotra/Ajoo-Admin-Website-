# AajooHomes — API Contract Handoff

> **Authored:** 2026-06-09 (Tue) by Account A under `FULL_DELIVERY_PLAN.md A-01`.
> **Status:** v1.0 — FROZEN as of Day 1 EOD. Subsequent changes go through § 11 Change Log.
> **Audience:** Account A (backend impl), Account B (FE wiring), Sumit (review).
>
> **What this doc is:** the complete contract for every endpoint backend must deliver during the sprint, grounded in the existing backend conventions (`{success, message, data}` envelope, Yup `stripUnknown` validation, JWT bearer auth, Sequelize models). Any deviation from this contract during implementation → update this doc + the matching slice/page in `src/` before writing code.
>
> **What this doc is NOT:** OpenAPI/Swagger. That's A-19 (Day 9). This is the lighter-weight contract that unblocks parallel work.

---

## 0 · Conventions (apply to EVERY endpoint below unless explicitly overridden)

### 0.1 Response envelope

All responses use the existing `common.response` helper (`aajooBackend-2026/utils/common.js`):

```js
res.status(status).json({ success: bool, message: string, data: any });
```

- `success` = `true` on 2xx (including "no record found" — that's still a successful query that returned an empty list)
- `message` = short human string; "success" by default, or a descriptive failure reason
- `data` = the payload. For lists, `data` is `{ items: [], totalRecords, currentPage, totalPages }`. For single resources, `data` is the entity. For actions, `data` is `{}` or the updated entity.

Status codes used in this codebase:
- `commonConfig.successStatus` = **200**
- `commonConfig.errorStatus` = **400**
- 401 = auth missing/expired (set directly in middleware)
- 403 = role mismatch (new — introduced with A-13 RBAC)
- 404 = resource not found
- 500 = unhandled server error

**FE rule:** read `data.items` for paged lists, `data` for single resources. Never assume `data` is non-null — empty list returns `data: []` per the helper default.

### 0.2 Auth middleware (already in `middleware/authorization.js`)

| Middleware | Sets `req.*` | Use for |
|---|---|---|
| `authenticateJWT` | `req.user` | guest/renter routes (existing standard) |
| `hostAuthentication` | `req.user` | host routes |
| `adminAuth` | `req.admin`, `req.token` | admin routes (canonical) |
| `adminAuthToken` | `req.admin`, `req.token` | admin routes (duplicate of `adminAuth` — see § 11 Q-CONV-01) |

**Convention for this sprint:** use `adminAuth` for ALL new admin endpoints. Don't add usages of `adminAuthToken`. (Cleanup of the duplicate is deferred — out of sprint scope, see § 11.)

JWT payload (current shape, A-13 extends):
```js
{ userId, email, isHost, isAdmin, iat, exp }
```
After A-13, JWT will additionally carry `{ role: "admin" | "finance" | "host" | "support" | "guest" }`. Existing fields stay for back-compat.

### 0.3 Yup validation (THE footgun)

Validation runs via `middleware/validation.js` with `stripUnknown: true`. **Any request field not declared in the schema is silently deleted before the controller runs.** This is documented inline in `schema/user.schema.js:18-22`.

**Rule for every new endpoint:**
1. Add the schema in `aajooBackend-2026/schema/<area>.schema.js`
2. Declare EVERY field the controller will read (including pagination, query filters, free-form text fields)
3. Wire the route: `validation(schema.endpointName), middleware, controller.handler`

### 0.4 Path conflicts — resolution policy

Where FE expects path X and BE currently exposes path Y, this doc names the FE path as the contract target. Backend adds the new path; old path is kept as a deprecated alias for one sprint (delete in Day 10 cleanup) UNLESS the old path has zero consumers, in which case backend renames in place.

### 0.5 Rate limiting

Every new endpoint MUST attach a rate-limiter middleware:
- `generalLimiter` — default for read endpoints
- `adminApiLimiter` — admin routes
- `uploadLimiter` — file uploads
- `adminCriticalLimiter` — admin write endpoints (login, create, destructive)

### 0.6 Pagination shape (lists)

Every list endpoint accepts:
```json
{ "page": 1, "limit": 20, "search": "optional", "sortBy": "optional", "sortDir": "asc|desc" }
```
And returns `data` shaped as:
```json
{
  "items": [ /* entities */ ],
  "totalRecords": 123,
  "currentPage": 1,
  "totalPages": 7,
  "limit": 20
}
```

Defaults: `page=1`, `limit=20`, max `limit=100`.

### 0.7 Timestamps

All timestamps in responses are ISO-8601 UTC strings (`2026-06-09T15:00:00.000Z`). Sequelize defaults `created_at` / `updated_at`. Date filter inputs accept `YYYY-MM-DD` (interpreted as Asia/Kolkata local).

### 0.8 Money

INR amounts are integers in **paise** (₹1.00 = `100`). Backend stores `DECIMAL(12,2)` rupees — convert at the API boundary. FE displays via `formatINR()` helper.

> ⚠️ **Decision needed** (Q-CONV-02 in § 11): the existing `src/pages/admin/finance/FinanceDashboard.tsx` mock uses raw rupees as integers (e.g. `totalRevenue: 1250000`). To avoid a FE refactor mid-sprint, backend returns **rupees as numbers** (not paise). This contract uses rupees throughout.

---

## 1 · Endpoint Index (60 endpoints)

| # | Area | Endpoints |
|---|---|---|
| 2 | FMS — Dashboard | 1 |
| 3 | FMS — Ledger | 5 |
| 4 | FMS — Payout | 11 |
| 5 | FMS — Invoice | 4 |
| 6 | FMS — Reconciliation | 4 |
| 7 | FMS — Reports | 5 |
| 8 | HMS — Host portal | 14 |
| 9 | HMS — Admin-side | 8 |
| 10 | Admin shell | 3 |
| 11 | KYC | 4 |
| 12 | Notifications | 3 |
| 13 | Auth fix | 1 |
| | **TOTAL** | **63** |

Reality vs the original "60-ish" estimate: 63 once expansions are counted. No surprise.

---

## 2 · FMS — Dashboard

### GET `/admin/finance/dashboard`
- **Status:** NEW · **Auth:** `adminAuth` · **Limiter:** `adminApiLimiter`
- **FE consumer:** `src/pages/admin/finance/FinanceDashboard.tsx` via `fetchFinanceDashboard` thunk
- **Tracker:** P4-FMS-05, A-03
- **Request:** none (query params optional: `?from=YYYY-MM-DD&to=YYYY-MM-DD`)
- **Yup schema fields:** `from` (string, optional, date), `to` (string, optional, date)
- **Response 200:**
```json
{
  "success": true,
  "message": "success",
  "data": {
    "totalRevenue": 1250000,
    "totalCommission": 187500,
    "totalPayouts": 1020000,
    "pendingPayouts": 32000,
    "revenueGrowth": 12.4,
    "commissionGrowth": 8.1,
    "monthlyRevenue": [
      { "month": "Oct", "revenue": 170000, "commission": 25500, "payouts": 138000 }
    ],
    "categoryBreakdown": [
      { "category": "Hotels", "revenue": 650000, "percentage": 52 }
    ],
    "recentTransactions": [ /* LedgerEntry shape — see § 3 */ ],
    "reconciliationSummary": { "matched": 45, "variance": 7, "pending": 12 }
  }
}
```
- **Notes:** FE shape mirrors existing mock at `FinanceDashboard.tsx:44-97`. Default window = trailing 6 months if no `from/to`.

---

## 3 · FMS — Ledger (5 endpoints)

**Shared entity — `LedgerEntry`:**
```json
{
  "ledger_id": 901,
  "booking_id": 4101,
  "host_id": 22,
  "user_id": 301,
  "transaction_type": "GUEST_PAYMENT|HOST_EARNING|PLATFORM_COMMISSION|TAX_COLLECTED|REFUND|PAYOUT|ADJUSTMENT",
  "entry_type": "CREDIT|DEBIT",
  "amount": 8500,
  "balance_after": 8500,
  "reference_id": "rzp_pay_xxx | rzp_payout_xxx | rzp_refund_xxx",
  "description": "Guest booking payment",
  "status": "COMPLETED|PENDING|FAILED|REVERSED",
  "created_at": "2026-06-09T10:00:00.000Z",
  "updated_at": "2026-06-09T10:00:00.000Z"
}
```

### POST `/admin/finance/ledger/search`
- **Status:** NEW · **Auth:** `adminAuth` · **Limiter:** `adminApiLimiter`
- **FE:** `LedgerList.tsx` via `ledgerList.slice`
- **Tracker:** A-03, A-04
- **Request:**
```json
{ "page": 1, "limit": 20, "search": "", "hostId": null, "userId": null,
  "transactionType": null, "dateFrom": null, "dateTo": null, "status": null }
```
- **Yup fields:** `page` (number, optional), `limit` (number, optional), `search` (string, optional), `hostId` (number, nullable, optional), `userId` (number, nullable, optional), `transactionType` (string, oneOf the 7 enums, optional), `dateFrom` (string, optional, date), `dateTo` (string, optional, date), `status` (string, oneOf 4 statuses, optional)
- **Response 200:** paged list of `LedgerEntry` (§ 0.6 shape)

### GET `/admin/finance/ledger/:ledgerId`
- **Status:** NEW · **Auth:** `adminAuth` · **Limiter:** `adminApiLimiter`
- **FE:** `LedgerDetailDrawer` (Account B may inline this — confirm)
- **Tracker:** A-04
- **Response 200:** `data: LedgerEntry`

### POST `/admin/finance/ledger/host/:hostId`
- **Status:** NEW · **Auth:** `adminAuth`
- **FE:** `HostLedger.tsx`
- **Request:** `{ page, limit, dateFrom?, dateTo? }`
- **Response 200:** `data: { items: [LedgerEntry], balance: 24500, totalRecords, currentPage, totalPages, limit }`

### POST `/admin/finance/ledger/user/:userId`
- **Status:** NEW · **Auth:** `adminAuth`
- **FE:** `GuestLedger.tsx`
- **Request:** `{ page, limit, dateFrom?, dateTo? }`
- **Response 200:** paged list

### POST `/admin/finance/ledger/export`
- **Status:** NEW · **Auth:** `adminAuth` · **Limiter:** `adminApiLimiter`
- **FE:** Export CSV button on LedgerList
- **Request:** `{ hostId?, userId?, dateFrom?, dateTo?, format: "csv"|"excel" }`
- **Response 200:** file stream (Content-Type `text/csv` or `application/vnd.ms-excel`)
- **Notes:** stream via `res.attachment('...').send(buffer)` — no JSON envelope for file downloads. FE handles via `fetch` + `blob()`.

---

## 4 · FMS — Payout (11 endpoints)

**Shared entity — `Payout`:**
```json
{
  "payout_id": 401,
  "host_id": 22,
  "amount": 24500,
  "status": "QUEUED|PROCESSING|COMPLETED|FAILED",
  "payout_method": "BANK_TRANSFER|UPI",
  "reference_id": "rzp_payout_xxx",
  "initiated_by": "SYSTEM|ADMIN",
  "initiated_at": "2026-06-09T...",
  "completed_at": null,
  "failure_reason": null,
  "period_start": "2026-06-01",
  "period_end": "2026-06-07"
}
```

**Shared entity — `PayoutSchedule`:**
```json
{
  "schedule_id": 11,
  "host_id": 22,
  "frequency": "DAILY|WEEKLY|BIWEEKLY|MONTHLY",
  "next_payout_date": "2026-06-15",
  "last_payout_date": "2026-06-08",
  "min_payout_amount": 100,
  "is_active": true,
  "payout_method": "BANK_TRANSFER|UPI",
  "account_details_masked": "XXXX1234 / HDFC0001234"
}
```

### POST `/admin/finance/payout/search`
- NEW · `adminAuth` · `PayoutQueue.tsx` + `PayoutHistory.tsx`
- Request: `{ page, limit, hostId?, status?, dateFrom?, dateTo? }`
- Response: paged list of `Payout`

### GET `/admin/finance/payout/:payoutId`
- NEW · `adminAuth` · `PayoutQueue` row drilldown
- Response: `data: Payout` with extra fields `{ ledgerEntries: [...], host: { id, name, email } }`

### POST `/admin/finance/payout/initiate`
- NEW · `adminAuth` · `adminCriticalLimiter` · "Manual Payout" button
- Request: `{ hostId, amount?, note? }` (amount omitted = pay the full pending balance)
- Yup: `hostId` (number, required), `amount` (number, optional, min 1), `note` (string, optional, max 500)
- Response: `data: { payoutId: 405, status: "QUEUED" }`

### PUT `/admin/finance/payout/:payoutId/approve`
- NEW · `adminAuth` · `adminCriticalLimiter` · Approve button on PayoutQueue
- Request: `{}` (id in URL)
- Response: `data: { payoutId, status: "PROCESSING" }`
- Notes: triggers backend RazorpayX call (or stub if RazorpayX not yet integrated; in that case, transitions to COMPLETED manually).

### PUT `/admin/finance/payout/:payoutId/reject`
- NEW · `adminAuth` · `adminCriticalLimiter` · Reject button
- Request: `{ reason: "..." }`
- Yup: `reason` (string, required, min 10, max 500)
- Response: `data: { payoutId, status: "FAILED" }`

### POST `/admin/finance/payout/schedule/search`
- NEW · `adminAuth` · `PayoutSchedules.tsx`
- Request: `{ page, limit, hostId? }`
- Response: paged list of `PayoutSchedule`

### PUT `/admin/finance/payout/schedule/:scheduleId`
- NEW · `adminAuth` · edit modal on PayoutSchedules
- Request: `{ frequency?, minPayoutAmount?, isActive?, payoutMethod? }`
- Response: `data: PayoutSchedule` (updated)

### POST `/admin/finance/payout/schedule/create`
- NEW · `adminAuth` · "Add Schedule" button
- Request: `{ hostId, frequency, minPayoutAmount, payoutMethod, accountDetails }`
- Yup: `hostId` (number, required), `frequency` (string, required, oneOf 4), `minPayoutAmount` (number, required, min 100), `payoutMethod` (string, required, oneOf 2), `accountDetails` (object, required) `{ accountNumber?, ifsc?, upiId? }`
- Response: `data: PayoutSchedule`

### GET `/host/payout-account/get` *(see § 8 — duplicate listed there)*
### PUT `/host/payout-account/update` *(see § 8)*
### GET `/host/payout/history` *(see § 8)*

The three host-facing payout endpoints are listed under § 8 HMS to keep host-portal concerns colocated.

---

## 5 · FMS — Invoice (4 endpoints)

**Shared entity — `Invoice`:**
```json
{
  "invoice_id": 501,
  "invoice_number": "AAJOO-INV-202606-0001",
  "booking_id": 4101,
  "host_id": 22,
  "user_id": 301,
  "invoice_type": "BOOKING_RECEIPT|HOST_COMMISSION|PAYOUT_STATEMENT",
  "subtotal": 8475,
  "tax_amount": 1525,
  "tax_rate": 18.00,
  "total": 10000,
  "hsn_sac_code": "996311",
  "gstin": "29AABCT1332L000",
  "pdf_url": "/uploads/invoices/AAJOO-INV-202606-0001.pdf",
  "status": "GENERATED|SENT|VOID",
  "created_at": "2026-06-09T..."
}
```

### POST `/admin/finance/invoice/search`
- NEW · `adminAuth` · `InvoiceList.tsx`
- Request: `{ page, limit, hostId?, userId?, invoiceType?, dateFrom?, dateTo?, status? }`
- Response: paged list of `Invoice`

### GET `/admin/finance/invoice/:invoiceId`
- NEW · `adminAuth` · `InvoiceDetail.tsx`
- Response: `data: Invoice` plus `data.lineItems: [{ description, quantity, rate, amount }]`

### GET `/admin/finance/invoice/:invoiceId/download`
- NEW · `adminAuth` · `adminApiLimiter`
- Response: PDF stream (`Content-Type: application/pdf`, `Content-Disposition: attachment; filename=...`)
- Notes: backend generates via `pdfkit` or reuses existing `utils/invoiceGenerator.js` (file present — verify integration).

### POST `/admin/finance/invoice/void/:invoiceId`
- NEW · `adminAuth` · `adminCriticalLimiter`
- Request: `{ reason }`
- Yup: `reason` (string, required, min 10)
- Response: `data: Invoice` (status now VOID)

---

## 6 · FMS — Reconciliation (4 endpoints)

**Shared entity — `ReconciliationRecord`:**
```json
{
  "recon_id": 1101,
  "booking_id": 4101,
  "payment_amount": 10000,
  "expected_amount": 10000,
  "payout_amount": 6975,
  "variance": 0,
  "status": "MATCHED|VARIANCE|PENDING|RESOLVED",
  "resolved_by": null,
  "resolved_at": null,
  "notes": null,
  "created_at": "2026-06-09T..."
}
```

### POST `/admin/finance/reconciliation/search`
- NEW · `adminAuth` · `ReconciliationList.tsx`
- Request: `{ page, limit, status?, dateFrom?, dateTo? }`
- Response: `data: { items: [...], totalRecords, ..., summary: { matched, variance, pending } }`

### GET `/admin/finance/reconciliation/:reconId`
- NEW · `adminAuth`
- Response: `data: ReconciliationRecord` + `{ booking: {...}, payment: {...}, payout: {...} }`

### PUT `/admin/finance/reconciliation/:reconId/resolve`
- NEW · `adminAuth` · `adminCriticalLimiter`
- Request: `{ notes, action: "ADJUST"|"WRITE_OFF"|"REFUND" }`
- Yup: `notes` (string, required, min 10), `action` (string, required, oneOf 3)
- Response: `data: ReconciliationRecord` (status RESOLVED)

### POST `/admin/finance/reconciliation/run`
- NEW · `adminAuth` · `adminCriticalLimiter`
- Request: `{ dateFrom, dateTo }`
- Yup: both dates required
- Response: `data: { jobId, status: "PROCESSING", recordsCreated: 0 }`
- Notes: async kicks off the reconciliation engine. Returns immediately. UI polls `/admin/finance/reconciliation/search` for results.

---

## 7 · FMS — Reports (5 endpoints)

### POST `/admin/finance/reports/revenue`
- NEW · `adminAuth` · `RevenueReport.tsx`
- Request: `{ dateFrom, dateTo, groupBy: "day"|"week"|"month", propertyId?, categoryId? }`
- Yup: dates required, `groupBy` required oneOf 3
- Response: `data: { items: [{ period, revenue, bookings, avgValue, growth }], totals: { revenue, bookings, avgValue } }`

### POST `/admin/finance/reports/commission`
- NEW · `adminAuth` · `CommissionReport.tsx`
- Request: `{ dateFrom, dateTo, groupBy }`
- Response: `data: { items: [{ period, commission, bookings }], totals }`

### POST `/admin/finance/reports/tax`
- NEW · `adminAuth` · `TaxSummary.tsx`
- Request: `{ dateFrom, dateTo }`
- Response: `data: { items: [{ period, taxCollected, taxPayable }], totals }`

### POST `/admin/finance/reports/cashflow`
- NEW · `adminAuth` · `CashFlowReport.tsx`
- Request: `{ dateFrom, dateTo, groupBy }`
- Response: `data: { items: [{ period, inflow, outflow, net }], totals }`

### POST `/admin/finance/reports/export`
- NEW · `adminAuth` · `adminApiLimiter`
- Request: `{ reportType: "revenue"|"commission"|"tax"|"cashflow", dateFrom, dateTo, format: "csv"|"excel" }`
- Response: file stream (no envelope)

---

## 8 · HMS — Host portal (14 endpoints)

### GET `/host/dashboard/summary`
- NEW · `hostAuthentication` · `generalLimiter`
- FE: `src/pages/host/dashboard.tsx` via `fetchHostDashboard`
- Tracker: P3-HST-02, A-07
- Response 200:
```json
{ "success": true, "message": "success", "data": {
  "monthEarnings": 18300,
  "activeListings": 4,
  "upcomingBookings": 6,
  "occupancyRate": 72,
  "recentActivity": [
    { "id": "B-1042", "type": "booking", "title": "3-night booking confirmed", "when": "2026-06-09T10:22:00.000Z", "status": "Confirmed" }
  ]
}}
```

### POST `/host/bookings/search` 🚧 INT-04 RESOLUTION
- **Status:** RENAME from existing `/host/booking-history` · `hostAuthentication` · `generalLimiter`
- **Resolution:** Add `/host/bookings/search` alongside the existing `/host/booking-history`. Both call the same controller. Delete `/host/booking-history` in Day 10 cleanup. **Reason:** FE convention `/<resource>/search` is more REST-ish and matches FMS/admin patterns; FE expects this shape already.
- FE: `HostBookings.tsx` via `hostBookings.slice`
- Tracker: INT-04, P3-HST-03, A-07
- Request: `{ page, limit, search?, status?, dateFrom?, dateTo? }`
- Response: paged list:
```json
{ "items": [ { "booking_id": 4101, "guest_name": "Rahul G", "property_title": "Sea View Villa",
  "check_in": "2026-06-15", "check_out": "2026-06-18", "amount": 10000, "status": "CONFIRMED",
  "is_paid": true } ], "totalRecords": 42, "currentPage": 1, "totalPages": 3, "limit": 20 }
```

### GET `/host/bookings/detail/:bookingId`
- NEW · `hostAuthentication`
- FE: HostBookings drilldown
- Response: `data: { booking, guest, property, timeline, payment }` — full booking detail with sub-objects

### GET `/host/earnings/summary`
- NEW · `hostAuthentication`
- FE: `HostEarnings.tsx` via `hostEarnings.slice`
- Tracker: P3-HST-04, A-07
- Response:
```json
{ "data": {
  "thisMonth": 18300, "lastMonth": 21500, "ytd": 245000,
  "pendingPayout": 6800, "nextPayoutDate": "2026-06-15",
  "trend": [{ "month": "Jan", "earnings": 22000 }],
  "commissionRate": 15,
  "recentEarnings": [{ "booking_id": 4101, "amount": 6975, "date": "2026-06-09" }]
}}
```

### GET `/host/payout/history` 🚧 INT-06 RESOLUTION
- **Status:** RENAME from existing `/payout/request/list` · `hostAuthentication`
- **Resolution:** Add `/host/payout/history` calling same controller as `/payout/request/list`. Old path deprecated.
- FE: HostEarnings + HostStatements
- Tracker: INT-06
- Request: `{ page, limit }`
- Response: paged list of `Payout` (§ 4 shape)

### GET `/host/profile/get`
- NEW · `hostAuthentication`
- FE: `HostProfile.tsx` via `hostProfile.slice`
- Tracker: P3-HST-05, A-07
- Response:
```json
{ "data": {
  "userId": 22, "fullName": "Priya S", "email": "priya@x.com", "phone": "9988776655",
  "address": "...", "city": "Goa", "state": "Goa", "country": "India",
  "avatarUrl": "https://...", "joinedAt": "2025-08-12T...",
  "verificationStatus": "verified", "verifiedAt": "2026-05-10T..."
}}
```

### PUT `/host/profile/update`
- NEW · `hostAuthentication` · `generalLimiter`
- Request: `{ fullName?, email?, phone?, address?, city?, state?, country? }`
- Yup: all optional but at least one required (use `yup.lazy` or post-validate)
- Response: `data: <updated profile>`

### GET `/host/payout-account/get` 🚧 INT-05 RESOLUTION
- **Status:** RENAME from existing `/payout/account/details` · `hostAuthentication`
- **Resolution:** Add `/host/payout-account/get` alongside existing `/payout/account/details`.
- FE: HostProfile bank section
- Tracker: INT-05
- Response: `data: { accountNumber: "XXXX1234", ifsc: "HDFC0001234", accountHolderName: "Priya S", upiId: null, isVerified: true }` (account number masked except last 4)

### PUT `/host/payout-account/update`
- **Status:** RENAME from existing `/payout/account/details-add` · `hostAuthentication`
- Request: `{ accountNumber, confirmAccountNumber, ifsc, accountHolderName }` or `{ upiId }`
- Yup: matches existing `schema/payout.schema.js createHostAccDetails`; reuse if shape identical
- Response: `data: <updated account>`

### POST `/host/statements/search`
- NEW · `hostAuthentication`
- FE: `HostStatements.tsx` via NEW `hostStatements.slice`
- Tracker: P3-HST-06, A-07
- Request: `{ page, limit, year?, month? }`
- Response: paged list:
```json
{ "items": [{ "statement_id": 801, "period": "2026-05", "totalEarnings": 45000,
  "totalCommission": 6750, "totalPayouts": 38250, "invoiceCount": 12,
  "generatedAt": "2026-06-01T..." }], "totalRecords": 12, "currentPage": 1, "totalPages": 1, "limit": 20 }
```

### GET `/host/statements/download/:statementId`
- NEW · `hostAuthentication`
- Response: PDF stream

### POST `/host/support/tickets/search` 🚧 INT-07
- NEW · `hostAuthentication`
- FE: `HostSupport.tsx` via NEW `hostSupport.slice`
- Tracker: INT-07, P3-HST-07
- Request: `{ page, limit, status?, dateFrom?, dateTo? }`
- Response: paged list:
```json
{ "items": [{ "ticket_id": 901, "subject": "Payout delay", "status": "OPEN|RESOLVED|PENDING",
  "category": "PAYOUT|BOOKING|PROFILE|OTHER", "createdAt": "2026-06-08T...",
  "lastReplyAt": "2026-06-09T...", "unreadCount": 2 }], "totalRecords": 5, ... }
```

### POST `/host/support/tickets/create`
- NEW · `hostAuthentication`
- Request: `{ subject, category, message }`
- Yup: `subject` (required, max 200), `category` (required, oneOf 4), `message` (required, min 10, max 5000)
- Response: `data: { ticket_id, status: "OPEN" }`

### POST `/host/support/tickets/reply`
- NEW · `hostAuthentication`
- Request: `{ ticketId, message }`
- Yup: `ticketId` (required, number), `message` (required, min 1, max 5000)
- Response: `data: { messageId, ticketId, at }`

> **NOTE on messages:** the original FE plan listed separate `/host/messages/list` + `/host/messages/send` (INT-08). After reviewing socket.io infra in `sockets/index.js` (`registerChatHandlers` exists), the recommendation is to fold "Communication" into either (a) the support-tickets endpoints above OR (b) the existing socket.io channel.
>
> **Resolution INT-08:** for Day 1 contract, `HostCommunication.tsx` consumes the support tickets endpoints with `category="GENERAL"`. The dedicated `/host/messages/*` REST endpoints are CUT from sprint scope. Real-time chat upgrade (via socket.io) is a post-sprint enhancement. Account B updates `HostCommunication.tsx` to use tickets API. → See § 11 Q-RES-INT08.

### GET `/host/performance/summary`
- NEW · `hostAuthentication`
- FE: `HostPerformance.tsx` via NEW `hostPerformance.slice` — **ONE endpoint, not 4** (simplifies FE wiring)
- Tracker: P3-HST-09, P4-HMS-04, A-07
- Request: query `?dateFrom=&dateTo=` (default trailing 90 days)
- Response:
```json
{ "data": {
  "occupancy": { "current": 72, "previous": 68, "trend": [{ "period": "2026-05", "value": 65 }] },
  "revenue":   { "current": 245000, "previous": 220000, "trend": [...] },
  "cancellations": { "current": 3, "previous": 5, "trend": [...] },
  "ratings":   { "current": 4.6, "previous": 4.5, "trend": [...] }
}}
```

### POST `/host/onboarding/submit` 🚧 INT-10
- NEW · `authenticateJWT` (any logged-in user; backend updates `isHost` to true)
- FE: `BecomeHost.tsx` form submit
- Tracker: INT-10
- Request: `{ propertyType, city, state, country, hostingExperience, contactName, contactPhone, message }`
- Yup: all required strings; phone matches `^\d{10}$`
- Response: `data: { applicationId, status: "RECEIVED", nextStep: "kyc" }`

---

## 9 · HMS — Admin-side (8 endpoints)

### GET `/admin/host/detail/:hostId`
- NEW · `adminAuth` · `adminApiLimiter`
- FE: `HostDetailDialog.tsx` Detail tab
- Tracker: P3-ADM-05, A-08
- Response:
```json
{ "data": {
  "host": { "userId": 22, "fullName": "Priya S", "email": "...", "phone": "...",
            "joinedAt": "...", "verificationStatus": "verified", "isActive": true },
  "kycStatus": "verified",
  "stats": { "totalProperties": 4, "activeBookings": 6, "totalEarnings": 245000, "rating": 4.6 },
  "lastLoginAt": "2026-06-09T...",
  "contactTimeline": [{ "type": "support", "at": "...", "summary": "..." }]
}}
```

### GET `/admin/host/kyc/detail/:hostId`
- NEW · `adminAuth`
- FE: HostDetailDialog KYC tab
- Tracker: INT-11
- Response:
```json
{ "data": {
  "userId": 22, "verification_status": "in_review",
  "didit_session_id": "sess_xxx", "submittedAt": "...",
  "documents": [{ "type": "ID_FRONT", "url": "...", "verifiedAt": null }],
  "diditDecision": { "score": 0.92, "flags": [] },
  "consoleLinkBase": "https://console.didit.me/session/" /* + session_id */
}}
```

### POST `/admin/host/kyc/approve`
- NEW · `adminAuth` · `adminCriticalLimiter`
- FE: HostActions.tsx + HostDetailDialog
- Tracker: INT-11
- Request: `{ hostId, note? }`
- Yup: `hostId` required number, `note` optional string max 500
- Response: `data: { hostId, verification_status: "verified", verified_at }`
- Notes: side effect — backend writes ledger entry, fires notification to host, unlocks property listing.

### POST `/admin/host/kyc/reject`
- NEW · `adminAuth` · `adminCriticalLimiter`
- Request: `{ hostId, reason }`
- Yup: `reason` required min 10
- Response: `data: { hostId, verification_status: "declined", reason }`

### GET `/admin/host/performance/summary?hostId=`
- NEW · `adminAuth`
- FE: HostDetailDialog Performance tab
- Tracker: P3-ADM-05
- Request: query `hostId` required, optional `dateFrom`/`dateTo`
- Response: same shape as `/host/performance/summary` but scoped admin (no role-check on hostId match)

### GET `/admin/host/payout/history?hostId=`
- NEW · `adminAuth`
- FE: HostDetailDialog Payout tab
- Request: query `hostId` required, `page`, `limit`
- Response: paged list of `Payout` for that host + `data.summary: { totalPaidOut, pending, holdAmount }`

### POST `/admin/host/payout/hold`
- NEW · `adminAuth` · `adminCriticalLimiter`
- Request: `{ hostId, reason }`
- Response: `data: { hostId, payoutsOnHold: true, reason, holdAt }`
- Notes: marks future payouts as ineligible until released.

### POST `/admin/host/payout/release`
- NEW · `adminAuth` · `adminCriticalLimiter`
- Request: `{ hostId, note? }`
- Response: `data: { hostId, payoutsOnHold: false, releasedAt }`

---

## 10 · Admin shell (3 endpoints)

### GET `/admin/verify-token` 🚧 INT-02 RESOLUTION
- NEW · `adminAuth`
- FE: `AdminProtectedRoute` boot — confirms admin session is still valid
- Tracker: INT-02
- Request: none (token in Authorization header)
- Response: `data: { adminId, email, role: "admin", isValid: true }` on 200; 401 on expired
- **Resolution INT-02:** add this endpoint. FE flips from current "trust localStorage" to "verify on each boot". Account B work — coordinate.

### GET `/admin/notifications/search`
- NEW · `adminAuth`
- FE: `AdminNotifySidebar.tsx` via `notifications.slice`
- Tracker: GAP-08, A-14
- Request: query `?page=1&limit=20&category=&unreadOnly=false`
- Response: paged list:
```json
{ "items": [{ "id": 1, "category": "BOOKING|USER|HOST|PAYOUT|KYC|SYSTEM",
  "title": "New host registered", "body": "...", "isRead": false,
  "linkPath": "/admin/host", "createdAt": "..." }], "totalRecords": 12, ... }
```

### PUT `/admin/notifications/:id/read`
- NEW · `adminAuth`
- Request: `{}`
- Response: `data: { id, isRead: true }`

> **Host-side notifications** share the same backend table with a `recipient_role` column. FE consumer is the host header dropdown (B-13). Endpoint: `GET /host/notifications/search` (same shape as admin) and `PUT /host/notifications/:id/read`. Listed here under "Admin shell" but implemented in same controller, separate routes.

---

## 11 · KYC — Didit (4 endpoints + 1 webhook)

> **Stack reminders:** MySQL/Sequelize; webhook MUST use `express.raw()` body parser so HMAC over raw bytes works. All Didit secrets env-gated.

### POST `/verify/create-session`
- NEW · `authenticateJWT` OR `hostAuthentication` (accept either — controller branches on `req.user.isHost`)
- FE: KYC VerifyButton (Account B B-10)
- Tracker: KYC-BE-05, A-12
- Request:
```json
{ "context": "host_kyc|guest_kyc", "bookingId": 4101 /* required only for guest_kyc */ }
```
- Yup: `context` required oneOf 2; `bookingId` required-if context is guest_kyc
- Response:
```json
{ "data": {
  "sessionId": "sess_xxx",
  "sessionUrl": "https://verify.didit.me/...",
  "vendorData": "host_22" /* or guest_301_booking_4101 */,
  "expiresAt": "2026-06-09T...+24h"
}}
```
- Notes: backend calls Didit `POST /v3/session/` with chosen workflow_id (`HOST_KYC_WORKFLOW_ID` or `GUEST_KYC_WORKFLOW_ID` env vars). Stores `didit_session_id` on user/booking. Sets `verification_status='pending'`.

### GET `/verify/status?sessionId=...`
- NEW · `authenticateJWT` (or `hostAuthentication`)
- FE: `/verify/complete` polling page
- Request: query `sessionId` required
- Response:
```json
{ "data": { "sessionId": "sess_xxx", "status": "pending|verified|declined|in_review|expired",
  "verifiedAt": null, "expiresAt": "...", "skipReason": null /* or "verified_within_90_days" */ }}
```

### GET `/verify/check-session/:sessionId`
- NEW · `authenticateJWT`
- Polling fallback (calls Didit `GET /v3/session/:id/decision/` directly)
- Response: same shape as `/verify/status`

### POST `/webhooks/didit`
- NEW · NO AUTH MIDDLEWARE (Didit signs with HMAC instead) · NO RATE LIMITER (Didit retries)
- **CRITICAL:** mount with `express.raw({ type: 'application/json' })`. Verify `x-signature-v2` header using HMAC-SHA256 over raw body with `DIDIT_WEBHOOK_SECRET` before parsing JSON.
- Request body (after verify): standard Didit webhook payload
- Response: 200 `{ received: true }` (Didit retries on non-2xx)
- Side effects: routes to `handleApproved` / `handleDeclined` / `handleInReview` handlers — update DB, fire notifications, unblock UI gates.

### Sequelize migrations driven by KYC-BE (Account A's A-11):
- `tbl_user` adds `didit_session_id` (varchar 64 null), `verification_status` (enum 5 values, default 'unverified'), `verified_at` (datetime null), `verification_expires_at` (datetime null) + indexes
- `tbl_bookings` adds `guest_verification_status` (enum 5), `guest_didit_session_id`
- `tbl_property` status enum gains `pending_verification`
- `tbl_admin_flags` new table `(id, user_id, session_id, flag_type, resolved, notes, created_at)`

---

## 12 · Notifications (already covered in § 10 — endpoints listed here for indexing)

| Path | Method | Auth | Used by |
|---|---|---|---|
| `/admin/notifications/search` | GET | adminAuth | AdminNotifySidebar |
| `/admin/notifications/:id/read` | PUT | adminAuth | AdminNotifySidebar |
| `/host/notifications/search` | GET | hostAuthentication | HostHeader dropdown |
| `/host/notifications/:id/read` | PUT | hostAuthentication | HostHeader dropdown |

(4 endpoints; original count was 3 — counted host vs admin separately.)

**Backend implementation:** ONE table `tbl_notifications (id, recipient_role enum, recipient_id, category, title, body, link_path, is_read, created_at)`. ONE controller with two routes that filter by `recipient_role`. Event hooks in: `booking.controller.js` (on confirm), `payout.controller.js` (on initiate/complete/fail), `verify.controller.js` (on in_review).

---

## 13 · Auth fix (1 endpoint) — INT-12

### POST `/user/forgot-password/request`
- **Status:** FIX existing — currently `POST /user/update/forget-password` is gated by `authenticateJWT`, which is wrong for forgot-password (the user is logged out)
- **Resolution:** add new public endpoint `POST /user/forgot-password/request` with NO auth, only `generalLimiter`. Old auth-gated endpoint stays for in-session password change (different feature). FE swaps to new endpoint.
- Tracker: INT-12
- Request: `{ email }`
- Yup: `email` required, valid email
- Response: `data: {}` with 200 always (do not leak whether email exists — security best practice)
- Side effect: backend sends OTP via mailer.js (or after A-10, via Brevo HTTP API).

---

## 14 · Path Conflicts — Resolution Summary

| ID | FE expects | BE currently has | Resolution | Cleanup day |
|---|---|---|---|---|
| INT-02 | `GET /admin/verify-token` | (missing) | Add new endpoint § 10 | — |
| INT-04 | `POST /host/bookings/search` | `POST /host/booking-history` | Add new path, both call same controller | Day 10 — remove old |
| INT-05 | `GET /host/payout-account/get` + `PUT /host/payout-account/update` | `GET /payout/account/details` + `POST /payout/account/details-add` | Add new paths, same controllers; PUT replaces POST for update semantics | Day 10 |
| INT-06 | `GET /host/payout/history` | `GET /payout/request/list` | Add new path, same controller | Day 10 |
| INT-07 | `/host/support/tickets/*` | (missing) | Build new (§ 8) | — |
| INT-08 | `/host/messages/*` | (socket.io chat handlers exist) | **CUT scope** — `HostCommunication` uses tickets API instead. Socket.io chat is post-sprint upgrade. | — |
| INT-09 | `/host/performance/summary` | (missing) | Build new (§ 8) — ONE endpoint covering all 4 dimensions (not 4 separate) | — |
| INT-10 | `POST /host/onboarding/submit` | (missing) | Build new (§ 8) | — |
| INT-11 | `/admin/host/kyc/*` | (missing) | Build new (§ 9) | — |
| INT-12 | public forgot-password | auth-gated `/user/update/forget-password` | Add new public path § 13; keep old for in-session change | — |
| INT-13 | CORS `FRONTEND_URL` correct | currently `origin: true` (all) | Backend hardens in A-16 — tighten to `FRONTEND_URL` env var | Day 7 |

---

## 15 · Yup schema files to create / extend

Per § 0.3 footgun. Touch these files (Account A):

| File | New / Extend | Schemas needed |
|---|---|---|
| `aajooBackend-2026/schema/adminFinance.schema.js` | NEW | ledgerSearch, ledgerExport, payoutSearch, payoutInitiate, payoutApprove, payoutReject, scheduleCreate, scheduleUpdate, invoiceSearch, invoiceVoid, reconSearch, reconResolve, reconRun, reportRevenue, reportCommission, reportTax, reportCashflow, reportExport |
| `aajooBackend-2026/schema/host.schema.js` | EXTEND | bookingSearch, bookingDetail, profileUpdate, payoutAccountUpdate, statementSearch, ticketSearch, ticketCreate, ticketReply, performanceSummary, onboardingSubmit |
| `aajooBackend-2026/schema/adminHost.schema.js` | NEW (or extend `adminUser.schema.js`) | hostDetailGet, kycDetailGet, kycApprove, kycReject, perfSummaryGet, payoutHistoryGet, payoutHold, payoutRelease |
| `aajooBackend-2026/schema/admin.schema.js` | EXTEND | verifyToken (no body), notificationsSearch, notificationsRead |
| `aajooBackend-2026/schema/verify.schema.js` | NEW | createSession, statusGet, checkSessionGet |
| `aajooBackend-2026/schema/notification.schema.js` | NEW | search, markRead |

---

## 16 · Open questions / decisions log

| ID | Question | Default | Resolved by |
|---|---|---|---|
| Q-CONV-01 | `adminAuth` vs `adminAuthToken` — two near-identical middlewares. Consolidate? | Use `adminAuth` for all new endpoints; cleanup of duplicate is post-sprint. | Account A (declared above) |
| Q-CONV-02 | Money: paise or rupees over the wire? | Rupees (matches FE mock; cheap). | Account A (declared above) |
| Q-CONV-03 | Pagination default `limit` and max | Default 20, max 100. | Account A (declared above) |
| Q-RES-INT08 | Host messages — REST or socket.io? | CUT REST; fold into tickets. Socket.io chat is post-sprint. | Account A (declared above) — confirms with Sumit Day 2 AM |
| Q-RBAC | RBAC role taxonomy (A-13 question) | `admin / finance / host / support / guest` | Sumit — see § 11 of FULL_DELIVERY_PLAN.md |
| Q-CSV | CSV export format — UTF-8 BOM for Excel compatibility? | Yes, prepend BOM | Account A (declared above) |
| Q-PDF | Invoice PDF template — existing `utils/invoiceGenerator.js` usable? | Account A reads in A-05 and either reuses or replaces. Final decision logged in A-05 Notes. | Account A (Day 2) |

---

## 17 · Change log

| Date | Change | Author |
|---|---|---|
| 2026-06-09 21:30 | v1.0 — initial contract drafted | Account A (A-01) |
| 2026-06-09 21:40 | v1.1 — FMS tables created with names `tbl_financial_ledger`, `tbl_payouts` (plural — distinct from existing `tbl_payout_req`), `tbl_payout_schedules`, `tbl_invoices`, `tbl_reconciliation_records`. Existing `tbl_host_earnings` / `tbl_payout_req` / `tbl_payout_history` / `tbl_host_acc_details` continue to serve old flows; new controllers write to new tables only. No data migration in sprint scope. | Account A (A-02) |
| 2026-06-10 12:19 | v1.2 — **RBAC role claim live (A-13).** JWT now carries `role: "admin"\|"finance"\|"host"\|"guest"` (derived in `utils/methods.genrateToken`; explicit `role` on payload wins for finance/support). `requireRole(...roles)` middleware in `middleware/authorization.js` — compose after an auth middleware; admin is superuser (always passes). Legacy tokens (no role claim) fall back to derivation from isAdmin/isHost. FE (Account B B-12) reads `role` for route guards. | Account A (A-13) |

---

*This doc is the single source of API truth during the sprint. If implementation deviates, update this doc FIRST, then code.*
