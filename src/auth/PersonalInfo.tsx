import {
  TextField,
  InputAdornment,
  MenuItem,
  Checkbox,
  FormControlLabel,
  Typography,
  Box,
  IconButton,
} from "@mui/material";
import { motion } from "framer-motion";
import PersonIcon from "@mui/icons-material/Person";
import EmailIcon from "@mui/icons-material/Email";
import LockIcon from "@mui/icons-material/Lock";
import VisibilityIcon from "@mui/icons-material/Visibility";
import VisibilityOffIcon from "@mui/icons-material/VisibilityOff";
import WcIcon from "@mui/icons-material/Wc";
import PhoneIphoneIcon from "@mui/icons-material/PhoneIphone";
import EventIcon from "@mui/icons-material/Event";
import { useState } from "react";

const PRIMARY = "#1B2447";
const ERROR_COLOR = "#333";

const fadeUp = {
  hidden: { opacity: 0, y: 30 },
  show: { opacity: 1, y: 0, transition: { duration: 0.4 } },
};

const PersonalInfo = ({ data, errors, onChange }: any) => {
  // Password visibility state
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);

  // SINGLE SELECT CHECKBOX HANDLER
  const handleUserTypeChange = (type: "user" | "host") => {
    if (type === "user") {
      onChange("isUser", true);
      onChange("isHost", false);
    } else {
      onChange("isUser", false);
      onChange("isHost", true);
    }
  };

  const renderInput = (
    label: string,
    name: string,
    value: string,
    error: string,
    icon: any,
    type = "text",
    extraEndAdornment: any = null
  ) => (
    <TextField
      fullWidth
      required
      type={type}
      label={label}
      value={value}
      error={!!error}
      onChange={(e) => onChange(name, e.target.value)}
      helperText={error}
      FormHelperTextProps={{
        sx: { color: ERROR_COLOR, fontWeight: 600 },
      }}
      InputProps={{
        startAdornment: (
          <InputAdornment position="start">{icon}</InputAdornment>
        ),
        endAdornment: extraEndAdornment,
      }}
      sx={{
        "& .MuiOutlinedInput-root": {
          borderRadius: "12px",
          transition: "all 0.25s ease",
          "&:hover fieldset": { borderColor: PRIMARY },
          "&.Mui-focused fieldset": {
            borderColor: PRIMARY,
            boxShadow: `0 0 0 2px ${PRIMARY}33`,
          },
        },
        "& label": {
          color: PRIMARY,
          fontWeight: 600,
        },
        "& .MuiInputLabel-root.Mui-focused": {
          color: PRIMARY,
        },
        "& .MuiFormLabel-asterisk": {
          color: PRIMARY,
        },
      }}
    />
  );

  return (
    <motion.div
      variants={fadeUp}
      initial="hidden"
      animate="show"
      style={{ width: "100%" }}
    >
      <Typography
        variant="h5"
        sx={{ fontWeight: 700, mb: 2, color: PRIMARY, textAlign: "center" }}
      >
        Personal Information
      </Typography>

      <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
        {/* Name */}
        {renderInput(
          "Full Name",
          "fullName",
          data.fullName,
          errors.fullName,
          <PersonIcon sx={{ color: PRIMARY }} />
        )}

        {/* Email */}
        {renderInput(
          "Email",
          "email",
          data.email,
          errors.email,
          <EmailIcon sx={{ color: PRIMARY }} />
        )}

        {/* Password + Confirm Password */}
        <Box
          sx={{
            display: "flex",
            gap: 2,
            flexDirection: { xs: "column", sm: "row" },
          }}
        >
          {/* Password */}
          {renderInput(
            "Password",
            "password",
            data.password,
            errors.password,
            <LockIcon sx={{ color: PRIMARY }} />,
            showPassword ? "text" : "password",
            <InputAdornment position="end">
              <IconButton onClick={() => setShowPassword(!showPassword)}>
                {showPassword ? <VisibilityOffIcon /> : <VisibilityIcon />}
              </IconButton>
            </InputAdornment>
          )}

          {/* Confirm Password */}
          {renderInput(
            "Confirm Password",
            "confirmPassword",
            data.confirmPassword,
            errors.confirmPassword,
            <LockIcon sx={{ color: PRIMARY }} />,
            showConfirm ? "text" : "password",
            <InputAdornment position="end">
              <IconButton onClick={() => setShowConfirm(!showConfirm)}>
                {showConfirm ? <VisibilityOffIcon /> : <VisibilityIcon />}
              </IconButton>
            </InputAdornment>
          )}
        </Box>

        {/* DOB */}
        <TextField
          fullWidth
          type="date"
          label="Date of Birth *"
          value={data.dob}
          error={!!errors.dob}
          helperText={errors.dob}
          FormHelperTextProps={{ sx: { color: ERROR_COLOR, fontWeight: 600 } }}
          onChange={(e) => onChange("dob", e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <EventIcon sx={{ color: PRIMARY }} />
              </InputAdornment>
            ),
          }}
          InputLabelProps={{ shrink: true }}
          sx={{
            "& .MuiOutlinedInput-root": {
              borderRadius: "12px",
              "&:hover fieldset": { borderColor: PRIMARY },
              "&.Mui-focused fieldset": { borderColor: PRIMARY },
            },
            "& label": { color: PRIMARY, fontWeight: 600 },
            "& .MuiInputLabel-root.Mui-focused": { color: PRIMARY },
            "& .MuiFormLabel-asterisk": { color: PRIMARY },
          }}
        />

        {/* Gender */}
        <TextField
          select
          fullWidth
          label="Gender *"
          value={data.gender}
          error={!!errors.gender}
          helperText={errors.gender}
          FormHelperTextProps={{ sx: { color: ERROR_COLOR, fontWeight: 600 } }}
          onChange={(e) => onChange("gender", e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <WcIcon sx={{ color: PRIMARY }} />
              </InputAdornment>
            ),
          }}
          sx={{
            "& .MuiOutlinedInput-root": {
              borderRadius: "12px",
              "&:hover fieldset": { borderColor: PRIMARY },
              "&.Mui-focused fieldset": { borderColor: PRIMARY },
            },
            "& label": { color: PRIMARY, fontWeight: 600 },
            "& .MuiInputLabel-root.Mui-focused": { color: PRIMARY },
            "& .MuiFormLabel-asterisk": { color: PRIMARY },
          }}
        >
          <MenuItem value="Male">Male</MenuItem>
          <MenuItem value="Female">Female</MenuItem>
          <MenuItem value="Other">Other</MenuItem>
        </TextField>

        {/* Phones */}
        {renderInput(
          "Primary Phone",
          "contact",
          data.contact,
          errors.contact,
          <PhoneIphoneIcon sx={{ color: PRIMARY }} />
        )}
        {renderInput(
          "Alternate Phone",
          "alternatePhone",
          data.alternatePhone,
          "",
          <PhoneIphoneIcon sx={{ color: PRIMARY }} />
        )}

        {/* User Type Radio-like Checkboxes */}
        <Box sx={{ mt: 1 }}>
          <Typography sx={{ fontWeight: 700, color: PRIMARY, mb: 1 }}>
            Select User Type
          </Typography>

          <FormControlLabel
            control={
              <Checkbox
                checked={data.isUser}
                onChange={() => handleUserTypeChange("user")}
                sx={{ color: PRIMARY, "&.Mui-checked": { color: PRIMARY } }}
              />
            }
            label="User"
          />

          <FormControlLabel
            control={
              <Checkbox
                checked={data.isHost}
                onChange={() => handleUserTypeChange("host")}
                sx={{ color: PRIMARY, "&.Mui-checked": { color: PRIMARY } }}
              />
            }
            label="Host"
          />
        </Box>
      </Box>
    </motion.div>
  );
};

export default PersonalInfo;
