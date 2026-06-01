import React, { useState, useEffect } from "react";
import { RazorpayPayment } from "../../components";
import { useNavigate } from "react-router-dom";

import {
  Box,
  Typography,
  Button,
  Divider,
  TextField,
  useTheme,
  useMediaQuery,
} from "@mui/material";
import { PropertyBookingBox } from "../../components";
import {
  // AttachMoney as AttachMoneyIcon,
  LocationOn,
} from "@mui/icons-material";
import securePay from "../../assets/UI/securePay.jpg";

const themeColor = "#1B2447";

const propertyData = {
  name: "Luxury Apartment in Chennai",
  address: "123 Ani Street, Chennai, India",
  categories: ["Apartment", "Luxury", "Family"],
  amenities: ["Pool", "Parking", "WiFi"],
  basePrice: 1500,
  image: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200",
};

const FinalBookingPage: React.FC = () => {
  const [stayType, _setStayType] = useState<"Daily" | "Weekly" | "Monthly">(
    "Daily"
  );
  const navigate = useNavigate();

  const [guests, _setGuests] = useState(1);
  const [gstNumber, setGstNumber] = useState("");
  const [price, setPrice] = useState<number>(propertyData.basePrice);

  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  useEffect(() => {
    let total = propertyData.basePrice;
    switch (stayType) {
      case "Daily":
        total = propertyData.basePrice * guests;
        break;
      case "Weekly":
        total = propertyData.basePrice * 7 * guests;
        break;
      case "Monthly":
        total = propertyData.basePrice * 30 * guests;
        break;
    }
    setPrice(total);
  }, [stayType, guests]);
  const applyGST = async () => {
    // try {
    //   // Example API call, replace with your backend endpoint
    //   const response = await fetch("/api/calculate-bill", {
    //     method: "POST",
    //     headers: { "Content-Type": "application/json" },
    //     body: JSON.stringify({
    //       price,
    //       gstNumber,
    //       stayType,
    //       guests,
    //     }),
    //   });
    //   const data = await response.json();
    //   if (data.success) {
    //     setPrice(data.newPrice);
    //     // gstAmount and totalBill will automatically recalc in useEffect or you can update here:
    //     // setGstAmount(data.newGST);
    //     // setTotalBill(data.newTotal);
    //   } else {
    //     alert("Failed to apply GST. Please try again.");
    //   }
    // } catch (error) {
    //   console.error(error);
    //   alert("Error applying GST.");
    // }
  };

  const GST_PERCENT = 18;
  const gstAmount = (price * GST_PERCENT) / 100;
  const totalBill = price + gstAmount;

  const handlePaymentSuccess = (response: any) => {
    console.log("Payment Success:", response);
    alert("Payment successful! 🎉");
  };

  const handlePaymentFailure = (error: any) => {
    console.error("Payment Failed:", error);
    alert("Payment failed. Please try again.");
  };

  const handlePayLater = () => {
    const trigger = document.getElementById("hiddenRazorpayTrigger");
    trigger?.click();
  };

  return (
    <Box
      sx={{
        maxWidth: 1320,
        mx: "auto",
        px: { xs: "20px", md: "48px" },
        py: { xs: "32px", md: "48px" },
        bgcolor: "#EFE7D6",
        minHeight: "100vh",
        fontFamily: "'Inter', system-ui, sans-serif",
      }}
    >
      {/* Page heading — POC: h1 36 Fraunces */}
      <Typography
        component="h1"
        sx={{
          fontFamily: "'Fraunces', serif",
          fontWeight: 400,
          fontSize: { xs: 26, md: 36 },
          letterSpacing: "-0.025em",
          color: "#1B2447",
          mb: "32px",
        }}
      >
        Complete your booking
      </Typography>

      {/* Checkout grid — POC: 1.4fr 1fr, gap 48 */}
      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: { xs: "1fr", md: "1.4fr 1fr" },
          gap: { xs: "32px", md: "48px" },
          alignItems: "flex-start",
        }}
      >
        {/* Left Side: Property + Booking */}
        <Box>
          <Typography
            sx={{
              fontFamily: "'Fraunces', serif",
              fontWeight: 400,
              fontSize: { xs: 20, md: 24 },
              letterSpacing: "-0.02em",
              color: "#1B2447",
              mb: "4px",
            }}
          >
            {propertyData.name}
          </Typography>
          <Typography
            sx={{ display: "flex", alignItems: "center", gap: 0.5, mb: 2 }}
          >
            <LocationOn sx={{ color: themeColor }} /> {propertyData.address}
          </Typography>

          <Box
            component="img"
            src={propertyData.image}
            alt={propertyData.name}
            sx={{
              width: "100%",
              borderRadius: "14px",
              mb: "24px",
              boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)",
              objectFit: "cover",
              maxHeight: 320,
            }}
          />

          {/* Trip cell — POC: padding 14, radius 10 */}
          <Box
            sx={{
              bgcolor: "#FFFAF0",
              border: "1px solid #D9CFB8",
              borderRadius: "10px",
              padding: "14px 16px",
              mb: "24px",
            }}
          >
            <Typography sx={{ fontSize: 11, fontWeight: 600, color: "#6B7390", letterSpacing: "0.04em", textTransform: "uppercase", mb: "8px" }}>
              Trip details
            </Typography>
            <Box sx={{ display: "flex", gap: "24px", flexWrap: "wrap" }}>
              {[
                { label: "Check-in", value: "Oct 20, 2025" },
                { label: "Check-out", value: "Oct 23, 2025" },
                { label: "Guests", value: "2 adults" },
              ].map((item) => (
                <Box key={item.label}>
                  <Typography sx={{ fontSize: 11, color: "#6B7390", letterSpacing: "0.04em", textTransform: "uppercase", mb: "2px" }}>
                    {item.label}
                  </Typography>
                  <Typography sx={{ fontSize: 14, fontWeight: 600, color: "#1B2447" }}>
                    {item.value}
                  </Typography>
                </Box>
              ))}
            </Box>
          </Box>

          <PropertyBookingBox />
        </Box>

        {/* Right Side: Summary card — POC: radius 18, padding 24 */}
        <Box
          sx={{
            bgcolor: "#FFFAF0",
            borderRadius: "18px",
            border: "1px solid #D9CFB8",
            boxShadow: "0 12px 40px rgba(27,36,71,.12)",
            p: "24px",
            display: "flex",
            flexDirection: "column",
            gap: "20px",
            position: { md: "sticky" },
            top: { md: "80px" },
          }}
        >
          {/* Header */}
          <Typography
            sx={{
              fontFamily: "'Fraunces', serif",
              fontWeight: 500,
              fontSize: { xs: 18, sm: 20 },
              letterSpacing: "-0.015em",
              color: "#1B2447",
            }}
          >
            Billing Summary
          </Typography>

          <Divider />

          {/* Price Breakdown — POC: gap 10, fs 14 */}
          <Box sx={{ display: "flex", flexDirection: "column", gap: "10px" }}>
            <Box sx={{ display: "flex", justifyContent: "space-between" }}>
              <Typography sx={{ fontWeight: 500 }}>
                Price ({stayType})
              </Typography>
              <Typography sx={{ fontWeight: 500 }}>
                ₹ {price.toLocaleString()}
              </Typography>
            </Box>

            <Box sx={{ display: "flex", justifyContent: "space-between" }}>
              <Typography sx={{ fontWeight: 500 }}>
                GST ({GST_PERCENT}%)
              </Typography>
              <Typography sx={{ fontWeight: 500 }}>
                ₹ {gstAmount.toLocaleString()}
              </Typography>
            </Box>

            {/* GST Input & Apply Button */}
            <Box
              sx={{
                display: "flex",
                flexDirection: { xs: "column", sm: "row" },
                gap: 1,
                alignItems: "center",
                mt: 1,
              }}
            >
              <TextField
                label="GST Number (optional)"
                variant="outlined"
                size="small"
                value={gstNumber}
                onChange={(e) => setGstNumber(e.target.value)}
                sx={{ flex: 1 }}
              />
              <Button
                variant="contained"
                sx={{
                  bgcolor: themeColor,
                  "&:hover": { bgcolor: "#2A356B" },
                  borderRadius: 2,
                  py: 1,
                  fontWeight: 600,
                  width: { xs: "100%", sm: "auto" },
                }}
                onClick={applyGST}
              >
                Apply GST
              </Button>
            </Box>
          </Box>

          <Divider sx={{ my: 2 }} />

          {/* Total */}
          <Box
            sx={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              fontWeight: 700,
              fontSize: { xs: 18, sm: 20 },
            }}
          >
            <Typography>Total</Typography>
            <Typography>₹ {totalBill.toLocaleString()}</Typography>
          </Box>

          {/* Payment Buttons */}
          <Box
            sx={{
              display: "flex",
              flexDirection: "column",
              gap: 1.5,
              mt: 2,
            }}
          >
            <Button
              variant="contained"
              sx={{
                bgcolor: themeColor,
                "&:hover": { bgcolor: "#2A356B" },
                borderRadius: "12px",
                padding: "16px",
                fontWeight: 600,
                fontSize: 15,
                textTransform: "none",
              }}
              onClick={handlePayLater}
            >
              Pay Now
            </Button>

            <Button
              variant="outlined"
              sx={{
                borderColor: "#D9CFB8",
                color: themeColor,
                "&:hover": { bgcolor: "rgba(27,36,71,.05)", borderColor: "#1B2447" },
                borderRadius: "12px",
                padding: "16px",
                fontWeight: 600,
                fontSize: 15,
                textTransform: "none",
              }}
              onClick={() => navigate("/booking/confirmation")}
            >
              Pay Later
            </Button>

            <RazorpayPayment
              amount={totalBill}
              onSuccess={handlePaymentSuccess}
              onFailure={handlePaymentFailure}
            />
          </Box>
        </Box>
      </Box>

      {/* Secure Payment Section */}
      <Box
        sx={{
          display: "flex",
          flexDirection: isMobile ? "column" : "row",
          alignItems: "center",
          gap: 3,
          mt: 6,
          backgroundColor: "#FFFAF0",
          borderRadius: "14px",
          boxShadow: "0 6px 18px rgba(0,0,0,0.08)",
          p: 3,
        }}
      >
        <Box
          component="img"
          src={securePay}
          alt="Secure Payments Illustration"
          sx={{
            width: isMobile ? "100%" : "45%",
            borderRadius: 2,
          }}
        />

        <Box sx={{ flex: 1 }}>
          <Typography
            variant="h5"
            sx={{ color: themeColor, fontWeight: 700, mb: 1 }}
          >
            Secure Online Payments with Razorpay
          </Typography>
          <Typography sx={{ fontSize: "1rem", color: "#6B7390", mb: 1.5 }}>
            Enjoy seamless and secure transactions powered by Razorpay. Your
            payments are protected with advanced encryption and trusted payment
            gateways, ensuring a smooth and worry-free checkout experience.
          </Typography>
          <Typography sx={{ fontSize: "1rem", color: "#6B7390" }}>
            We accept all major credit/debit cards, UPI, and wallets to make
            your booking experience fast, easy, and secure.
          </Typography>
        </Box>
      </Box>
    </Box>
  );
};

export default FinalBookingPage;
