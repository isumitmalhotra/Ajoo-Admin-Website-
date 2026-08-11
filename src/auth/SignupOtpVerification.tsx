import React, { useState, useEffect } from "react";
import { Box, Typography, Button, TextField, Stack, CircularProgress } from "@mui/material";
import { useNavigate, useLocation } from "react-router-dom";
import toast from "react-hot-toast";
import { verifySignupOtp, resendSignupOtp } from "../services/customerApi";

const SignupOtpVerification: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { userId, email } = (location.state || {}) as {
    userId?: number | string;
    email?: string;
  };

  const [otp, setOtp] = useState("");
  const [timer, setTimer] = useState(30); // 30s timer
  const [canResend, setCanResend] = useState(false);
  const [verifying, setVerifying] = useState(false);

  // Timer countdown effect
  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (timer > 0) {
      interval = setInterval(() => setTimer((prev) => prev - 1), 1000);
    } else {
      setCanResend(true);
    }
    return () => clearInterval(interval);
  }, [timer]);

  // Handle resend OTP
  const handleResend = async () => {
    if (!userId) return;
    try {
      await resendSignupOtp(userId);
      setOtp("");
      setTimer(30);
      setCanResend(false);
      toast.success("OTP resent to your email.");
    } catch (e: any) {
      toast.error(e?.response?.data?.message || "Couldn't resend OTP.");
    }
  };

  const handleVerify = async () => {
    if (!userId) {
      toast.error("Session expired. Please sign up again.");
      navigate("/auth/signup");
      return;
    }
    setVerifying(true);
    try {
      await verifySignupOtp({ userId, otp });
      toast.success("Account verified! Please sign in.");
      navigate("/auth/login");
    } catch (e: any) {
      toast.error(e?.response?.data?.message || "Invalid OTP. Please try again.");
    } finally {
      setVerifying(false);
    }
  };

  return (
    <Box
      sx={{
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        background: "#f9f9f9",
        px: 2,
      }}
    >
      <Box
        sx={{
          width: "100%",
          maxWidth: 400,
          bgcolor: "#fff",
          p: 4,
          borderRadius: 3,
          boxShadow: "0 6px 16px rgba(0,0,0,0.15)",
          textAlign: "center",
        }}
      >
        {/* Title */}
        <Typography
          variant="h5"
          fontWeight={700}
          color="#1B2447"
          gutterBottom
        >
          OTP Verification
        </Typography>
        <Typography variant="body2" color="text.secondary" mb={3}>
          Please enter the OTP sent to{" "}
          {email ? <strong>{email}</strong> : "your registered email"}.
        </Typography>

        {/* OTP Input */}
        <TextField
          label="Enter OTP"
          fullWidth
          value={otp}
          onChange={(e) => {
            const value = e.target.value.replace(/\D/g, ""); // allow only numbers
            if (value.length <= 4) setOtp(value);
          }}
          inputProps={{ maxLength: 4, style: { textAlign: "center", fontSize: 20 } }}
          sx={{
            "& .MuiOutlinedInput-root.Mui-focused fieldset": {
              borderColor: "#1B2447",
            },
            "& .MuiInputLabel-root.Mui-focused": {
              color: "#1B2447",
            },
          }}
        />

        {/* Timer + Resend */}
        <Stack
          direction="row"
          justifyContent="center"
          alignItems="center"
          spacing={1}
          mt={2}
        >
          {canResend ? (
            <Button
              onClick={handleResend}
              sx={{ color: "#1B2447", fontWeight: 600 }}
            >
              Resend OTP
            </Button>
          ) : (
            <Typography variant="body2" color="text.secondary">
              Resend OTP in {timer}s
            </Typography>
          )}
        </Stack>

        {/* Submit Button */}
        <Button
          fullWidth
          variant="contained"
          sx={{
            mt: 3,
            backgroundColor: "#1B2447",
            "&:hover": { backgroundColor: "#a93250" },
            borderRadius: "8px",
            py: 1.5,
            fontWeight: 600,
          }}
          onClick={handleVerify}
          disabled={otp.length !== 4 || verifying}
          startIcon={verifying ? <CircularProgress size={16} sx={{ color: "#fff" }} /> : undefined}
        >
          {verifying ? "Verifying…" : "Verify OTP"}
        </Button>
      </Box>
    </Box>
  );
};

export default SignupOtpVerification;
