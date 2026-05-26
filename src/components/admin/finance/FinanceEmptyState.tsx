import { Box, Typography } from "@mui/material";
import { FileX2, Search, BarChart3, Receipt, Wallet, RefreshCcw } from "lucide-react";

type EmptyVariant = "default" | "search" | "reports" | "invoices" | "payouts" | "reconciliation";

const VARIANT_CONFIG: Record<EmptyVariant, { icon: typeof FileX2; defaultMessage: string }> = {
  default: { icon: FileX2, defaultMessage: "No data found" },
  search: { icon: Search, defaultMessage: "No results match your search criteria" },
  reports: { icon: BarChart3, defaultMessage: "No report data available for the selected period" },
  invoices: { icon: Receipt, defaultMessage: "No invoices found. Invoices are auto-generated as bookings are confirmed." },
  payouts: { icon: Wallet, defaultMessage: "No payout records found" },
  reconciliation: { icon: RefreshCcw, defaultMessage: "No reconciliation records found. Records appear after the reconciliation engine runs." },
};

interface FinanceEmptyStateProps {
  variant?: EmptyVariant;
  message?: string;
  minHeight?: number;
  actionLabel?: string;
  onAction?: () => void;
}

const FinanceEmptyState = ({
  variant = "default",
  message,
  minHeight = 300,
  actionLabel,
  onAction,
}: FinanceEmptyStateProps) => {
  const config = VARIANT_CONFIG[variant];
  const Icon = config.icon;

  return (
    <Box
      sx={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        minHeight,
        py: 6,
        gap: 1.4,
      }}
    >
      <Box
        sx={{
          width: 70,
          height: 70,
          borderRadius: "50%",
          background:
            "radial-gradient(circle at 30% 20%, #f5d0fe 0%, #f3e8ff 55%, #ede9fe 100%)",
          border: "1px solid #e9d5ff",
          boxShadow: "0 10px 20px rgba(168,85,247,0.12)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <Icon size={30} color="#7e22ce" />
      </Box>
      <Typography variant="subtitle1" fontWeight={700} color="#374151">
        Nothing to show yet
      </Typography>
      <Typography
        variant="body1"
        color="text.secondary"
        textAlign="center"
        maxWidth={400}
      >
        {message || config.defaultMessage}
      </Typography>
      {actionLabel && onAction && (
        <Box
          component="button"
          onClick={onAction}
          sx={{
            mt: 1.1,
            border: "1px solid #d8b4fe",
            borderRadius: "0.65rem",
            bgcolor: "#faf5ff",
            color: "#6b21a8",
            px: 2,
            py: 0.9,
            fontWeight: 600,
            fontSize: "0.8rem",
            cursor: "pointer",
            "&:hover": { bgcolor: "#f3e8ff" },
          }}
        >
          {actionLabel}
        </Box>
      )}
    </Box>
  );
};

export default FinanceEmptyState;
