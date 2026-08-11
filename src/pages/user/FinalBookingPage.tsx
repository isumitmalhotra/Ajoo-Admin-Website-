import React, { useState } from "react";
import "slick-carousel/slick/slick.css";
import "slick-carousel/slick/slick-theme.css";
import Slider from "react-slick";
import { RazorpayPayment } from "../../components";
import { useNavigate, useLocation } from "react-router-dom";

import {
  Box,
  Typography,
  Button,
  Divider,
  TextField,
  Chip,
} from "@mui/material";
import LocationOnIcon from "@mui/icons-material/LocationOn";
import CalendarMonthIcon from "@mui/icons-material/CalendarMonth";
import KingBedIcon from "@mui/icons-material/KingBed";
import GroupIcon from "@mui/icons-material/Group";
import LockIcon from "@mui/icons-material/Lock";
import VerifiedUserIcon from "@mui/icons-material/VerifiedUser";

const INDIGO = "#1B2447";
const TERRA = "#C16345";
const CREAM = "#FFFAF0";
const BORDER = "#D9CFB8";
const MUTED = "#6B7390";

const propertyData = {
  name: "Luxury Apartment in Chennai",
  address: "123 Ani Street, Chennai, India",
  basePrice: 1500,
  image: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200",
};

const fmtDate = (d?: string) =>
  d
    ? new Date(d).toLocaleDateString("en-IN", {
        day: "numeric",
        month: "short",
        year: "numeric",
      })
    : "—";

const FinalBookingPage: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();

  // Booking selection passed from the property page's BookingSection.
  const booking = (location.state || {}) as {
    propertyName?: string;
    propertyAddress?: string;
    propertyImage?: string;
    propertyImages?: string[];
    rate?: number;
    stayType?: string;
    checkIn?: string;
    checkOut?: string;
    nights?: number;
    adults?: number;
    children?: number;
    price?: number;
  };

  const propertyName = booking.propertyName || propertyData.name;
  const propertyAddress = booking.propertyAddress || propertyData.address;
  const propertyImage = booking.propertyImage || propertyData.image;
  const propertyImages =
    booking.propertyImages && booking.propertyImages.length > 0
      ? booking.propertyImages
      : [propertyImage];
  const nightlyRate =
    booking.rate && booking.rate > 0 ? booking.rate : propertyData.basePrice;
  const stayType = booking.stayType || "Daily";
  const adults = booking.adults ?? 1;
  const children = booking.children ?? 0;
  const nights = booking.nights ?? 1;
  const checkIn = booking.checkIn;
  const checkOut = booking.checkOut;

  const guestSummary =
    `${adults} adult${adults > 1 ? "s" : ""}` +
    (children > 0 ? `, ${children} child${children > 1 ? "ren" : ""}` : "");

  const [gstNumber, setGstNumber] = useState("");
  const subtotal =
    booking.price && booking.price > 0 ? booking.price : nightlyRate * nights;

  const GST_PERCENT = 18;
  const gstAmount = Math.round((subtotal * GST_PERCENT) / 100);
  const totalBill = subtotal + gstAmount;

  const applyGST = () => {
    /* GST application hooks into the backend billing API once available. */
  };

  const handlePaymentSuccess = (response: any) => {
    console.log("Payment Success:", response);
    navigate("/booking/confirmation");
  };
  const handlePaymentFailure = (error: any) => {
    console.error("Payment Failed:", error);
    alert("Payment failed. Please try again.");
  };
  const handlePayNow = () => {
    document.getElementById("hiddenRazorpayTrigger")?.click();
  };

  const tripItems = [
    { label: "Check-in", value: fmtDate(checkIn), icon: <CalendarMonthIcon /> },
    { label: "Check-out", value: fmtDate(checkOut), icon: <CalendarMonthIcon /> },
    { label: "Nights", value: `${nights} night${nights > 1 ? "s" : ""}`, icon: <KingBedIcon /> },
    { label: "Guests", value: guestSummary, icon: <GroupIcon /> },
  ];

  return (
    <Box
      sx={{
        bgcolor: "#EFE7D6",
        minHeight: "100vh",
        fontFamily: "'Inter', system-ui, sans-serif",
      }}
    >
      <Box
        sx={{
          maxWidth: 1180,
          mx: "auto",
          px: { xs: "16px", md: "48px" },
          py: { xs: "28px", md: "48px" },
        }}
      >
        {/* Heading */}
        <Typography
          component="h1"
          sx={{
            fontFamily: "'Fraunces', serif",
            fontWeight: 400,
            fontSize: { xs: 28, md: 38 },
            letterSpacing: "-0.025em",
            color: INDIGO,
            mb: "4px",
          }}
        >
          Complete your booking
        </Typography>
        <Typography sx={{ color: MUTED, fontSize: 14, mb: { xs: "24px", md: "36px" } }}>
          One last step — review your stay and confirm.
        </Typography>

        {/* Checkout grid */}
        <Box
          sx={{
            display: "grid",
            gridTemplateColumns: { xs: "1fr", md: "1.5fr 1fr" },
            gap: { xs: "24px", md: "40px" },
            alignItems: "flex-start",
          }}
        >
          {/* ── LEFT: the stay ── */}
          <Box
            sx={{
              bgcolor: CREAM,
              border: `1px solid ${BORDER}`,
              borderRadius: "20px",
              overflow: "hidden",
              boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 10px 30px rgba(27,36,71,.07)",
            }}
          >
            {/* Image slider */}
            <Box
              sx={{
                "& .slick-dots": { bottom: 12 },
                "& .slick-dots li button:before": { color: CREAM, opacity: 0.6, fontSize: 9 },
                "& .slick-dots li.slick-active button:before": { color: TERRA, opacity: 1 },
              }}
            >
              <Slider
                dots={propertyImages.length > 1}
                arrows={false}
                infinite={propertyImages.length > 1}
                speed={400}
                slidesToShow={1}
                slidesToScroll={1}
              >
                {propertyImages.map((img, i) => (
                  <Box
                    key={i}
                    component="img"
                    src={img}
                    alt={`${propertyName} ${i + 1}`}
                    sx={{ width: "100%", height: { xs: 230, md: 340 }, objectFit: "cover", display: "block" }}
                  />
                ))}
              </Slider>
            </Box>

            {/* Property summary + trip details */}
            <Box sx={{ p: { xs: "20px", md: "28px" } }}>
              <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 1 }}>
                <Chip
                  icon={<VerifiedUserIcon sx={{ fontSize: 16, color: "#3F6B4E !important" }} />}
                  label="Verified stay"
                  size="small"
                  sx={{ bgcolor: "rgba(63,107,78,.1)", color: "#3F6B4E", fontWeight: 600 }}
                />
                <Chip label={stayType} size="small" sx={{ bgcolor: "rgba(27,36,71,.06)", color: INDIGO, fontWeight: 600 }} />
              </Box>

              <Typography
                sx={{
                  fontFamily: "'Fraunces', serif",
                  fontWeight: 500,
                  fontSize: { xs: 22, md: 26 },
                  letterSpacing: "-0.02em",
                  color: INDIGO,
                  lineHeight: 1.2,
                }}
              >
                {propertyName}
              </Typography>
              <Typography sx={{ display: "flex", alignItems: "center", gap: 0.5, color: MUTED, mt: 0.5, fontSize: 14 }}>
                <LocationOnIcon sx={{ fontSize: 18, color: TERRA }} /> {propertyAddress}
              </Typography>

              <Divider sx={{ my: 2.5 }} />

              <Box
                sx={{
                  display: "grid",
                  gridTemplateColumns: { xs: "1fr 1fr", sm: "repeat(4, 1fr)" },
                  gap: "16px",
                }}
              >
                {tripItems.map((t) => (
                  <Box key={t.label} sx={{ display: "flex", gap: 1.25, alignItems: "center" }}>
                    <Box
                      sx={{
                        width: 40,
                        height: 40,
                        borderRadius: "12px",
                        bgcolor: "rgba(27,36,71,.06)",
                        display: "grid",
                        placeItems: "center",
                        color: INDIGO,
                        flexShrink: 0,
                        "& svg": { fontSize: 20 },
                      }}
                    >
                      {t.icon}
                    </Box>
                    <Box sx={{ minWidth: 0 }}>
                      <Typography sx={{ fontSize: 11, color: MUTED, textTransform: "uppercase", letterSpacing: "0.04em" }}>
                        {t.label}
                      </Typography>
                      <Typography sx={{ fontSize: 14, fontWeight: 600, color: INDIGO }}>
                        {t.value}
                      </Typography>
                    </Box>
                  </Box>
                ))}
              </Box>
            </Box>
          </Box>

          {/* ── RIGHT: price / payment ── */}
          <Box
            sx={{
              bgcolor: CREAM,
              borderRadius: "20px",
              border: `1px solid ${BORDER}`,
              boxShadow: "0 12px 40px rgba(27,36,71,.12)",
              p: { xs: "20px", md: "26px" },
              display: "flex",
              flexDirection: "column",
              gap: "18px",
              position: { md: "sticky" },
              top: { md: "90px" },
            }}
          >
            <Typography
              sx={{
                fontFamily: "'Fraunces', serif",
                fontWeight: 500,
                fontSize: 20,
                letterSpacing: "-0.015em",
                color: INDIGO,
              }}
            >
              Price details
            </Typography>

            <Divider />

            <Box sx={{ display: "flex", flexDirection: "column", gap: "12px" }}>
              <Box sx={{ display: "flex", justifyContent: "space-between" }}>
                <Typography sx={{ color: "#3D4670" }}>
                  ₹{nightlyRate.toLocaleString("en-IN")} × {nights} night{nights > 1 ? "s" : ""}
                </Typography>
                <Typography sx={{ fontWeight: 600, color: INDIGO }}>
                  ₹{subtotal.toLocaleString("en-IN")}
                </Typography>
              </Box>

              <Box sx={{ display: "flex", justifyContent: "space-between" }}>
                <Typography sx={{ color: "#3D4670" }}>GST ({GST_PERCENT}%)</Typography>
                <Typography sx={{ fontWeight: 600, color: INDIGO }}>
                  ₹{gstAmount.toLocaleString("en-IN")}
                </Typography>
              </Box>

              {/* GST number */}
              <Box sx={{ display: "flex", flexDirection: { xs: "column", sm: "row" }, gap: 1, mt: 0.5 }}>
                <TextField
                  label="GST number (optional)"
                  variant="outlined"
                  size="small"
                  value={gstNumber}
                  onChange={(e) => setGstNumber(e.target.value)}
                  sx={{ flex: 1 }}
                />
                <Button
                  variant="outlined"
                  onClick={applyGST}
                  sx={{
                    borderColor: BORDER,
                    color: INDIGO,
                    borderRadius: "10px",
                    fontWeight: 600,
                    textTransform: "none",
                    "&:hover": { borderColor: INDIGO, bgcolor: "rgba(27,36,71,.04)" },
                    width: { xs: "100%", sm: "auto" },
                  }}
                >
                  Apply
                </Button>
              </Box>
            </Box>

            <Divider />

            <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
              <Typography sx={{ fontWeight: 700, fontSize: 18, color: INDIGO }}>Total</Typography>
              <Typography sx={{ fontFamily: "'Fraunces', serif", fontWeight: 600, fontSize: 24, color: TERRA }}>
                ₹{totalBill.toLocaleString("en-IN")}
              </Typography>
            </Box>

            {/* CTAs */}
            <Button
              variant="contained"
              onClick={handlePayNow}
              sx={{
                bgcolor: INDIGO,
                "&:hover": { bgcolor: "#2A356B" },
                borderRadius: "12px",
                padding: "15px",
                fontWeight: 700,
                fontSize: 15,
                textTransform: "none",
              }}
            >
              Pay ₹{totalBill.toLocaleString("en-IN")} now
            </Button>
            <Button
              variant="outlined"
              onClick={() => navigate("/booking/confirmation")}
              sx={{
                borderColor: BORDER,
                color: INDIGO,
                "&:hover": { bgcolor: "rgba(27,36,71,.05)", borderColor: INDIGO },
                borderRadius: "12px",
                padding: "14px",
                fontWeight: 600,
                fontSize: 15,
                textTransform: "none",
              }}
            >
              Reserve & pay later
            </Button>

            <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 0.75, mt: 0.5 }}>
              <LockIcon sx={{ fontSize: 15, color: MUTED }} />
              <Typography sx={{ fontSize: 12, color: MUTED }}>
                Secure payments · Razorpay · UPI, cards & wallets
              </Typography>
            </Box>

            <RazorpayPayment
              amount={totalBill}
              onSuccess={handlePaymentSuccess}
              onFailure={handlePaymentFailure}
            />
          </Box>
        </Box>
      </Box>
    </Box>
  );
};

export default FinalBookingPage;
