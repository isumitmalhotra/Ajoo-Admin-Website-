import { useMemo, useState } from "react";
import {
  Box,
  Chip,
  LinearProgress,
  MenuItem,
  Paper,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import { BarChart, LineChart } from "@mui/x-charts";

const PERIOD_DATA = {
  "30D": {
    occupancy: 76,
    rating: 4.6,
    cancellationRate: 3.8,
    responseTimeHours: 1.9,
    revenueTrend: [56000, 62000, 59000, 67000],
    labels: ["W1", "W2", "W3", "W4"],
    channelSplit: [44, 31, 25],
  },
  "90D": {
    occupancy: 72,
    rating: 4.5,
    cancellationRate: 4.2,
    responseTimeHours: 2.3,
    revenueTrend: [168000, 182000, 194000],
    labels: ["Jan", "Feb", "Mar"],
    channelSplit: [41, 34, 25],
  },
};

type PeriodKey = keyof typeof PERIOD_DATA;

export default function HostPerformance() {
  const [period, setPeriod] = useState<PeriodKey>("30D");
  const snapshot = PERIOD_DATA[period];

  const score = useMemo(() => {
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
          border: "1px solid #ede9fe",
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

      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(210px, 1fr))",
          gap: 1.3,
        }}
      >
        <Paper elevation={0} sx={{ p: 1.8, borderRadius: "0.9rem", border: "1px solid #ede9fe" }}>
          <Typography variant="caption" color="text.secondary">
            Occupancy
          </Typography>
          <Typography variant="h6" fontWeight={800}>
            {snapshot.occupancy}%
          </Typography>
        </Paper>
        <Paper elevation={0} sx={{ p: 1.8, borderRadius: "0.9rem", border: "1px solid #ede9fe" }}>
          <Typography variant="caption" color="text.secondary">
            Guest Rating
          </Typography>
          <Typography variant="h6" fontWeight={800}>
            {snapshot.rating}/5
          </Typography>
        </Paper>
        <Paper elevation={0} sx={{ p: 1.8, borderRadius: "0.9rem", border: "1px solid #ede9fe" }}>
          <Typography variant="caption" color="text.secondary">
            Cancellation Rate
          </Typography>
          <Typography variant="h6" fontWeight={800}>
            {snapshot.cancellationRate}%
          </Typography>
        </Paper>
        <Paper elevation={0} sx={{ p: 1.8, borderRadius: "0.9rem", border: "1px solid #ede9fe" }}>
          <Typography variant="caption" color="text.secondary">
            Avg Response Time
          </Typography>
          <Typography variant="h6" fontWeight={800}>
            {snapshot.responseTimeHours} hrs
          </Typography>
        </Paper>
      </Box>

      <Paper elevation={0} sx={{ p: 2, borderRadius: "1rem", border: "1px solid #ede9fe" }}>
        <Stack direction="row" justifyContent="space-between" alignItems="center" mb={1}>
          <Typography variant="subtitle1" fontWeight={800}>
            Overall Health Score
          </Typography>
          <Chip label={`${score}/100`} sx={{ bgcolor: "#ede9fe", color: "#5b21b6", fontWeight: 700 }} />
        </Stack>
        <LinearProgress
          variant="determinate"
          value={score}
          sx={{
            height: 10,
            borderRadius: 99,
            bgcolor: "#ede9fe",
            "& .MuiLinearProgress-bar": { bgcolor: "#6d28d9" },
          }}
        />
      </Paper>

      <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", lg: "1.3fr 1fr" }, gap: 1.4 }}>
        <Paper elevation={0} sx={{ p: 2, borderRadius: "1rem", border: "1px solid #ede9fe" }}>
          <Typography variant="subtitle1" fontWeight={800} mb={1}>
            Revenue Trend
          </Typography>
          <LineChart
            xAxis={[{ scaleType: "point", data: snapshot.labels }]}
            series={[{ data: snapshot.revenueTrend, label: "Revenue", color: "#6d28d9" }]}
            height={260}
            margin={{ top: 12, right: 12, bottom: 30, left: 48 }}
          />
        </Paper>

        <Paper elevation={0} sx={{ p: 2, borderRadius: "1rem", border: "1px solid #ede9fe" }}>
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
                color: "#7c3aed",
              },
            ]}
            height={260}
            margin={{ top: 12, right: 12, bottom: 30, left: 38 }}
          />
        </Paper>
      </Box>
    </Stack>
  );
}
