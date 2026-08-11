import React from "react";
import { Box, Typography, Chip, Rating, useTheme, useMediaQuery } from "@mui/material";
import { LocationOn } from "@mui/icons-material";

const themeColor = "#1B2447";

interface PropertyBookingBoxProps {
  price?: number;
  title?: string;
  location?: string;
  categories?: string[];
  rating?: number;
}

/**
 * Compact summary shown right below the property images: real title, location,
 * category tags, rating and price. (Amenities live once in <AmenitiesGrid/> —
 * "What this place offers" — so they're intentionally NOT repeated here.)
 */
const PropertyBookingBox: React.FC<PropertyBookingBoxProps> = ({
  price: priceProp,
  title,
  location,
  categories = [],
  rating = 0,
}) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));
  const price = priceProp && priceProp > 0 ? priceProp : 0;

  return (
    <Box
      sx={{
        backgroundColor: "#FFFAF0",
        borderRadius: "18px",
        border: "1px solid #D9CFB8",
        padding: isMobile ? "1.3rem" : "1.75rem",
        width: "100%",
        margin: "1rem auto 0",
        boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)",
        display: "flex",
        flexDirection: "column",
        gap: 1.2,
      }}
    >
      {title && (
        <Typography
          sx={{
            color: "#222",
            fontWeight: 700,
            fontSize: isMobile ? "1.25rem" : "1.5rem",
            lineHeight: 1.25,
          }}
        >
          {title}
        </Typography>
      )}

      {/* Rating (real). Falls back to a "New" tag when there are no reviews. */}
      <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
        {rating > 0 ? (
          <>
            <Rating value={rating} precision={0.5} readOnly size="small" sx={{ color: "#C16345" }} />
            <Typography sx={{ fontSize: "0.9rem", fontWeight: 700, color: themeColor }}>
              {rating.toFixed(1)}
            </Typography>
          </>
        ) : (
          <Chip label="New listing" size="small" sx={{ bgcolor: "rgba(63,107,78,.1)", color: "#3F6B4E", fontWeight: 600 }} />
        )}
      </Box>

      {location && (
        <Typography
          sx={{
            display: "flex",
            alignItems: "center",
            gap: 0.5,
            color: "#555",
            fontSize: isMobile ? "0.9rem" : "1rem",
          }}
        >
          <LocationOn sx={{ color: themeColor, fontSize: 20 }} /> {location}
        </Typography>
      )}

      {categories.length > 0 && (
        <Box sx={{ display: "flex", flexWrap: "wrap", gap: 1, mt: 0.5 }}>
          {categories.map((label) => (
            <Chip
              key={label}
              label={label}
              sx={{
                color: "#fff",
                bgcolor: themeColor,
                fontSize: isMobile ? "0.75rem" : "0.85rem",
                textTransform: "capitalize",
              }}
            />
          ))}
        </Box>
      )}

      {price > 0 && (
        <Typography
          sx={{
            color: themeColor,
            fontWeight: 700,
            fontSize: isMobile ? "1.5rem" : "1.9rem",
            mt: 0.5,
          }}
        >
          ₹{price.toLocaleString("en-IN")}
          <Typography component="span" sx={{ fontSize: "0.9rem", color: "#6B7390", fontWeight: 500, ml: 0.5 }}>
            / night
          </Typography>
        </Typography>
      )}
    </Box>
  );
};

export default PropertyBookingBox;
