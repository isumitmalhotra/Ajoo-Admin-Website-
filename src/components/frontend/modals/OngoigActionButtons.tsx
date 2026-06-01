// OngoigActionButtons.tsx
import React, { useEffect, useState } from "react";
import { Box, Typography, Divider, Button } from "@mui/material";
import { useNavigate } from "react-router-dom";
import SupportAgentIcon from "@mui/icons-material/SupportAgent";
import PaymentIcon from "@mui/icons-material/Payment";
import DirectionsIcon from "@mui/icons-material/Directions";
import CancelIcon from "@mui/icons-material/Cancel";
import LogoutIcon from "@mui/icons-material/Logout";
// import RateReviewIcon from "@mui/icons-material/RateReview";

interface OngoigActionButtonsProps {
  booking: any;
  onCancel?: () => void;
}

const OngoigActionButtons: React.FC<OngoigActionButtonsProps> = ({
  booking,
  onCancel,
}) => {
  const navigate = useNavigate();
  const [userLocation, setUserLocation] = useState<{ lat: number; lng: number } | null>(null);

  useEffect(() => {
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (p) => setUserLocation({ lat: p.coords.latitude, lng: p.coords.longitude }),
        () => setUserLocation(null)
      );
    }
  }, []);

  const handleSupport = () => navigate("/support");

  const handleGetDirections = () => {
    // If booking has coordinates prefer them
    const destLat = booking?.lat;
    const destLng = booking?.lng;
    if (destLat && destLng && userLocation) {
      window.open(`https://www.google.com/maps/dir/${userLocation.lat},${userLocation.lng}/${destLat},${destLng}`, "_blank");
      return;
    }

    const destination = encodeURIComponent(booking.location || booking.propertyName || "Aajoo Property");
    if (userLocation) {
      window.open(`https://www.google.com/maps/dir/${userLocation.lat},${userLocation.lng}/${destination}`, "_blank");
    } else {
      window.open(`https://www.google.com/maps/search/?api=1&query=${destination}`, "_blank");
    }
  };

  const handleCheckout = () => navigate(`/user/checkout/${booking.id}`, { state: { booking } });
  const handlePayNow = () => navigate(`/user/payment/${booking.id}`, { state: { booking } });
  const handleCancel = () => {
    if (onCancel) onCancel();
    else navigate(`/booking/cancel-result/${booking.id}`, { state: { booking } });
  };

  return (
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
        <Button
          onClick={handleCheckout}
          startIcon={<LogoutIcon />}
          variant="contained"
          sx={{ bgcolor: "#1B2447", px: 2.5, py: 0.7, minWidth: 140, textTransform: "none", fontWeight: 700 }}
        >
          Check Out
        </Button>

        <Button
          onClick={handlePayNow}
          startIcon={<PaymentIcon />}
          variant="contained"
          sx={{ bgcolor: "#1B2447", px: 2.5, py: 0.7, minWidth: 140, textTransform: "none", fontWeight: 700 }}
        >
          Pay Now
        </Button>

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

        <Button
          onClick={handleSupport}
          startIcon={<SupportAgentIcon />}
          variant="contained"
          sx={{ bgcolor: "#1976d2", px: 2.5, py: 0.7, minWidth: 160, textTransform: "none", fontWeight: 700 }}
        >
          Customer Support
        </Button>

        {/* <Button
          startIcon={<RateReviewIcon />}
          variant="contained"
          sx={{ bgcolor: "#ff9800", px: 2.5, py: 0.7, minWidth: 150, textTransform: "none", fontWeight: 700 }}
          onClick={() => navigate(`/user/review/${booking.id}`)}
        >
          Rate Stay
        </Button> */}
      </Box>
    </Box>
  );
};

export default OngoigActionButtons;
