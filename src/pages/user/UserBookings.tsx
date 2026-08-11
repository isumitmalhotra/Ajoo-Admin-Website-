import React, { useState, useEffect } from "react";
import {
  Box,
  Card,
  CardContent,
  Typography,
  useTheme,
  useMediaQuery,
  CircularProgress,
} from "@mui/material";
import { BookingDetailsModal } from "../../components";
import { getMyBookings } from "../../services/customerApi";

const themeColor = "#1B2447";

interface BookingRow {
  id: string;
  propertyName: string;
  price: number;
  status: string;
  date: string;
}

const UserBookings: React.FC = () => {
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [open, setOpen] = useState(false);

  // Real bookings — GET /user/booking-history
  const [bookings, setBookings] = useState<BookingRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadBookings = async () => {
    setLoading(true);
    setError(null);
    try {
      const rows = await getMyBookings();
      setBookings(
        rows.map((b: any) => ({
          id: String(b.book_id ?? b.book_pri_id ?? ""),
          propertyName:
            b["bookingProperty.property_name"] ||
            b.bookingProperty?.property_name ||
            "Property",
          price: Number(b.book_price) || 0,
          status: b["bookingStatus.bs_title"] || b.bookingStatus?.bs_title || "—",
          date: b.book_added_at
            ? new Date(b.book_added_at).toLocaleDateString("en-IN")
            : "",
        }))
      );
    } catch {
      setError("Couldn't load your bookings. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadBookings();
  }, []);

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
          fontFamily: "'Inter', sans-serif",
          fontSize: isMobile ? "1.6rem" : "2rem",
        }}
      >
        My Bookings
      </Typography>

      {loading && (
        <Box sx={{ display: "flex", justifyContent: "center", py: 6 }}>
          <CircularProgress sx={{ color: themeColor }} />
        </Box>
      )}
      {!loading && error && (
        <Typography sx={{ textAlign: "center", color: "#b00020", py: 4 }}>{error}</Typography>
      )}
      {!loading && !error && bookings.length === 0 && (
        <Typography sx={{ textAlign: "center", color: "#6B7390", py: 6 }}>
          You have no bookings yet.
        </Typography>
      )}

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
                    fontFamily: "'Inter', sans-serif",
                    fontSize: isMobile ? "1rem" : "1.2rem",
                  }}
                >
                  {booking.propertyName}
                </Typography>
                <Typography
                  variant="body2"
                  sx={{
                    color: "#666",
                    fontFamily: "'Inter', sans-serif",
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
                    fontFamily: "'Inter', sans-serif",
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
                    fontFamily: "'Inter', sans-serif",
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
                    fontFamily: "'Inter', sans-serif",
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
        onCancelled={loadBookings}
      />
    </Box>
  );
};

export default UserBookings;
