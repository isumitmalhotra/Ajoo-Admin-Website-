import React, { useState } from "react";
import { Typography, Slider, Button, Paper, Box } from "@mui/material";

interface FilterDropdownProps {
  onApply: () => void;
}

const FilterDropdown: React.FC<FilterDropdownProps> = ({ onApply }) => {
  const [price, setPrice] = useState<number[]>([1000, 10000]);
  const [radius, setRadius] = useState<number>(5);

  return (
    <Paper
      sx={{
        p: 2,
        width: { xs: "75vw", sm: 260, md: 280 },
        borderRadius: 3,
        boxShadow: 6,
        backgroundColor: "#fff",
        zIndex: 2000,
        position: "relative",
        maxHeight: { xs: "70vh", sm: "auto" },
        overflowY: { xs: "auto", sm: "visible" },
        "&::-webkit-scrollbar": { display: "none" },
      }}
    >
      {/* 🔹 Header */}
      <Typography
        variant="subtitle1"
        sx={{
          fontWeight: 600,
          mb: 2,
          textAlign: { xs: "center", sm: "left" },
        }}
      >
        Filters
      </Typography>

      {/* 💰 Price Range */}
      <Box
        sx={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          mb: 1,
        }}
      >
        <Typography variant="body2" sx={{ fontWeight: 500 }}>
          Price Range (₹)
        </Typography>
        <Typography
          variant="body2"
          sx={{ color: "#1B2447", fontWeight: 600 }}
        >
          {price[0]} - {price[1]}
        </Typography>
      </Box>
      <Slider
        value={price}
        onChange={(_, val) => setPrice(val as number[])}
        valueLabelDisplay="auto"
        min={500}
        max={20000}
        step={500}
        sx={{ color: "#1B2447" }}
      />

      {/* 📏 Radius */}
      <Box
        sx={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          mt: 2,
          mb: 1,
        }}
      >
        <Typography variant="body2" sx={{ fontWeight: 500 }}>
          Radius (km)
        </Typography>
        <Typography
          variant="body2"
          sx={{ color: "#1B2447", fontWeight: 600 }}
        >
          {radius} km
        </Typography>
      </Box>
      <Slider
        value={radius}
        onChange={(_, val) => setRadius(val as number)}
        valueLabelDisplay="auto"
        min={1}
        max={20}
        step={1}
        sx={{ color: "#1B2447" }}
      />

      {/* ✅ Apply Button */}
      <Box
        sx={{
          mt: 2,
          pt: 1,
          position: { xs: "sticky", sm: "static" },
          bottom: 0,
          backgroundColor: "#fff",
        }}
      >
        <Button
          variant="contained"
          fullWidth
          sx={{
            textTransform: "none",
            backgroundColor: "#1B2447",
            borderRadius: 2,
            "&:hover": { backgroundColor: "#a83c58" },
          }}
          onClick={onApply}
        >
          Apply Filters
        </Button>
      </Box>
    </Paper>
  );
};

export default FilterDropdown;
