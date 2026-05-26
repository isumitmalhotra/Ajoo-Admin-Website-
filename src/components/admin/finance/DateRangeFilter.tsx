import { TextField, Stack, InputAdornment } from "@mui/material";
import { CalendarDays } from "lucide-react";

interface DateRangeFilterProps {
  dateFrom: string;
  dateTo: string;
  onChange: (from: string, to: string) => void;
}

const DateRangeFilter = ({ dateFrom, dateTo, onChange }: DateRangeFilterProps) => {
  return (
    <Stack
      direction={{ xs: "column", sm: "row" }}
      spacing={1.25}
      alignItems={{ xs: "stretch", sm: "center" }}
      sx={{ width: { xs: "100%", sm: "auto" } }}
    >
      <TextField
        type="date"
        size="small"
        label="From"
        value={dateFrom}
        onChange={(e) => onChange(e.target.value, dateTo)}
        slotProps={{
          inputLabel: { shrink: true },
          input: {
            startAdornment: (
              <InputAdornment position="start">
                <CalendarDays size={15} color="#9ca3af" />
              </InputAdornment>
            ),
          },
        }}
        sx={{
          width: { xs: "100%", sm: 170 },
          "& .MuiOutlinedInput-root": { borderRadius: "0.7rem" },
        }}
      />
      <TextField
        type="date"
        size="small"
        label="To"
        value={dateTo}
        onChange={(e) => onChange(dateFrom, e.target.value)}
        slotProps={{
          inputLabel: { shrink: true },
          input: {
            startAdornment: (
              <InputAdornment position="start">
                <CalendarDays size={15} color="#9ca3af" />
              </InputAdornment>
            ),
          },
        }}
        sx={{
          width: { xs: "100%", sm: 170 },
          "& .MuiOutlinedInput-root": { borderRadius: "0.7rem" },
        }}
      />
    </Stack>
  );
};

export default DateRangeFilter;
