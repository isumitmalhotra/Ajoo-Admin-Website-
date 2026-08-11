import React, { useEffect, useState } from "react";
import { Box, Typography, Paper, CircularProgress } from "@mui/material";
import HotelIcon from "@mui/icons-material/Hotel";
import FavoriteIcon from "@mui/icons-material/Favorite";
import PaymentsIcon from "@mui/icons-material/Payments";
import { getMyBookings, getSavedProperties } from "../../services/customerApi";

const themeColor = "#1B2447";

interface StatCard {
  label: string;
  value: string;
  icon: React.ReactNode;
  accent: string;
}

const UserDashboard: React.FC = () => {
  const [bookingsCount, setBookingsCount] = useState(0);
  const [savedCount, setSavedCount] = useState(0);
  const [totalSpent, setTotalSpent] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      try {
        const [bookings, saved] = await Promise.all([
          getMyBookings().catch(() => []),
          getSavedProperties().catch(() => []),
        ]);
        if (cancelled) return;
        setBookingsCount(bookings.length);
        setSavedCount(saved.length);
        setTotalSpent(
          bookings.reduce(
            (sum: number, b: any) => sum + (Number(b.book_price) || 0),
            0
          )
        );
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const cards: StatCard[] = [
    {
      label: "Total Bookings",
      value: String(bookingsCount),
      icon: <HotelIcon />,
      accent: "#1B2447",
    },
    {
      label: "Saved Properties",
      value: String(savedCount),
      icon: <FavoriteIcon />,
      accent: "#C16345",
    },
    {
      label: "Total Spent",
      value: `₹ ${totalSpent.toLocaleString("en-IN")}`,
      icon: <PaymentsIcon />,
      accent: "#3F6B4E",
    },
  ];

  return (
    <Box sx={{ p: { xs: 1, sm: 2 } }}>
      <Typography
        variant="h5"
        sx={{
          fontWeight: 700,
          mb: 1,
          color: themeColor,
          fontFamily: "'Inter', sans-serif",
        }}
      >
        Dashboard
      </Typography>
      <Typography sx={{ color: "#6B7390", fontSize: 14, mb: 3 }}>
        A quick snapshot of your activity on Aajoo Homes.
      </Typography>

      {loading ? (
        <Box sx={{ display: "flex", justifyContent: "center", py: 6 }}>
          <CircularProgress sx={{ color: themeColor }} />
        </Box>
      ) : (
        <Box
          sx={{
            display: "grid",
            gridTemplateColumns: { xs: "1fr", sm: "repeat(3, 1fr)" },
            gap: 2.5,
          }}
        >
          {cards.map((c) => (
            <Paper
              key={c.label}
              elevation={0}
              sx={{
                p: 3,
                borderRadius: 3,
                border: "1px solid #D9CFB8",
                background: "#FFFAF0",
                display: "flex",
                alignItems: "center",
                gap: 2,
              }}
            >
              <Box
                sx={{
                  width: 52,
                  height: 52,
                  borderRadius: "14px",
                  display: "grid",
                  placeItems: "center",
                  color: "#fff",
                  bgcolor: c.accent,
                }}
              >
                {c.icon}
              </Box>
              <Box>
                <Typography
                  sx={{
                    fontFamily: "'Fraunces', serif",
                    fontSize: 26,
                    fontWeight: 600,
                    color: themeColor,
                    lineHeight: 1.1,
                  }}
                >
                  {c.value}
                </Typography>
                <Typography sx={{ color: "#6B7390", fontSize: 13 }}>
                  {c.label}
                </Typography>
              </Box>
            </Paper>
          ))}
        </Box>
      )}
    </Box>
  );
};

export { UserDashboard };
export default UserDashboard;
