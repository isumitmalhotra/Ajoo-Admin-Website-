import {
    Box,
    Button,
    FormControl,
    InputAdornment,
    InputLabel,
    MenuItem,
    Select,
    TextField,
    Collapse,
  } from "@mui/material";
  import { DatePicker } from "@mui/x-date-pickers/DatePicker";
  import { LocalizationProvider } from "@mui/x-date-pickers/LocalizationProvider";
  import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
  
  type StatusFilter = "active" | "inactive" | null;
  
  interface AdvancedFiltersProps {
    open: boolean;
  
    statusFilter: StatusFilter;
    setStatusFilter: (val: StatusFilter) => void;
  
    category: string;
    setCategory: (val: string) => void;
  
    date: any;
    setDate: (val: any) => void;
  
    price: string;
    setPrice: (val: string) => void;
  
    rating: string;
    setRating: (val: string) => void;
  
    onApply: () => void;
    onClear: () => void;
  }
  
  /* 🎨 COLORS */
  const PURPLE = "#1B2447";
  const PURPLE_LIGHT = "#EDE9FE";
  const GREEN = "#16A34A";
  const RED = "#DC2626";
  
  /* 🎯 Shared Input Styles */
  const filterInputSx = {
    "& .MuiOutlinedInput-root": {
      borderRadius: 3,
      color: PURPLE,
      backgroundColor: "#fff",
      "& fieldset": {
        borderColor: PURPLE_LIGHT,
      },
      "&:hover fieldset": {
        borderColor: PURPLE,
      },
      "&.Mui-focused fieldset": {
        borderColor: PURPLE,
        borderWidth: 2,
      },
    },
    "& .MuiInputLabel-root": {
      color: PURPLE,
    },
    "& .MuiInputLabel-root.Mui-focused": {
      color: PURPLE,
    },
  };
  
  export default function AdvancedFilters({
    open,
    statusFilter,
    setStatusFilter,
    category,
    setCategory,
    date,
    setDate,
    price,
    setPrice,
    rating,
    setRating,
    onApply,
    onClear,
  }: AdvancedFiltersProps) {
    return (
      <Collapse in={open} timeout="auto" unmountOnExit>
        <Box
          sx={{
            p: 3,
            borderTop: `1px solid ${PURPLE_LIGHT}`,
            background: "linear-gradient(180deg, #FAF5FF, #FFFFFF)",
          }}
        >
          {/* FILTER GRID */}
          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: {
                xs: "1fr",
                sm: "180px 1fr 1fr",
                md: "180px 1fr 1fr 1fr",
              },
              gap: 3,
              alignItems: "flex-start",
            }}
          >
            {/* STATUS TOGGLE */}
            <Box sx={{ display: "flex", flexDirection: "column", gap: 1.5 }}>
              {["active", "inactive"].map((status) => {
                const isActive = statusFilter === status;
                const isGreen = status === "active";
  
                return (
                  <Button
                    key={status}
                    fullWidth
                    onClick={() =>
                      setStatusFilter(isActive ? null : (status as StatusFilter))
                    }
                    sx={{
                      py: 1.3,
                      fontWeight: 700,
                      textTransform: "capitalize",
                      borderRadius: 3,
                      color: isActive
                        ? "#fff"
                        : isGreen
                          ? GREEN
                          : RED,
                      backgroundColor: isActive
                        ? isGreen
                          ? GREEN
                          : RED
                        : "transparent",
                      boxShadow: isActive
                        ? "0 10px 20px rgba(0,0,0,0.15)"
                        : "none",
                      "&:hover": {
                        backgroundColor: isActive
                          ? isGreen
                            ? GREEN
                            : RED
                          : isGreen
                            ? "#DCFCE7"
                            : "#FEE2E2",
                      },
                    }}
                  >
                    {status}
                  </Button>
                );
              })}
            </Box>
  
            {/* CATEGORY */}
            <FormControl fullWidth sx={filterInputSx}>
              <InputLabel>Category</InputLabel>
              <Select
                value={category}
                label="Category"
                onChange={(e) => setCategory(e.target.value)}
              >
                {["Single", "Couple", "Family", "Sharing"].map((c) => (
                  <MenuItem key={c} value={c}>
                    {c}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
  
            {/* DATE */}
            <LocalizationProvider dateAdapter={AdapterDayjs}>
              <DatePicker
                label="Available From"
                value={date}
                onChange={(val) => setDate(val)}
                slotProps={{
                  textField: {
                    fullWidth: true,
                    sx: filterInputSx,
                  },
                }}
              />
            </LocalizationProvider>
  
            {/* PRICE */}
            <TextField
              label="Max Price"
              value={price}
              onChange={(e) => setPrice(e.target.value)}
              fullWidth
              sx={filterInputSx}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start" sx={{ color: PURPLE }}>
                    $
                  </InputAdornment>
                ),
              }}
            />
  
            {/* RATING */}
            <FormControl fullWidth sx={filterInputSx}>
              <InputLabel>Rating</InputLabel>
              <Select
                value={rating}
                label="Rating"
                onChange={(e) => setRating(e.target.value)}
              >
                {[5, 4, 3, 2].map((r) => (
                  <MenuItem key={r} value={r}>
                    ⭐ {r}+ Rating
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Box>
  
          {/* ACTION BUTTONS */}
          <Box
            sx={{
              mt: 4,
              display: "flex",
              justifyContent: "flex-end",
              gap: 2,
            }}
          >
            <Button
              onClick={onClear}
              sx={{
                color: PURPLE,
                fontWeight: 700,
                textTransform: "none",
              }}
            >
              Clear Filters
            </Button>
  
            <Button
              onClick={onApply}
              variant="contained"
              sx={{
                background: "linear-gradient(135deg, #1B2447, #C16345)",
                px: 4,
                py: 1.4,
                fontWeight: 800,
                borderRadius: 3,
                textTransform: "none",
                boxShadow: "0 10px 30px rgba(124,58,237,0.45)",
              }}
            >
              Apply Filters
            </Button>
          </Box>
        </Box>
      </Collapse>
    );
  }
  