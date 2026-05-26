import { Alert, AlertTitle, Button, Box, Stack, Typography } from "@mui/material";
import { RefreshCcw } from "lucide-react";

interface FinanceErrorAlertProps {
  message?: string;
  onRetry?: () => void;
}

const FinanceErrorAlert = ({
  message = "Failed to load data. Please try again.",
  onRetry,
}: FinanceErrorAlertProps) => (
  <Box sx={{ p: 2 }}>
    <Alert
      severity="error"
      variant="outlined"
      sx={{
        borderRadius: "0.8rem",
        borderColor: "#fecaca",
        bgcolor: "#fef2f2",
      }}
      action={
        onRetry && (
          <Button
            color="inherit"
            size="small"
            onClick={onRetry}
            startIcon={<RefreshCcw size={14} />}
            sx={{ fontWeight: 600, textTransform: "none" }}
          >
            Try again
          </Button>
        )
      }
    >
      <AlertTitle sx={{ mb: 0.3 }}>Unable to load finance data</AlertTitle>
      <Stack spacing={0.4}>
        <Typography variant="body2">{message}</Typography>
      </Stack>
    </Alert>
  </Box>
);

export default FinanceErrorAlert;
