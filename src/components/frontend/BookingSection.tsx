import React, { useState, useEffect } from "react";
import {
  Box,
  Typography,
  Button,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  IconButton,
  useTheme,
  useMediaQuery,
} from "@mui/material";
import { Add, Remove } from "@mui/icons-material";
import { useNavigate } from "react-router-dom";

import dayjs from "dayjs";
import ThemedDatePicker from "./ThemedDatePicker";

type StayType = "Daily" | "Monthly";
const themeColor = "#1B2447";

interface BookingSectionProps {
  price?: number;
  propertyId?: number | string;
  propertyName?: string;
  propertyAddress?: string;
  propertyImage?: string;
  propertyImages?: string[];
}

const BookingSection: React.FC<BookingSectionProps> = ({
  price,
  propertyId,
  propertyName,
  propertyAddress,
  propertyImage,
  propertyImages,
}) => {
  const navigate = useNavigate();

  // Real nightly rate from the property (falls back if unavailable).
  const rate = price && price > 0 ? price : 1500;

  const [stayType, setStayType] = useState<StayType>("Daily");
  const [checkIn, setCheckIn] = useState(dayjs().format("YYYY-MM-DD"));
  const [checkOut, setCheckOut] = useState(dayjs().add(1, "day").format("YYYY-MM-DD"));
  const [adults, setAdults] = useState<number>(1);
  const [children, setChildren] = useState<number>(0);
  const [manualCheckout, setManualCheckout] = useState<boolean>(false);

  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  // Stay type only seeds the default checkout; the user can still pick any
  // date range and the price follows the actual nights (so a 7-day stay shows
  // the weekly total automatically — no separate "Weekly" tier needed).
  useEffect(() => {
    if (manualCheckout) return;
    const days = stayType === "Monthly" ? 30 : 1;
    setCheckOut(dayjs(checkIn).add(days, "day").format("YYYY-MM-DD"));
  }, [stayType, checkIn, manualCheckout]);

  const nights = Math.max(1, dayjs(checkOut).diff(dayjs(checkIn), "day"));
  const total = rate * nights;

  const handleAdultsChange = (delta: number) =>
    setAdults((prev) => Math.max(1, prev + delta));
  const handleChildrenChange = (delta: number) =>
    setChildren((prev) => Math.max(0, prev + delta));

  const handleBookNow = () => {
    navigate("/property-booking/final", {
      state: {
        propertyId,
        propertyName,
        propertyAddress,
        propertyImage,
        propertyImages,
        rate,
        stayType,
        checkIn,
        checkOut,
        nights,
        adults,
        children,
        price: total,
      },
    });
  };

  return (
    <Box
      sx={{
        p: "24px",
        backgroundColor: "#FFFAF0",
        borderRadius: "18px",
        border: "1px solid #D9CFB8",
        boxShadow: "0 12px 40px rgba(27,36,71,.12)",
        display: "flex",
        flexDirection: "column",
        gap: 2,
        width: "100%",
        maxWidth: "100%",
        boxSizing: "border-box",
        overflow: "hidden",
      }}
    >
      <Typography
        sx={{
          fontFamily: "'Fraunces', serif",
          fontWeight: 500,
          fontSize: "1.3rem",
          letterSpacing: "-0.01em",
          color: themeColor,
        }}
      >
        Book This Property
      </Typography>

      <Typography sx={{ color: "#444", mb: 1 }}>
        <strong>₹{total.toLocaleString("en-IN")}</strong> total
        <Typography component="span" sx={{ color: "#6B7390", fontSize: "0.85rem", ml: 0.5 }}>
          · {nights} night{nights > 1 ? "s" : ""}
        </Typography>
      </Typography>

      {/* Stay Type — Weekly removed; price auto-derives from the date range */}
      <FormControl fullWidth>
        <InputLabel>Stay Type</InputLabel>
        <Select
          value={stayType}
          label="Stay Type"
          onChange={(e) => {
            setStayType(e.target.value as StayType);
            setManualCheckout(false);
          }}
          sx={{
            "& .MuiOutlinedInput-notchedOutline": { borderColor: themeColor },
            "&.Mui-focused .MuiOutlinedInput-notchedOutline": { borderColor: themeColor },
          }}
        >
          <MenuItem value="Daily">Daily</MenuItem>
          <MenuItem value="Monthly">Monthly</MenuItem>
        </Select>
      </FormControl>

      {/* Dates */}
      <Box
        sx={{
          display: "flex",
          gap: 1,
          flexDirection: isMobile ? "column" : "row",
          width: "100%",
        }}
      >
        <ThemedDatePicker
          label="Check-in"
          value={checkIn}
          onChange={(v) => setCheckIn(v)}
          minDate={dayjs()}
        />
        <ThemedDatePicker
          label="Check-out"
          value={checkOut}
          onChange={(v) => {
            setCheckOut(v);
            setManualCheckout(true);
          }}
          minDate={checkIn ? dayjs(checkIn).add(1, "day") : dayjs().add(1, "day")}
        />
      </Box>

      {/* Guests with age preference */}
      <Box
        sx={{
          display: "flex",
          gap: 2,
          flexDirection: isMobile ? "column" : "row",
          width: "100%",
        }}
      >
        {/* Adults */}
        <Box
          sx={{
            display: "flex",
            alignItems: "center",
            border: `1px solid ${themeColor}`,
            borderRadius: "10px",
            px: 2,
            py: 0.5,
            gap: 1.5,
            flex: 1,
            minWidth: 0,
          }}
        >
          <Box sx={{ flexShrink: 0 }}>
            <Typography sx={{ fontWeight: 600, lineHeight: 1.1 }}>Adults</Typography>
            <Typography sx={{ fontSize: 11, color: "#6B7390" }}>Ages 13+</Typography>
          </Box>
          <Box sx={{ display: "flex", alignItems: "center", gap: 1.5, ml: "auto" }}>
            <IconButton
              size="small"
              onClick={() => handleAdultsChange(-1)}
              sx={{ bgcolor: themeColor, color: "#fff", "&:hover": { bgcolor: "#2A356B" } }}
            >
              <Remove fontSize="small" />
            </IconButton>
            <Typography sx={{ minWidth: 24, textAlign: "center" }}>{adults}</Typography>
            <IconButton
              size="small"
              onClick={() => handleAdultsChange(1)}
              sx={{ bgcolor: themeColor, color: "#fff", "&:hover": { bgcolor: "#2A356B" } }}
            >
              <Add fontSize="small" />
            </IconButton>
          </Box>
        </Box>

        {/* Children */}
        <Box
          sx={{
            display: "flex",
            alignItems: "center",
            border: `1px solid ${themeColor}`,
            borderRadius: "10px",
            px: 2,
            py: 0.5,
            gap: 1.5,
            flex: 1,
            minWidth: 0,
          }}
        >
          <Box sx={{ flexShrink: 0 }}>
            <Typography sx={{ fontWeight: 600, lineHeight: 1.1 }}>Children</Typography>
            <Typography sx={{ fontSize: 11, color: "#6B7390" }}>Ages 2–12</Typography>
          </Box>
          <Box sx={{ display: "flex", alignItems: "center", gap: 1.5, ml: "auto" }}>
            <IconButton
              size="small"
              onClick={() => handleChildrenChange(-1)}
              sx={{ bgcolor: themeColor, color: "#fff", "&:hover": { bgcolor: "#2A356B" } }}
            >
              <Remove fontSize="small" />
            </IconButton>
            <Typography sx={{ minWidth: 24, textAlign: "center" }}>{children}</Typography>
            <IconButton
              size="small"
              onClick={() => handleChildrenChange(1)}
              sx={{ bgcolor: themeColor, color: "#fff", "&:hover": { bgcolor: "#2A356B" } }}
            >
              <Add fontSize="small" />
            </IconButton>
          </Box>
        </Box>
      </Box>

      {/* Button */}
      <Button
        variant="contained"
        sx={{
          bgcolor: themeColor,
          color: "#fff",
          fontWeight: 600,
          padding: "14px",
          fontSize: 15,
          borderRadius: "10px",
          textTransform: "none",
          "&:hover": { bgcolor: "#2A356B" },
          width: "100%",
        }}
        onClick={handleBookNow}
      >
        Book Now
      </Button>
    </Box>
  );
};

export default BookingSection;
