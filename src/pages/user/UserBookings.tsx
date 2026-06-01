import React, { useState } from "react";
import {
  Box,
  Card,
  CardContent,
  Typography,
  useTheme,
  useMediaQuery,
} from "@mui/material";
import { BookingDetailsModal } from "../../components";

const themeColor = "#1B2447";

const bookings = [
  { id: "BKG001", propertyName: "Luxury Apartment in Chennai", price: 4500, status: "Confirmed", date: "2025-10-10" },
  { id: "BKG002", propertyName: "Cozy Villa in Goa", price: 7200, status: "Pending", date: "2025-10-09" },
  { id: "BKG003", propertyName: "Mountain Retreat in Manali", price: 6500, status: "Cancelled", date: "2025-09-28" },
  { id: "BKG004", propertyName: "Beachfront Suite in Pondicherry", price: 8200, status: "Confirmed", date: "2025-09-26" },
  { id: "BKG005", propertyName: "Modern Flat in Mumbai", price: 5300, status: "Pending", date: "2025-09-24" },
  { id: "BKG006", propertyName: "Hill View Stay in Ooty", price: 4600, status: "Confirmed", date: "2025-09-21" },
  { id: "BKG007", propertyName: "Heritage Home in Jaipur", price: 7500, status: "Cancelled", date: "2025-09-19" },
  { id: "BKG008", propertyName: "Skyline Apartment in Bangalore", price: 6900, status: "Confirmed", date: "2025-09-17" },
  { id: "BKG009", propertyName: "Palm Villa in Kerala", price: 7200, status: "Pending", date: "2025-09-14" },
  { id: "BKG010", propertyName: "Forest Cabin in Munnar", price: 4800, status: "Confirmed", date: "2025-09-12" },
];

const UserBookings: React.FC = () => {
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [open, setOpen] = useState(false);

  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const handleCardClick = (id: string) => {
    setSelectedId(id);
    setOpen(true);
  };

  const handleClose = () => setOpen(false);

  return (
    <Box
      sx={{
        maxWidth: "1400px",
        mx: "auto",
        mt: 4,
        px: isMobile ? 2 : 3,
      }}
    >
      <Typography
        variant="h4"
        sx={{
          fontWeight: 700,
          color: themeColor,
          mb: 4,
          textAlign: "center",
          fontFamily: "'Poppins', sans-serif",
          fontSize: isMobile ? "1.6rem" : "2rem",
        }}
      >
        My Bookings
      </Typography>

      {/* Cards Wrapper */}
      <Box
        sx={{
          display: "flex",
          flexWrap: "wrap",
          gap: 3,
          justifyContent: isMobile ? "center" : "flex-start",
        }}
      >
        {bookings.map((booking) => (
          <Card
            key={booking.id}
            onClick={() => handleCardClick(booking.id)}
            sx={{
              flex: isMobile ? "1 1 100%" : "1 1 calc(50% - 24px)",
              borderRadius: "18px",
              boxShadow: "0 8px 20px rgba(0,0,0,0.1)",
              cursor: "pointer",
              transition: "transform 0.25s ease, box-shadow 0.25s ease",
              "&:hover": {
                transform: "translateY(-5px)",
                boxShadow: "0 10px 28px rgba(0,0,0,0.15)",
              },
              minHeight: "180px",
              display: "flex",
              alignItems: "center",
            }}
          >
            <CardContent
              sx={{
                width: "100%",
                p: isMobile ? 2 : 3.5,
                display: "flex",
                flexDirection: isMobile ? "column" : "row",
                justifyContent: "space-between",
                alignItems: isMobile ? "flex-start" : "center",
                gap: isMobile ? 1 : 3,
              }}
            >
              {/* Property Info */}
              <Box>
                <Typography
                  variant="h6"
                  sx={{
                    fontWeight: 700,
                    fontFamily: "'Poppins', sans-serif",
                    fontSize: isMobile ? "1rem" : "1.2rem",
                  }}
                >
                  {booking.propertyName}
                </Typography>
                <Typography
                  variant="body2"
                  sx={{
                    color: "#666",
                    fontFamily: "'Poppins', sans-serif",
                    fontSize: "0.9rem",
                  }}
                >
                  Booking ID: {booking.id}
                </Typography>
              </Box>

              {/* Price + Status */}
              <Box sx={{ textAlign: isMobile ? "left" : "center" }}>
                <Typography
                  variant="subtitle1"
                  sx={{
                    fontWeight: 700,
                    color: "#000",
                    fontFamily: "'Poppins', sans-serif",
                    fontSize: "1rem",
                  }}
                >
                  ₹ {booking.price.toLocaleString()}
                </Typography>
                <Typography
                  variant="body2"
                  sx={{
                    color:
                      booking.status === "Confirmed"
                        ? "green"
                        : booking.status === "Pending"
                        ? "#e6a100"
                        : "red",
                    fontWeight: 600,
                    fontFamily: "'Poppins', sans-serif",
                    fontSize: "0.9rem",
                  }}
                >
                  {booking.status}
                </Typography>
              </Box>

              {/* Date */}
              <Box sx={{ textAlign: isMobile ? "left" : "right" }}>
                <Typography
                  variant="body2"
                  sx={{
                    color: "#777",
                    fontFamily: "'Poppins', sans-serif",
                    fontSize: "0.9rem",
                  }}
                >
                  Booked on: {booking.date}
                </Typography>
              </Box>
            </CardContent>
          </Card>
        ))}
      </Box>

      {/* Booking Details Modal */}
      <BookingDetailsModal
        open={open}
        onClose={handleClose}
        bookingId={selectedId}
      />
    </Box>
  );
};

export default UserBookings;
