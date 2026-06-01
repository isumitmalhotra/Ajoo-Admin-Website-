import { TextField, InputAdornment, Typography, MenuItem } from "@mui/material";
import { motion } from "framer-motion";
import HomeIcon from "@mui/icons-material/Home";
import LocationCityIcon from "@mui/icons-material/LocationCity";
import PinIcon from "@mui/icons-material/Pin";

const PRIMARY = "#1B2447";

const fadeUp = {
  hidden: { opacity: 0, y: 20 },
  show: { opacity: 1, y: 0, transition: { duration: 0.4 } },
};

const AddressInfo = ({ data, errors, onChange }: any) => {
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
        sx={{ fontWeight: 700, mb: 3, color: PRIMARY, textAlign: "center" }}
      >
        Address Information
      </Typography>

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
        onChange={(e) => onChange("state", e.target.value)}
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
        <MenuItem value="X">X</MenuItem>
        <MenuItem value="Y">Y</MenuItem>
        <MenuItem value="Z">Z</MenuItem>
      </TextField>

      {/* City */}
      {renderInput(
        "City",
        "city",
        data.city,
        errors.city,
        <LocationCityIcon sx={{ color: PRIMARY }} />,
        "Enter your city"
      )}

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
