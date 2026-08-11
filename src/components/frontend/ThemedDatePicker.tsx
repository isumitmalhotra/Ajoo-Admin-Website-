import React from "react";
import { LocalizationProvider } from "@mui/x-date-pickers/LocalizationProvider";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
import { DatePicker } from "@mui/x-date-pickers/DatePicker";
import { ThemeProvider, createTheme } from "@mui/material/styles";
import dayjs, { Dayjs } from "dayjs";

const INDIGO = "#1B2447";
const TERRA = "#C16345";

// Local Sand & Indigo theme for the calendar popup so it matches the site.
const pickerTheme = createTheme({
  palette: { primary: { main: INDIGO }, secondary: { main: TERRA } },
  shape: { borderRadius: 12 },
  typography: { fontFamily: "'Inter', system-ui, sans-serif" },
});

interface ThemedDatePickerProps {
  label: string;
  value: string; // ISO yyyy-mm-dd (matches the existing string form state)
  onChange: (value: string) => void;
  error?: boolean;
  helperText?: string;
  required?: boolean;
  disableFuture?: boolean;
  minDate?: Dayjs;
  maxDate?: Dayjs;
}

/**
 * App-wide date picker with a themed (Sand & Indigo) calendar. Drop-in for the
 * old native <input type="date"> — works with the same yyyy-mm-dd string state.
 * Uses the dayjs adapter to stay consistent with the rest of the app.
 */
const ThemedDatePicker: React.FC<ThemedDatePickerProps> = ({
  label,
  value,
  onChange,
  error,
  helperText,
  required,
  disableFuture,
  minDate,
  maxDate,
}) => (
  <ThemeProvider theme={pickerTheme}>
    <LocalizationProvider dateAdapter={AdapterDayjs}>
      <DatePicker
        label={label}
        value={value ? dayjs(value) : null}
        onChange={(d) => onChange(d ? (d as Dayjs).format("YYYY-MM-DD") : "")}
        disableFuture={disableFuture}
        minDate={minDate}
        maxDate={maxDate}
        format="DD-MM-YYYY"
        slotProps={{
          textField: {
            fullWidth: true,
            required,
            error,
            helperText,
            sx: {
              "& .MuiOutlinedInput-root": {
                borderRadius: "12px",
                "&:hover fieldset": { borderColor: INDIGO },
                "&.Mui-focused fieldset": { borderColor: INDIGO },
              },
              "& label": { color: INDIGO, fontWeight: 600 },
              "& .MuiInputLabel-root.Mui-focused": { color: INDIGO },
              "& .MuiFormLabel-asterisk": { color: INDIGO },
            },
          },
        }}
      />
    </LocalizationProvider>
  </ThemeProvider>
);

export default ThemedDatePicker;
