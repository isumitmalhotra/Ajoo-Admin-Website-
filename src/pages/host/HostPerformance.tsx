import { useEffect, useMemo, useState } from "react";
import {
  Alert,
  Box,
  Chip,
  CircularProgress,
  LinearProgress,
  MenuItem,
  Paper,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import { BarChart, LineChart } from "@mui/x-charts";
import { useAppDispatch, useAppSelector } from "../../app/hooks";
import {
  fetchHostPerformance,
  type PeriodKey,
} from "../../features/host/hostPerformance.slice";

export default function HostPerformance() {
  const dispatch = useAppDispatch();
  const { data, loading, error } = useAppSelector((state) => state.hostPerformance);
  const [period, setPeriod] = useState<PeriodKey>("30D");

  useEffect(() => {
    dispatch(fetchHostPerformance());
  }, [dispatch]);

  const snapshot = data?.[period] ?? null;

  const score = useMemo(() => {
    if (!snapshot) return 0;
    const occupancyScore = snapshot.occupancy;
    const ratingScore = (snapshot.rating / 5) * 100;
    const cancellationPenalty = Math.max(0, 100 - snapshot.cancellationRate * 8);
    return Math.round((occupancyScore + ratingScore + cancellationPenalty) / 3);
  }, [snapshot]);

  return (
    <Stack spacing={2}>
      <Paper
        elevation={0}
        sx={{
          p: 2.6,
          borderRadius: "1rem",
          border: "1px solid #FFFAF0",
          boxShadow: "0 12px 28px rgba(17,24,39,0.05)",
        }}
      >
        <Stack
          direction={{ xs: "column", md: "row" }}
          spacing={1.2}
          alignItems={{ xs: "flex-start", md: "center" }}
          justifyContent="space-between"
        >
          <Box>
            <Typography variant="h6" fontWeight={800}>
              Performance Snapshot
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Track occupancy, guest satisfaction, cancellation behavior, and earnings momentum.
            </Typography>
          </Box>
          <TextField
            select
            size="small"
            label="Period"
            value={period}
            onChange={(event) => setPeriod(event.target.value as PeriodKey)}
            sx={{ minWidth: 170 }}
          >
            <MenuItem value="30D">Last 30 Days</MenuItem>
            <MenuItem value="90D">Last 90 Days</MenuItem>
          </TextField>
        </Stack>
      </Paper>

      {error && (
        <Alert severity="error" sx={{ borderRadius: "0.8rem" }}>
          {error}
        </Alert>
      )}

      {loading ? (
        <Paper
          elevation={0}
          sx={{ p: 6, borderRadius: "1rem", border: "1px solid #FFFAF0", display: "flex", justifyContent: "center" }}
        >
          <CircularProgress size={28} sx={{ color: "#2A356B" }} />
        </Paper>
      ) : !snapshot ? (
        <Paper elevation={0} sx={{ p: 4, borderRadius: "1rem", border: "1px solid #FFFAF0" }}>
          <Typography variant="body2" color="text.secondary" textAlign="center">
            No performance data available yet. Metrics will appear once your listings start receiving bookings.
          </Typography>
        </Paper>
      ) : (
        <>
      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(210px, 1fr))",
          gap: 1.3,
        }}
      >
        <Paper elevation={0} sx={{ p: 1.8, borderRadius: "0.9rem", border: "1px solid #FFFAF0" }}>
          <Typography variant="caption" color="text.secondary">
            Occupancy
          </Typography>
          <Typography variant="h6" fontWeight={800}>
            {snapshot.occupancy}%
          </Typography>
        </Paper>
        <Paper elevation={0} sx={{ p: 1.8, borderRadius: "0.9rem", border: "1px solid #FFFAF0" }}>
          <Typography variant="caption" color="text.secondary">
            Guest Rating
          </Typography>
          <Typography variant="h6" fontWeight={800}>
            {snapshot.rating}/5
          </Typography>
        </Paper>
        <Paper elevation={0} sx={{ p: 1.8, borderRadius: "0.9rem", border: "1px solid #FFFAF0" }}>
          <Typography variant="caption" color="text.secondary">
            Cancellation Rate
          </Typography>
          <Typography variant="h6" fontWeight={800}>
            {snapshot.cancellationRate}%
          </Typography>
        </Paper>
        <Paper elevation={0} sx={{ p: 1.8, borderRadius: "0.9rem", border: "1px solid #FFFAF0" }}>
          <Typography variant="caption" color="text.secondary">
            Avg Response Time
          </Typography>
          <Typography variant="h6" fontWeight={800}>
            {snapshot.responseTimeHours} hrs
          </Typography>
        </Paper>
      </Box>

      <Paper elevation={0} sx={{ p: 2, borderRadius: "1rem", border: "1px solid #FFFAF0" }}>
        <Stack direction="row" justifyContent="space-between" alignItems="center" mb={1}>
          <Typography variant="subtitle1" fontWeight={800}>
            Overall Health Score
          </Typography>
          <Chip label={`${score}/100`} sx={{ bgcolor: "#FFFAF0", color: "#1B2447", fontWeight: 700 }} />
        </Stack>
        <LinearProgress
          variant="determinate"
          value={score}
          sx={{
            height: 10,
            borderRadius: 99,
            bgcolor: "#FFFAF0",
            "& .MuiLinearProgress-bar": { bgcolor: "#2A356B" },
          }}
        />
      </Paper>

      <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", lg: "1.3fr 1fr" }, gap: 1.4 }}>
        <Paper elevation={0} sx={{ p: 2, borderRadius: "1rem", border: "1px solid #FFFAF0" }}>
          <Typography variant="subtitle1" fontWeight={800} mb={1}>
            Revenue Trend
          </Typography>
          <LineChart
            xAxis={[{ scaleType: "point", data: snapshot.labels }]}
            series={[{ data: snapshot.revenueTrend, label: "Revenue", color: "#2A356B" }]}
            height={260}
            margin={{ top: 12, right: 12, bottom: 30, left: 48 }}
          />
        </Paper>

        <Paper elevation={0} sx={{ p: 2, borderRadius: "1rem", border: "1px solid #FFFAF0" }}>
          <Typography variant="subtitle1" fontWeight={800} mb={1}>
            Booking Channel Mix
          </Typography>
          <BarChart
            xAxis={[
              {
                scaleType: "band",
                data: ["Direct", "Platform", "Referral"],
              },
            ]}
            series={[
              {
                data: snapshot.channelSplit,
                color: "#1B2447",
              },
            ]}
            height={260}
            margin={{ top: 12, right: 12, bottom: 30, left: 38 }}
          />
        </Paper>
      </Box>
        </>
      )}
    </Stack>
  );
}
