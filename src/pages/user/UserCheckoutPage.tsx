import React, { useState } from "react";
import {
  Box,
  Typography,
  Card,
  CardContent,
  Divider,
  Rating,
  TextField,
  Button,
  Snackbar,
  Alert,
  useTheme,
  useMediaQuery,
} from "@mui/material";
import { useNavigate } from "react-router-dom";

const UserCheckoutPage: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));
  const navigate = useNavigate();

  const [snackbarOpen, setSnackbarOpen] = useState(false);
  const [snackbarMessage, setSnackbarMessage] = useState("");
  const [ratingData, setRatingData] = useState({
    propertyStars: 0,
    hostStars: 0,
    platformStars: 0,
    propertyReview: "",
    hostReview: "",
    platformReview: "",
  });

  const propertyInfo = {
    name: "Sea View Villa",
    location: "Goa, India",
    price: 12500,
    checkIn: "2025-10-20",
    checkOut: "2025-10-23",
  };

  const ownerInfo = {
    name: "Rohit Sharma",
    contact: "+91 98765 43210",
    email: "rohit.villaowner@example.com",
  };

  const handleSubmit = () => {
    setSnackbarMessage("Checkout successful! Redirecting to your bookings...");
    setSnackbarOpen(true);

    // Simulate redirect after 3 seconds
    setTimeout(() => {
      navigate("/user-dashboard", { state: { section: "ongoing" } });
    }, 3000);
  };

  const handleCancel = () => {
    navigate("/user-dashboard", { state: { section: "ongoing" } });
  };

  return (
    <Box
      sx={{
        p: { xs: 2, sm: 4 },
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        minHeight: "100vh",
        backgroundColor: "#f9f9f9",
      }}
    >
      <Typography
        variant="h5"
        sx={{
          fontWeight: 700,
          color: "#1B2447",
          mb: 3,
          fontFamily: "'Poppins', sans-serif",
          textAlign: "center",
        }}
      >
        Checkout
      </Typography>

      <Card
        sx={{
          width: "100%",
          maxWidth: 900,
          borderRadius: 3,
          boxShadow: "0 6px 18px rgba(0,0,0,0.1)",
          p: { xs: 2, sm: 3 },
        }}
      >
        <CardContent>
          {/* Property Info */}
          <Typography
            variant="h6"
            sx={{
              color: "#1A237E",
              fontWeight: 700,
              mb: 1,
              fontFamily: "'Poppins', sans-serif",
            }}
          >
            Property Information
          </Typography>
          <Divider sx={{ mb: 2 }} />
          <Typography variant="body1">
            <strong>Name:</strong> {propertyInfo.name}
          </Typography>
          <Typography variant="body1">
            <strong>Location:</strong> {propertyInfo.location}
          </Typography>
          <Typography variant="body1">
            <strong>Check-In:</strong> {propertyInfo.checkIn}
          </Typography>
          <Typography variant="body1">
            <strong>Check-Out:</strong> {propertyInfo.checkOut}
          </Typography>
          <Typography variant="body1" sx={{ mb: 2 }}>
            <strong>Total Price:</strong> ₹ {propertyInfo.price.toLocaleString()}
          </Typography>

          {/* Owner Info */}
          <Typography
            variant="h6"
            sx={{
              color: "#1A237E",
              fontWeight: 700,
              mt: 3,
              mb: 1,
              fontFamily: "'Poppins', sans-serif",
            }}
          >
            Host Information
          </Typography>
          <Divider sx={{ mb: 2 }} />
          <Typography variant="body1">
            <strong>Name:</strong> {ownerInfo.name}
          </Typography>
          <Typography variant="body1">
            <strong>Contact:</strong> {ownerInfo.contact}
          </Typography>
          <Typography variant="body1" sx={{ mb: 2 }}>
            <strong>Email:</strong> {ownerInfo.email}
          </Typography>

          {/* Reviews Section */}
          <Typography
            variant="h6"
            sx={{
              color: "#1A237E",
              fontWeight: 700,
              mt: 3,
              mb: 2,
              fontFamily: "'Poppins', sans-serif",
            }}
          >
            Submit Your Reviews
          </Typography>

          {/* Property Review */}
          <Box sx={{ mb: 3 }}>
            <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
              Property Review
            </Typography>
            <Rating
              value={ratingData.propertyStars}
              onChange={(_e, newValue) =>
                setRatingData((prev) => ({ ...prev, propertyStars: newValue ?? prev.propertyStars }))
              }
            />
            <TextField
              fullWidth
              multiline
              minRows={2}
              variant="outlined"
              placeholder="Share your experience about the property..."
              value={ratingData.propertyReview}
              onChange={(e) =>
                setRatingData((prev) => ({
                  ...prev,
                  propertyReview: e.target.value,
                }))
              }
              sx={{ mt: 1 }}
            />
          </Box>

          {/* Host Review */}
          <Box sx={{ mb: 3 }}>
            <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
              Host Review
            </Typography>
            <Rating
              value={ratingData.hostStars}
              onChange={(_e, newValue) =>
                setRatingData((prev) => ({ ...prev, hostStars: newValue ?? prev.hostStars }))
              }
            />
            <TextField
              fullWidth
              multiline
              minRows={2}
              variant="outlined"
              placeholder="Share your experience about the host..."
              value={ratingData.hostReview}
              onChange={(e) =>
                setRatingData((prev) => ({
                  ...prev,
                  hostReview: e.target.value,
                }))
              }
              sx={{ mt: 1 }}
            />
          </Box>

          {/* Platform Review */}
          <Box sx={{ mb: 3 }}>
            <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
              Platform Review (Aajoo)
            </Typography>
            <Rating
              value={ratingData.platformStars}
              onChange={(_e, newValue) =>
                setRatingData((prev) => ({ ...prev, platformStars: newValue ?? prev.platformStars }))
              }
            />
            <TextField
              fullWidth
              multiline
              minRows={2}
              variant="outlined"
              placeholder="Share your feedback about the Aajoo platform..."
              value={ratingData.platformReview}
              onChange={(e) =>
                setRatingData((prev) => ({
                  ...prev,
                  platformReview: e.target.value,
                }))
              }
              sx={{ mt: 1 }}
            />
          </Box>

          {/* Buttons */}
          <Box
            sx={{
              display: "flex",
              flexDirection: isMobile ? "column" : "row",
              justifyContent: "space-between",
              gap: 2,
              mt: 3,
            }}
          >
            <Button
              variant="contained"
              sx={{
                bgcolor: "#1B2447",
                "&:hover": { bgcolor: "#a83454" },
                textTransform: "none",
                px: 4,
                py: 1.5,
                borderRadius: 2,
                fontWeight: 600,
              }}
              onClick={handleSubmit}
            >
              Submit & Checkout
            </Button>

            <Button
              variant="outlined"
              sx={{
                borderColor: "#1B2447",
                color: "#1B2447",
                "&:hover": { bgcolor: "#fce4ec" },
                textTransform: "none",
                px: 4,
                py: 1.5,
                borderRadius: 2,
                fontWeight: 600,
              }}
              onClick={handleCancel}
            >
              Cancel Checkout
            </Button>
          </Box>
        </CardContent>
      </Card>

      {/* Snackbar */}
      <Snackbar
        open={snackbarOpen}
        autoHideDuration={3000}
        onClose={() => setSnackbarOpen(false)}
        anchorOrigin={{ vertical: "bottom", horizontal: "center" }}
      >
        <Alert
          severity="success"
          sx={{ width: "100%", fontWeight: 600 }}
          onClose={() => setSnackbarOpen(false)}
        >
          {snackbarMessage}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default UserCheckoutPage;
