// OngoingBookingModal.tsx
import React, { useState } from "react";
import {
  Modal,
  Box,
  Typography,
  Divider,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  useTheme,
  useMediaQuery,
  IconButton,
} from "@mui/material";

import CloseIcon from "@mui/icons-material/Close";
import { motion } from "framer-motion";
import toast from "react-hot-toast";

import BookingDetails from "./BookingDetails";
import HostInfo from "./HostInfo";
import OngoigActionButtons from "./OngoigActionButtons";
import { cancelBooking } from "../../../services/customerApi";

interface OngoingBookingModalProps {
  open: boolean;
  onClose: () => void;
  booking: any;
  /** Called after a cancel/payment so the parent can refresh the list. */
  onChanged?: () => void;
}

const OngoingBookingModal: React.FC<OngoingBookingModalProps> = ({
  open,
  onClose,
  booking,
  onChanged,
}) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [cancelling, setCancelling] = useState(false);

  if (!booking) return null;

  const confirmCancel = async () => {
    setCancelling(true);
    try {
      await cancelBooking(booking.id);
      toast.success("Booking cancelled");
      setConfirmOpen(false);
      onChanged?.();
    } catch (e: any) {
      toast.error(
        e?.response?.data?.message || e?.message || "Couldn't cancel this booking."
      );
    } finally {
      setCancelling(false);
    }
  };

  return (
    <>
      <Modal
        open={open}
        onClose={onClose}
        sx={{
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          backdropFilter: "blur(6px)",
          zIndex: 1400,
        }}
      >
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.35 }}
        >
          <Box
            sx={{
              width: isMobile ? "96vw" : "88vw",
              maxWidth: 900,
              maxHeight: "90vh",
              overflowY: "auto",
              backgroundColor: "#fff",
              borderRadius: 3,
              p: { xs: 2.5, sm: 4 },
              boxShadow: "0 14px 50px rgba(0,0,0,0.25)",
              position: "relative",

              // thin scroll
              "&::-webkit-scrollbar": { height: 8, width: 8 },
              "&::-webkit-scrollbar-thumb": {
                background: "#f0a6b6",
                borderRadius: 10,
              },
              "&::-webkit-scrollbar-track": { background: "#fff" },
            }}
          >
            {/* Floating top-left close */}
            <IconButton
              onClick={onClose}
              size="small"
              sx={{
                position: "absolute",
                top: 10,
                right: 10,
                bgcolor: "#fff",
                boxShadow: 1,
                color: "#1B2447",
                "&:hover": { bgcolor: "#ffe4ed" },
              }}
            >
              <CloseIcon />
            </IconButton>

            {/* ---------------- HEADER IMAGE ---------------- */}
            <Box sx={{ width: "100%", mb: 2 }}>
              <motion.img
                src={
                  booking.image ||
                  "https://images.unsplash.com/photo-1600585154340-be6161a56a0c"
                }
                alt="Booking"
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.45 }}
                style={{
                  width: "100%",
                  height: 220,
                  borderRadius: 14,
                  objectFit: "cover",
                  boxShadow: "0 6px 25px rgba(0,0,0,0.14)",
                }}
              />
            </Box>

            {/* ---------------- TITLE & BASIC INFO ---------------- */}
            <Box sx={{ textAlign: "center", mb: 2 }}>
              <Typography
                variant="h4"
                sx={{
                  fontWeight: 700,
                  color: "#1B2447",
                  fontFamily: "'Inter', sans-serif",
                }}
              >
                {booking.propertyName || "Aajoo Premium Homestay"}
              </Typography>

              <Typography sx={{ mt: 0.8, color: "#777" }}>
                {booking.location || "Manali, Himachal Pradesh"}
              </Typography>

              <Typography sx={{ mt: 1.2, color: "#444" }}>
                {booking.summary ||
                  "Cozy stay with mountain views and a friendly host."}
              </Typography>

              <Typography
                sx={{
                  mt: 1.2,
                  color: "#2E7D32",
                  fontWeight: 700,
                  fontSize: "1.1rem",
                }}
              >
                Status: {booking.status || "Ongoing"}
              </Typography>

              {/* Amount — prominent */}
              {booking.totalPrice != null && (
                <Box
                  sx={{
                    mt: 1.5,
                    display: "inline-flex",
                    alignItems: "baseline",
                    gap: 0.75,
                    bgcolor: "rgba(27,36,71,.05)",
                    border: "1px solid #D9CFB8",
                    borderRadius: "999px",
                    px: 2,
                    py: 0.75,
                  }}
                >
                  <Typography sx={{ fontSize: "0.8rem", color: "#6B7390" }}>
                    {booking.isPaid ? "Paid" : "Amount due"}
                  </Typography>
                  <Typography sx={{ fontWeight: 800, color: "#1B2447", fontSize: "1.2rem" }}>
                    ₹{Number(booking.totalPrice).toLocaleString("en-IN")}
                  </Typography>
                </Box>
              )}
            </Box>

            <Divider sx={{ my: 2 }} />

            {/* ---------------- VERTICAL BOOKING DETAILS ---------------- */}
            <Box sx={{ mb: 2 }}>
              <BookingDetails booking={booking} />
            </Box>

            <Divider sx={{ my: 2 }} />

            {/* ---------------- VERTICAL HOST INFO ---------------- */}
            <Box sx={{ mb: 2 }}>
              <HostInfo
                host={{
                  name: booking.hostName,
                  phone: booking.hostPhone,
                  email: booking.hostEmail,
                  address: booking.hostAddress,
                  image: booking.hostImage,
                }}
              />
            </Box>

            <Divider sx={{ my: 3 }} />

            {/* ---------------- ACTION BUTTONS (FULL WIDTH, STACKED) ---------------- */}
            <Box sx={{ mb: 3 }}>
              <OngoigActionButtons
                booking={booking}
                onCancel={() => setConfirmOpen(true)}
                onPaid={onChanged}
              />
            </Box>

            {/* ---------------- FLOATING BOTTOM CLOSE CIRCLE ---------------- */}
            <Box sx={{ display: "flex", justifyContent: "center", mt: 2 }}>
              <Button
                onClick={onClose}
                sx={{
                  bgcolor: "#fff",
                  color: "#1B2447",
                  borderRadius: "50%",
                  width: 56,
                  height: 56,
                  minWidth: 56,
                  boxShadow: "0 6px 20px rgba(193,67,101,0.2)",
                  "&:hover": { bgcolor: "#ffeaf1" },
                }}
              >
                <CloseIcon />
              </Button>
            </Box>
          </Box>
        </motion.div>
      </Modal>

      {/* CANCEL CONFIRMATION */}
      <Dialog open={confirmOpen} onClose={() => setConfirmOpen(false)}>
        <DialogTitle sx={{ fontWeight: 700, color: "#1B2447" }}>
          Cancel Booking?
        </DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to cancel this booking? This action cannot be
            undone.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setConfirmOpen(false)} disabled={cancelling}>
            No, keep it
          </Button>
          <Button
            onClick={confirmCancel}
            disabled={cancelling}
            sx={{
              bgcolor: "#1B2447",
              color: "#fff",
              "&:hover": { bgcolor: "#a83454" },
            }}
          >
            {cancelling ? "Cancelling…" : "Yes, cancel"}
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
};

export default OngoingBookingModal;
