import { Alert, AlertTitle, Button, Box } from "@mui/material";

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
      action={
        onRetry && (
          <Button color="inherit" size="small" onClick={onRetry}>
            Retry
          </Button>
        )
      }
    >
      <AlertTitle>Error</AlertTitle>
      {message}
    </Alert>
  </Box>
);

export default FinanceErrorAlert;
