import React from "react";
import { Box } from "@mui/material";
import { useMap } from "react-leaflet";

import MyLocationIcon from "@mui/icons-material/MyLocation";

const RecenterButton: React.FC<{ location: { lat: number; lng: number } }> = ({
  location,
}) => {
  const map = useMap();
  const handleRecenter = () => {
    map.setView(location, 14, { animate: true });
  };

  return (
    <Box
      sx={{
        position: "absolute",
        bottom: 20,
        right: 20,
        zIndex: 1000,
        width: 45,
        height: 45,
        borderRadius: "50%",
        backgroundColor: "#ffffff",
        boxShadow: "0 2px 6px rgba(0,0,0,0.3)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        cursor: "pointer",
        transition: "all 0.2s ease",
        "&:hover": {
          backgroundColor: "#1B2447",
          "& svg": { color: "#fff" },
        },
      }}
      onClick={handleRecenter}
    >
      <MyLocationIcon sx={{ color: "#1B2447", fontSize: 26 }} />
    </Box>
  );
};

export default RecenterButton;
