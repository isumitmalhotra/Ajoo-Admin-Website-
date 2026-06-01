import React, { useState } from "react";
import {
  Box,
  Typography,
  Card,
  CardContent,
  Chip,
  Divider,
  useTheme,
  useMediaQuery,
  Button,
} from "@mui/material";
import { motion } from "framer-motion";
import RoomIcon from "@mui/icons-material/Room";
import { OngoingBookingModal } from "../../components";

const bookings = [
  {
    id: "BK12345",
    propertyName: "Sea View Villa",
    location: "Goa, India",
    bookedDate: "2025-10-10",
    checkIn: "2025-10-20",
    checkOut: "2025-10-23",
    totalPrice: 12500,
    status: "Confirmed",
    lat: 15.2993,
    lng: 74.124,
  },
  {
    id: "BK67890",
    propertyName: "Mountain Retreat",
    location: "Manali, India",
    bookedDate: "2025-10-05",
    checkIn: "2025-10-15",
    checkOut: "2025-10-18",
    totalPrice: 8700,
    status: "Pending",
    lat: 32.2396,
    lng: 77.1887,
  },
];

const UserOngoingBooking: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));
  const [selectedBooking, setSelectedBooking] = useState<any>(null);

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case "confirmed":
        return "success";
      case "pending":
        return "warning";
      case "cancelled":
        return "error";
      default:
        return "default";
    }
  };

  // 🌍 Redirect to Google Maps
  const handleDirection = (lat: number, lng: number) => {
    const googleMapsUrl = `https://www.google.com/maps?q=${lat},${lng}`;
    window.open(googleMapsUrl, "_blank");
  };

  return (
    <Box
      sx={{
        p: { xs: 2, sm: 3 },
        display: "flex",
        flexDirection: "column",
        gap: 2,
      }}
    >
      <Typography
        variant="h5"
        sx={{
          fontWeight: 700,
          mb: 2,
          color: "#1B2447",
          textAlign: isMobile ? "center" : "left",
          fontFamily: "'Poppins', sans-serif",
        }}
      >
        Ongoing Bookings
      </Typography>

      {bookings.map((booking, index) => (
        <motion.div
          key={booking.id}
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: index * 0.1, duration: 0.4 }}
        >
          <Card
            onClick={() => setSelectedBooking(booking)}
            sx={{
              width: "100%",
              borderRadius: 3,
              boxShadow: "0 4px 16px rgba(0,0,0,0.08)",
              transition: "all 0.2s ease",
              cursor: "pointer",
              "&:hover": {
                transform: "scale(1.01)",
                boxShadow: "0 6px 20px rgba(0,0,0,0.12)",
              },
            }}
          >
            <CardContent
              sx={{
                display: "flex",
                flexDirection: isMobile ? "column" : "row",
                justifyContent: "space-between",
                alignItems: isMobile ? "flex-start" : "center",
                gap: 2,
                fontFamily: "'Inter', sans-serif",
              }}
            >
              {/* Left Section */}
              <Box
                sx={{
                  flex: 1,
                  display: "flex",
                  flexDirection: "column",
                  gap: 1.2,
                  p: 1,
                }}
              >
                {/* Property Name */}
                <Typography
                  variant="h6"
                  sx={{
                    fontWeight: 800,
                    color: "#162447",
                    mb: 0.2,
                    lineHeight: 1.2,
                    fontFamily: "'Poppins', sans-serif",
                    fontSize: { xs: "18px", sm: "20px" },
                  }}
                >
                  {booking.propertyName}
                </Typography>

                {/* Location */}
                <Typography
                  variant="body2"
                  sx={{
                    display: "flex",
                    alignItems: "center",
                    gap: 0.8,
                    color: "#6c757d",
                    fontSize: "14px",
                    fontFamily: "'Inter', sans-serif",
                  }}
                >
                  📍 {booking.location}
                </Typography>

                <Divider sx={{ my: 1, opacity: 0.5 }} />

                {/* Detail Box */}
                <Box
                  sx={{
                    display: "flex",
                    flexDirection: "column",
                    gap: 1,
                    background: "#f8f9fc",
                    p: 2,
                    borderRadius: 2,
                    border: "1px solid #e3e6f0",
                  }}
                >
                  {/* Booking ID */}
                  <Typography
                    variant="body2"
                    sx={{
                      fontFamily: "'Inter', sans-serif",
                      fontSize: "14px",
                      display: "flex",
                      alignItems: "center",
                      gap: 1,
                      color: "#3a3a3a",
                    }}
                  >
                    <strong style={{ color: "#1d3557" }}>📄 Booking ID:</strong>
                    {booking.id}
                  </Typography>

                  {/* Booked On */}
                  <Typography
                    variant="body2"
                    sx={{
                      fontFamily: "'Inter', sans-serif",
                      fontSize: "14px",
                      display: "flex",
                      alignItems: "center",
                      gap: 1,
                      color: "#3a3a3a",
                    }}
                  >
                    <strong style={{ color: "#1d3557" }}>🗓 Booked On:</strong>
                    {booking.bookedDate}
                  </Typography>

                  {/* Check-in */}
                  <Typography
                    variant="body2"
                    sx={{
                      fontFamily: "'Inter', sans-serif",
                      fontSize: "14px",
                      display: "flex",
                      alignItems: "center",
                      gap: 1,
                      color: "#3a3a3a",
                    }}
                  >
                    <strong style={{ color: "#1d3557" }}>🏨 Check-In:</strong>
                    {booking.checkIn}
                  </Typography>

                  {/* Check-out */}
                  <Typography
                    variant="body2"
                    sx={{
                      fontFamily: "'Inter', sans-serif",
                      fontSize: "14px",
                      display: "flex",
                      alignItems: "center",
                      gap: 1,
                      color: "#3a3a3a",
                    }}
                  >
                    <strong style={{ color: "#1d3557" }}>🚪 Check-Out:</strong>
                    {booking.checkOut}
                  </Typography>
                </Box>
              </Box>

              {/* Right Section */}
              <Box
                sx={{
                  display: "flex",
                  flexDirection: "column",
                  alignItems: isMobile ? "flex-start" : "flex-end",
                  gap: 1.5,
                  minWidth: isMobile ? "100%" : "200px",
                }}
              >
                <Chip
                  label={booking.status}
                  color={getStatusColor(booking.status) as any}
                  sx={{
                    fontWeight: 600,
                    fontSize: 14,
                    borderRadius: "8px",
                    fontFamily: "'Poppins', sans-serif",
                  }}
                />

                <Typography
                  variant="h6"
                  sx={{
                    fontWeight: 700,
                    color: "#2E7D32",
                    fontFamily: "'Poppins', sans-serif",
                  }}
                >
                  ₹ {booking.totalPrice.toLocaleString()}
                </Typography>

                {/* 🌍 Get Direction Button */}
                <Button
                  variant="contained"
                  color="primary"
                  startIcon={<RoomIcon />}
                  onClick={(e) => {
                    e.stopPropagation(); // prevent modal open
                    handleDirection(booking.lat, booking.lng);
                  }}
                  sx={{
                    mt: 1,
                    textTransform: "none",
                    borderRadius: 2,
                    fontWeight: 600,
                    px: 2,
                    py: 1,
                    background: "#1B2447",
                    "&:hover": { background: "#a83654" },
                    width: isMobile ? "100%" : "auto",
                  }}
                >
                  Get Direction
                </Button>
              </Box>
            </CardContent>
          </Card>
        </motion.div>
      ))}

      {/* Booking Details Modal */}
      <OngoingBookingModal
        open={Boolean(selectedBooking)}
        onClose={() => setSelectedBooking(null)}
        booking={selectedBooking}
      />
    </Box>
  );
};

export default UserOngoingBooking;
