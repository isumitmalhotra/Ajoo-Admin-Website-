import { Box, Stack, Typography } from "@mui/material";
import { LineChart } from "@mui/x-charts/LineChart";

interface AdminLineChartProps {
  months: string[];
  successfulData: number[];
  cancelledData: number[];
}
const AdminLineChart = ({
  months,
  successfulData,
  cancelledData,
}: AdminLineChartProps) => {
  return (
    <Box
      sx={{
        padding: 2,
        backgroundColor: "#fff",
        mt: "3rem",
        px: "1rem",
      }}
    >
      {/* ===== Heading ===== */}
      <Typography
        sx={{
          fontSize: "1.2rem",
          fontWeight: 600,
          mb: 1,
          color: "#374151",
        }}
      >
        Monthly Bookings
      </Typography>

      {/* ===== Legend ===== */}
      <Stack direction="row" spacing={3} sx={{ mb: 2 }}>
        <Stack direction="row" spacing={1} alignItems="center">
          <Box
            sx={{
              width: 12,
              height: 12,
              borderRadius: "50%",
              backgroundColor: "#AA60C8",
            }}
          />
          <Typography sx={{ fontSize: "0.85rem", color: "#6b7280" }}>
            Successful Booking
          </Typography>
        </Stack>

        <Stack direction="row" spacing={1} alignItems="center">
          <Box
            sx={{
              width: 12,
              height: 12,
              borderRadius: "50%",
              backgroundColor: "#A294F9",
            }}
          />
          <Typography sx={{ fontSize: "0.85rem", color: "#6b7280" }}>
            Cancelled Booking
          </Typography>
        </Stack>
      </Stack>

      {/* ===== Chart ===== */}
      <Box sx={{ display: "flex", justifyContent: "center" }}>
        <LineChart
          xAxis={[
            {
              data: months,
              scaleType: "point",
              disableLine: true,
              disableTicks: true,
              tickLabelStyle: {
                fill: "#6B7390",
                fontFamily: "'Inter', system-ui, sans-serif",
              },
            },
          ]}
          yAxis={[
            {
              min: 0,
              max: 100,
              disableLine: true,
              disableTicks: true,
              tickLabelStyle: {
                fill: "#6B7390",
                fontFamily: "'Inter', system-ui, sans-serif",
              },
            },
          ]}
          series={[
            {
              data: successfulData,
              color: "#AA60C8",
              showMark: false,
              curve: "monotoneX",
            },
            {
              data: cancelledData,
              color: "#A294F9",
              showMark: false,
              curve: "monotoneX",
            },
          ]}
          height={300}
          width={600}
          grid={{ vertical: true, horizontal: true }}
        />
      </Box>
    </Box>
  );
};

export default AdminLineChart;
