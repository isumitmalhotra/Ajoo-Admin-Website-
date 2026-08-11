import React from "react";
import { Box, Typography, Button } from "@mui/material";
import CheckCircleOutlineIcon from "@mui/icons-material/CheckCircleOutline";
import NavigationIcon from "@mui/icons-material/Navigation";
import HomeIcon from "@mui/icons-material/Home";
import { motion } from "framer-motion";
import { useNavigate } from "react-router-dom";

const BookingConfirmed: React.FC = () => {
  const navigate = useNavigate();

  // Replace with your property coordinates
  const LAT = 13.0827;
  const LNG = 80.2707;

  const openDirections = () => {
    const url = `https://www.google.com/maps/dir/?api=1&destination=${LAT},${LNG}`;
    window.open(url, "_blank");
  };

  return (
    <Box
      sx={{
        minHeight: "100vh",
        background: "#EFE7D6",
        display: "flex",
        justifyContent: "center",
        alignItems: "center",
        p: 2,
      }}
    >
      <motion.div
        initial={{ opacity: 0, y: 40 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
      >
        <Box
          sx={{
            background: "#fff",
            width: "100%",
            maxWidth: 460,
            p: 4,
            borderRadius: "20px",
            boxShadow: "0 10px 25px rgba(0,0,0,0.1)",
            textAlign: "center",
          }}
        >
          {/* Animated Icon */}
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ type: "spring", stiffness: 160, damping: 12 }}
          >
            <CheckCircleOutlineIcon
              sx={{ fontSize: 110, color: "#4caf50", mb: 2 }}
            />
          </motion.div>

          {/* Title */}
          <Typography
            variant="h4"
            sx={{ fontWeight: 800, mb: 1, color: "#222" }}
          >
            Booking Confirmed!
          </Typography>

          {/* Subtitle */}
          <Typography
            variant="body1"
            sx={{ color: "#555", mb: 4, maxWidth: 350, margin: "0 auto" }}
          >
            Your booking has been successfully confirmed. A confirmation email
            with all the details has been sent to your inbox.
          </Typography>

          {/* Buttons */}
          <Box
            sx={{
              display: "flex",
              flexDirection: { xs: "column", sm: "row" },
              gap: 2,
              mt: 1,
              justifyContent: "center",
            }}
          >
            {/* GET DIRECTIONS BUTTON */}
            <Button
              variant="contained"
              onClick={openDirections}
              startIcon={<NavigationIcon />}
              sx={{
                backgroundColor: "#4caf50",
                px: 4,
                py: 1.3,
                borderRadius: "12px",
                fontWeight: 600,
                textTransform: "none",
                "&:hover": {
                  backgroundColor: "#3e8b42",
                },
              }}
            >
              Get Directions
            </Button>

            {/* After completing a booking, take the user to their bookings
                (not the homepage). */}
            <Button
              variant="contained"
              startIcon={<HomeIcon />}
              sx={{
                backgroundColor: "#1B2447",
                px: 4,
                py: 1.3,
                borderRadius: "12px",
                fontWeight: 600,
                textTransform: "none",
                "&:hover": {
                  backgroundColor: "#2A356B",
                },
              }}
              onClick={() =>
                navigate("/user-dashboard", { state: { section: "bookings" } })
              }
            >
              View My Bookings
            </Button>
          </Box>
        </Box>
      </motion.div>
    </Box>
  );
};

export default BookingConfirmed;
