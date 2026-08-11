import { useState, useEffect } from "react";
import { Box, Typography, TextField, Button } from "@mui/material";
import "../../styles/ForgetPasswordForm.css";
import { useNavigate } from "react-router-dom";
import bgImage from "../../assets/UI/forgetpass1.svg";
import logo from "../../assets/UI/logo.svg";

export const ForgetPasswordForm = () => {
  const [step, setStep] = useState<"email" | "otp">("email");
  const [email, setEmail] = useState("");
  const [otp, setOtp] = useState("");
  const [error, setError] = useState("");
  const [timer, setTimer] = useState(30);

  const navigate = useNavigate();

  // Timer effect
  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (step === "otp" && timer > 0) {
      interval = setInterval(() => setTimer((prev) => prev - 1), 1000);
    }
    return () => clearInterval(interval);
  }, [step, timer]);

  // Email validation
  const validateEmail = (email: string) => {
    const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return regex.test(email);
  };

  const returnToLogin = () => {
    navigate("/auth/login");
  };

  const handleSubmit = () => {
    if (step === "email") {
      if (!email) {
        setError("Email is required");
        return;
      }
      if (!validateEmail(email)) {
        setError("Please enter a valid email address");
        return;
      }
      setError("");
      setStep("otp");
      setTimer(30); // reset timer
    } else {
      if (!otp) {
        setError("OTP is required");
        return;
      }
      if (otp.length !== 4) {
        setError("OTP must be 4 digits");
        return;
      }
      setError("");
      alert(`OTP Submitted: ${otp}`); // replace with your API call
    }
  };

  const handleResendOtp = () => {
    setOtp("");
    setTimer(30);
    alert("OTP resent to your email"); // replace with API call
  };

  return (
    <Box className="forget-container">
      {/* Left: Form */}
      <Box className="forget-box">
        <img src={logo} alt="" className="topLogofrgtpas"/>
        <Typography variant="h4" fontWeight={700} mb={1} color="#1B2447">
          Forgot Password
        </Typography>
        <Typography variant="body1" color="text.secondary" mb={3}>
          {step === "email"
            ? "Don’t worry, enter your email below to reset your password."
            : `We sent an OTP to your email: ${email}`}
        </Typography>

        {/* Email Field */}
        <TextField
          label="Email"
          fullWidth
          margin="normal"
          disabled={step === "otp"}
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          error={!!error && step === "email"}
          helperText={step === "email" ? error : ""}
          sx={{
            "& .MuiOutlinedInput-root.Mui-focused fieldset": {
              borderColor: "#1B2447",
            },
            "& .MuiInputLabel-root.Mui-focused": {
              color: "#1B2447",
            },
          }}
        />

        {/* OTP Field */}
        {step === "otp" && (
          <TextField
            label="Enter OTP"
            fullWidth
            margin="normal"
            value={otp}
            onChange={(e) => setOtp(e.target.value.replace(/\D/g, ""))} // only digits
            error={!!error && step === "otp"}
            helperText={step === "otp" ? error : ""}
            inputProps={{ maxLength: 4 }}
            sx={{
              "& .MuiOutlinedInput-root.Mui-focused fieldset": {
                borderColor: "#1B2447",
              },
              "& .MuiInputLabel-root.Mui-focused": {
                color: "#1B2447",
              },
            }}
          />
        )}

        {/* Timer / Resend OTP */}
        {step === "otp" && (
          <Typography variant="body2" color="text.secondary" mb={2}>
            {timer > 0 ? `Resend OTP in ${timer}s` : ""}
          </Typography>
        )}
        {step === "otp" && timer === 0 && (
          <Button
            variant="text"
            onClick={handleResendOtp}
            sx={{ color: "#1B2447", fontWeight: 600 }}
          >
            Resend OTP
          </Button>
        )}

        {/* Button */}
        <Button
          fullWidth
          variant="contained"
          sx={{
            mt: 2,
            backgroundColor: "#1B2447",
            color: "#fff",
            borderRadius: "8px",
            py: 1.5,
            fontWeight: 600,
            "&:hover": { backgroundColor: "#a93250" },
          }}
          onClick={handleSubmit}
          disabled={step === "otp" && otp.length !== 4} // ✅ disabled until 4-digit OTP
        >
          {step === "email" ? "Submit" : "Submit OTP"}
        </Button>

        <Button
          fullWidth
          variant="outlined"
          sx={{
            mt: 2,
            borderColor: "#1B2447",
            color: "#1B2447",
            borderRadius: "8px",
            py: 1.5,
            fontWeight: 600,
            "&:hover": { borderColor: "#2A356B", backgroundColor: "rgba(27,36,71,0.04)" },
          }}
          onClick={returnToLogin}
        >
          Return to Login
        </Button>
      </Box>

      {/* Right: Image */}
      <Box className="rightImgFrgtPass">
        <img src={bgImage} alt="Forgot password" />
      </Box>
    </Box>
  );
};
