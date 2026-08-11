import React, { useState } from "react";
import Modal from "react-modal";
import {
  Box,
  Typography,
  // Divider,
  Button,
  IconButton,
  useMediaQuery,
  CircularProgress,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import DownloadIcon from "@mui/icons-material/Download";
import CancelIcon from "@mui/icons-material/Cancel";
import toast from "react-hot-toast";
import { cancelBooking } from "../../services/customerApi";

interface BookingDetailsModalProps {
  open: boolean;
  onClose: () => void;
  bookingId: string | null;
  /** Called after a successful cancellation so the parent can refresh its list. */
  onCancelled?: () => void;
}

const themeColor = "#1B2447";

Modal.setAppElement("#root");

const BookingDetailsModal: React.FC<BookingDetailsModalProps> = ({
  open,
  onClose,
  bookingId,
  onCancelled,
}) => {
  const isMobile = useMediaQuery("(max-width: 600px)");
  const [cancelling, setCancelling] = useState(false);

  if (!bookingId) return null;

  const handleCancel = async () => {
    if (!bookingId) return;
    setCancelling(true);
    try {
      await cancelBooking(bookingId);
      toast.success("Booking cancelled successfully");
      onCancelled?.();
      onClose();
    } catch (e: any) {
      toast.error(
        e?.response?.data?.message ||
          e?.message ||
          "Couldn't cancel this booking. Please try again."
      );
    } finally {
      setCancelling(false);
    }
  };

  const booking = {
    id: bookingId,
    propertyName: "Luxury Apartment in Chennai",
    guestName: "John Doe",
    price: 4500,
    status: "Confirmed",
    date: "2025-10-10",
    checkIn: "2025-10-15",
    checkOut: "2025-10-18",
  };

  // const starAnimation = {
  //   "@keyframes pulseStar": {
  //     "0%": { transform: "scale(1)" },
  //     "50%": { transform: "scale(1.25)" },
  //     "100%": { transform: "scale(1)" },
  //   },
  // };

  return (
    <Modal
      isOpen={open}
      onRequestClose={onClose}
      shouldCloseOnOverlayClick={true}
      contentLabel="Booking Details"
      style={{
        overlay: {
          backgroundColor: "rgba(0,0,0,0.55)",
          zIndex: 1000,
          display: "flex",
          alignItems: "center", // center vertically
          justifyContent: "center", // center horizontally
          padding: 0,
        },
        content: {
          width: isMobile ? "92%" : "620px",
          maxHeight: "85vh",
          borderRadius: "18px",
          padding: 0,
          border: "none",
          overflow: "hidden",
          margin: "0 auto",
          marginTop: isMobile ? "40px" : "80px", // ← clean margin from top
          inset: "auto", // prevents default fixed positioning
        },
      }}
    >
      {/* Header */}
      <Box
        sx={{
          bgcolor: themeColor,
          color: "#fff",
          px: isMobile ? 2 : 3,
          py: isMobile ? 1.5 : 2,
          position: "relative",
          fontFamily: "'Inter', sans-serif",
        }}
      >
        <Typography variant={isMobile ? "h6" : "h5"} sx={{ fontWeight: 700 }}>
          Booking Details
        </Typography>

        <IconButton
          onClick={onClose}
          sx={{
            position: "absolute",
            top: isMobile ? 6 : 10,
            right: isMobile ? 6 : 10,
            color: "#fff",
            "&:hover": { color: "#fbdce4" },
          }}
        >
          <CloseIcon />
        </IconButton>
      </Box>

      {/* Body */}
      <Box
        sx={{
          p: isMobile ? 2 : 3,
          overflowY: "auto",
          maxHeight: isMobile ? "65vh" : "60vh",
        }}
      >
        {/* Booking Card */}
        <Box
          sx={{
            p: isMobile ? 2 : 3,
            borderRadius: 3,
            bgcolor: "#fff",
            boxShadow: "0 4px 15px rgba(0,0,0,0.08)",
            border: "1px solid #eee",
            mb: 3,
            fontFamily: "'Inter', sans-serif",
          }}
        >
          <Typography
            sx={{
              fontWeight: 700,
              fontSize: isMobile ? "1rem" : "1.1rem",
              mb: 0.5,
            }}
          >
            {booking.propertyName}
          </Typography>

          <Typography
            sx={{
              color: "#777",
              fontSize: "0.85rem",
              mb: 2,
              fontStyle: "italic",
            }}
          >
            Booking ID: {booking.id}
          </Typography>

          {/* Responsive Grid */}
          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: isMobile ? "1fr" : "1fr 1fr",
              rowGap: 1.5,
              columnGap: 2,
              fontSize: "0.95rem",
            }}
          >
            <Typography>
              <strong>Guest:</strong> {booking.guestName}
            </Typography>

            <Typography>
              <strong>Price:</strong> ₹ {booking.price.toLocaleString()}
            </Typography>

            <Typography>
              <strong>Status:</strong>{" "}
              <span
                style={{
                  color:
                    booking.status === "Confirmed"
                      ? "green"
                      : booking.status === "Pending"
                        ? "#e6a100"
                        : "red",
                  fontWeight: 600,
                }}
              >
                {booking.status}
              </span>
            </Typography>

            <Typography>
              <strong>Booking Date:</strong> {booking.date}
            </Typography>

            <Typography sx={{ gridColumn: "1 / -1" }}>
              <strong>Stay:</strong> {booking.checkIn} – {booking.checkOut}
            </Typography>
          </Box>

          {/* Ratings Section */}

          <Typography
            sx={{
              fontWeight: 700,
              mb: 2,
              fontSize: isMobile ? "1rem" : "1.1rem",
              color: "#1B2447",
              marginTop: "20px",
            }}
          >
            Ratings
          </Typography>

          {/* Host Rating */}
          <Box
            sx={{
              display: "flex",
              alignItems: "center",
              mb: 2,
              justifyContent: "space-between",
            }}
          >
            <Typography sx={{ fontWeight: 600 }}>Host Rating</Typography>
            <Box sx={{ display: "flex", alignItems: "center", gap: 0.5 }}>
              {[1, 2, 3, 4].map((i) => (
                <span
                  key={i}
                  style={{
                    color: "#FFC107",
                    fontSize: isMobile ? "20px" : "24px",
                    animation: "pulseStar 1.5s ease-in-out",
                    animationDelay: `${i * 0.15}s`,
                    display: "inline-block",
                  }}
                >
                  ★
                </span>
              ))}
              <span
                style={{
                  color: "#ddd",
                  fontSize: isMobile ? "20px" : "24px",
                }}
              >
                ★
              </span>
            </Box>
          </Box>

          {/* Property Rating */}
          <Box
            sx={{
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
            }}
          >
            <Typography sx={{ fontWeight: 600 }}>Property Rating</Typography>
            <Box sx={{ display: "flex", alignItems: "center", gap: 0.5 }}>
              {[1, 2, 3, 4, 5].map((i) => (
                <span
                  key={i}
                  style={{
                    color: "#FFC107",
                    fontSize: isMobile ? "20px" : "24px",
                    animation: "pulseStar 1.5s ease-in-out",
                    animationDelay: `${i * 0.15}s`,
                    display: "inline-block",
                  }}
                >
                  ★
                </span>
              ))}
            </Box>
          </Box>
        </Box>

        {/* Download Invoice Button */}
        <Button
          variant="contained"
          startIcon={<DownloadIcon />}
          sx={{
            bgcolor: themeColor,
            "&:hover": { bgcolor: "#a83355" },
            py: 1.2,
            px: 3,
            borderRadius: "10px",
            width: "100%",
            textTransform: "none",
            fontWeight: 600,
            fontFamily: "'Inter', sans-serif",
            fontSize: isMobile ? "0.9rem" : "1rem",
            mb: 2,
          }}
        >
          Download Invoice
        </Button>
      </Box>

      {/* Footer */}
      <Box
        sx={{
          p: isMobile ? 1.5 : 2,
          borderTop: "1px solid #eee",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          gap: 1.5,
        }}
      >
        <Button
          onClick={handleCancel}
          disabled={cancelling}
          startIcon={
            cancelling ? (
              <CircularProgress size={16} sx={{ color: "#b00020" }} />
            ) : (
              <CancelIcon />
            )
          }
          sx={{
            textTransform: "none",
            px: isMobile ? 2 : 3,
            py: 1.2,
            borderRadius: "10px",
            color: "#b00020",
            border: "1px solid #f0c2c8",
            bgcolor: "#fff5f6",
            "&:hover": { bgcolor: "#ffe9ec" },
            fontFamily: "'Inter', sans-serif",
            fontWeight: 600,
          }}
        >
          {cancelling ? "Cancelling…" : "Cancel Booking"}
        </Button>

        <Button
          onClick={onClose}
          sx={{
            textTransform: "none",
            px: isMobile ? 3 : 4,
            py: 1.2,
            borderRadius: "10px",
            bgcolor: "#f2f2f2",
            "&:hover": { bgcolor: "#e6e6e6" },
            fontFamily: "'Inter', sans-serif",
            fontWeight: 600,
          }}
        >
          Close
        </Button>
      </Box>
    </Modal>
  );
};

export default BookingDetailsModal;
