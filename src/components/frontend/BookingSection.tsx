import React, { useState, useEffect } from "react";
import {
  Box,
  Typography,
  TextField,
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

type StayType = "Daily" | "Weekly" | "Monthly";
const themeColor = "#1B2447";

const BookingSection: React.FC = () => {
  const navigate = useNavigate();


  const [stayType, setStayType] = useState<StayType>("Daily");
  const [checkIn, setCheckIn] = useState(dayjs().format("YYYY-MM-DD"));
  const [checkOut, setCheckOut] = useState(
    dayjs().add(1, "day").format("YYYY-MM-DD")
  );
  const [price, setPrice] = useState<number>(1500);
  const [adults, setAdults] = useState<number>(1);
  const [children, setChildren] = useState<number>(0);
  const [manualCheckout, setManualCheckout] = useState<boolean>(false);

  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  useEffect(() => {
    let newCheckOut = dayjs(checkIn);
    let newPrice = 1500;

    switch (stayType) {
      case "Daily":
        newCheckOut = dayjs(checkIn).add(1, "day");
        newPrice = 1500 * (adults + children * 0.5);
        break;
      case "Weekly":
        newCheckOut = dayjs(checkIn).add(7, "day");
        newPrice = 1500 * 7 * (adults + children * 0.5);
        break;
      case "Monthly":
        newCheckOut = dayjs(checkIn).add(30, "day");
        newPrice = 1500 * 30 * (adults + children * 0.5);
        break;
    }

    if (!manualCheckout) setCheckOut(newCheckOut.format("YYYY-MM-DD"));
    setPrice(newPrice);
  }, [stayType, checkIn, adults, children, manualCheckout]);

  const handleAdultsChange = (delta: number) =>
    setAdults((prev) => Math.max(1, prev + delta));
  const handleChildrenChange = (delta: number) =>
    setChildren((prev) => Math.max(0, prev + delta));

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
        maxWidth: "100%", // prevents overflow
        boxSizing: "border-box", // ensures padding stays inside
        overflow: "hidden", // hides any minor pixel overflow
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
        <strong>₹{price.toLocaleString()}</strong> total
      </Typography>

      {/* Stay Type */}
      <FormControl fullWidth>
        <InputLabel>Stay Type</InputLabel>
        <Select
          value={stayType}
          label="Stay Type"
          onChange={(e) => setStayType(e.target.value as StayType)}
          sx={{
            "& .MuiOutlinedInput-notchedOutline": { borderColor: themeColor },
            "&.Mui-focused .MuiOutlinedInput-notchedOutline": {
              borderColor: themeColor,
            },
          }}
        >
          <MenuItem value="Daily">Daily</MenuItem>
          <MenuItem value="Weekly">Weekly</MenuItem>
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
        <TextField
          type="date"
          label="Check-in"
          value={checkIn}
          onChange={(e) => setCheckIn(e.target.value)}
          InputLabelProps={{ shrink: true }}
          fullWidth
        />
        <TextField
          type="date"
          label="Check-out"
          value={checkOut}
          onChange={(e) => {
            setCheckOut(e.target.value);
            setManualCheckout(true);
          }}
          InputLabelProps={{ shrink: true }}
          fullWidth
        />
      </Box>

      {/* Guests */}
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
          <Typography sx={{ fontWeight: 600, flexShrink: 0 }}>
            Adults:
          </Typography>
          <IconButton
            size="small"
            onClick={() => handleAdultsChange(-1)}
            sx={{
              bgcolor: themeColor,
              color: "#fff",
              "&:hover": { bgcolor: "#2A356B" },
            }}
          >
            <Remove fontSize="small" />
          </IconButton>
          <Typography sx={{ minWidth: 24, textAlign: "center" }}>
            {adults}
          </Typography>
          <IconButton
            size="small"
            onClick={() => handleAdultsChange(1)}
            sx={{
              bgcolor: themeColor,
              color: "#fff",
              "&:hover": { bgcolor: "#2A356B" },
            }}
          >
            <Add fontSize="small" />
          </IconButton>
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
          <Typography sx={{ fontWeight: 600, flexShrink: 0 }}>
            Children:
          </Typography>
          <IconButton
            size="small"
            onClick={() => handleChildrenChange(-1)}
            sx={{
              bgcolor: themeColor,
              color: "#fff",
              "&:hover": { bgcolor: "#2A356B" },
            }}
          >
            <Remove fontSize="small" />
          </IconButton>
          <Typography sx={{ minWidth: 24, textAlign: "center" }}>
            {children}
          </Typography>
          <IconButton
            size="small"
            onClick={() => handleChildrenChange(1)}
            sx={{
              bgcolor: themeColor,
              color: "#fff",
              "&:hover": { bgcolor: "#2A356B" },
            }}
          >
            <Add fontSize="small" />
          </IconButton>
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
        onClick={() => navigate("/property-booking/final")}
      >
        Book Now
      </Button>
    </Box>
  );
};

export default BookingSection;
