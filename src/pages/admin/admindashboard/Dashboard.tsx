import { useEffect } from "react";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import { useNavigate } from "react-router-dom";
import { getAdminDashboardData } from "../../../features/admin/Dashboard/dashboard.slice";
import { Box, Paper, Stack, Typography } from "@mui/material";

import AdminUserTable from "../../../components/admin/adminTable/AdminUserTable";
import AdminBookingTable from "../../../components/admin/adminTable/AdminBookingTable";
import AdminPropertyTable from "../../../components/admin/adminTable/AdminPropertyTable";
import { TableLoader } from "../../../components/admin/common/TableLoader";

import {
  AdmindPieChart,
  AdminBarChart,
  AdminLineChart,
} from "../../../components";

import DashboardHeading from "./DashboardHeading";

import type {
  DashboardPayload,
  LatestUser,
  LatestBooking,
  LatestProperty,
} from "../../../features/admin/Dashboard/types";

const Dashboard = () => {
  const dispatch = useAppDispatch();
  const navigate = useNavigate();

  const {
    data: dashboardResponse,
    loading
  } = useAppSelector((state) => state.adminDashboardSlice);

  useEffect(() => {
    dispatch(getAdminDashboardData());
  }, [dispatch]);

  /* ============================
     SAFELY EXTRACT PAYLOAD
  ============================ */
  const dashboardData: DashboardPayload | null =
    dashboardResponse?.data ?? null;

  /* ============================
     LOADING STATE
  ============================ */
  if (loading) {
    return <TableLoader text="Loading dashboard data..." minHeight={400} />;
  }

  /* ============================
     STATS
  ============================ */
  const stats = [
    {
      label: "Total Number of User",
      value: dashboardData?.userCount ?? 0,
    },
    {
      label: "Total Number of Host",
      value: dashboardData?.hostCount ?? 0,
    },
    {
      label: "Total Number of Properties",
      value: dashboardData?.propCount ?? 0,
    },
    {
      label: "Total Bookings",
      value: dashboardData?.BookingCount ?? 0,
    },
  ];

  /* ============================
     CHART DATA
  ============================ */
  const months = dashboardData?.getMonthlyBookingsData?.months ?? [];
  const successfulBookings =
    dashboardData?.getMonthlyBookingsData?.successful ?? [];
  const cancelledBookings =
    dashboardData?.getMonthlyBookingsData?.cancelled ?? [];

  const dates = dashboardData?.getDailyUsersData?.dates ?? [];
  const users = dashboardData?.getDailyUsersData?.users ?? [];

  /* ============================
     TABLE DATA
  ============================ */
  const latestUsers: LatestUser[] = dashboardData?.getLatestUser ?? [];
  const latestBookings: LatestBooking[] =
    dashboardData?.getLatestBooking ?? [];
  const latestProperties: LatestProperty[] =
    dashboardData?.getLatestProperties ?? [];

  /* ============================
     RENDER
  ============================ */
  return (
    <>
      {/* ================= HERO ================= */}
      <Paper
        sx={{
          background:
            "linear-gradient(135deg, #1B2447 0%, #C16345 50%, #3F6B4E 100%)",
          height: "25rem",
          borderRadius: "1rem",
          p: 4,
          mb: 4,
          color: "#fff",
        }}
      >
        <Typography variant="h6">Welcome Back 🤟🏻</Typography>
        <Typography variant="h4" fontWeight={700} mb={4}>
          Glad to see you
        </Typography>

        <Box
          sx={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(250px, 1fr))",
            gap: "1.5rem",
          }}
        >
          {stats.map(({ label, value }) => (
            <Paper
              key={label}
              sx={{
                height: "8rem",
                display: "flex",
                flexDirection: "column",
                justifyContent: "center",
                alignItems: "center",
                borderRadius: "1rem",
              }}
            >
              <Typography variant="h4" color="#1B2447" fontWeight={700}>
                {value.toLocaleString()}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {label}
              </Typography>
            </Paper>
          ))}
        </Box>
      </Paper>

      {/* ================= MOTIVATION ================= */}
      <Paper sx={sectionCard}>
        <Stack
          direction={{ xs: "column-reverse", md: "row" }}
          spacing={4}
          alignItems="center"
          justifyContent="space-between"
        >
          <Stack spacing={2}>
            <Typography variant="h4" fontWeight={600} color="#1B2447">
              “The only way to do great work is to love what you do”
            </Typography>
            <Typography fontStyle="italic" color="#1B2447">
              — Steve Jobs
            </Typography>
          </Stack>

          <Paper sx={{ p: 3, textAlign: "center" }}>
            <Typography variant="caption" fontWeight={600}>
              Pending Properties
            </Typography>
            <Typography variant="h4" color="#3F6B4E">
              {dashboardData?.pendingPropCount ?? 0}
            </Typography>
          </Paper>
        </Stack>
      </Paper>

      {/* ================= CHARTS ================= */}
      <Paper sx={sectionCard}>
        <Box sx={{ flex: 1, minWidth: 0 }}>
          {months.length > 0 && (
            <AdminLineChart
              months={months}
              successfulData={successfulBookings}
              cancelledData={cancelledBookings}
            />
          )}
        </Box>

        <Box sx={{ flex: 1, minWidth: 0 }}>
          {dates.length > 0 && <AdminBarChart dates={dates} users={users} />}
        </Box>
      </Paper>

      {/* ================= PIE CHARTS ================= */}
      <Paper sx={{ ...sectionCard, gap: 4 }}>
        <Box sx={{ flex: 1 }}>
          <AdmindPieChart
            title="User Overview"
            data={[
              {
                id: 0,
                label: "Active Users",
                value: dashboardData?.getUserStatsData?.active ?? 0,
              },
              {
                id: 1,
                label: "Inactive Users",
                value: dashboardData?.getUserStatsData?.inactive ?? 0,
              },
              {
                id: 2,
                label: "Verified Users",
                value: dashboardData?.getUserStatsData?.verified ?? 0,
              },
            ]}
          />
        </Box>

        <Box sx={{ flex: 1 }}>
          <AdmindPieChart
            title="Host Overview"
            data={[
              {
                id: 0,
                label: "Active Hosts",
                value: dashboardData?.getHostStatsData?.active ?? 0,
              },
              {
                id: 1,
                label: "Inactive Hosts",
                value: dashboardData?.getHostStatsData?.inactive ?? 0,
              },
              {
                id: 2,
                label: "Verified Hosts",
                value: dashboardData?.getHostStatsData?.verified ?? 0,
              },
            ]}
          />
        </Box>
      </Paper>

      <DashboardHeading
        heading="Latest Users"
        buttonText="View All"
        onButtonClick={() => navigate("/admin/users")}
      />
      <Paper sx={sectionCard}>
        <AdminUserTable rows={latestUsers} />
      </Paper>

      <DashboardHeading
        heading="Latest Bookings"
        buttonText="View All"
        onButtonClick={() => navigate("/admin/bookings")}
      />
      <Paper sx={sectionCard}>
        <AdminBookingTable
          rows={latestBookings.map((booking) => ({
            ...booking,
            book_status: booking.book_status ?? 0, // Default to 0 if undefined
          }))}
        />
      </Paper>

      <DashboardHeading
        heading="Latest Properties"
        buttonText="View All"
        onButtonClick={() => navigate("/admin/properties")}
      />
      <Paper sx={sectionCard}>
        <AdminPropertyTable rows={latestProperties} />
      </Paper>
    </>
  );
};

const sectionCard = {
  display: "flex",
  gap: 4,
  p: 4,
  mb: 4,
  borderRadius: "1.5rem",
  background: "linear-gradient(145deg, #ffffff, #f9fafb)",
  boxShadow: "0 10px 40px rgba(0,0,0,0.08)",
  flexWrap: "wrap",
};

export default Dashboard;