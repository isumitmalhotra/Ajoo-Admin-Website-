// Shared KYC types for the web verification flow (A-12 /verify/* backend).

// Backend statuses: unverified | pending | in_review | verified | declined.
// FE-only states: not_started (no session yet), skipped (verified within the
// 90-day validity window), expired, error. Eight render states in total.
export type KycStatus =
  | "not_started"
  | "unverified"
  | "pending"
  | "in_review"
  | "verified"
  | "declined"
  | "skipped"
  | "expired"
  | "error";

export type KycContext = "host_kyc" | "guest_kyc";

export const TERMINAL_STATUSES: KycStatus[] = ["verified", "declined", "skipped", "expired"];

export const isTerminal = (s: KycStatus) => TERMINAL_STATUSES.includes(s);
export const isApproved = (s: KycStatus) => s === "verified" || s === "skipped";

export interface CreateSessionResponse {
  sessionId: string | null;
  sessionUrl: string | null;
  status?: KycStatus;
  skipReason?: string | null;
  vendorData?: string;
  stub?: boolean;
  expiresAt?: string;
}

export interface VerifyStatusResponse {
  sessionId: string;
  status: KycStatus;
  verifiedAt?: string | null;
  expiresAt?: string | null;
  skipReason?: string | null;
}
