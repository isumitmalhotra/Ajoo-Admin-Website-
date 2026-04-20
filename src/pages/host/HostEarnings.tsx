import { useEffect } from "react";
import { Alert, Box, Paper, Typography } from "@mui/material";
import { useAppDispatch, useAppSelector } from "../../app/hooks";
import { fetchHostEarnings } from "../../features/host/hostEarnings.slice";

export default function HostEarnings() {
  const dispatch = useAppDispatch();
  const { data, loading, error } = useAppSelector((state) => state.hostEarnings);

  useEffect(() => {
    dispatch(fetchHostEarnings());
  }, [dispatch]);

  return (
    <Paper sx={{ p: 3, borderRadius: 2 }} elevation={0}>
      <Typography variant="h6" fontWeight={700}>
        Earnings and Payouts
      </Typography>

      {error && (
        <Alert sx={{ mt: 2 }} severity="warning">
          {error}
        </Alert>
      )}

      <Box
        sx={{
          mt: 2,
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
          gap: 1.5,
        }}
      >
        <Paper variant="outlined" sx={{ p: 1.5 }}>
          <Typography variant="caption" color="text.secondary">
            Total Earnings
          </Typography>
          <Typography variant="h6" fontWeight={700}>
            INR {loading ? "..." : data?.totalEarnings ?? 0}
          </Typography>
        </Paper>

        <Paper variant="outlined" sx={{ p: 1.5 }}>
          <Typography variant="caption" color="text.secondary">
            Pending Payouts
          </Typography>
          <Typography variant="h6" fontWeight={700}>
            INR {loading ? "..." : data?.pendingPayouts ?? 0}
          </Typography>
        </Paper>

        <Paper variant="outlined" sx={{ p: 1.5 }}>
          <Typography variant="caption" color="text.secondary">
            Last Payout
          </Typography>
          <Typography variant="h6" fontWeight={700}>
            INR {loading ? "..." : data?.lastPayoutAmount ?? 0}
          </Typography>
        </Paper>
      </Box>
    </Paper>
  );
}
