import { useState } from "react";
import { TextField, InputAdornment, Typography, MenuItem, Button, Box, CircularProgress } from "@mui/material";
import { motion } from "framer-motion";
import HomeIcon from "@mui/icons-material/Home";
import LocationCityIcon from "@mui/icons-material/LocationCity";
import PinIcon from "@mui/icons-material/Pin";
import MyLocationIcon from "@mui/icons-material/MyLocation";
import toast from "react-hot-toast";
import { detectAddress, INDIAN_STATES } from "../styles/utils/locationUtils";
import { citiesForState } from "../styles/utils/indiaCities";

const PRIMARY = "#1B2447";

const fadeUp = {
  hidden: { opacity: 0, y: 20 },
  show: { opacity: 1, y: 0, transition: { duration: 0.4 } },
};

const AddressInfo = ({ data, errors, onChange }: any) => {
  const [locating, setLocating] = useState(false);

  const handleUseLocation = async () => {
    setLocating(true);
    try {
      const addr = await detectAddress();
      if (addr.address) onChange("address", addr.address);
      if (addr.city) onChange("city", addr.city);
      if (addr.state) onChange("state", addr.state);
      if (addr.pincode) onChange("pincode", addr.pincode);
      if (addr.country) onChange("country", addr.country);
      toast.success("Address filled from your location");
    } catch {
      toast.error("Couldn't get your location. Please allow location access.");
    } finally {
      setLocating(false);
    }
  };

  const renderInput = (
    label: string,
    name: string,
    value: string,
    error: string,
    icon: any,
    placeholder = ""
  ) => (
    <TextField
      fullWidth
      required
      label={label}
      placeholder={placeholder}
      value={value}
      error={!!error}
      helperText={error}
      onChange={(e) => onChange(name, e.target.value)}
      InputProps={{
        startAdornment: (
          <InputAdornment position="start">{icon}</InputAdornment>
        ),
      }}
      sx={{
        mb: 2,
        "& .MuiOutlinedInput-root": {
          borderRadius: "12px",
          "& fieldset": { borderColor: PRIMARY },
          "&:hover fieldset": { borderColor: PRIMARY },
          "&.Mui-focused fieldset": {
            borderColor: PRIMARY,
            boxShadow: `0 0 0 2px ${PRIMARY}33`,
          },
        },
        "& label": { color: PRIMARY, fontWeight: 600 },
        "& .MuiInputLabel-root.Mui-focused": { color: PRIMARY },
        "& .MuiFormLabel-asterisk": { color: PRIMARY }, // star color
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
        Address Information
      </Typography>

      {/* Use my location → auto-fills address fields */}
      <Box sx={{ display: "flex", justifyContent: "center", mb: 2.5 }}>
        <Button
          onClick={handleUseLocation}
          disabled={locating}
          startIcon={locating ? <CircularProgress size={16} /> : <MyLocationIcon />}
          variant="outlined"
          sx={{ borderColor: PRIMARY, color: PRIMARY, textTransform: "none", fontWeight: 600, borderRadius: "10px", "&:hover": { borderColor: PRIMARY, bgcolor: "rgba(27,36,71,.05)" } }}
        >
          {locating ? "Detecting…" : "Use my current location"}
        </Button>
      </Box>

      {/* Address */}
      {renderInput(
        "Address",
        "address",
        data.address,
        errors.address,
        <HomeIcon sx={{ color: PRIMARY }} />,
        "Enter your address"
      )}

      {/* Country */}
      <TextField
        fullWidth
        required
        label="Country *"
        value="India"
        disabled
        InputProps={{
          startAdornment: (
            <InputAdornment position="start">
              <LocationCityIcon sx={{ color: PRIMARY }} />
            </InputAdornment>
          ),
          // FORCE text color even when disabled
          sx: {
            color: "#000",
            "&.Mui-disabled": {
              WebkitTextFillColor: "#000", // text color fix
            },
          },
        }}
        sx={{
          mb: 2,

          // Force border for disabled mode
          "& .MuiOutlinedInput-root": {
            borderRadius: "12px",

            "& fieldset": {
              borderColor: PRIMARY + " !important", // Keep border color always
            },

            "&:hover fieldset": {
              borderColor: PRIMARY + " !important",
            },

            "&.Mui-focused fieldset": {
              borderColor: PRIMARY + " !important",
            },

            "&.Mui-disabled fieldset": {
              borderColor: PRIMARY + " !important",
            },

            // Remove MUI disabled grey background
            "&.Mui-disabled": {
              backgroundColor: "transparent !important",
            },
          },

          // Label color
          "& label": { color: PRIMARY, fontWeight: 600 },
          "& .MuiInputLabel-root.Mui-focused": { color: PRIMARY },

          // Required (*) color
          "& .MuiFormLabel-asterisk": {
            color: PRIMARY,
          },
        }}
      />

      {/* State Dropdown */}
      <TextField
        fullWidth
        select
        required
        label="State"
        value={data.state}
        error={!!errors.state}
        helperText={errors.state}
        onChange={(e) => {
          onChange("state", e.target.value);
          onChange("city", ""); // reset city when state changes
        }}
        InputProps={{
          startAdornment: (
            <InputAdornment position="start">
              <LocationCityIcon sx={{ color: PRIMARY }} />
            </InputAdornment>
          ),
        }}
        sx={{
          mb: 2,
          "& .MuiOutlinedInput-root": {
            borderRadius: "12px",
            "& fieldset": { borderColor: PRIMARY },
            "&:hover fieldset": { borderColor: PRIMARY },
            "&.Mui-focused fieldset": { borderColor: PRIMARY },
          },
          "& label": { color: PRIMARY, fontWeight: 600 },
          "& .MuiInputLabel-root.Mui-focused": { color: PRIMARY },
          "& .MuiFormLabel-asterisk": { color: PRIMARY },
        }}
      >
        {INDIAN_STATES.map((s) => (
          <MenuItem key={s} value={s}>
            {s}
          </MenuItem>
        ))}
      </TextField>

      {/* City Dropdown — depends on the selected state */}
      <TextField
        fullWidth
        select
        required
        label="City"
        value={data.city || ""}
        error={!!errors.city}
        helperText={errors.city || (!data.state ? "Select a state first" : "")}
        disabled={!data.state}
        onChange={(e) => onChange("city", e.target.value)}
        InputProps={{
          startAdornment: (
            <InputAdornment position="start">
              <LocationCityIcon sx={{ color: PRIMARY }} />
            </InputAdornment>
          ),
        }}
        sx={{
          mb: 2,
          "& .MuiOutlinedInput-root": {
            borderRadius: "12px",
            "& fieldset": { borderColor: PRIMARY },
            "&:hover fieldset": { borderColor: PRIMARY },
            "&.Mui-focused fieldset": { borderColor: PRIMARY },
          },
          "& label": { color: PRIMARY, fontWeight: 600 },
          "& .MuiInputLabel-root.Mui-focused": { color: PRIMARY },
          "& .MuiFormLabel-asterisk": { color: PRIMARY },
        }}
      >
        {/* Include the autofilled city even if it's not in the curated list */}
        {Array.from(
          new Set([
            ...(data.city ? [data.city] : []),
            ...citiesForState(data.state),
          ])
        ).map((c) => (
          <MenuItem key={c} value={c}>
            {c}
          </MenuItem>
        ))}
      </TextField>

      {/* Pincode */}
      <TextField
        fullWidth
        required
        label="Pincode *"
        value={data.pincode}
        error={!!errors.pincode}
        helperText={errors.pincode}
        onChange={(e) => {
          const val = e.target.value;

          // Allow only numbers & max length 6
          if (/^\d{0,6}$/.test(val)) {
            onChange("pincode", val);
          }
        }}
        placeholder="Enter your pincode"
        InputProps={{
          startAdornment: (
            <InputAdornment position="start">
              <PinIcon sx={{ color: PRIMARY }} />
            </InputAdornment>
          ),
          inputProps: { maxLength: 6 },
        }}
        sx={{
          mb: 2,
          "& .MuiOutlinedInput-root": {
            borderRadius: "12px",
            "& fieldset": { borderColor: PRIMARY },
            "&.Mui-focused fieldset": { borderColor: PRIMARY },
          },
          "& label": { color: PRIMARY, fontWeight: 600 },
          "& .MuiInputLabel-root.Mui-focused": { color: PRIMARY },
        }}
      />
    </motion.div>
  );
};

export default AddressInfo;
