// OngoigActionButtons.tsx
import React, { useEffect, useState } from "react";
import { Box, Typography, Divider, Button, CircularProgress } from "@mui/material";
import toast from "react-hot-toast";
import PaymentIcon from "@mui/icons-material/Payment";
import DirectionsIcon from "@mui/icons-material/Directions";
import CancelIcon from "@mui/icons-material/Cancel";
import LogoutIcon from "@mui/icons-material/Logout";
import WhatsAppIcon from "@mui/icons-material/WhatsApp";
import DirectionsModal from "./DirectionsModal";
import {
  createOngoingPaymentOrder,
  verifyBookingPayment,
} from "../../../services/customerApi";

// TODO: replace with the real Aajoo support contacts.
const SUPPORT_WHATSAPP = "919999999999";
const RZP_KEY =
  (import.meta.env.VITE_RAZORPAY_KEY as string | undefined) || "rzp_test_XUTODhUdMAshi6";

const loadRazorpay = () =>
  new Promise<boolean>((resolve) => {
    if ((window as any).Razorpay) return resolve(true);
    const s = document.createElement("script");
    s.src = "https://checkout.razorpay.com/v1/checkout.js";
    s.onload = () => resolve(true);
    s.onerror = () => resolve(false);
    document.body.appendChild(s);
  });

interface OngoigActionButtonsProps {
  booking: any;
  onCancel?: () => void;
  onPaid?: () => void;
}

const OngoigActionButtons: React.FC<OngoigActionButtonsProps> = ({
  booking,
  onCancel,
  onPaid,
}) => {
  const [userLocation, setUserLocation] = useState<{ lat: number; lng: number } | null>(null);
  const [directionsOpen, setDirectionsOpen] = useState(false);
  const [paying, setPaying] = useState(false);

  const isPaid = booking?.isPaid === true;

  useEffect(() => {
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (p) => setUserLocation({ lat: p.coords.latitude, lng: p.coords.longitude }),
        () => setUserLocation(null)
      );
    }
  }, []);

  // Customer support — one tap to WhatsApp (easy to reach).
  const handleSupport = () =>
    window.open(
      `https://wa.me/${SUPPORT_WHATSAPP}?text=${encodeURIComponent(
        `Hi Aajoo support, I need help with booking ${booking?.id ?? ""}.`
      )}`,
      "_blank"
    );

  // Directions are shown in-app via an embedded map (no external tab).
  const handleGetDirections = () => setDirectionsOpen(true);

  // Check-out only applies once a stay is paid; managed at the property.
  const handleCheckout = () =>
    toast("Check-out is completed at the property at the end of your stay.", { icon: "🏨" });

  // Pay Now → real Razorpay gateway for pay-on-arrival (COD) bookings.
  const handlePayNow = async () => {
    setPaying(true);
    try {
      const order = await createOngoingPaymentOrder(booking.id);
      const ready = await loadRazorpay();
      if (!ready || !order?.id) {
        toast.error("Couldn't start payment. Please try again.");
        return;
      }
      const rzp = new (window as any).Razorpay({
        key: RZP_KEY,
        amount: order.amount,
        currency: order.currency || "INR",
        order_id: order.id,
        name: "Aajoo Homes",
        description: booking.propertyName || "Booking payment",
        theme: { color: "#1B2447" },
        handler: async (resp: any) => {
          try {
            await verifyBookingPayment({
              paymentId: resp.razorpay_payment_id,
              orderId: resp.razorpay_order_id,
              signature: resp.razorpay_signature,
            });
            toast.success("Payment successful!");
            onPaid?.();
          } catch {
            toast.error("Payment received — verification pending. We'll confirm shortly.");
          }
        },
      });
      rzp.on("payment.failed", () => toast.error("Payment failed. Please try again."));
      rzp.open();
    } catch (e: any) {
      toast.error(e?.response?.data?.message || "Couldn't start payment.");
    } finally {
      setPaying(false);
    }
  };

  const handleCancel = () => onCancel?.();

  return (
    <>
    <Box
      sx={{
        mt: 3,
        p: 2.5,
        borderRadius: 3,
        backgroundColor: "#fff",
        boxShadow: "0 6px 18px rgba(193,67,101,0.06)",
      }}
    >
      <Typography variant="h6" sx={{ fontWeight: 700, color: "#1B2447", mb: 1 }}>
        Actions
      </Typography>

      <Typography variant="body2" sx={{ color: "#777", mb: 2 }}>
        Manage your booking
      </Typography>

      <Divider sx={{ mb: 2 }} />

      <Box sx={{ display: "flex", flexWrap: "wrap", gap: 1.25, justifyContent: "center" }}>
        {/* Pay-on-arrival (unpaid) → Pay Now; once paid → Check Out */}
        {isPaid ? (
          <Button
            onClick={handleCheckout}
            startIcon={<LogoutIcon />}
            variant="contained"
            sx={{ bgcolor: "#1B2447", px: 2.5, py: 0.7, minWidth: 150, textTransform: "none", fontWeight: 700 }}
          >
            Check Out
          </Button>
        ) : (
          <Button
            onClick={handlePayNow}
            disabled={paying}
            startIcon={paying ? <CircularProgress size={16} sx={{ color: "#fff" }} /> : <PaymentIcon />}
            variant="contained"
            sx={{ bgcolor: "#1B2447", px: 2.5, py: 0.7, minWidth: 150, textTransform: "none", fontWeight: 700 }}
          >
            {paying ? "Starting…" : "Pay Now"}
          </Button>
        )}

        <Button
          onClick={handleGetDirections}
          startIcon={<DirectionsIcon />}
          variant="contained"
          sx={{ bgcolor: "#4caf50", px: 2.5, py: 0.7, minWidth: 160, textTransform: "none", fontWeight: 700 }}
        >
          Get Directions
        </Button>

        <Button
          onClick={handleCancel}
          startIcon={<CancelIcon />}
          variant="contained"
          sx={{ bgcolor: "#f44336", px: 2.5, py: 0.7, minWidth: 160, textTransform: "none", fontWeight: 700 }}
        >
          Cancel Booking
        </Button>
      </Box>

      {/* Support — prominent & one-tap (was easy to miss) */}
      <Button
        onClick={handleSupport}
        startIcon={<WhatsAppIcon />}
        fullWidth
        variant="outlined"
        sx={{
          mt: 1.75,
          borderColor: "#25D366",
          color: "#1B7a3e",
          py: 1,
          borderRadius: 2,
          textTransform: "none",
          fontWeight: 700,
          "&:hover": { bgcolor: "rgba(37,211,102,0.08)", borderColor: "#25D366" },
        }}
      >
        Chat with Aajoo Support
      </Button>
    </Box>

    <DirectionsModal
      open={directionsOpen}
      onClose={() => setDirectionsOpen(false)}
      destination={{
        lat: booking?.lat,
        lng: booking?.lng,
        label: booking?.location || booking?.propertyName,
      }}
      userLocation={userLocation}
    />
    </>
  );
};

export default OngoigActionButtons;
