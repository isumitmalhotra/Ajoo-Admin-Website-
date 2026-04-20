// ============================================================
// India Financial Utilities
// All currency, tax, and compliance helpers for Indian market
// ============================================================

// ────────────────── INR FORMATTING ──────────────────

/**
 * Format a number as Indian Rupees using the Indian numbering system.
 * e.g., 125000 → "₹1,25,000"
 *       1500.5 → "₹1,500.50"
 */
export function formatINR(amount: number | undefined | null): string {
  if (amount == null || isNaN(amount)) return "₹0";
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    minimumFractionDigits: amount % 1 === 0 ? 0 : 2,
    maximumFractionDigits: 2,
  }).format(amount);
}

/**
 * Format number with Indian grouping without currency symbol.
 * e.g., 125000 → "1,25,000"
 */
export function formatIndianNumber(amount: number | undefined | null): string {
  if (amount == null || isNaN(amount)) return "0";
  return new Intl.NumberFormat("en-IN", {
    maximumFractionDigits: 2,
  }).format(amount);
}

/**
 * Format percentage with up to 2 decimal places.
 */
export function formatPercent(value: number | undefined | null): string {
  if (value == null || isNaN(value)) return "0%";
  return `${value % 1 === 0 ? value : value.toFixed(2)}%`;
}

// ────────────────── GST CALCULATIONS ──────────────────

/** Standard GST rate for hotel/accommodation services */
export const GST_RATE_STANDARD = 18; // 18% for room tariff ≥ ₹7,500
export const GST_RATE_MODERATE = 12; // 12% for room tariff ₹1,001 – ₹7,499
export const GST_RATE_ECONOMY = 5; // 5% for room tariff up to ₹1,000 (with ITC)

/** SAC (Services Accounting Code) for accommodation services */
export const SAC_ACCOMMODATION = "996311";
/** SAC for platform/intermediary services */
export const SAC_PLATFORM_SERVICE = "998599";

export interface GSTBreakdown {
  /** Base amount before tax */
  baseAmount: number;
  /** GST rate applied */
  gstRate: number;
  /** Total GST amount */
  gstAmount: number;
  /** CGST component (intra-state: half of GST) */
  cgst: number;
  /** SGST/UTGST component (intra-state: half of GST) */
  sgst: number;
  /** IGST component (inter-state: full GST) */
  igst: number;
  /** Whether this is an inter-state transaction */
  isInterState: boolean;
  /** Final amount inclusive of GST */
  totalAmount: number;
}

/**
 * Calculate GST breakdown for a given amount.
 * @param baseAmount - Amount before tax
 * @param gstRate - GST rate (5, 12, or 18)
 * @param isInterState - true if supplier and recipient are in different states
 */
export function calculateGST(
  baseAmount: number,
  gstRate: number = GST_RATE_STANDARD,
  isInterState: boolean = false
): GSTBreakdown {
  const gstAmount = roundToTwo(baseAmount * (gstRate / 100));
  return {
    baseAmount,
    gstRate,
    gstAmount,
    cgst: isInterState ? 0 : roundToTwo(gstAmount / 2),
    sgst: isInterState ? 0 : roundToTwo(gstAmount / 2),
    igst: isInterState ? gstAmount : 0,
    isInterState,
    totalAmount: roundToTwo(baseAmount + gstAmount),
  };
}

/**
 * Extract base amount from a GST-inclusive amount.
 */
export function extractBaseFromGSTInclusive(
  totalAmount: number,
  gstRate: number = GST_RATE_STANDARD
): number {
  return roundToTwo(totalAmount / (1 + gstRate / 100));
}

/**
 * Determine applicable GST rate based on room tariff per night.
 * As per GST Council notifications for accommodation services.
 */
export function getGSTRateForTariff(tariffPerNight: number): number {
  if (tariffPerNight <= 1000) return GST_RATE_ECONOMY;
  if (tariffPerNight <= 7499) return GST_RATE_MODERATE;
  return GST_RATE_STANDARD;
}

// ────────────────── TDS CALCULATIONS ──────────────────

/**
 * TDS rate under Section 194-O of the Income Tax Act.
 * Applicable on e-commerce operators for payments to e-commerce participants (hosts).
 * Rate: 1% on gross amount of sale/service.
 * Threshold: > ₹5,00,000 per financial year per participant.
 */
export const TDS_RATE_194O = 1;
export const TDS_THRESHOLD_194O = 500000;

/**
 * TDS rate under Section 194-I for rent payments.
 * Rate: 10% for rent exceeding ₹2,40,000 per financial year.
 */
export const TDS_RATE_194I = 10;
export const TDS_THRESHOLD_194I = 240000;

export interface TDSCalculation {
  grossAmount: number;
  tdsRate: number;
  tdsAmount: number;
  netAmount: number;
  section: string;
}

/**
 * Calculate TDS under Section 194-O for e-commerce participant payouts.
 * @param grossAmount - Gross amount payable to host
 * @param financialYearTotal - Total already paid to this host in current FY
 */
export function calculateTDS194O(
  grossAmount: number,
  financialYearTotal: number = 0
): TDSCalculation {
  const cumulativeTotal = financialYearTotal + grossAmount;
  // TDS applies if cumulative exceeds threshold
  if (cumulativeTotal <= TDS_THRESHOLD_194O) {
    return {
      grossAmount,
      tdsRate: 0,
      tdsAmount: 0,
      netAmount: grossAmount,
      section: "194-O",
    };
  }

  // If previously below threshold, TDS only on amount exceeding it
  const taxableAmount =
    financialYearTotal < TDS_THRESHOLD_194O
      ? cumulativeTotal - TDS_THRESHOLD_194O
      : grossAmount;

  const tdsAmount = roundToTwo(taxableAmount * (TDS_RATE_194O / 100));
  return {
    grossAmount,
    tdsRate: TDS_RATE_194O,
    tdsAmount,
    netAmount: roundToTwo(grossAmount - tdsAmount),
    section: "194-O",
  };
}

// ────────────────── GSTIN VALIDATION ──────────────────

/**
 * Validate GSTIN format (15 characters).
 * Format: 2-digit state code + 10-char PAN + 1 entity code + Z + check digit
 * Example: 27AAPFU0939F1ZV
 */
const GSTIN_REGEX = /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/;

export function isValidGSTIN(gstin: string): boolean {
  if (!gstin || gstin.length !== 15) return false;
  return GSTIN_REGEX.test(gstin.toUpperCase());
}

/**
 * Extract state code from GSTIN.
 */
export function getStateFromGSTIN(gstin: string): string {
  if (!gstin || gstin.length < 2) return "";
  return gstin.substring(0, 2);
}

/**
 * Indian state codes for GST (used to determine inter/intra-state).
 */
export const GST_STATE_CODES: Record<string, string> = {
  "01": "Jammu & Kashmir",
  "02": "Himachal Pradesh",
  "03": "Punjab",
  "04": "Chandigarh",
  "05": "Uttarakhand",
  "06": "Haryana",
  "07": "Delhi",
  "08": "Rajasthan",
  "09": "Uttar Pradesh",
  "10": "Bihar",
  "11": "Sikkim",
  "12": "Arunachal Pradesh",
  "13": "Nagaland",
  "14": "Manipur",
  "15": "Mizoram",
  "16": "Tripura",
  "17": "Meghalaya",
  "18": "Assam",
  "19": "West Bengal",
  "20": "Jharkhand",
  "21": "Odisha",
  "22": "Chhattisgarh",
  "23": "Madhya Pradesh",
  "24": "Gujarat",
  "25": "Daman & Diu",
  "26": "Dadra & Nagar Haveli",
  "27": "Maharashtra",
  "28": "Andhra Pradesh",
  "29": "Karnataka",
  "30": "Goa",
  "31": "Lakshadweep",
  "32": "Kerala",
  "33": "Tamil Nadu",
  "34": "Puducherry",
  "35": "Andaman & Nicobar Islands",
  "36": "Telangana",
  "37": "Andhra Pradesh (new)",
  "38": "Ladakh",
};

// ────────────────── INDIAN FINANCIAL YEAR ──────────────────

/**
 * Get the Indian Financial Year string for a date.
 * Indian FY runs April 1 to March 31.
 * e.g., for Jan 2026 → "FY 2025-26", for May 2026 → "FY 2026-27"
 */
export function getFinancialYear(date: Date = new Date()): string {
  const month = date.getMonth(); // 0-indexed
  const year = date.getFullYear();
  const fyStart = month >= 3 ? year : year - 1; // April=3 onwards is new FY
  const fyEnd = (fyStart + 1) % 100;
  return `FY ${fyStart}-${fyEnd.toString().padStart(2, "0")}`;
}

/**
 * Get the quarter for Indian fiscal year.
 * Q1: Apr-Jun, Q2: Jul-Sep, Q3: Oct-Dec, Q4: Jan-Mar
 */
export function getIndianQuarter(date: Date = new Date()): number {
  const month = date.getMonth(); // 0-indexed
  if (month >= 3 && month <= 5) return 1;
  if (month >= 6 && month <= 8) return 2;
  if (month >= 9 && month <= 11) return 3;
  return 4; // Jan-Mar
}

/**
 * Get FY start and end dates.
 */
export function getFinancialYearDates(date: Date = new Date()): {
  start: Date;
  end: Date;
} {
  const month = date.getMonth();
  const year = date.getFullYear();
  const fyStartYear = month >= 3 ? year : year - 1;
  return {
    start: new Date(fyStartYear, 3, 1), // April 1
    end: new Date(fyStartYear + 1, 2, 31), // March 31
  };
}

// ────────────────── DATE FORMATTING ──────────────────

/**
 * Format date in Indian standard format: DD/MM/YYYY
 */
export function formatDateIN(
  dateStr: string | Date | null | undefined
): string {
  if (!dateStr) return "—";
  const d = typeof dateStr === "string" ? new Date(dateStr) : dateStr;
  if (isNaN(d.getTime())) return "—";
  return d.toLocaleDateString("en-IN", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });
}

/**
 * Format date with time in IST.
 */
export function formatDateTimeIN(
  dateStr: string | Date | null | undefined
): string {
  if (!dateStr) return "—";
  const d = typeof dateStr === "string" ? new Date(dateStr) : dateStr;
  if (isNaN(d.getTime())) return "—";
  return d.toLocaleString("en-IN", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    hour12: true,
    timeZone: "Asia/Kolkata",
  });
}

// ────────────────── INVOICE NUMBER GENERATION ──────────────────

/**
 * Generate an invoice number in Indian format.
 * Format: AAJAO/FY/TYPE/SERIAL
 * e.g., AAJAO/2526/INV/000142
 */
export function generateInvoiceNumber(
  serial: number,
  type: "INV" | "CN" | "DN" = "INV",
  date: Date = new Date()
): string {
  const month = date.getMonth();
  const year = date.getFullYear();
  const fyStart = month >= 3 ? year : year - 1;
  const fyCode = `${fyStart % 100}${(fyStart + 1) % 100}`;
  return `AAJAO/${fyCode}/${type}/${serial.toString().padStart(6, "0")}`;
}

// ────────────────── HELPERS ──────────────────

function roundToTwo(num: number): number {
  return Math.round((num + Number.EPSILON) * 100) / 100;
}
