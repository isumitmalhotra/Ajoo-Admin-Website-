import { TextField, InputAdornment } from "@mui/material";
import { Search as SearchIcon } from "@mui/icons-material";

interface SearchBarProps {
  placeholder?: string;
  value: string;
  onChange: (val: string) => void;
  color?: string;
}

export default function SearchBar({ placeholder, value, onChange, color = "#1B2447" }: SearchBarProps) {
  return (
    <TextField
      fullWidth
      placeholder={placeholder}
      value={value}
      // onChange={(e) => onChange(e.target.value)}
      onChange={(e) => onChange(e.target.value)}
      InputProps={{
        startAdornment: (
          <InputAdornment position="start">
            <SearchIcon sx={{ color }} />
          </InputAdornment>
        ),
      }}
      sx={{
        "& .MuiOutlinedInput-root": {
          borderRadius: 3,
          "&:hover fieldset": { borderColor: color },
          "&.Mui-focused fieldset": { borderColor: color },
        },
      }}
    />
  );
}
