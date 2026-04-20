import { Chip } from "@mui/material";

type StatusValue =
  | "COMPLETED"
  | "PENDING"
  | "FAILED"
  | "REVERSED"
  | "QUEUED"
  | "PROCESSING"
  | "PAID"
  | "VOIDED"
  | "MATCHED"
  | "VARIANCE"
  | "RESOLVED"
  | string;

const STATUS_CONFIG: Record<
  string,
  { bg: string; color: string; label?: string }
> = {
  COMPLETED: { bg: "#dcfce7", color: "#15803d" },
  PAID: { bg: "#dcfce7", color: "#15803d" },
  MATCHED: { bg: "#dcfce7", color: "#15803d" },
  RESOLVED: { bg: "#dcfce7", color: "#15803d" },
  GENERATED: { bg: "#dbeafe", color: "#1d4ed8" },
  SENT: { bg: "#dcfce7", color: "#15803d" },
  VOID: { bg: "#f3f4f6", color: "#6b7280" },
  PENDING: { bg: "#fef9c3", color: "#a16207" },
  QUEUED: { bg: "#fef9c3", color: "#a16207", label: "Pending" },
  PROCESSING: { bg: "#dbeafe", color: "#1d4ed8" },
  FAILED: { bg: "#fee2e2", color: "#b91c1c" },
  REVERSED: { bg: "#f3e8ff", color: "#7c3aed" },
  VOIDED: { bg: "#f3f4f6", color: "#6b7280" },
  VARIANCE: { bg: "#ffedd5", color: "#c2410c" },
};

interface FinanceStatusChipProps {
  status: StatusValue;
  size?: "small" | "medium";
}

const FinanceStatusChip = ({ status, size = "small" }: FinanceStatusChipProps) => {
  const config = STATUS_CONFIG[status] ?? { bg: "#f3f4f6", color: "#374151" };

  return (
    <Chip
      label={config.label ?? status.charAt(0) + status.slice(1).toLowerCase()}
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

export default FinanceStatusChip;
