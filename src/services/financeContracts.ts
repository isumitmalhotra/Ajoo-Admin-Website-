import type {
  Invoice,
  LedgerEntry,
  Payout,
  ReconciliationRecord,
  ReconciliationSummary,
} from "../pages/admin/finance/types";
import { extractApiData } from "./apiContracts";

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null;

const toNumber = (value: unknown, fallback = 0): number => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const toStringOrEmpty = (value: unknown): string => (typeof value === "string" ? value : "");

const toStringOrNull = (value: unknown): string | null =>
  typeof value === "string" ? value : null;

const toBoolean = (value: unknown): boolean => {
  if (typeof value === "boolean") return value;
  if (typeof value === "number") return value === 1;
  if (typeof value === "string") return value.toLowerCase() === "true" || value === "1";
  return false;
};

export const getFinanceDataNode = (payload: unknown): Record<string, unknown> | null => {
  const data = extractApiData<Record<string, unknown> | unknown[]>(payload);
  if (isRecord(data)) return data;
  return null;
};

export const normalizeLedgerEntry = (value: unknown): LedgerEntry | null => {
  if (!isRecord(value)) return null;
  const ledgerId = toNumber(value.ledger_id ?? value.ledgerId, NaN);
  if (!Number.isFinite(ledgerId)) return null;

  return {
    ledger_id: ledgerId,
    booking_id: toNumber(value.booking_id ?? value.bookingId, 0) || null,
    host_id: toNumber(value.host_id ?? value.hostId, 0) || null,
    user_id: toNumber(value.user_id ?? value.userId, 0) || null,
    transaction_type: toStringOrEmpty(value.transaction_type ?? value.transactionType) as LedgerEntry["transaction_type"],
    entry_type: toStringOrEmpty(value.entry_type ?? value.entryType) as LedgerEntry["entry_type"],
    amount: toNumber(value.amount),
    balance_after: toNumber(value.balance_after ?? value.balanceAfter),
    reference_id: toStringOrEmpty(value.reference_id ?? value.referenceId),
    description: toStringOrEmpty(value.description),
    status: toStringOrEmpty(value.status) as LedgerEntry["status"],
    created_at: toStringOrEmpty(value.created_at ?? value.createdAt),
    updated_at: toStringOrEmpty(value.updated_at ?? value.updatedAt),
    host_name: toStringOrNull(value.host_name ?? value.hostName) || undefined,
    user_name: toStringOrNull(value.user_name ?? value.userName) || undefined,
    property_name: toStringOrNull(value.property_name ?? value.propertyName) || undefined,
  };
};

export const normalizeLedgerRows = (value: unknown): LedgerEntry[] => {
  if (!Array.isArray(value)) return [];
  return value
    .map((row) => normalizeLedgerEntry(row))
    .filter((row): row is LedgerEntry => row !== null);
};

export const normalizePayout = (value: unknown): Payout | null => {
  if (!isRecord(value)) return null;
  const payoutId = toNumber(value.payout_id ?? value.payoutId ?? value.id, NaN);
  if (!Number.isFinite(payoutId)) return null;

  const amount = toNumber(value.amount);
  const tdsAmount = toNumber(value.tds_amount ?? value.tdsAmount);
  const netAmount = toNumber(value.net_amount ?? value.netAmount, amount - tdsAmount);

  return {
    payout_id: payoutId,
    host_id: toNumber(value.host_id ?? value.hostId),
    host_name: toStringOrEmpty(value.host_name ?? value.hostName),
    amount,
    status: toStringOrEmpty(value.status) as Payout["status"],
    payout_method: toStringOrEmpty(value.payout_method ?? value.payoutMethod) as Payout["payout_method"],
    reference_id: toStringOrEmpty(value.reference_id ?? value.referenceId),
    initiated_by: toStringOrEmpty(value.initiated_by ?? value.initiatedBy) as Payout["initiated_by"],
    initiated_at: toStringOrEmpty(value.initiated_at ?? value.initiatedAt),
    completed_at: toStringOrNull(value.completed_at ?? value.completedAt),
    failure_reason: toStringOrNull(value.failure_reason ?? value.failureReason),
    period_start: toStringOrEmpty(value.period_start ?? value.periodStart),
    period_end: toStringOrEmpty(value.period_end ?? value.periodEnd),
    tds_rate: toNumber(value.tds_rate ?? value.tdsRate),
    tds_amount: tdsAmount,
    net_amount: netAmount,
  };
};

export const normalizePayoutRows = (value: unknown): Payout[] => {
  if (!Array.isArray(value)) return [];
  return value
    .map((row) => normalizePayout(row))
    .filter((row): row is Payout => row !== null);
};

export const normalizeInvoice = (value: unknown): Invoice | null => {
  if (!isRecord(value)) return null;
  const invoiceId = toNumber(value.invoice_id ?? value.invoiceId ?? value.id, NaN);
  if (!Number.isFinite(invoiceId)) return null;

  const isInterState = toBoolean(value.is_inter_state ?? value.isInterState);
  const taxRate = toNumber(value.tax_rate ?? value.taxRate);
  const taxAmount = toNumber(value.tax_amount ?? value.taxAmount);
  const defaultHalfGst = taxAmount / 2;
  const cgst = toNumber(value.cgst, isInterState ? 0 : defaultHalfGst);
  const sgst = toNumber(value.sgst, isInterState ? 0 : defaultHalfGst);
  const igst = toNumber(value.igst, isInterState ? taxAmount : 0);

  return {
    invoice_id: invoiceId,
    invoice_number: toStringOrEmpty(value.invoice_number ?? value.invoiceNumber),
    booking_id: toNumber(value.booking_id ?? value.bookingId),
    host_id: toNumber(value.host_id ?? value.hostId),
    user_id: toNumber(value.user_id ?? value.userId),
    invoice_type: toStringOrEmpty(value.invoice_type ?? value.invoiceType) as Invoice["invoice_type"],
    subtotal: toNumber(value.subtotal),
    tax_amount: taxAmount,
    tax_rate: taxRate,
    total: toNumber(value.total),
    hsn_sac_code: toStringOrEmpty(value.hsn_sac_code ?? value.hsnSacCode),
    gstin: toStringOrEmpty(value.gstin),
    pdf_url: toStringOrNull(value.pdf_url ?? value.pdfUrl),
    status: toStringOrEmpty(value.status) as Invoice["status"],
    created_at: toStringOrEmpty(value.created_at ?? value.createdAt),
    cgst,
    sgst,
    igst,
    is_inter_state: isInterState,
    place_of_supply: toStringOrEmpty(value.place_of_supply ?? value.placeOfSupply),
    supplier_gstin: toStringOrEmpty(value.supplier_gstin ?? value.supplierGstin),
    tds_rate: toNumber(value.tds_rate ?? value.tdsRate),
    tds_amount: toNumber(value.tds_amount ?? value.tdsAmount),
    host_name: toStringOrNull(value.host_name ?? value.hostName) || undefined,
    user_name: toStringOrNull(value.user_name ?? value.userName) || undefined,
    property_name: toStringOrNull(value.property_name ?? value.propertyName) || undefined,
  };
};

export const normalizeInvoiceRows = (value: unknown): Invoice[] => {
  if (!Array.isArray(value)) return [];
  return value
    .map((row) => normalizeInvoice(row))
    .filter((row): row is Invoice => row !== null);
};

export const normalizeReconciliationRecord = (value: unknown): ReconciliationRecord | null => {
  if (!isRecord(value)) return null;
  const reconId = toNumber(value.recon_id ?? value.reconId ?? value.id, NaN);
  if (!Number.isFinite(reconId)) return null;

  return {
    recon_id: reconId,
    booking_id: toNumber(value.booking_id ?? value.bookingId),
    payment_amount: toNumber(value.payment_amount ?? value.paymentAmount),
    expected_amount: toNumber(value.expected_amount ?? value.expectedAmount),
    payout_amount: toNumber(value.payout_amount ?? value.payoutAmount),
    variance: toNumber(value.variance),
    status: toStringOrEmpty(value.status) as ReconciliationRecord["status"],
    resolved_by: toNumber(value.resolved_by ?? value.resolvedBy, 0) || null,
    resolved_at: toStringOrNull(value.resolved_at ?? value.resolvedAt),
    notes: toStringOrNull(value.notes),
    created_at: toStringOrEmpty(value.created_at ?? value.createdAt),
    host_name: toStringOrNull(value.host_name ?? value.hostName) || undefined,
    user_name: toStringOrNull(value.user_name ?? value.userName) || undefined,
    property_name: toStringOrNull(value.property_name ?? value.propertyName) || undefined,
  };
};

export const normalizeReconciliationRows = (value: unknown): ReconciliationRecord[] => {
  if (!Array.isArray(value)) return [];
  return value
    .map((row) => normalizeReconciliationRecord(row))
    .filter((row): row is ReconciliationRecord => row !== null);
};

export const normalizeReconciliationSummary = (value: unknown): ReconciliationSummary => {
  if (!isRecord(value)) {
    return { matched: 0, variance: 0, pending: 0 };
  }

  return {
    matched: toNumber(value.matched),
    variance: toNumber(value.variance),
    pending: toNumber(value.pending),
  };
};

export const getPage = (dataNode: Record<string, unknown> | null, fallback = 1): number =>
  toNumber(dataNode?.currentPage, fallback);

export const getTotalPages = (dataNode: Record<string, unknown> | null): number =>
  toNumber(dataNode?.totalPages, 1);

export const getTotalRecords = (dataNode: Record<string, unknown> | null, fallback = 0): number =>
  toNumber(dataNode?.totalRecords, fallback);

export const getAmount = (value: unknown, fallback = 0): number => toNumber(value, fallback);
