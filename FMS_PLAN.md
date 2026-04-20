# Finance Management System (FMS) — Detailed Development Plan

> **Module:** Phase 4A — Finance Management System  
> **Project:** AAJOO Homes  
> **Status:** Planning  
> **Created:** March 10, 2026  
> **Estimated Effort:** ~27 tasks, 8–10 business days

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [What We're Building](#2-what-were-building)
3. [Current Foundation (What Already Exists)](#3-current-foundation)
4. [System Architecture](#4-system-architecture)
5. [Data Models & API Contracts](#5-data-models--api-contracts)
6. [Frontend Architecture](#6-frontend-architecture)
7. [Backend Strategy](#7-backend-strategy)
8. [Development Order](#8-development-order)
9. [Screen-by-Screen Specification](#9-screen-by-screen-specification)
10. [Integration Points](#10-integration-points)
11. [File Structure (What Gets Created)](#11-file-structure)

---

## 1. Executive Summary

The FMS is a completely new module — **zero code exists today**. It adds financial visibility, payout processing, reconciliation, invoicing, and reporting capabilities to the AAJOO Homes admin panel.

### What it does (in plain terms):

1. **Tracks every rupee** flowing through the platform — guest payments, host earnings, platform commissions, taxes, refunds
2. **Manages host payouts** — calculates what each host is owed, schedules payouts, tracks execution
3. **Reconciles** — matches bookings → payments → payouts to catch discrepancies
4. **Generates invoices** — GST-compliant invoices for hosts and guests, downloadable as PDF
5. **Reports & dashboards** — revenue, commission, cash flow charts and KPIs for the admin

### Who uses it:

| Role | What they see |
|------|---------------|
| **Admin** | Full FMS dashboard: ledgers, payouts, reconciliation, reports, invoices |
| **Host** | Earnings summary, payout history, invoice downloads (in Host Portal — Phase 4B) |
| **Guest** | Transaction history, booking receipts (future enhancement to existing UserTransactions stub) |

---

## 2. What We're Building

### Module Map

```
Finance Management System (FMS)
│
├── 1. Finance Dashboard (Admin)
│   ├── Revenue KPI cards (total revenue, commission, net payouts, pending)
│   ├── Revenue trend chart (line — monthly)
│   ├── Commission breakdown chart (pie — by property category)
│   ├── Payout status overview (gauge — completed vs pending)
│   └── Recent transactions table (quick view, links to full list)
│
├── 2. Ledger Management
│   ├── Host Ledger — per-host transaction history
│   ├── Guest Ledger — per-guest payment history
│   ├── Platform Ledger — platform commission + fee records
│   └── Transaction Search — unified search across all ledgers
│
├── 3. Payout Processing
│   ├── Payout Queue — pending payouts list with approval workflow
│   ├── Payout Schedule Config — frequency rules per host (daily/weekly/monthly)
│   ├── Payout Execution Log — status tracking (initiated/processing/completed/failed)
│   └── Manual Payout Trigger — admin can force-process a payout
│
├── 4. Reconciliation
│   ├── Booking-to-Payment matching view
│   ├── Payment-to-Payout matching view
│   ├── Variance/Discrepancy report
│   └── Reconciliation Status Dashboard
│
├── 5. Invoice Generation
│   ├── Invoice List (all invoices, filterable)
│   ├── Invoice Detail View
│   ├── PDF Download
│   └── GST-compliant template (HSN, SAC codes, GSTIN)
│
└── 6. Reports & Analytics
    ├── Revenue Report (date range, property, category filters)
    ├── Commission Report (platform earnings breakdown)
    ├── Tax Summary Report (GST collected, payable)
    ├── Cash Flow Report (inflows vs outflows over time)
    └── Export to CSV/Excel
```

---

## 3. Current Foundation

### What we CAN build on:

| Existing | Location | How FMS Uses It |
|----------|----------|-----------------|
| Booking payment data | `BookingDetail.pricing` | Source of truth for ledger entries — every booking generates a financial record |
| Payment status | `book_is_paid`, `book_is_cod` | Drives reconciliation matching |
| Razorpay component | `RazorpayPayment.tsx` | Payment gateway — FMS needs to consume transaction IDs from Razorpay callbacks |
| Admin booking table | `AdminBookingTable.tsx` | Already shows amount + payment status — FMS extends this data |
| Chart components | `src/components/admin/charts/` | LineChart, BarChart, PieChart, GaugeChart, SparkLine — all reusable for FMS dashboard |
| Table + Pagination | `adminTable/`, `Pagination/` | Reusable for all FMS list views |
| Modal pattern | `AdminCommonModal/`, `modals/` | Reusable for ledger detail, invoice detail, payout approval |
| Redux slice pattern | `src/features/admin/Bookings/` | Same createAsyncThunk + slice architecture |
| API layer | `src/services/api.ts` | Axios instance with auth interceptor — all FMS API calls go through this |
| Yup validations | `src/validations/admin-validations.tsx` | Add FMS-specific schemas to this file |
| Sidebar nav | `AdminSidebar.tsx` | Add "Finance" nav item with sub-items |
| Admin layout | `AdminLayout.tsx` | FMS pages render inside existing `<Outlet />` |

### What does NOT exist (must be built from scratch):

- No financial transaction model or table
- No ledger concept
- No payout scheduling or processing
- No reconciliation engine
- No invoice generation
- No revenue/commission tracking
- No financial Redux slices
- No financial API endpoints
- No finance admin pages/routes

---

## 4. System Architecture

### Data Flow Diagram

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Guest books  │───►│   Booking    │───►│   Payment    │
│  a property   │    │   Created    │    │  via Razorpay│
└──────────────┘    └──────┬───────┘    └──────┬───────┘
                           │                    │
                    ┌──────▼────────────────────▼───────┐
                    │        LEDGER ENGINE (Backend)     │
                    │                                    │
                    │  Creates entries:                  │
                    │  ► Guest debit  (amount paid)      │
                    │  ► Host credit  (host share)       │
                    │  ► Platform credit (commission)    │
                    │  ► Tax record   (GST component)    │
                    └──────┬───────────────────┬────────┘
                           │                   │
                    ┌──────▼───────┐    ┌──────▼───────┐
                    │   Payout     │    │   Invoice    │
                    │   Scheduler  │    │   Generator  │
                    │              │    │              │
                    │ Aggregates   │    │ Auto-creates │
                    │ host credits │    │ on booking   │
                    │ → payout     │    │ confirmation │
                    └──────┬───────┘    └──────────────┘
                           │
                    ┌──────▼───────┐
                    │  Payout      │
                    │  Execution   │
                    │  (Bank/UPI)  │
                    └──────┬───────┘
                           │
                    ┌──────▼──────────────┐
                    │   Reconciliation    │
                    │                     │
                    │ Booking ↔ Payment   │
                    │ Payment ↔ Payout    │
                    │ Detects variances   │
                    └─────────────────────┘
```

### Financial Transaction Lifecycle

```
Booking Confirmed
    │
    ├── Razorpay payment captured → payment_id stored
    │
    ├── Ledger Entry: GUEST_PAYMENT (debit from guest perspective)
    │   └── amount = book_total_amt
    │
    ├── Ledger Entry: PLATFORM_COMMISSION (credit to platform)
    │   └── amount = book_total_amt × commission_rate
    │
    ├── Ledger Entry: HOST_EARNING (credit to host)
    │   └── amount = book_total_amt - commission - tax
    │
    ├── Ledger Entry: TAX_COLLECTED (GST)
    │   └── amount = book_tax
    │
    ├── Invoice generated → invoice_number assigned
    │
    └── Host payout queued → based on schedule (daily/weekly/monthly)

Booking Cancelled
    │
    ├── Ledger Entry: REFUND (credit back to guest)
    ├── Ledger Entry: COMMISSION_REVERSAL (if applicable)
    ├── Ledger Entry: HOST_EARNING_REVERSAL
    └── Payout adjustment (reduce pending payout)
```

---

## 5. Data Models & API Contracts

### 5.1 Database Models (Backend)

#### `financial_ledger`

| Column | Type | Description |
|--------|------|-------------|
| `ledger_id` | UUID/INT (PK) | Unique ledger entry ID |
| `booking_id` | INT (FK) | Related booking |
| `host_id` | INT (FK, nullable) | Related host (null for guest-only entries) |
| `user_id` | INT (FK, nullable) | Related guest |
| `transaction_type` | ENUM | `GUEST_PAYMENT`, `HOST_EARNING`, `PLATFORM_COMMISSION`, `TAX_COLLECTED`, `REFUND`, `PAYOUT`, `ADJUSTMENT` |
| `entry_type` | ENUM | `CREDIT`, `DEBIT` |
| `amount` | DECIMAL(12,2) | Transaction amount in INR |
| `balance_after` | DECIMAL(12,2) | Running balance after this entry |
| `reference_id` | VARCHAR | Razorpay payment_id / payout_id / refund_id |
| `description` | TEXT | Human-readable description |
| `status` | ENUM | `COMPLETED`, `PENDING`, `FAILED`, `REVERSED` |
| `created_at` | TIMESTAMP | Entry creation time |
| `updated_at` | TIMESTAMP | Last update time |

#### `payout_schedule`

| Column | Type | Description |
|--------|------|-------------|
| `schedule_id` | INT (PK) | |
| `host_id` | INT (FK) | Which host |
| `frequency` | ENUM | `DAILY`, `WEEKLY`, `BIWEEKLY`, `MONTHLY` |
| `next_payout_date` | DATE | Computed next date |
| `last_payout_date` | DATE | Last processed date |
| `min_payout_amount` | DECIMAL(10,2) | Minimum threshold to trigger payout |
| `is_active` | BOOLEAN | Whether auto-payout is enabled |
| `payout_method` | ENUM | `BANK_TRANSFER`, `UPI` |
| `account_details` | JSON | Encrypted bank account or UPI details |
| `created_at` | TIMESTAMP | |

#### `payout`

| Column | Type | Description |
|--------|------|-------------|
| `payout_id` | INT (PK) | |
| `host_id` | INT (FK) | |
| `amount` | DECIMAL(12,2) | Total payout amount |
| `status` | ENUM | `QUEUED`, `PROCESSING`, `COMPLETED`, `FAILED` |
| `payout_method` | ENUM | `BANK_TRANSFER`, `UPI` |
| `reference_id` | VARCHAR | Payment gateway payout reference |
| `initiated_by` | ENUM | `SYSTEM` (auto), `ADMIN` (manual) |
| `initiated_at` | TIMESTAMP | When payout was triggered |
| `completed_at` | TIMESTAMP | When payout was confirmed |
| `failure_reason` | TEXT | If failed, why |
| `period_start` | DATE | Earning period start |
| `period_end` | DATE | Earning period end |

#### `invoice`

| Column | Type | Description |
|--------|------|-------------|
| `invoice_id` | INT (PK) | |
| `invoice_number` | VARCHAR | Format: `AAJOO-INV-YYYYMM-XXXX` |
| `booking_id` | INT (FK) | |
| `host_id` | INT (FK) | |
| `user_id` | INT (FK) | Guest |
| `invoice_type` | ENUM | `BOOKING_RECEIPT`, `HOST_COMMISSION`, `PAYOUT_STATEMENT` |
| `subtotal` | DECIMAL(12,2) | Before tax |
| `tax_amount` | DECIMAL(12,2) | GST amount |
| `tax_rate` | DECIMAL(5,2) | GST rate (e.g., 18.00) |
| `total` | DECIMAL(12,2) | After tax |
| `hsn_sac_code` | VARCHAR | GST classification code |
| `gstin` | VARCHAR | GSTIN of issuer |
| `pdf_url` | VARCHAR | S3/storage path to generated PDF |
| `status` | ENUM | `GENERATED`, `SENT`, `VOID` |
| `created_at` | TIMESTAMP | |

#### `reconciliation_record`

| Column | Type | Description |
|--------|------|-------------|
| `recon_id` | INT (PK) | |
| `booking_id` | INT (FK) | |
| `payment_amount` | DECIMAL(12,2) | What Razorpay captured |
| `expected_amount` | DECIMAL(12,2) | What booking says should be paid |
| `payout_amount` | DECIMAL(12,2) | What was paid out to host |
| `variance` | DECIMAL(12,2) | Difference (should be 0) |
| `status` | ENUM | `MATCHED`, `VARIANCE`, `PENDING`, `RESOLVED` |
| `resolved_by` | INT | Admin who resolved variance |
| `resolved_at` | TIMESTAMP | |
| `notes` | TEXT | Admin notes on resolution |
| `created_at` | TIMESTAMP | |

---

### 5.2 API Endpoints

All new endpoints go under `/admin/finance/` namespace.

#### Ledger APIs

```
POST   /admin/finance/ledger/search
       Body: { page, limit, search?, hostId?, userId?, transactionType?, dateFrom?, dateTo?, status? }
       Response: { ledgers: [], totalRecords, currentPage, totalPages }

GET    /admin/finance/ledger/:ledgerId
       Response: { ledger: LedgerEntry }

POST   /admin/finance/ledger/host/:hostId
       Body: { page, limit, dateFrom?, dateTo? }
       Response: { ledgers: [], balance, totalRecords, currentPage, totalPages }

POST   /admin/finance/ledger/user/:userId
       Body: { page, limit, dateFrom?, dateTo? }
       Response: { ledgers: [], totalRecords, currentPage, totalPages }

POST   /admin/finance/ledger/export
       Body: { hostId?, userId?, dateFrom?, dateTo?, format: "csv"|"excel" }
       Response: File download
```

#### Payout APIs

```
POST   /admin/finance/payout/search
       Body: { page, limit, hostId?, status?, dateFrom?, dateTo? }
       Response: { payouts: [], totalRecords, currentPage, totalPages }

GET    /admin/finance/payout/:payoutId
       Response: { payout: PayoutDetail }

POST   /admin/finance/payout/initiate
       Body: { hostId, amount?, note? }
       Response: { payoutId, status: "QUEUED" }

PUT    /admin/finance/payout/:payoutId/approve
       Response: { status: "PROCESSING" }

PUT    /admin/finance/payout/:payoutId/reject
       Body: { reason }
       Response: { status: "FAILED" }

POST   /admin/finance/payout/schedule/search
       Body: { page, limit, hostId? }
       Response: { schedules: [] }

PUT    /admin/finance/payout/schedule/:scheduleId
       Body: { frequency?, minPayoutAmount?, isActive?, payoutMethod? }
       Response: { schedule }

POST   /admin/finance/payout/schedule/create
       Body: { hostId, frequency, minPayoutAmount, payoutMethod, accountDetails }
       Response: { schedule }
```

#### Invoice APIs

```
POST   /admin/finance/invoice/search
       Body: { page, limit, hostId?, userId?, invoiceType?, dateFrom?, dateTo?, status? }
       Response: { invoices: [], totalRecords, currentPage, totalPages }

GET    /admin/finance/invoice/:invoiceId
       Response: { invoice: InvoiceDetail }

GET    /admin/finance/invoice/:invoiceId/download
       Response: PDF file stream

POST   /admin/finance/invoice/void/:invoiceId
       Body: { reason }
       Response: { invoice }
```

#### Reconciliation APIs

```
POST   /admin/finance/reconciliation/search
       Body: { page, limit, status?, dateFrom?, dateTo? }
       Response: { records: [], totalRecords, currentPage, totalPages, summary: { matched, variance, pending } }

GET    /admin/finance/reconciliation/:reconId
       Response: { record: ReconciliationDetail }

PUT    /admin/finance/reconciliation/:reconId/resolve
       Body: { notes, action: "ADJUST"|"WRITE_OFF"|"REFUND" }
       Response: { record }

POST   /admin/finance/reconciliation/run
       Body: { dateFrom, dateTo }
       Response: { jobId, status: "PROCESSING" }
```

#### Dashboard & Reports APIs

```
GET    /admin/finance/dashboard
       Response: {
         totalRevenue, totalCommission, totalPayouts, pendingPayouts,
         revenueGrowth, commissionGrowth,
         monthlyRevenue: [{ month, revenue, commission, payouts }],
         categoryBreakdown: [{ category, revenue, percentage }],
         recentTransactions: LedgerEntry[],
         reconciliationSummary: { matched, variance, pending }
       }

POST   /admin/finance/reports/revenue
       Body: { dateFrom, dateTo, groupBy: "day"|"week"|"month", propertyId?, categoryId? }
       Response: { data: [{ period, revenue, bookings, avgValue }], totals }

POST   /admin/finance/reports/commission
       Body: { dateFrom, dateTo, groupBy }
       Response: { data: [{ period, commission, bookings }], totals }

POST   /admin/finance/reports/tax
       Body: { dateFrom, dateTo }
       Response: { data: [{ period, taxCollected, taxPayable }], totals }

POST   /admin/finance/reports/cashflow
       Body: { dateFrom, dateTo, groupBy }
       Response: { data: [{ period, inflow, outflow, net }], totals }

POST   /admin/finance/reports/export
       Body: { reportType, dateFrom, dateTo, format: "csv"|"excel" }
       Response: File download
```

---

## 6. Frontend Architecture

### 6.1 Page Components (What the Admin Sees)

```
src/pages/admin/finance/
├── FinanceDashboard.tsx          ← Main FMS landing page with KPIs + charts
├── LedgerList.tsx                ← Unified transaction ledger with search/filter
├── HostLedger.tsx                ← Single host's ledger (drilldown from LedgerList)
├── GuestLedger.tsx               ← Single guest's payment history
├── PayoutQueue.tsx               ← Pending payouts — approve/reject workflow
├── PayoutHistory.tsx             ← Completed/failed payouts log
├── PayoutSchedules.tsx           ← Configure host payout schedules
├── ReconciliationDashboard.tsx   ← Reconciliation status overview
├── ReconciliationList.tsx        ← Detailed reconciliation records
├── InvoiceList.tsx               ← All invoices with filters
├── InvoiceDetail.tsx             ← Single invoice view + PDF download
├── RevenueReport.tsx             ← Revenue analytics with charts
├── CommissionReport.tsx          ← Commission breakdown
├── TaxSummary.tsx                ← GST collected/payable
├── CashFlowReport.tsx            ← Inflow vs outflow chart
└── types.ts                      ← All FMS TypeScript interfaces
```

### 6.2 Reusable Components (FMS-specific)

```
src/components/admin/finance/
├── FinanceKPICard.tsx            ← KPI card with icon, value, trend arrow, % change
├── FinanceStatusChip.tsx         ← Color-coded chips for COMPLETED/PENDING/FAILED etc.
├── TransactionTypeChip.tsx       ← Color-coded chips for GUEST_PAYMENT/HOST_EARNING etc.
├── LedgerTable.tsx               ← Table for ledger entries (reused across Host/Guest/All)
├── PayoutTable.tsx               ← Table for payout records
├── InvoiceTable.tsx              ← Table for invoices
├── ReconciliationTable.tsx       ← Table for reconciliation records
├── DateRangeFilter.tsx           ← Reusable date range picker (used across all reports)
├── ExportButton.tsx              ← CSV/Excel export trigger
├── PayoutApprovalModal.tsx       ← Approve/reject payout dialog
├── PayoutScheduleModal.tsx       ← Create/edit payout schedule dialog
├── LedgerDetailDrawer.tsx        ← Side drawer showing full ledger entry details
└── ReconciliationResolveModal.tsx ← Resolve variance dialog
```

### 6.3 Redux Slices

```
src/features/admin/finance/
├── financeDashboard.slice.ts     ← Dashboard KPIs + chart data
├── ledgerList.slice.ts           ← Paginated ledger search
├── ledgerDetail.slice.ts         ← Single ledger entry detail
├── hostLedger.slice.ts           ← Host-specific ledger
├── payoutList.slice.ts           ← Payout queue/history search
├── payoutDetail.slice.ts         ← Single payout detail
├── payoutAction.slice.ts         ← Initiate/approve/reject payout
├── payoutScheduleList.slice.ts   ← Payout schedule CRUD
├── invoiceList.slice.ts          ← Invoice search
├── invoiceDetail.slice.ts        ← Single invoice detail
├── reconciliationList.slice.ts   ← Reconciliation records search
├── reconciliationResolve.slice.ts← Resolve variance action
├── revenueReport.slice.ts        ← Revenue report data
├── commissionReport.slice.ts     ← Commission report data
├── taxReport.slice.ts            ← Tax summary data
└── cashFlowReport.slice.ts       ← Cash flow report data
```

### 6.4 Validation Schemas

Added to `src/validations/admin-validations.tsx`:

```typescript
// Payout Schedule
export const payoutScheduleSchema = Yup.object({
  hostId: Yup.number().required("Host is required"),
  frequency: Yup.string()
    .oneOf(["DAILY", "WEEKLY", "BIWEEKLY", "MONTHLY"])
    .required("Frequency is required"),
  minPayoutAmount: Yup.number()
    .min(100, "Minimum ₹100")
    .required("Minimum payout amount is required"),
  payoutMethod: Yup.string()
    .oneOf(["BANK_TRANSFER", "UPI"])
    .required("Payout method is required"),
});

// Manual Payout
export const manualPayoutSchema = Yup.object({
  hostId: Yup.number().required("Host is required"),
  amount: Yup.number()
    .min(1, "Amount must be positive")
    .required("Amount is required"),
  note: Yup.string().max(500, "Note too long"),
});

// Reconciliation Resolve
export const reconciliationResolveSchema = Yup.object({
  action: Yup.string()
    .oneOf(["ADJUST", "WRITE_OFF", "REFUND"])
    .required("Action is required"),
  notes: Yup.string()
    .required("Notes are required")
    .min(10, "Please provide more detail"),
});

// Report Filters
export const reportFilterSchema = Yup.object({
  dateFrom: Yup.date().required("Start date is required"),
  dateTo: Yup.date()
    .min(Yup.ref("dateFrom"), "End date must be after start date")
    .required("End date is required"),
  groupBy: Yup.string().oneOf(["day", "week", "month"]),
});
```

---

## 7. Backend Strategy

> The backend is a **separate repository** (Node.js API at `localhost:8000`).  
> This section defines what the backend team needs to build to support the FMS frontend.

### 7.1 Backend Architecture

```
Backend (Node.js / Express)
│
├── Routes
│   └── /admin/finance/*          ← All FMS endpoints (see Section 5.2)
│
├── Controllers
│   ├── ledgerController.js       ← Ledger CRUD + search
│   ├── payoutController.js       ← Payout lifecycle management
│   ├── invoiceController.js      ← Invoice CRUD + PDF generation
│   ├── reconciliationController.js ← Reconciliation engine
│   └── reportController.js       ← Report aggregation queries
│
├── Services (Business Logic)
│   ├── ledgerService.js          ← Creates ledger entries on booking events
│   ├── commissionService.js      ← Calculates platform commission
│   ├── payoutService.js          ← Aggregates host earnings → payout
│   ├── invoiceService.js         ← Generates invoice data + PDF
│   ├── reconciliationService.js  ← Matches booking ↔ payment ↔ payout
│   └── reportService.js          ← Aggregation queries for reports
│
├── Models (Sequelize/Prisma)
│   ├── FinancialLedger
│   ├── Payout
│   ├── PayoutSchedule
│   ├── Invoice
│   └── ReconciliationRecord
│
├── Jobs (Cron / Queue)
│   ├── payoutSchedulerJob.js     ← Runs daily — checks which hosts are due for payout
│   ├── reconciliationJob.js      ← Runs nightly — reconciles day's transactions
│   └── invoiceGeneratorJob.js    ← Runs on booking confirmation event
│
└── Events (Hooks into existing booking system)
    ├── onBookingConfirmed        ← Create ledger entries + invoice
    ├── onPaymentCaptured         ← Update ledger with Razorpay payment_id
    ├── onBookingCancelled        ← Create reversal entries + refund
    └── onPayoutCompleted         ← Update ledger + reconciliation
```

### 7.2 Commission Calculation Logic

```
Guest pays:       ₹10,000  (book_total_amt)
├── Base price:   ₹ 8,475  (book_price)
├── GST (18%):    ₹ 1,525  (book_tax)

Platform takes:
├── Commission:   ₹ 1,500  (15% of base price — configurable per category)
├── GST on commission: ₹ 270  (18% of commission)

Host receives:
├── Net earning:  ₹ 6,975  (base price - commission)
├── Payout after TDS: ₹ 6,905  (1% TDS on host earnings — if applicable)
```

### 7.3 Backend Development Sequence

| Order | Task | Why This Order |
|-------|------|----------------|
| 1 | Create DB migrations for all 5 tables | Foundation — everything depends on these |
| 2 | Ledger service + booking event hooks | Core — every financial operation starts with a ledger entry |
| 3 | Ledger CRUD APIs | Frontend can start showing data immediately |
| 4 | Commission calculation service | Needed before payout can work |
| 5 | Payout schedule CRUD APIs | Admin can configure schedules |
| 6 | Payout processing service + APIs | Hosts start getting paid |
| 7 | Invoice generation service + APIs | Legal compliance |
| 8 | Reconciliation service + APIs | Audit safety net |
| 9 | Dashboard aggregation API | Summary view pulls from all tables |
| 10 | Report aggregation APIs | Analytics last — data must exist first |

---

## 8. Development Order (Frontend)

### The key insight: we CAN'T wait for backend to be 100% done.

**Strategy: Build frontend and backend in parallel using mock data first, then swap to real APIs.**

### Phase A — Foundation (Days 1–2)

| # | Task | Depends On |
|---|------|------------|
| A1 | Create TypeScript interfaces for all FMS types (`src/pages/admin/finance/types.ts`) | Nothing — pure typing |
| A2 | Register all FMS API endpoints in `endpoints.ts` | Nothing — just strings |
| A3 | Create all Redux slices (16 files) with mock initial states | A1 |
| A4 | Register all slices in `store.ts` | A3 |
| A5 | Add "Finance" menu to admin sidebar with sub-items | Nothing |
| A6 | Register all FMS routes in `App.tsx` | Nothing |
| A7 | Add Yup validation schemas | A1 |
| A8 | Create `FinanceKPICard`, `FinanceStatusChip`, `TransactionTypeChip`, `DateRangeFilter`, `ExportButton` shared components | Nothing |

### Phase B — Core Pages (Days 3–5)

| # | Task | Depends On |
|---|------|------------|
| B1 | Build Finance Dashboard page (KPIs + charts + recent transactions) | A8, A3 |
| B2 | Build LedgerList page (unified search, filters, table) | A3, A8 |
| B3 | Build HostLedger page (host-specific drilldown with balance) | B2 |
| B4 | Build GuestLedger page (guest-specific payment history) | B2 |
| B5 | Build LedgerDetailDrawer component | B2 |

### Phase C — Payout Pages (Days 5–6)

| # | Task | Depends On |
|---|------|------------|
| C1 | Build PayoutQueue page (pending payouts, approve/reject buttons) | A3 |
| C2 | Build PayoutApprovalModal component | C1 |
| C3 | Build PayoutHistory page (completed/failed payouts log) | A3 |
| C4 | Build PayoutSchedules page (CRUD for schedule configs) | A3 |
| C5 | Build PayoutScheduleModal component | C4 |

### Phase D — Reconciliation & Invoices (Days 6–8)

| # | Task | Depends On |
|---|------|------------|
| D1 | Build ReconciliationDashboard page (summary cards + status) | A3 |
| D2 | Build ReconciliationList page (detailed records table) | A3 |
| D3 | Build ReconciliationResolveModal component | D2 |
| D4 | Build InvoiceList page (all invoices with filters) | A3 |
| D5 | Build InvoiceDetail page (full invoice view) | D4 |
| D6 | Add PDF download functionality | D5, Backend |

### Phase E — Reports & Integration (Days 8–10)

| # | Task | Depends On |
|---|------|------------|
| E1 | Build RevenueReport page (line chart + table + date filters) | A3, A8 |
| E2 | Build CommissionReport page (pie chart + breakdown table) | A3, A8 |
| E3 | Build TaxSummary page | A3 |
| E4 | Build CashFlowReport page (inflow/outflow bar chart) | A3, A8 |
| E5 | Implement CSV/Excel export across all report pages | E1–E4 |
| E6 | Connect all slices to real backend APIs (swap mock → real) | Backend ready |
| E7 | Add loading/error states, empty states across all pages | E6 |
| E8 | Integration testing (end-to-end flows) | E6, E7 |

---

## 9. Screen-by-Screen Specification

### 9.1 Finance Dashboard (`/admin/finance/dashboard`)

```
┌─────────────────────────────────────────────────────────────┐
│  Finance Dashboard                                          │
├─────────┬─────────┬─────────┬─────────┬────────────────────┤
│ Total   │ Platform│ Total   │ Pending │                    │
│ Revenue │ Commis. │ Payouts │ Payouts │  (4 KPI cards)     │
│ ₹12.5L  │ ₹1.87L  │ ₹10.2L  │ ₹32K    │                    │
│ ↑12.3%  │ ↑8.1%   │ ↑15.2%  │ ↓4.1%   │                    │
├─────────┴─────────┴─────────┴─────────┴────────────────────┤
│                                                             │
│  Monthly Revenue Trend (Line Chart)        Commission       │
│  ┌─────────────────────────────┐          Breakdown (Pie)   │
│  │     ╱─╲    ╱─╲              │          ┌──────────┐      │
│  │   ╱    ╲╱    ╲──            │          │  ●Hotels  │      │
│  │ ╱               ╲           │          │  ●Villas  │      │
│  └─────────────────────────────┘          │  ●Apts    │      │
│  Jan Feb Mar Apr May Jun                  └──────────┘      │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  Reconciliation    │  Recent Transactions                   │
│  ┌───────────┐     │  ┌─────────────────────────────────┐   │
│  │ Gauge:    │     │  │ ID  | Type    | Amount | Status │   │
│  │ 94%       │     │  │ ... | Payment | ₹8500  | ✓      │   │
│  │ Matched   │     │  │ ... | Payout  | ₹6200  | ⏳     │   │
│  └───────────┘     │  │ ... | Refund  | ₹3400  | ✓      │   │
│  7 variances       │  └──── View All ────────────────────┘  │
│  12 pending        │                                         │
└─────────────────────────────────────────────────────────────┘
```

**Components used:** `AdminLineChart`, `AdmindPieChart`, `AdminGaugeChart`, `FinanceKPICard`, `LedgerTable` (limited to 5 recent rows)

### 9.2 Ledger List (`/admin/finance/ledgers`)

```
┌─────────────────────────────────────────────────────────────┐
│  Transaction Ledger                          [Export CSV ▼]  │
├─────────────────────────────────────────────────────────────┤
│  🔍 Search    │ Type ▼  │ Status ▼  │ 📅 From │ 📅 To     │
├─────────────────────────────────────────────────────────────┤
│  # │ Date       │ Type           │ Host/Guest    │ Amount  │
│  1 │ 10 Mar '26 │ 🟢 PAYMENT     │ Guest: Rahul  │ ₹8,500 │
│  2 │ 10 Mar '26 │ 🟣 COMMISSION  │ Platform      │ ₹1,275 │
│  3 │ 10 Mar '26 │ 🔵 EARNING     │ Host: Priya   │ ₹7,225 │
│  4 │ 09 Mar '26 │ 🔴 REFUND      │ Guest: Amit   │ ₹3,400 │
│  ...                                                        │
├─────────────────────────────────────────────────────────────┤
│  ◀ 1 2 3 ... 12 ▶              Showing 1-10 of 115         │
└─────────────────────────────────────────────────────────────┘
```

Clicking a row opens `LedgerDetailDrawer` (side panel with full entry details + related booking link).

### 9.3 Payout Queue (`/admin/finance/payouts`)

```
┌─────────────────────────────────────────────────────────────┐
│  Payout Queue                    [+ Manual Payout]          │
├────────┬───────────┬──────────┬────────┬────────┬──────────┤
│ Tabs:  │ Pending   │ Processing│ Completed│ Failed│          │
├────────┴───────────┴──────────┴────────┴────────┴──────────┤
│  # │ Host       │ Period      │ Amount  │ Method │ Actions  │
│  1 │ Priya S.   │ 1-7 Mar    │ ₹24,500 │ Bank   │ ✓ ✗     │
│  2 │ Rajesh K.  │ 1-7 Mar    │ ₹18,200 │ UPI    │ ✓ ✗     │
│  3 │ Meena T.   │ 1-7 Mar    │ ₹ 6,800 │ Bank   │ ✓ ✗     │
├─────────────────────────────────────────────────────────────┤
│  ◀ 1 2 3 ▶                                                  │
└─────────────────────────────────────────────────────────────┘
```

✓ = Approve (opens PayoutApprovalModal), ✗ = Reject (opens reject reason dialog)

### 9.4 Invoice List (`/admin/finance/invoices`)

```
┌─────────────────────────────────────────────────────────────┐
│  Invoices                                                    │
├─────────────────────────────────────────────────────────────┤
│  🔍 Search    │ Type ▼       │ Status ▼  │ 📅 Range        │
├─────────────────────────────────────────────────────────────┤
│  # │ Invoice No.        │ Type      │ Host/Guest │ Amount  │
│  1 │ AAJOO-INV-2603-001 │ Booking   │ Rahul G.   │ ₹8,500 │
│  2 │ AAJOO-INV-2603-002 │ Payout    │ Priya S.   │ ₹24,500│
│  3 │ AAJOO-INV-2602-089 │ Booking   │ Amit K.    │ ₹3,400 │
│  Click row → InvoiceDetail page with [Download PDF] button  │
├─────────────────────────────────────────────────────────────┤
│  ◀ 1 2 3 ... 8 ▶                                            │
└─────────────────────────────────────────────────────────────┘
```

### 9.5 Revenue Report (`/admin/finance/reports/revenue`)

```
┌─────────────────────────────────────────────────────────────┐
│  Revenue Report                          [Export CSV ▼]      │
├─────────────────────────────────────────────────────────────┤
│  📅 From: [01 Jan 2026]  📅 To: [10 Mar 2026]              │
│  Group By: [Monthly ▼]   Category: [All ▼]                  │
│  [Generate Report]                                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Revenue Trend (Line + Bar Chart)                            │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  █ Revenue   ─ Bookings                             │    │
│  │  █   █                                              │    │
│  │  █ █ █   █                                          │    │
│  │  █ █ █ █ █                                          │    │
│  └─────────────────────────────────────────────────────┘    │
│  Jan      Feb      Mar                                      │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│  Period    │ Revenue    │ Bookings │ Avg. Value │ Growth    │
│  Jan 2026  │ ₹3,45,000  │ 42       │ ₹8,214     │ —        │
│  Feb 2026  │ ₹4,12,000  │ 51       │ ₹8,078     │ ↑19.4%   │
│  Mar 2026  │ ₹1,85,000  │ 22       │ ₹8,409     │ (partial)│
├─────────────────────────────────────────────────────────────┤
│  TOTAL     │ ₹9,42,000  │ 115      │ ₹8,191     │          │
└─────────────────────────────────────────────────────────────┘
```

---

## 10. Integration Points

### 10.1 With Existing Booking System

| Event | FMS Action |
|-------|------------|
| Booking confirmed + payment captured | Create 4 ledger entries (guest payment, host earning, commission, tax) + generate invoice |
| Booking cancelled | Create reversal entries, trigger refund, adjust pending payout |
| Booking status updated | Update reconciliation status |

### 10.2 With Existing Admin Dashboard

| Current | After FMS |
|---------|-----------|
| 4 KPI cards (users, hosts, properties, bookings) | Add 2 more: Total Revenue, Pending Payouts (from `financeDashboard.slice`) |
| Monthly bookings chart | Keep as-is; new detailed revenue chart lives in FMS dashboard |

### 10.3 With Host Portal (Phase 4B)

| FMS provides to HMS | How |
|---------------------|-----|
| Host earnings summary | `hostLedger.slice` — same API, filtered by logged-in host |
| Payout history | `payoutList.slice` — filtered by host |
| Invoice downloads | `invoiceList.slice` — filtered by host |
| Earnings dashboard KPIs | `financeDashboard.slice` — host-scoped variant |

### 10.4 With Razorpay

| What | How |
|------|-----|
| Payment confirmation | Backend webhook receives Razorpay `payment.captured` event → creates ledger entry |
| Refund processing | Backend calls Razorpay Refund API → creates refund ledger entry |
| Payout execution | Backend calls Razorpay Route/Fund Account Transfer API → updates payout status |
| Transaction verification | Reconciliation engine compares Razorpay transaction records with local ledger |

---

## 11. File Structure (What Gets Created)

### Complete list of new files:

```
src/
├── pages/admin/finance/
│   ├── types.ts                        ← All FMS TypeScript interfaces
│   ├── FinanceDashboard.tsx            ← Main dashboard with KPIs + charts
│   ├── LedgerList.tsx                  ← Unified ledger search
│   ├── HostLedger.tsx                  ← Per-host ledger drilldown
│   ├── GuestLedger.tsx                 ← Per-guest payment history
│   ├── PayoutQueue.tsx                 ← Pending payouts with approve/reject
│   ├── PayoutHistory.tsx               ← Completed/failed payouts log
│   ├── PayoutSchedules.tsx             ← Payout schedule CRUD
│   ├── ReconciliationDashboard.tsx     ← Reconciliation status overview
│   ├── ReconciliationList.tsx          ← Reconciliation records
│   ├── InvoiceList.tsx                 ← Invoice listing
│   ├── InvoiceDetail.tsx               ← Invoice detail + PDF download
│   ├── RevenueReport.tsx               ← Revenue analytics
│   ├── CommissionReport.tsx            ← Commission breakdown
│   ├── TaxSummary.tsx                  ← Tax report
│   └── CashFlowReport.tsx             ← Cash flow analytics
│
├── features/admin/finance/
│   ├── financeDashboard.slice.ts
│   ├── ledgerList.slice.ts
│   ├── ledgerDetail.slice.ts
│   ├── hostLedger.slice.ts
│   ├── payoutList.slice.ts
│   ├── payoutDetail.slice.ts
│   ├── payoutAction.slice.ts
│   ├── payoutScheduleList.slice.ts
│   ├── invoiceList.slice.ts
│   ├── invoiceDetail.slice.ts
│   ├── reconciliationList.slice.ts
│   ├── reconciliationResolve.slice.ts
│   ├── revenueReport.slice.ts
│   ├── commissionReport.slice.ts
│   ├── taxReport.slice.ts
│   └── cashFlowReport.slice.ts
│
├── components/admin/finance/
│   ├── FinanceKPICard.tsx
│   ├── FinanceStatusChip.tsx
│   ├── TransactionTypeChip.tsx
│   ├── LedgerTable.tsx
│   ├── PayoutTable.tsx
│   ├── InvoiceTable.tsx
│   ├── ReconciliationTable.tsx
│   ├── DateRangeFilter.tsx
│   ├── ExportButton.tsx
│   ├── PayoutApprovalModal.tsx
│   ├── PayoutScheduleModal.tsx
│   ├── LedgerDetailDrawer.tsx
│   └── ReconciliationResolveModal.tsx
│
└── (modified files)
    ├── services/endpoints.ts           ← Add ~20 new FMS endpoint constants
    ├── app/store.ts                    ← Register 16 new FMS reducers
    ├── components/admin/adminsidebar/  ← Add "Finance" nav group
    ├── App.tsx                         ← Add FMS routes under /admin/finance/*
    └── validations/admin-validations.tsx ← Add FMS validation schemas
```

**Total new files: ~45**  
**Modified files: ~5**

---

## Summary: Where to Start

```
Day 1 → Types + Endpoints + Sidebar + Routes (scaffolding)
Day 2 → All Redux slices + shared components
Day 3 → Finance Dashboard page
Day 4 → Ledger pages (List + Host + Guest + Detail drawer)
Day 5 → Payout pages (Queue + History + Schedules + Modals)
Day 6 → Reconciliation pages (Dashboard + List + Resolve modal)
Day 7 → Invoice pages (List + Detail + PDF download)
Day 8 → Report pages (Revenue + Commission + Tax + Cash flow)
Day 9 → Export functionality + integration with real APIs
Day 10 → Polish, error states, empty states, testing
```

**Frontend can start immediately — Day 1 is just scaffolding with zero backend dependency.**

The backend team should start with DB migrations + ledger service in parallel, so by Day 4–5 when frontend needs real data, the ledger APIs are ready.
