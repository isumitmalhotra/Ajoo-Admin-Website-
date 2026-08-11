import { useState, type FormEvent } from "react";
import {
  ToggleButton,
  ToggleButtonGroup,
  Checkbox,
  FormControlLabel,
  TextField,
  Button,
  CircularProgress,
} from "@mui/material";
import { Link, useNavigate } from "react-router-dom";
import GoogleIcon from "@mui/icons-material/Google";
import toast from "react-hot-toast";
import loginPage from "../../assets/UI/loginpagesvg.svg";
import "../../styles/LoginForm.css";
import api from "../../services/api";
import storage from "../../styles/utils/storage";
import { parseAdminAuthPayload } from "../../services/apiContracts";
import {
  setAdminToken,
  setAdminUser,
  setAdminClaims,
  setAdminRoles,
  setAdminPermissions,
} from "../../services/adminSession";

export const LoginForm = () => {
  const navigate = useNavigate();
  const [userType, setUserType] = useState<"renter" | "host">("renter");
  const [rememberMe, setRememberMe] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e: FormEvent) => {
    e.preventDefault();
    if (loading) return;

    if (!email.trim() || !password) {
      toast.error("Please enter your email and password.");
      return;
    }

    setLoading(true);
    try {
      const isHost = userType === "host" ? 1 : 0;
      // Backend `/user/login` filters by the isHost flag, so the Renter/Host
      // toggle decides which credential set is matched.
      const res = await api.post("/user/login", {
        user_email: email.trim(),
        user_password: password,
        isHost,
      });

      // The backend returns HTTP 200 even for "No record found" / "Incorrect
      // password" (success:false), so we must inspect the envelope.
      const body = res.data;
      if (!body?.success) {
        toast.error(
          body?.message || "Login failed. Please check your credentials."
        );
        return;
      }

      const parsed = parseAdminAuthPayload(body);
      const token = parsed?.token || body?.data?.token;
      if (!token) {
        toast.error("Login succeeded but no session token was returned.");
        return;
      }

      // Customer portal API stack (src/axios/axios.ts) reads from `storage`.
      storage.setToken(token);

      // Host portal pages (services/api) + route guards (authGaurd) read from
      // adminSession, so a host login must populate it too.
      if (userType === "host") {
        setAdminToken(token);
        if (parsed?.admin) setAdminUser(parsed.admin);
        setAdminClaims(parsed?.claims ?? null);
        setAdminRoles(parsed?.roles ?? []);
        setAdminPermissions(parsed?.permissions ?? []);
      }

      toast.success(body?.message || "Logged in successfully.");
      navigate(userType === "host" ? "/host/dashboard" : "/", {
        replace: true,
      });
    } catch (err: unknown) {
      const message =
        (err as { response?: { data?: { message?: string } } })?.response?.data
          ?.message || "Login failed. Please try again.";
      toast.error(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      {/* Left Side Form */}
      <div className="login-form-section">
        <form className="login-box" onSubmit={handleLogin}>
          {/* Heading & Description */}
          <h2 className="login-title">Login to Your Account</h2>
          <p className="login-description">
            Please enter your details to continue. New here? Create an account
            in just a few steps.
          </p>

          {/* Toggle Button */}
          <ToggleButtonGroup
            value={userType}
            exclusive
            onChange={(_, value) => {
              if (value !== null) setUserType(value);
            }}
            sx={{
              display: "flex",
              justifyContent: "center",
              mb: 3,
              height: "40px",
              borderRadius: "30px",
              overflow: "hidden",
              "& .MuiToggleButton-root": {
                textTransform: "capitalize",
                px: 4,
                py: 1.2,
                border: "1px solid #1B2447",
                color: "#1B2447",
                fontWeight: 600,
                borderRadius: 0,
                transition: "all 0.25s ease-in-out",

                "&:first-of-type": {
                  borderTopLeftRadius: "30px",
                  borderBottomLeftRadius: "30px",
                },
                "&:last-of-type": {
                  borderTopRightRadius: "30px",
                  borderBottomRightRadius: "30px",
                },

                "&:hover": {
                  backgroundColor: "rgba(27,36,71,0.05)",
                  color: "#1B2447",
                  borderColor: "#1B2447",
                },

                "&.Mui-selected": {
                  backgroundColor: "#1B2447",
                  color: "#FFFAF0",
                  borderColor: "#1B2447",
                  boxShadow: "0 0 8px rgba(27,36,71,0.35)",
                },

                "&.Mui-selected:hover": {
                  backgroundColor: "#2A356B",
                  borderColor: "#2A356B",
                  color: "#FFFAF0",
                  boxShadow: "0 0 10px rgba(27,36,71,0.45)",
                },
              },
            }}
          >
            <ToggleButton value="renter">Renter</ToggleButton>
            <ToggleButton value="host">Host</ToggleButton>
          </ToggleButtonGroup>

          {/* Email Field */}
          <TextField
            label="Email"
            type="email"
            fullWidth
            margin="normal"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            autoComplete="email"
            sx={{
              "& .MuiOutlinedInput-root.Mui-focused fieldset": {
                borderColor: "#1B2447",
              },
              "& .MuiInputLabel-root.Mui-focused": {
                color: "#1B2447",
              },
            }}
          />

          {/* Password Field */}
          <TextField
            label="Password"
            type="password"
            fullWidth
            margin="normal"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoComplete="current-password"
            sx={{
              "& .MuiOutlinedInput-root.Mui-focused fieldset": {
                borderColor: "#1B2447",
              },
              "& .MuiInputLabel-root.Mui-focused": {
                color: "#1B2447",
              },
            }}
          />

          {/* Remember Me + Forgot Password */}
          <div className="form-options">
            <FormControlLabel
              control={
                <Checkbox
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                  sx={{
                    color: "#1B2447",
                    "&.Mui-checked": {
                      color: "#1B2447",
                    },
                  }}
                />
              }
              label="Remember Me"
            />
            <Link to="/auth/forget" className="forgot-password">
              Forgot Password?
            </Link>
          </div>

          {/* Login Button */}
          <Button
            type="submit"
            variant="contained"
            fullWidth
            disabled={loading}
            sx={{
              mt: 2,
              mb: 2,
              backgroundColor: "#1B2447",
              color: "#fff",
              borderRadius: "8px",
              padding: "12px",
              fontWeight: 600,
              "&:hover": { backgroundColor: "#2A356B" },
            }}
          >
            {loading ? (
              <CircularProgress size={22} sx={{ color: "#fff" }} />
            ) : (
              "Login"
            )}
          </Button>

          {/* Google Button */}
          <Button
            type="button"
            variant="outlined"
            fullWidth
            startIcon={<GoogleIcon />}
            onClick={() =>
              toast("Google sign-in is coming soon.", { icon: "ℹ️" })
            }
            sx={{
              borderColor: "#1B2447",
              color: "#1B2447",
              borderRadius: "8px",
              padding: "12px",
              fontWeight: 600,
              "&:hover": {
                borderColor: "#1B2447",
                backgroundColor: "rgba(27,36,71,0.05)",
              },
            }}
          >
            Login with Google
          </Button>
          <div className="singuponLogin">
            <Link to="/auth/signup" className="forgot-password">
              Don't Have Account? Sign-up
            </Link>
          </div>
        </form>
      </div>

      {/* Right Side Image */}
      <div className="login-image-section">
        <img src={loginPage} alt="Login" className="login-image" />
      </div>
    </div>
  );
};
