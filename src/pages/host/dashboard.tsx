import { useEffect } from "react";
import { Alert, Box, Paper, Stack, Typography } from "@mui/material";
import { useAppDispatch, useAppSelector } from "../../app/hooks";
import { fetchHostDashboard } from "../../features/host/hostDashboard.slice";

const KPI_CARDS = [
    { label: "This Month Earnings", value: "INR 0" },
    { label: "Active Listings", value: "0" },
    { label: "Upcoming Bookings", value: "0" },
    { label: "Occupancy", value: "0%" },
];

export default function HostDashboard() {
    const dispatch = useAppDispatch();
    const { data, loading, error } = useAppSelector((state) => state.hostDashboard);

    useEffect(() => {
        dispatch(fetchHostDashboard());
    }, [dispatch]);

    const kpis = [
        {
            label: "This Month Earnings",
            value: `INR ${data?.monthEarnings ?? 0}`,
        },
        {
            label: "Active Listings",
            value: String(data?.activeListings ?? 0),
        },
        {
            label: "Upcoming Bookings",
            value: String(data?.upcomingBookings ?? 0),
        },
        {
            label: "Occupancy",
            value: `${data?.occupancyRate ?? 0}%`,
        },
    ];

    return (
        <Stack spacing={3}>
            {error && <Alert severity="warning">{error}</Alert>}

            <Box>
                <Typography variant="h5" fontWeight={700} color="#111827">
                    Host Dashboard
                </Typography>
                <Typography variant="body2" color="text.secondary">
                    Earnings and property performance overview.
                </Typography>
            </Box>

            <Box
                sx={{
                    display: "grid",
                    gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
                    gap: 2,
                }}
            >
                {(loading ? KPI_CARDS : kpis).map((kpi) => (
                    <Paper key={kpi.label} sx={{ p: 2.5, borderRadius: 2 }} elevation={0}>
                        <Typography variant="caption" color="text.secondary">
                            {kpi.label}
                        </Typography>
                        <Typography variant="h6" fontWeight={700} mt={0.5}>
                            {kpi.value}
                        </Typography>
                    </Paper>
                ))}
            </Box>

            <Paper sx={{ p: 3, borderRadius: 2 }} elevation={0}>
                <Typography variant="subtitle1" fontWeight={600} mb={1}>
                    Recent Bookings
                </Typography>
                <Typography variant="body2" color="text.secondary">
                    Booking feed will be connected in HMS-3001.
                </Typography>
            </Paper>
        </Stack>
    );
}