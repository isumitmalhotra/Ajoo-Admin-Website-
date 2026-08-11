import React, { useEffect, useState } from "react";
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
  CircularProgress,
} from "@mui/material";
import { motion } from "framer-motion";
import RoomIcon from "@mui/icons-material/Room";
import { OngoingBookingModal } from "../../components";
import { getOngoingBookings } from "../../services/customerApi";

// Read a value that may be nested (raw+nest Sequelize) or flattened dot-notation.
const pick = (row: any, nestedPath: string[], dotKey: string) => {
  let cur = row;
  for (const k of nestedPath) {
    cur = cur?.[k];
    if (cur == null) break;
  }
  return cur ?? row?.[dotKey];
};

interface OngoingBooking {
  id: string;
  propertyName: string;
  location: string;
  checkIn: string;
  checkOut: string;
  totalPrice: number;
  status: string;
  isPaid: boolean;
  isCod: boolean;
  image: string | null;
  hostName: string;
  hostPhone: string;
  lat?: number;
  lng?: number;
}

const UserOngoingBooking: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));
  const [selectedBooking, setSelectedBooking] = useState<any>(null);

  const [bookings, setBookings] = useState<OngoingBooking[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadBookings = async () => {
    setLoading(true);
    setError(null);
    try {
      const rows = await getOngoingBookings();
      setBookings(
        rows.map((b: any) => ({
          id: String(b.book_id ?? b.book_pri_id ?? ""),
          propertyName:
            pick(b, ["bookingProperty", "property_name"], "bookingProperty.property_name") ||
            "Property",
          location:
            pick(b, ["bookingProperty", "property_city"], "bookingProperty.property_city") ||
            pick(b, ["bookingProperty", "HostDetails", "user_fullName"], "bookingProperty.HostDetails.user_fullName") ||
            "",
          checkIn:
            pick(b, ["bookDetails", "bt_book_from"], "bookDetails.bt_book_from") || "",
          checkOut:
            pick(b, ["bookDetails", "bt_book_to"], "bookDetails.bt_book_to") || "",
          totalPrice: Number(b.book_price) || 0,
          status:
            pick(b, ["bookingStatus", "bs_title"], "bookingStatus.bs_title") || "Ongoing",
          isPaid: b.book_is_paid === true || b.book_is_paid === 1,
          isCod: b.book_is_cod === true || b.book_is_cod === 1,
          image: b.property_image ?? null,
          hostName:
            pick(b, ["bookingProperty", "HostDetails", "user_fullName"], "bookingProperty.HostDetails.user_fullName") ||
            "",
          hostPhone:
            pick(b, ["bookingProperty", "HostDetails", "user_pnumber"], "bookingProperty.HostDetails.user_pnumber") ||
            "",
        }))
      );
    } catch {
      setError("Couldn't load your ongoing bookings. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadBookings();
  }, []);

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case "confirmed":
      case "paid":
        return "success";
      case "pending":
      case "payment pending":
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
          fontFamily: "'Inter', sans-serif",
        }}
      >
        Ongoing Bookings
      </Typography>

      {loading && (
        <Box sx={{ display: "flex", justifyContent: "center", py: 6 }}>
          <CircularProgress sx={{ color: "#1B2447" }} />
        </Box>
      )}
      {!loading && error && (
        <Typography sx={{ textAlign: "center", color: "#b00020", py: 4 }}>
          {error}
        </Typography>
      )}
      {!loading && !error && bookings.length === 0 && (
        <Typography sx={{ textAlign: "center", color: "#6B7390", py: 6 }}>
          You have no ongoing bookings right now.
        </Typography>
      )}

      {!loading &&
        !error &&
        bookings.map((booking, index) => (
          <motion.div
            key={booking.id || index}
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
                      fontFamily: "'Inter', sans-serif",
                      fontSize: { xs: "18px", sm: "20px" },
                    }}
                  >
                    {booking.propertyName}
                  </Typography>

                  {/* Host */}
                  {booking.hostName && (
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
                      👤 Hosted by {booking.hostName}
                    </Typography>
                  )}

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

                    {/* Check-in */}
                    {booking.checkIn && (
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
                    )}

                    {/* Check-out */}
                    {booking.checkOut && (
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
                    )}
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
                      fontFamily: "'Inter', sans-serif",
                    }}
                  />

                  <Typography
                    variant="h6"
                    sx={{
                      fontWeight: 700,
                      color: "#2E7D32",
                      fontFamily: "'Inter', sans-serif",
                    }}
                  >
                    ₹ {booking.totalPrice.toLocaleString()}
                  </Typography>

                  {/* 🌍 Get Direction Button (only when coords are available) */}
                  {booking.lat != null && booking.lng != null && (
                    <Button
                      variant="contained"
                      color="primary"
                      startIcon={<RoomIcon />}
                      onClick={(e) => {
                        e.stopPropagation(); // prevent modal open
                        handleDirection(booking.lat as number, booking.lng as number);
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
                  )}
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
        onChanged={() => {
          setSelectedBooking(null);
          loadBookings();
        }}
      />
    </Box>
  );
};

export default UserOngoingBooking;
