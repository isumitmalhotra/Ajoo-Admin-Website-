import { Box, Typography } from "@mui/material";
import { BarChart } from "@mui/x-charts/BarChart";

interface AdminBarChartProps {
  dates: string[];
  users: number[];
}

const AdminBarChart = ({ dates, users }: AdminBarChartProps) => {
  const axisLabelStyle = {
    fontFamily: "Poppins, sans-serif",
    color: "#547792",
    fontWeight: 500,
    fontSize: "0.875rem",
  };

  return (
    <Box sx={{ mt: "5rem", px: "1rem" }}>
      {/* ===== Heading ===== */}
      <Typography
        sx={{
          fontSize: "1.2rem",
          fontWeight: 600,
          mb: 1.5,
          color: "#374151",
        }}
      >
        Daily Booking Activity
      </Typography>

      <Box sx={{ display: "flex", justifyContent: "center" }}>
        <BarChart
          width={600}
          height={350}
          series={[
            {
              data: users, // 🔥 from API
              color: "#1B2447",
              valueFormatter: (value) => `${value} users`,
            },
          ]}
          xAxis={[
            {
              scaleType: "band",
              data: dates, // 🔥 from API
              tickLabelStyle: {
                fill: "#547792",
                fontFamily: "Poppins, sans-serif",
                fontSize: "0.75rem",
              },
              disableLine: true,
              disableTicks: true,
              labelStyle: {
                ...axisLabelStyle,
                dominantBaseline: "hanging",
                textAnchor: "middle",
              },
            },
          ]}
          yAxis={[
            {
              min: 0,
              max: 100,
              tickLabelStyle: {
                fill: "#547792",
                fontFamily: "Poppins, sans-serif",
                fontSize: "0.75rem",
              },
              disableLine: true,
              disableTicks: true,
              labelStyle: {
                ...axisLabelStyle,
                textAnchor: "middle",
              },
            },
          ]}
          margin={{ top: 30, bottom: 60, left: 60, right: 30 }}
        />
      </Box>
    </Box>
  );
};

export default AdminBarChart;