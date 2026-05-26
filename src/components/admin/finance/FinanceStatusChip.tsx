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
  { bg: string; border: string; color: string; dot: string; label?: string }
> = {
  COMPLETED: {
    bg: "#ecfdf3",
    border: "#bbf7d0",
    color: "#166534",
    dot: "#16a34a",
  },
  PAID: { bg: "#ecfdf3", border: "#bbf7d0", color: "#166534", dot: "#16a34a" },
  MATCHED: {
    bg: "#ecfdf3",
    border: "#bbf7d0",
    color: "#166534",
    dot: "#16a34a",
  },
  RESOLVED: {
    bg: "#ecfdf3",
    border: "#bbf7d0",
    color: "#166534",
    dot: "#16a34a",
  },
  GENERATED: {
    bg: "#eff6ff",
    border: "#bfdbfe",
    color: "#1d4ed8",
    dot: "#2563eb",
  },
  SENT: { bg: "#ecfdf3", border: "#bbf7d0", color: "#166534", dot: "#16a34a" },
  VOID: { bg: "#f9fafb", border: "#e5e7eb", color: "#6b7280", dot: "#9ca3af" },
  PENDING: {
    bg: "#fffbeb",
    border: "#fde68a",
    color: "#92400e",
    dot: "#d97706",
  },
  QUEUED: {
    bg: "#fffbeb",
    border: "#fde68a",
    color: "#92400e",
    dot: "#d97706",
    label: "Pending",
  },
  PROCESSING: {
    bg: "#eff6ff",
    border: "#bfdbfe",
    color: "#1d4ed8",
    dot: "#2563eb",
  },
  FAILED: {
    bg: "#fef2f2",
    border: "#fecaca",
    color: "#991b1b",
    dot: "#dc2626",
  },
  REVERSED: {
    bg: "#f5f3ff",
    border: "#ddd6fe",
    color: "#6d28d9",
    dot: "#7c3aed",
  },
  VOIDED: { bg: "#f9fafb", border: "#e5e7eb", color: "#6b7280", dot: "#9ca3af" },
  VARIANCE: {
    bg: "#fff7ed",
    border: "#fed7aa",
    color: "#9a3412",
    dot: "#ea580c",
  },
};

interface FinanceStatusChipProps {
  status: StatusValue;
  size?: "small" | "medium";
}

const FinanceStatusChip = ({ status, size = "small" }: FinanceStatusChipProps) => {
  const config = STATUS_CONFIG[status] ?? {
    bg: "#f9fafb",
    border: "#e5e7eb",
    color: "#374151",
    dot: "#6b7280",
  };
  const fallbackLabel = status
    .toLowerCase()
    .split("_")
    .map((chunk) => chunk.charAt(0).toUpperCase() + chunk.slice(1))
    .join(" ");

  return (
    <Chip
      label={
        <span style={{ display: "inline-flex", alignItems: "center", gap: 6 }}>
          <span
            style={{
              width: 7,
              height: 7,
              borderRadius: "50%",
              backgroundColor: config.dot,
              display: "inline-block",
            }}
          />
          {config.label ?? fallbackLabel}
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
          px: 1.15,
        },
      }}
    />
  );
};

export default FinanceStatusChip;
