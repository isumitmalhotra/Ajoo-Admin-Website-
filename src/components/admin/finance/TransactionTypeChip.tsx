import { Chip } from "@mui/material";
import type { TransactionType } from "../../../pages/admin/finance/types";

const TYPE_CONFIG: Record<
  TransactionType,
  { bg: string; color: string; label: string }
> = {
  GUEST_PAYMENT: { bg: "#dbeafe", color: "#1d4ed8", label: "Guest Payment" },
  HOST_EARNING: { bg: "#dcfce7", color: "#15803d", label: "Host Earning" },
  PLATFORM_COMMISSION: {
    bg: "#f3e8ff",
    color: "#7c3aed",
    label: "Commission",
  },
  TAX_COLLECTED: { bg: "#fef9c3", color: "#a16207", label: "Tax" },
  REFUND: { bg: "#fee2e2", color: "#b91c1c", label: "Refund" },
  PAYOUT: { bg: "#cffafe", color: "#0e7490", label: "Payout" },
  ADJUSTMENT: { bg: "#f3f4f6", color: "#374151", label: "Adjustment" },
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
    bg: "#f3f4f6",
    color: "#374151",
    label: type,
  };

  return (
    <Chip
      label={config.label}
      size={size}
      sx={{
        bgcolor: config.bg,
        color: config.color,
        fontWeight: 600,
        fontSize: "0.7rem",
        height: size === "small" ? 24 : 28,
      }}
    />
  );
};

export default TransactionTypeChip;
