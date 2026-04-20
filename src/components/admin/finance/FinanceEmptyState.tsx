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
}

const FinanceEmptyState = ({
  variant = "default",
  message,
  minHeight = 300,
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
        gap: 2,
      }}
    >
      <Box
        sx={{
          width: 64,
          height: 64,
          borderRadius: "50%",
          bgcolor: "#f3e8ff",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <Icon size={28} color="#881f9b" />
      </Box>
      <Typography
        variant="body1"
        color="text.secondary"
        textAlign="center"
        maxWidth={400}
      >
        {message || config.defaultMessage}
      </Typography>
    </Box>
  );
};

export default FinanceEmptyState;
