import { Chip } from "@mui/material";
import type { TransactionType } from "../../../pages/admin/finance/types";
import {
  ArrowDownLeft,
  ArrowUpRight,
  BadgeIndianRupee,
  Receipt,
  Undo2,
  Wallet,
  Scale,
} from "lucide-react";

const TYPE_CONFIG: Record<
  TransactionType,
  { bg: string; border: string; color: string; icon: typeof ArrowUpRight; label: string }
> = {
  GUEST_PAYMENT: {
    bg: "#eff6ff",
    border: "#bfdbfe",
    color: "#1d4ed8",
    icon: ArrowDownLeft,
    label: "Guest Payment",
  },
  HOST_EARNING: {
    bg: "#ecfdf3",
    border: "#bbf7d0",
    color: "#166534",
    icon: ArrowUpRight,
    label: "Host Earning",
  },
  PLATFORM_COMMISSION: {
    bg: "#f5f3ff",
    border: "#ddd6fe",
    color: "#6d28d9",
    icon: BadgeIndianRupee,
    label: "Commission",
  },
  TAX_COLLECTED: {
    bg: "#fffbeb",
    border: "#fde68a",
    color: "#92400e",
    icon: Receipt,
    label: "Tax",
  },
  REFUND: {
    bg: "#fef2f2",
    border: "#fecaca",
    color: "#991b1b",
    icon: Undo2,
    label: "Refund",
  },
  PAYOUT: {
    bg: "#ecfeff",
    border: "#a5f3fc",
    color: "#0f766e",
    icon: Wallet,
    label: "Payout",
  },
  ADJUSTMENT: {
    bg: "#f9fafb",
    border: "#e5e7eb",
    color: "#374151",
    icon: Scale,
    label: "Adjustment",
  },
};

interface TransactionTypeChipProps {
  type: TransactionType;
  size?: "small" | "medium";
}

const TransactionTypeChip = ({
  type,
  size = "small",
}: TransactionTypeChipProps) => {
  const config = TYPE_CONFIG[type] ?? {
    bg: "#f9fafb",
    border: "#e5e7eb",
    color: "#374151",
    icon: Scale,
    label: type,
  };
  const Icon = config.icon;

  return (
    <Chip
      label={
        <span style={{ display: "inline-flex", alignItems: "center", gap: 5 }}>
          <Icon size={12} />
          {config.label}
        </span>
      }
      size={size}
      sx={{
        bgcolor: config.bg,
        border: `1px solid ${config.border}`,
        color: config.color,
        fontWeight: 700,
        fontSize: "0.72rem",
        letterSpacing: 0.1,
        height: size === "small" ? 24 : 28,
        "& .MuiChip-label": {
          px: 1,
        },
      }}
    />
  );
};

export default TransactionTypeChip;
