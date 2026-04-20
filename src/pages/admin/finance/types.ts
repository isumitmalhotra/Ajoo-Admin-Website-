// ============================================================
// FMS — Finance Management System Types
// All TypeScript interfaces for the Finance module
// ============================================================

// ────────────────── ENUMS ──────────────────

export type TransactionType =
  | "GUEST_PAYMENT"
  | "HOST_EARNING"
  | "PLATFORM_COMMISSION"
  | "TAX_COLLECTED"
  | "REFUND"
  | "PAYOUT"
  | "ADJUSTMENT";

export type EntryType = "CREDIT" | "DEBIT";

export type LedgerStatus = "COMPLETED" | "PENDING" | "FAILED" | "REVERSED";

export type PayoutStatus = "QUEUED" | "PROCESSING" | "COMPLETED" | "FAILED";

export type PayoutFrequency = "DAILY" | "WEEKLY" | "BIWEEKLY" | "MONTHLY";

export type PayoutMethod = "BANK_TRANSFER" | "UPI";

export type PayoutInitiator = "SYSTEM" | "ADMIN";

export type InvoiceType =
  | "BOOKING_RECEIPT"
  | "HOST_COMMISSION"
  | "PAYOUT_STATEMENT";

export type InvoiceStatus = "GENERATED" | "SENT" | "VOID";

export type ReconciliationStatus =
  | "MATCHED"
  | "VARIANCE"
  | "PENDING"
  | "RESOLVED";

export type ReconciliationAction = "ADJUST" | "WRITE_OFF" | "REFUND";

export type ReportGroupBy = "day" | "week" | "month";

export type ExportFormat = "csv" | "excel";

// ────────────────── LEDGER ──────────────────

export interface LedgerEntry {
  ledger_id: number;
  booking_id: number | null;
  host_id: number | null;
  user_id: number | null;
  transaction_type: TransactionType;
  entry_type: EntryType;
  amount: number;
  balance_after: number;
  reference_id: string;
  description: string;
  status: LedgerStatus;
  created_at: string;
  updated_at: string;
  // Joined fields from API
  host_name?: string;
  user_name?: string;
  property_name?: string;
}

export interface LedgerSearchPayload {
  page?: number;
  limit?: number;
  search?: string;
  hostId?: number;
  userId?: number;
  transactionType?: TransactionType;
  status?: LedgerStatus;
  dateFrom?: string;
  dateTo?: string;
}

export interface LedgerListResponse {
  ledgers: LedgerEntry[];
  totalRecords: number;
  currentPage: number;
  totalPages: number;
}

export interface HostLedgerResponse extends LedgerListResponse {
  balance: number;
}

// ────────────────── PAYOUT ──────────────────

export interface Payout {
  payout_id: number;
  host_id: number;
  host_name: string;
  amount: number;
  status: PayoutStatus;
  payout_method: PayoutMethod;
  reference_id: string;
  initiated_by: PayoutInitiator;
  initiated_at: string;
  completed_at: string | null;
  failure_reason: string | null;
  period_start: string;
  period_end: string;
  // TDS fields (India compliance — Section 194-O)
  tds_rate?: number;
  tds_amount?: number;
  net_amount?: number;
}

export interface PayoutSearchPayload {
  page?: number;
  limit?: number;
  hostId?: number;
  status?: PayoutStatus;
  dateFrom?: string;
  dateTo?: string;
}

export interface PayoutListResponse {
  payouts: Payout[];
  totalRecords: number;
  currentPage: number;
  totalPages: number;
}

export interface PayoutInitiatePayload {
  hostId: number;
  amount?: number;
  note?: string;
}

export interface PayoutRejectPayload {
  reason: string;
}

// ────────────────── PAYOUT SCHEDULE ──────────────────

export interface PayoutSchedule {
  schedule_id: number;
  host_id: number;
  host_name: string;
  frequency: PayoutFrequency;
  next_payout_date: string;
  last_payout_date: string | null;
  min_payout_amount: number;
  is_active: boolean;
  payout_method: PayoutMethod;
  created_at: string;
}

export interface PayoutScheduleSearchPayload {
  page?: number;
  limit?: number;
  hostId?: number;
}

export interface PayoutScheduleListResponse {
  schedules: PayoutSchedule[];
  totalRecords: number;
  currentPage: number;
  totalPages: number;
}

export interface PayoutScheduleCreatePayload {
  hostId: number;
  frequency: PayoutFrequency;
  minPayoutAmount: number;
  payoutMethod: PayoutMethod;
}

export interface PayoutScheduleUpdatePayload {
  frequency?: PayoutFrequency;
  minPayoutAmount?: number;
  isActive?: boolean;
  payoutMethod?: PayoutMethod;
}

// ────────────────── INVOICE ──────────────────

export interface Invoice {
  invoice_id: number;
  invoice_number: string;
  booking_id: number;
  host_id: number;
  user_id: number;
  invoice_type: InvoiceType;
  subtotal: number;
  tax_amount: number;
  tax_rate: number;
  total: number;
  hsn_sac_code: string;
  gstin: string;
  pdf_url: string | null;
  status: InvoiceStatus;
  created_at: string;
  // GST breakdown fields (India compliance)
  cgst: number;
  sgst: number;
  igst: number;
  is_inter_state: boolean;
  place_of_supply: string;
  supplier_gstin: string;
  // TDS fields
  tds_rate: number;
  tds_amount: number;
  // Joined fields
  host_name?: string;
  user_name?: string;
  property_name?: string;
}

export interface InvoiceSearchPayload {
  page?: number;
  limit?: number;
  hostId?: number;
  userId?: number;
  invoiceType?: InvoiceType;
  status?: InvoiceStatus;
  dateFrom?: string;
  dateTo?: string;
}

export interface InvoiceListResponse {
  invoices: Invoice[];
  totalRecords: number;
  currentPage: number;
  totalPages: number;
}

// ────────────────── RECONCILIATION ──────────────────

export interface ReconciliationRecord {
  recon_id: number;
  booking_id: number;
  payment_amount: number;
  expected_amount: number;
  payout_amount: number;
  variance: number;
  status: ReconciliationStatus;
  resolved_by: number | null;
  resolved_at: string | null;
  notes: string | null;
  created_at: string;
  // Joined fields
  host_name?: string;
  user_name?: string;
  property_name?: string;
}

export interface ReconciliationSearchPayload {
  page?: number;
  limit?: number;
  status?: ReconciliationStatus;
  dateFrom?: string;
  dateTo?: string;
}

export interface ReconciliationListResponse {
  records: ReconciliationRecord[];
  totalRecords: number;
  currentPage: number;
  totalPages: number;
  summary: ReconciliationSummary;
}

export interface ReconciliationSummary {
  matched: number;
  variance: number;
  pending: number;
}

export interface ReconciliationResolvePayload {
  notes: string;
  action: ReconciliationAction;
}

// ────────────────── DASHBOARD ──────────────────

export interface FinanceDashboardData {
  totalRevenue: number;
  totalCommission: number;
  totalPayouts: number;
  pendingPayouts: number;
  revenueGrowth: number;
  commissionGrowth: number;
  monthlyRevenue: MonthlyRevenueItem[];
  categoryBreakdown: CategoryBreakdownItem[];
  recentTransactions: LedgerEntry[];
  reconciliationSummary: ReconciliationSummary;
}

export interface MonthlyRevenueItem {
  month: string;
  revenue: number;
  commission: number;
  payouts: number;
}

export interface CategoryBreakdownItem {
  category: string;
  revenue: number;
  percentage: number;
}

// ────────────────── REPORTS ──────────────────

export interface ReportFilterPayload {
  dateFrom: string;
  dateTo: string;
  groupBy?: ReportGroupBy;
  propertyId?: number;
  categoryId?: number;
}

export interface RevenueReportItem {
  period: string;
  revenue: number;
  bookings: number;
  avgValue: number;
}

export interface RevenueReportResponse {
  data: RevenueReportItem[];
  totals: {
    revenue: number;
    bookings: number;
    avgValue: number;
  };
}

export interface CommissionReportItem {
  period: string;
  commission: number;
  rate: number;
  transactions: number;
}

export interface CommissionReportResponse {
  data: CommissionReportItem[];
  totals: {
    totalCommission: number;
    avgRate: number;
    transactions: number;
  };
}

export interface TaxReportItem {
  period: string;
  gstCollected: number;
  gstPayable: number;
  tdsDeducted: number;
  // GST component breakdown (India compliance)
  cgstCollected?: number;
  sgstCollected?: number;
  igstCollected?: number;
}

export interface TaxReportResponse {
  data: TaxReportItem[];
  totals: {
    gstCollected: number;
    gstPayable: number;
    tdsDeducted: number;
    cgstCollected?: number;
    sgstCollected?: number;
    igstCollected?: number;
  };
}

export interface CashFlowReportItem {
  period: string;
  inflow: number;
  outflow: number;
  netFlow: number;
}

export interface CashFlowReportResponse {
  data: CashFlowReportItem[];
  totals: {
    totalInflow: number;
    totalOutflow: number;
    netFlow: number;
  };
}

export interface ReportExportPayload {
  reportType: "revenue" | "commission" | "tax" | "cashflow";
  dateFrom: string;
  dateTo: string;
  format: ExportFormat;
}

// ────────────────── COMMON / PAGINATION ──────────────────

export interface PaginatedState<T> {
  data: T[];
  totalRecords: number;
  currentPage: number;
  totalPages: number;
  loading: boolean;
  error: string | null;
}

export interface DetailState<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
}

export interface ActionState {
  loading: boolean;
  success: boolean;
  error: string | null;
}
