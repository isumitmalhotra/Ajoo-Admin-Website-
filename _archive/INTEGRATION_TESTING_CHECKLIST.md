# Finance System Integration Testing Checklist

**Status**: ✅ Staging Integration Runner Added  
**Date**: March 30, 2026  
**Version**: Phase G - Staging Execution  

---

## 🎯 Overview

All Finance Management System (FMS) endpoints are now:
- ✅ Defined in codebase (`src/services/endpoints.ts`)
- ✅ Wired to Redux slices with async thunks
- ✅ Integrated with React pages
- ✅ Validated against India compliance requirements
- ✅ Smoke tested for configuration correctness

**No critical gaps found.**

Run the automated staging checks before manual validation:

```bash
npm run test:integration:staging
```

Optional write-path verification (requires dedicated test IDs and token):

```bash
npm run test:integration:staging:write
```

---

## 📋 Testing Phases

### **Phase 1: Endpoint Contract Validation** (1-2 hours)
Test each endpoint against staging backend to verify response shapes match our TypeScript types.

#### **Ledger Module**
- [ ] **POST `/admin/finance/ledger/search`**
  - Request: `{ page?: number; limit?: number; search?; transactionType?; status?; dateFrom?; dateTo? }`
  - Expected Response: `LedgerListResponse` with ledger array + pagination
  - Verify: Amount formatting works with `formatINR()`
  - Test Case: Search for guest payments, verify balance calculations

- [ ] **POST `/admin/finance/ledger/host/{hostId}`**
  - Request: `{ hostId: number; page?: number; limit?: number }`
  - Expected Response: `HostLedgerResponse` with `balance` field
  - Verify: Balance matches sum of all entries
  - Test Case: Host with 5+ transactions, verify running balance

- [ ] **POST `/admin/finance/ledger/user/{userId}`**
  - Request: `{ userId: number; page?: number; limit?: number }`
  - Expected Response: `LedgerListResponse` (guest payments only)
  - Verify: Entry types (CREDIT for payments, DEBIT for refunds)
  - Test Case: Guest with 3+ bookings, all payment records present

#### **Payout Module**
- [ ] **POST `/admin/finance/payout/search`**
  - Request: `{ page?; limit?; hostId?; status?; dateFrom?; dateTo? }`
  - Expected Response: `PayoutListResponse` with payouts array
  - **India Compliance**: Verify TDS fields present (`tds_rate`, `tds_amount`, `net_amount`)
  - Test Case: Filter by `status="QUEUED"`, verify pending payouts

- [ ] **POST `/admin/finance/payout/approve`**
  - Request: `{ payoutId: number }`
  - Expected Response: `{ success: boolean; status: "PROCESSING"|"COMPLETED" }`
  - Verify: Status changes from QUEUED to PROCESSING/COMPLETED
  - Test Case: Approve a QUEUED payout, verify ledger updated

- [ ] **POST `/admin/finance/payout/reject`**
  - Request: `{ payoutId: number; payload: { reason: string } }`
  - Expected Response: `{ success: boolean; message: string }`
  - Verify: Payout status → FAILED, failure_reason populated
  - Test Case: Reject payout with reason, verify host ledger not modified

- [ ] **POST `/admin/finance/payout/initiate`**
  - Request: `{ hostId: number; amount?: number; note?: string }`
  - Expected Response: `{ payoutId: number; status: string }`
  - Verify: New payout created with QUEUED status
  - Test Case: Manual payout for host, verify appears in queue

#### **Payout Schedule Module**
- [ ] **POST `/admin/finance/payout/schedule/search`**
  - Response: `PayoutScheduleListResponse` with schedules + next_payout_date
  - Test Case: List all active schedules, verify next payout dates are future dates

- [ ] **POST `/admin/finance/payout/schedule/create`**
  - Request: `{ hostId, frequency, minPayoutAmount, payoutMethod }`
  - Response: `{ scheduleId: number }`
  - Test Case: Create WEEKLY schedule with ₹1,000 minimum

- [ ] **POST `/admin/finance/payout/schedule/update`**
  - Request: `{ scheduleId, frequency?, minPayoutAmount?, isActive? }`
  - Response: `{ success: boolean }`
  - Test Case: Change schedule from WEEKLY to MONTHLY

#### **Invoice Module**
- [ ] **POST `/admin/finance/invoice/search`**
  - Request: `{ page?; limit?; invoiceType?; status?; dateFrom?; dateTo? }`
  - Expected Response: `InvoiceListResponse` with invoices array
  - **India Compliance**: Verify GST/TDS fields present
  - Test Case: Search BOOKING_RECEIPT type, verify all invoices have invoince_number

- [ ] **GET `/admin/finance/invoice/{invoiceId}`**
  - Expected Response: `Invoice` (full detail with HSN/SAC, GSTIN, tax breakdown)
  - **India Compliance**: 
    - [ ] `cgst`, `sgst`, `igst` fields present
    - [ ] `is_inter_state` boolean correct
    - [ ] `place_of_supply` populated
    - [ ] `supplier_gstin` matches admin GSTIN
  - Test Case: Get invoice, verify 18% GST split (9% CGST + 9% SGST) for intra-state

- [ ] **POST `/admin/finance/invoice/void`**
  - Request: `{ invoiceId: number; reason: string }`
  - Expected Response: `{ success: boolean }`
  - Verify: Invoice status → VOID, audit trail maintained
  - Test Case: Void an invoice, verify can't be used in ledger

- [ ] **GET `/admin/finance/invoice/{invoiceId}/download`**
  - Expected: PDF file with GST breakdown table
  - Verify: PDF contains GSTIN, HSN/SAC, tax components
  - Test Case: Download invoice, verify readable PDF with correct amounts

#### **Reconciliation Module**
- [ ] **POST `/admin/finance/reconciliation/search`**
  - Request: `{ page?; limit?; status?; dateFrom?; dateTo? }`
  - Expected Response: `ReconciliationListResponse` with summary
  - Test Case: Filter by `status="VARIANCE"`, verify only mismatched records

- [ ] **POST `/admin/finance/reconciliation/resolve`**
  - Request: `{ reconId: number; action: "ADJUST"|"WRITE_OFF"|"REFUND"; notes: string }`
  - Expected Response: `{ success: boolean }`
  - Verify: Record status → RESOLVED, action logged
  - Test Case: Resolve variance with ADJUST action, update booking amount

#### **Dashboard & Reports**
- [ ] **GET `/admin/finance/dashboard`**
  - Expected Response: `FinanceDashboardData` with KPIs + recent transactions
  - Verify: 
    - [ ] `totalRevenue` = sum of all GUEST_PAYMENT entries
    - [ ] `totalCommission` = calculated correctly
    - [ ] `recentTransactions` sorted by date DESC
  - Test Case: Dashboard loads, all KPIs match ledger calculations

- [ ] **POST `/admin/finance/reports/revenue`**
  - Request: `{ dateFrom, dateTo, groupBy: "day"|"week"|"month" }`
  - Expected Response: `RevenueReportResponse` with data array + totals
  - Test Case: FY 2025-26 revenue by month, verify sum matches dashboard

- [ ] **POST `/admin/finance/reports/commission`**
  - Expected Response: `CommissionReportResponse` with rate analysis
  - Test Case: Commission by month, verify avg rate calculation

- [ ] **POST `/admin/finance/reports/tax`**
  - Expected Response: `TaxReportResponse` with GST & TDS breakdown
  - **India Compliance**:
    - [ ] `gstCollected` matches invoice totals
    - [ ] `gstPayable` calculated correctly (collected - claimed ITC)
    - [ ] `tdsDeducted` matches payout TDS amounts
  - Test Case: FY tax summary, verify GST liability ≤ ₹25 lakhs (SEZ eligibility)

- [ ] **POST `/admin/finance/reports/cashflow`**
  - Expected Response: `CashFlowReportResponse` with inflow/outflow
  - Test Case: Monthly cash flow, verify net flow = inflow - outflow

---

### **Phase 2: Integration Path Testing** (2-3 hours)
Test complete financial flows end-to-end.

#### **Critical Path 1: Booking → Ledger → Invoice → Payout**
```
1. Create booking (guest payment)
   └─ Verify GUEST_PAYMENT entry in ledger
   
2. Host invoice generated (HOST_COMMISSION type)
   └─ Verify GST calculated (18% standard rate)
   └─ Verify invoice_number format: AAJAO/2526/INV/######
   
3. Profit calculated (Revenue - Commission - GST)
   └─ Verify ledger HOST_EARNING entry
   
4. Payout generated
   └─ Verify TDS deducted if host FY total > ₹5,00,000 (194-O)
   └─ Verify payout_amount = earning - TDS
   
5. Payout approved/rejected
   └─ If approved: status → COMPLETED, ledger updated
   └─ If rejected: status → FAILED, booking can be retried
```

**Test Execution**:
- [ ] Create 5 different bookings for different hosts
- [ ] Verify each creates correct ledger entries
- [ ] Check invoice generation timing
- [ ] Verify GST rates (5%, 12%, 18%) applied per tariff
- [ ] Test payout approval flow
- [ ] Verify final balance calculations

#### **Critical Path 2: Reconciliation Match**
```
1. Take a completed booking
   └─ expected_amount = invoice total (with GST)
   
2. Check payment received
   └─ payment_amount = guest payment amount
   
3. Check payout sent
   └─ payout_amount = host earning (after commission + tax)
   
4. Calculate variance
   └─ variance = expected - payment - payout
   
5. If variance > 0:
   └─ Mark as VARIANCE
   └─ Admin resolves with ADJUST/WRITE_OFF/REFUND
```

**Test Execution**:
- [ ] Create 10 bookings
- [ ] Run reconciliation
- [ ] Verify MATCHED count (should be ~8-9)
- [ ] Resolve 1-2 variances, verify status update
- [ ] Check that resolved records don't re-trigger

#### **Critical Path 3: Multi-Month Report Aggregation**
```
1. Q4 FY 2025 (Jan-Mar 2026): 10 bookings
2. Q1 FY 2026 (Apr-Jun 2026): 5 bookings
3. Generate report with dateFrom=Jan, dateTo=Jun

Expected:
  └─ Period breakdown matches bookings
  └─ Totals: sum of all periods
  └─ Growth: FY comparisons accurate
```

**Test Execution**:
- [ ] Create bookings across multiple months
- [ ] Run revenue report with different groupBy (day/week/month)
- [ ] Verify totals match dashboard
- [ ] Test tax report: GST + TDS aggregations correct

---

### **Phase 3: India Compliance Verification** (1-2 hours)

#### **GST Compliance**
- [ ] **Tariff-based Rate Selection**
  - [ ] Tariff ≤ ₹1,000 → 5% GST (IGST for inter-state)
  - [ ] Tariff ₹1,001–₹7,499 → 12% GST
  - [ ] Tariff ≥ ₹7,500 → 18% GST
  
- [ ] **CGST/SGST Split (Intra-state)**
  - [ ] 18% GST → 9% CGST + 9% SGST (each)
  - [ ] 12% GST → 6% CGST + 6% SGST
  - [ ] 5% GST → 2.5% CGST + 2.5% SGST
  
- [ ] **IGST (Inter-state)**
  - [ ] Different state supplier/recipient → IGST = full rate
  - [ ] CGST/SGST = 0
  
- [ ] **SAC Codes**
  - [ ] Accommodation (996311) on room invoices
  - [ ] Platform service (998599) on commission invoices

**Test Cases** (Staging Backend):
```sql
-- Test 1: Intra-state booking (Mah to Mah)
SELECT expected_gst FROM reconciliation 
WHERE booking_id = 101 
  AND is_inter_state = false;
-- Expected: 9% CGST + 9% SGST

-- Test 2: Inter-state booking (UP to Guj)
SELECT expected_gst FROM reconciliation 
WHERE booking_id = 102 
  AND is_inter_state = true;
-- Expected: 18% IGST, CGST/SGST = 0

-- Test 3: Economy tariff
SELECT tax_rate FROM invoices 
WHERE booking_id = 103 
  AND room_tariff <= 1000;
-- Expected: 5%
```

#### **TDS Compliance (Section 194-O)**
- [ ] **Threshold Check**
  - [ ] Host FY total ≤ ₹5,00,000 → TDS = 0%
  - [ ] Host FY total > ₹5,00,000 → TDS = 1%
  
- [ ] **Calculation**
  - [ ] TDS applied only on amount exceeding threshold
  - [ ] If FY was ₹4,50,000, payout is ₹1,00,000:
    - TDS = 1% × ₹50,000 = ₹500
    - Net = ₹99,500
  
- [ ] **Payout Fields**
  - [ ] `tds_rate` = 1 (or 0 if below threshold)
  - [ ] `tds_amount` = calculated TDS
  - [ ] `net_amount` = payout - TDS

**Test Cases**:
```sql
-- Test 1: First payout (total < 5L)
SELECT tds_rate, tds_amount, net_amount FROM payouts
WHERE host_id = 101 
  AND fy_total < 500000;
-- Expected: tds_rate=0, tds_amount=0, net=gross

-- Test 2: Payout exceeding threshold
SELECT tds_rate, tds_amount FROM payouts
WHERE host_id = 102 
  AND fy_total >= 500000;
-- Expected: tds_rate=1, tds_amount=gross×0.01
```

#### **GSTIN & State Validation**
- [ ] **GSTIN Format** (15 chars): `27AAPFU0939F1ZV`
  - Chars 1-2: State code (27=Maharashtra)
  - Chars 3-7: PAN (5 letters)
  - Chars 8-11: 4 digits
  - Char 12: Entity code (1-9, A-Z)
  - Char 13: Z (fixed)
  - Char 14-15: Check digit
  
- [ ] **State Code Mapping**
  - Use `GST_STATE_CODES` from `financeUtils.ts`
  - Verify state names match invoice records

**Test Cases**:
```
✅ Valid GSTIN: 27AAPFU0939F1ZV (42 chars, valid format)
❌ Invalid GSTIN: 27AAPFU0939F1Z (missing check digit)
❌ Invalid GSTIN: ABCDEF1234567890 (wrong format)
```

#### **Invoice & Reporting Format**
- [ ] Invoice Number Format: `AAJAO/2526/INV/000001`
  - AAJAO = Organization code
  - 2526 = FY code (FY 2025-26)
  - INV = Invoice type (or CN for credit note)
  - 000001 = Sequential serial
  
- [ ] Invoice PDF Contents
  - [ ] GSTIN visible at top
  - [ ] SAC/HSN code present
  - [ ] Tax components broken down (CGST, SGST, or IGST)
  - [ ] Net goods value + tax = total
  
- [ ] Financial Year Calculation
  - [ ] Jan 2026 → FY 2025-26 ✅
  - [ ] Mar 2026 → FY 2025-26 ✅
  - [ ] Apr 2026 → FY 2026-27 ✅

---

### **Phase 4: Performance & Scalability** (1 hour)

- [ ] **Ledger Search Performance**
  - Test: 10,000+ transactions
  - Expected: Search returns < 2 seconds
  - Verify: Pagination works with limit=100

- [ ] **Report Generation**
  - Test: 1-year report with daily grouping (365 days)
  - Expected: Generates < 3 seconds
  - Verify: All data accurate despite large dataset

- [ ] **Concurrent Requests**
  - Test: 5 simultaneous payout approvals
  - Expected: All succeed without data corruption
  - Verify: Balance calculations consistent

---

### **Phase 5: Error Handling & Edge Cases** (1.5 hours)

#### **API Error Scenarios**
- [ ] **500 Server Error**
  - Trigger: Kill backend briefly during request
  - Verify: Error message displays, retry button works
  
- [ ] **Invalid Payload**
  - Send: Missing required field in payout request
  - Expected: 400 Bad Request, clear error message
  
- [ ] **Unauthorized (401)**
  - Trigger: Expired token
  - Verify: Redirects to login, preserves intended action
  
- [ ] **Not Found (404)**
  - Request: Non-existent invoice
  - Verify: FinanceEmptyState or proper 404 message

#### **Data Edge Cases**
- [ ] **Zero Amount Payout**
  - Create: Host with ₹0 balance
  - Verify: Payout not initiated, clear message
  
- [ ] **Negative Balance**
  - Scenario: Refund > earnings
  - Verify: System allows negative, shows correctly
  
- [ ] **Null GST Fields**
  - Missing: `cgst` or `sgst` on invoice
  - Verify: Graceful fallback, UI doesn't break
  
- [ ] **Invalid GSTIN**
  - Input: "INVALID-GSTIN-123"
  - Verify: Validation error, invoice save prevented

---

## 🚀 Execution Plan

### **Day 1: Endpoint Testing**
```bash
# Start local dev server:
npm run dev

# Deploy frontend to staging
# Point VITE_API_BASE_URL to staging backend
npm run build

# Run manual Postman/cURL tests for each endpoint
# Verify response shapes match our types
```

### **Day 2: Integration Flow Testing**
```bash
# Create test data script:
# 1. Create 10 test bookings
# 2. Verify ledger entries
# 3. Check invoice generation
# 4. Approve/reject payouts
# 5. Run reconciliation
```

### **Day 3: Compliance Verification**
```bash
# Verify India-specific calculations:
# 1. GST rates per tariff
# 2. TDS threshold logic
# 3. GSTIN format validation
# 4. Invoice numbering
# 5. FY/quarter calculations
```

### **Day 4: Performance & Error Handling**
```bash
# Load testing (10K+ records)
# Error injection (API failures, timeouts)
# Edge case testing (zero amounts, null fields)
# Concurrent request testing
```

---

## 📊 Success Criteria

✅ **All endpoints respond with correct schema**  
✅ **Complete booking-to-payout flow works end-to-end**  
✅ **All India compliance requirements verified**  
✅ **Reconciliation matches > 95% of transactions**  
✅ **Reports aggregate correctly across time periods**  
✅ **Error handling graceful (no blank screens)**  
✅ **Performance acceptable (< 3 sec for reports)**  
✅ **No data corruption on concurrent requests**  

---

## 📝 Sign-Off

**Frontend Ready**: ✅ Phase F Smoke Tests (0 critical issues)  
**Next Phase**: Integration testing with staging backend  
**Estimated Duration**: 3-4 days  
**Target Completion**: March 31-April 2, 2026  

---

## 🔗 Related Documentation

- **Phase E**: [Real API Integration + India Compliance](WORK_COMPLETED_BY_ZYPHEX_TECH.md)
- **Task Tracker**: [FMS Progress](TASK_TRACKER.md)
- **Code**: 
  - API Validation: `src/utils/apiValidation.ts`
  - Smoke Test: `scripts/financeSmoke.js`
  - India Utils: `src/pages/admin/finance/utils/financeUtils.ts`
  - Types: `src/pages/admin/finance/types.ts`

---

**Report Generated**: March 30, 2026  
**Version**: 1.0  
**Status**: Ready for Staging Deployment ✅
