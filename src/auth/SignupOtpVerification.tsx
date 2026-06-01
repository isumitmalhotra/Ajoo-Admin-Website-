import React, { useState, useEffect } from "react";
import { Box, Typography, Button, TextField, Stack } from "@mui/material";

const SignupOtpVerification: React.FC = () => {
  const [otp, setOtp] = useState("");
  const [timer, setTimer] = useState(30); // 30s timer
  const [canResend, setCanResend] = useState(false);

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
  const handleResend = () => {
    setOtp("");
    setTimer(30);
    setCanResend(false);
    alert("OTP resent successfully!");
  };

  const handleVerify = () => {
    alert(`OTP Verified: ${otp}`);
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
          Please enter the 4-digit OTP sent to your registered email/phone.
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
          disabled={otp.length !== 4}
        >
          Verify OTP
        </Button>
      </Box>
    </Box>
  );
};

export default SignupOtpVerification;
