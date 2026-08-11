import { Chip } from "@mui/material";
import {
  ShieldCheck,
  ShieldAlert,
  ShieldQuestion,
  Clock3,
  ShieldX,
  ShieldOff,
} from "lucide-react";
import type { KycStatus } from "./kyc.types";

const META: Record<
  KycStatus,
  { label: string; bg: string; fg: string; border: string; Icon: typeof ShieldCheck }
> = {
  not_started: { label: "Not verified", bg: "#f3f4f6", fg: "#4b5563", border: "#e5e7eb", Icon: ShieldQuestion },
  unverified: { label: "Not verified", bg: "#f3f4f6", fg: "#4b5563", border: "#e5e7eb", Icon: ShieldQuestion },
  pending: { label: "Verification pending", bg: "#fef9c3", fg: "#a16207", border: "#fde68a", Icon: Clock3 },
  in_review: { label: "In review", bg: "#dbeafe", fg: "#1d4ed8", border: "#bfdbfe", Icon: ShieldAlert },
  verified: { label: "Verified", bg: "#dcfce7", fg: "#166534", border: "#bbf7d0", Icon: ShieldCheck },
  skipped: { label: "Verified", bg: "#dcfce7", fg: "#166534", border: "#bbf7d0", Icon: ShieldCheck },
  declined: { label: "Verification declined", bg: "#fee2e2", fg: "#b91c1c", border: "#fecaca", Icon: ShieldX },
  expired: { label: "Verification expired", bg: "#ffedd5", fg: "#9a3412", border: "#fed7aa", Icon: ShieldOff },
  error: { label: "Verification error", bg: "#fee2e2", fg: "#b91c1c", border: "#fecaca", Icon: ShieldX },
};

interface KycStatusBadgeProps {
  status: KycStatus;
  size?: "small" | "medium";
}

const KycStatusBadge = ({ status, size = "small" }: KycStatusBadgeProps) => {
  const m = META[status] ?? META.not_started;
  const Icon = m.Icon;
  return (
    <Chip
      size={size}
      icon={<Icon size={14} color={m.fg} />}
      label={m.label}
      sx={{
        bgcolor: m.bg,
        color: m.fg,
        fontWeight: 700,
        border: `1px solid ${m.border}`,
        "& .MuiChip-icon": { ml: 0.6 },
      }}
    />
  );
};

export default KycStatusBadge;
