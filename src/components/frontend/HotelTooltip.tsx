// HotelTooltip.tsx
import React from "react";
import {
  Card,
  CardMedia,
  CardContent,
  Typography,
  Box,
  Chip,
  Rating,
  Button,
} from "@mui/material";
import { useNavigate } from "react-router-dom";

interface HotelTooltipProps {
  id: number;
  name: string;
  price: number;
  image: string;
  rating?: number;
  tag?: string;
  location?: string;
  description?: string;
}

const HotelTooltip: React.FC<HotelTooltipProps> = ({
  id,
  name,
  price,
  image,
  rating = 4.5,
  tag = "Featured",
  location = "Unknown",
  description = "A comfortable stay with great amenities.",
}) => {
  const navigate = useNavigate();

  const handleClick = () => {
    navigate(`/property/detail/${id}`);
  };

  return (
    <Card
      sx={{
        width: 180, // 🔥 Smaller tooltip
        borderRadius: "12px",
        boxShadow: "0 3px 10px rgba(0,0,0,0.15)",
        overflow: "hidden",
        cursor: "pointer",
        p: 0,
      }}
    >
      {/* IMAGE + TAG */}
      <Box sx={{ position: "relative" }}>
        <CardMedia
          component="img"
          height="85"
          image={image}
          alt={name}
          sx={{ objectFit: "cover" }}
        />

        {/* TAG TOP RIGHT */}
        <Chip
          label={tag}
          size="small"
          sx={{
            position: "absolute",
            top: 6,
            right: 6,
            bgcolor: "#1B2447",
            color: "#fff",
            fontWeight: 600,
            fontSize: "0.6rem",
            height: "20px",
          }}
        />
      </Box>

      <CardContent sx={{ p: 1.2 }}>
        {/* NAME */}
        <Typography
          variant="subtitle2"
          sx={{ fontWeight: 700, color: "#1B2447", mb: 0.3, fontSize: "0.8rem" }}
        >
          {name}
        </Typography>

        {/* RATING */}
        <Box sx={{ display: "flex", alignItems: "center", mb: 0.3 }}>
          <Rating value={rating} precision={0.1} readOnly size="small" />
          <Typography variant="caption" sx={{ ml: 0.3, fontWeight: 600 }}>
            {rating}
          </Typography>
        </Box>

        {/* LOCATION */}
        <Typography
          variant="caption"
          sx={{ color: "#666", mb: 0.3, display: "block", fontSize: "0.7rem" }}
        >
          📍 {location}
        </Typography>

        {/* SHORT DESCRIPTION */}
        <Typography
          variant="caption"
          sx={{
            lineHeight: 1.1,
            mb: 0.4,
            display: "-webkit-box",
            WebkitLineClamp: 2,
            WebkitBoxOrient: "vertical",
            overflow: "hidden",
            fontSize: "0.7rem",
          }}
        >
          {description}
        </Typography>

        {/* PRICE */}
        <Typography
          variant="subtitle2"
          sx={{
            fontWeight: 700,
            color: "#1B2447",
            mb: 0.6,
            fontSize: "0.8rem",
          }}
        >
          ₹{price.toLocaleString()} / night
        </Typography>

        {/* VIEW DETAILS BUTTON */}
        <Button
          variant="contained"
          onClick={handleClick}
          sx={{
            width: "100%",
            background: "#1B2447",
            fontSize: "0.7rem",
            padding: "3px 0",
            textTransform: "none",
            borderRadius: "6px",
            "&:hover": {
              background: "#a83757",
            },
          }}
        >
          View Details
        </Button>
      </CardContent>
    </Card>
  );
};

export default HotelTooltip;
