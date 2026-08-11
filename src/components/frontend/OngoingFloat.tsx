import React, { useEffect, useState } from "react";
import { Box, Typography } from "@mui/material";
import { motion } from "framer-motion";
import RocketLaunchIcon from "@mui/icons-material/RocketLaunch";
import { useNavigate } from "react-router-dom";
import storage from "../../styles/utils/storage";
import { getOngoingBookings } from "../../services/customerApi";

const MotionBox = motion.create(Box);

const OngoingFloat: React.FC = () => {
  const navigate = useNavigate();
  // Only surface this for a logged-in user who actually has an ongoing trip.
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (!storage.getToken()) return;
    let cancelled = false;
    (async () => {
      try {
        const rows = await getOngoingBookings();
        if (!cancelled) setVisible(rows.length > 0);
      } catch {
        if (!cancelled) setVisible(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  if (!visible) return null;

  const handleClick = () => {
    navigate("/user-dashboard", { state: { section: "ongoing" } });
  };

  return (
    <MotionBox
      initial={{ opacity: 0, y: 50 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
      sx={{
        position: "fixed",
        bottom: { xs: 16, sm: 24 },
        right: { xs: 16, sm: 24 },
        zIndex: 1300,
      }}
    >
      <MotionBox
        whileHover={{ scale: 1.05, y: -4 }}
        whileTap={{ scale: 0.95 }}
        sx={{
          bgcolor: "#1B2447",
          color: "#fff",
          borderRadius: "16px",
          boxShadow: "0px 4px 20px rgba(0,0,0,0.2)",
          display: "flex",
          alignItems: "center",
          gap: 1,
          cursor: "pointer",
          px: 2,
          py: 1.2,
          minWidth: 160,
          justifyContent: "center",
        }}
        onClick={handleClick}
      >
        <RocketLaunchIcon sx={{ fontSize: 22 }} />
        <Typography
          variant="body2"
          sx={{ fontWeight: 600, textTransform: "capitalize" }}
        >
          Ongoing Trips
        </Typography>
      </MotionBox>
    </MotionBox>
  );
};

export default OngoingFloat;
