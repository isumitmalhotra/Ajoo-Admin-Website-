// SidebarFilters.tsx
import React from "react";
import {
  Box,
  Typography,
  TextField,
  Slider,
  FormControlLabel,
  Checkbox,
  Button,
  IconButton,
} from "@mui/material";
import ClearIcon from "@mui/icons-material/Clear";
import SearchIcon from "@mui/icons-material/Search";

interface Props {
  locationName: string;
  setLocationName: (v: string) => void;
  distance: number;
  setDistance: (v: number) => void;
  selectedPrices: string[];
  togglePrice: (v: string) => void;
  selectedAmenities: string[];
  toggleAmenity: (v: string) => void;
}

const SidebarFilters: React.FC<Props> = ({
  locationName,
  setLocationName,
  distance,
  setDistance,
  selectedPrices,
  togglePrice,
  selectedAmenities,
  toggleAmenity,
}) => {
  const priceOptions = ["₹0–₹1,000", "₹1,000–₹5,000", "₹5,000–₹10,000", "₹10,000+"];
  const amenitiesOptions = ["WiFi", "Parking", "Pool", "AC", "TV", "Kitchen"];

  return (
    <Box sx={{ width: "100%" }}>
      {/* Search */}
      <Typography sx={{ fontWeight: 600, mb: 1, color: "#1B2447" }}>
        Search
      </Typography>

      <TextField
        fullWidth
        placeholder="Search location..."
        value={locationName}
        onChange={(e) => setLocationName(e.target.value)}
        InputProps={{
          endAdornment: locationName && (
            <IconButton onClick={() => setLocationName("")}>
              <ClearIcon sx={{ color: "#1B2447" }} />
            </IconButton>
          ),
        }}
        sx={{
          "& .MuiOutlinedInput-root fieldset": { borderColor: "#1B2447" },
          mb: 3,
        }}
      />

      {/* Distance */}
      <Typography sx={{ fontWeight: 600, color: "#1B2447" }}>
        Distance: {distance} KM
      </Typography>
      <Slider
        value={distance}
        onChange={(_, v) => setDistance(v as number)}
        min={1}
        max={50}
        sx={{ color: "#1B2447", mb: 3 }}
      />

      {/* Price */}
      <Typography sx={{ fontWeight: 600, color: "#1B2447", mb: 1 }}>
        Price Range
      </Typography>
      {priceOptions.map((p) => (
        <FormControlLabel
          key={p}
          control={
            <Checkbox
              checked={selectedPrices.includes(p)}
              onChange={() => togglePrice(p)}
              sx={{
                color: "#1B2447",
                "&.Mui-checked": { color: "#1B2447" },
              }}
            />
          }
          label={p}
        />
      ))}

      {/* Amenities */}
      <Typography sx={{ fontWeight: 600, color: "#1B2447", mt: 2, mb: 1 }}>
        Amenities
      </Typography>
      {amenitiesOptions.map((a) => (
        <FormControlLabel
          key={a}
          control={
            <Checkbox
              checked={selectedAmenities.includes(a)}
              onChange={() => toggleAmenity(a)}
              sx={{
                color: "#1B2447",
                "&.Mui-checked": { color: "#1B2447" },
              }}
            />
          }
          label={a}
        />
      ))}

      <Button
        fullWidth
        variant="contained"
        startIcon={<SearchIcon />}
        sx={{ mt: 3, backgroundColor: "#1B2447" }}
      >
        Search
      </Button>
    </Box>
  );
};

export default SidebarFilters;
