import React from "react";
import { Box, Typography, Button } from "@mui/material";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import { useNavigate, useParams, useLocation } from "react-router-dom";

const CancelBookResult: React.FC = () => {
  const { bookingId } = useParams<{ bookingId: string }>();
  console.log(bookingId)
  const location = useLocation();
  console.log(location)
  const navigate = useNavigate();

  return (
    <Box
      sx={{
        minHeight: "100vh",
        backgroundColor: "#f8f9fa",
        display: "flex",
        justifyContent: "center",
        alignItems: "center",
        px: 2,
      }}
    >
      <Box
        sx={{
          backgroundColor: "#fff",
          p: 4,
          borderRadius: 4,
          boxShadow: "0px 6px 20px rgba(0,0,0,0.1)",
          maxWidth: 450,
          width: "100%",
          textAlign: "center",
        }}
      >
        <CheckCircleIcon sx={{ fontSize: 70, color: "#4CAF50", mb: 2 }} />

        <Typography
          variant="h5"
          fontWeight={700}
          sx={{ color: "#2e7d32", mb: 1 }}
        >
          Booking Cancelled Successfully
        </Typography>

        <Typography variant="body1" sx={{ color: "gray", mb: 3 }}>
          Your booking has been successfully cancelled. Any applicable refund
          will be processed within <b>3–5 business days</b>.
        </Typography>

        <Button
          variant="contained"
          sx={{
            bgcolor: "#1B2447",
            "&:hover": { bgcolor: "#a83454" },
            textTransform: "none",
            px: 4,
            py: 1.5,
            borderRadius: 2,
            fontWeight: 600,
          }}
        onClick={() => navigate("/user-dashboard", { state: { section: "ongoing" } })}
        >
          Back to My Bookings
        </Button>
      </Box>
    </Box>
  );
};

export default CancelBookResult;
