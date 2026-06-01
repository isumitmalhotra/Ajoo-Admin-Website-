// src/components/PlaceCard.tsx
import React from "react";
import { Box, Typography } from "@mui/material";

interface Place {
  name: string;
  img: string;
  distance: string;
  description: string;
}

const PlaceCard: React.FC<{ place: Place }> = ({ place }) => {
  return (
    <Box
      sx={{
        borderRadius: 2,
        overflow: "hidden",
        backgroundColor: "#fafafa",
        boxShadow: "0px 4px 10px rgba(0,0,0,0.08)",
        transition: "transform 0.3s ease",
        "&:hover": { transform: "translateY(-4px)" },
      }}
    >
      <Box
        component="img"
        src={place.img}
        alt={place.name}
        sx={{
          width: "100%",
          height: { xs: 150, sm: 160, md: 180 },
          objectFit: "cover",
        }}
      />
      <Box sx={{ p: 2 }}>
        <Typography
          sx={{ fontWeight: 700, fontSize: 16, color: "#1B2447", mb: 0.5 }}
        >
          {place.name}
        </Typography>
        <Typography sx={{ fontSize: 13, color: "#777", mb: 0.5 }}>
          {place.distance} away
        </Typography>
        <Typography sx={{ fontSize: 14, color: "#555" }}>
          {place.description}
        </Typography>
      </Box>
    </Box>
  );
};

export default PlaceCard;
