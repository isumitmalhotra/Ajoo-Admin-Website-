import { useEffect } from "react";
import {
  Alert,
  AlertTitle,
  Box,
  Button,
  Chip,
  LinearProgress,
  Paper,
  Stack,
  Typography,
} from "@mui/material";
import ArrowForwardRoundedIcon from "@mui/icons-material/ArrowForwardRounded";
import EventAvailableRoundedIcon from "@mui/icons-material/EventAvailableRounded";
import PaymentsRoundedIcon from "@mui/icons-material/PaymentsRounded";
import QueryStatsRoundedIcon from "@mui/icons-material/QueryStatsRounded";
import DescriptionRoundedIcon from "@mui/icons-material/DescriptionRounded";
import { useNavigate } from "react-router-dom";
import { useAppDispatch, useAppSelector } from "../../app/hooks";
import { fetchHostDashboard } from "../../features/host/hostDashboard.slice";
import { API_BASE_URL } from "../../configs/apiConfigs";

const KPI_SKELETON = [
  { label: "This Month Earnings", value: "INR 0" },
  { label: "Active Listings", value: "0" },
  { label: "Upcoming Bookings", value: "0" },
  { label: "Occupancy", value: "0%" },
];

export default function HostDashboard() {
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const { data, loading, error } = useAppSelector((state) => state.hostDashboard);

  const isConnectivityIssue =
    Boolean(error) && /unable to reach|network|failed to fetch|connect/i.test(error || "");

  const handleRetry = () => {
    dispatch(fetchHostDashboard());
  };

  useEffect(() => {
    dispatch(fetchHostDashboard());
  }, [dispatch]);

  const monthEarnings = data?.monthEarnings ?? 0;
  const activeListings = data?.activeListings ?? 0;
  const upcomingBookings = data?.upcomingBookings ?? 0;
  const occupancyRate = Math.max(0, Math.min(100, data?.occupancyRate ?? 0));
  const recentActivity = data?.recentActivity ?? [];

  const kpiCards = [
    { label: "This Month Earnings", value: `INR ${monthEarnings.toLocaleString("en-IN")}` },
    { label: "Active Listings", value: String(activeListings) },
    { label: "Upcoming Bookings", value: String(upcomingBookings) },
    { label: "Occupancy Rate", value: `${occupancyRate}%` },
  ];

  const quickActions = [
    { title: "Manage Bookings", icon: EventAvailableRoundedIcon, path: "/host/bookings" },
    { title: "View Earnings", icon: PaymentsRoundedIcon, path: "/host/earnings" },
    { title: "Performance", icon: QueryStatsRoundedIcon, path: "/host/performance" },
    { title: "Download Statements", icon: DescriptionRoundedIcon, path: "/host/statements" },
  ];

  return (
    <Stack spacing={2.2}>
      {error && (
        <Alert
          severity="warning"
          action={
            <Button color="inherit" size="small" onClick={handleRetry}>
              Retry
            </Button>
          }
        >
          <AlertTitle>Host dashboard data unavailable</AlertTitle>
          <Typography variant="body2">{error}</Typography>
          {isConnectivityIssue && (
            <Typography variant="caption" sx={{ display: "block", mt: 0.5 }}>
              Check backend availability and API base URL: {API_BASE_URL}
            </Typography>
          )}
        </Alert>
      )}

      <Paper
        elevation={0}
        sx={{
          p: { xs: 2.4, md: 3 },
          borderRadius: "1.1rem",
          color: "#ffffff",
          border: "1px solid rgba(255,255,255,0.25)",
          background: "linear-gradient(125deg, #1B2447 0%, #1B2447 45%, #3F6B4E 100%)",
          boxShadow: "0 18px 32px rgba(91,33,182,0.25)",
        }}
      >
        <Stack
          direction={{ xs: "column", md: "row" }}
          alignItems={{ xs: "flex-start", md: "center" }}
          justifyContent="space-between"
          spacing={1.5}
        >
          <Box>
            <Typography variant="overline" sx={{ letterSpacing: 1, opacity: 0.85 }}>
              Host Management System
            </Typography>
            <Typography variant="h4" sx={{ lineHeight: 1.15, fontWeight: 800 }}>
              Welcome back, Host
            </Typography>
            <Typography variant="body2" sx={{ mt: 0.7, opacity: 0.88 }}>
              Track operations, monitor payouts, and keep your business performance healthy.
            </Typography>
          </Box>

          <Button
            onClick={() => navigate("/host/communication")}
            variant="contained"
            endIcon={<ArrowForwardRoundedIcon />}
            sx={{
              textTransform: "none",
              fontWeight: 700,
              color: "#1B2447",
              bgcolor: "#ffffff",
              borderRadius: "0.65rem",
              "&:hover": { bgcolor: "#f5f3ff" },
            }}
          >
            Open Communication Center
          </Button>
        </Stack>
      </Paper>

      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
          gap: 1.4,
        }}
      >
        {(loading ? KPI_SKELETON : kpiCards).map((kpi) => (
          <Paper
            key={kpi.label}
            elevation={0}
            sx={{
              p: 2,
              borderRadius: "0.95rem",
              border: "1px solid #FFFAF0",
              boxShadow: "0 12px 26px rgba(17,24,39,0.05)",
            }}
          >
            <Typography variant="caption" color="text.secondary">
              {kpi.label}
            </Typography>
            <Typography variant="h6" fontWeight={800} mt={0.5} color="#111827">
              {kpi.value}
            </Typography>
          </Paper>
        ))}
      </Box>

      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(170px, 1fr))",
          gap: 1.2,
        }}
      >
        {quickActions.map((action) => {
          const Icon = action.icon;
          return (
            <Paper
              key={action.title}
              elevation={0}
              onClick={() => navigate(action.path)}
              sx={{
                p: 1.35,
                borderRadius: "0.85rem",
                border: "1px solid #e5e7eb",
                display: "flex",
                alignItems: "center",
                gap: 1,
                cursor: "pointer",
                transition: "all .2s ease",
                "&:hover": {
                  borderColor: "#D9CFB8",
                  bgcolor: "#faf5ff",
                  transform: "translateY(-1px)",
                },
              }}
            >
              <Box
                sx={{
                  width: 30,
                  height: 30,
                  borderRadius: "0.65rem",
                  bgcolor: "#f3e8ff",
                  display: "grid",
                  placeItems: "center",
                }}
              >
                <Icon sx={{ fontSize: 18, color: "#2A356B" }} />
              </Box>
              <Typography variant="body2" fontWeight={700} color="#374151">
                {action.title}
              </Typography>
            </Paper>
          );
        })}
      </Box>

      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: { xs: "1fr", xl: "1.4fr 1fr" },
          gap: 1.6,
        }}
      >
        <Paper elevation={0} sx={{ p: 2.2, borderRadius: "0.95rem", border: "1px solid #FFFAF0" }}>
          <Stack direction="row" justifyContent="space-between" alignItems="center" mb={1.2}>
            <Typography variant="subtitle1" fontWeight={800}>
              Occupancy Health
            </Typography>
            <Chip size="small" label="Current Month" sx={{ bgcolor: "#f3f4f6" }} />
          </Stack>
          <Typography variant="body2" color="text.secondary" mb={1}>
            Keep occupancy above 70% for stronger payout consistency.
          </Typography>
          <LinearProgress
            variant="determinate"
            value={occupancyRate}
            sx={{
              height: 10,
              borderRadius: 20,
              bgcolor: "#FFFAF0",
              "& .MuiLinearProgress-bar": { bgcolor: "#2A356B" },
            }}
          />
          <Typography variant="h6" fontWeight={800} mt={1}>
            {occupancyRate}% occupied
          </Typography>
        </Paper>

        <Paper elevation={0} sx={{ p: 2.2, borderRadius: "0.95rem", border: "1px solid #FFFAF0" }}>
          <Typography variant="subtitle1" fontWeight={800} mb={1.1}>
            Recent Activity
          </Typography>
          {recentActivity.length > 0 ? (
            <Stack spacing={1.1}>
              {recentActivity.map((item) => (
                <Box key={item.id} sx={{ p: 1.1, borderRadius: "0.7rem", bgcolor: "#faf5ff" }}>
                  <Stack direction="row" justifyContent="space-between" alignItems="center">
                    <Typography variant="body2" fontWeight={700} color="#1f2937">
                      {item.title}
                    </Typography>
                    <Chip size="small" label={item.status} sx={{ bgcolor: "#FFFAF0", color: "#1B2447" }} />
                  </Stack>
                  <Typography variant="caption" color="text.secondary">
                    {item.id} • {item.when}
                  </Typography>
                </Box>
              ))}
            </Stack>
          ) : (
            <Typography variant="body2" color="text.secondary" sx={{ py: 2 }}>
              No recent activity yet. New bookings, payouts, and reviews will appear here.
            </Typography>
          )}
        </Paper>
      </Box>
    </Stack>
  );
}
