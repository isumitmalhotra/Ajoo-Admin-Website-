import { TextField, Stack } from "@mui/material";

interface DateRangeFilterProps {
  dateFrom: string;
  dateTo: string;
  onChange: (from: string, to: string) => void;
}

const DateRangeFilter = ({ dateFrom, dateTo, onChange }: DateRangeFilterProps) => {
  return (
    <Stack direction="row" spacing={1} alignItems="center">
      <TextField
        type="date"
        size="small"
        label="From"
        value={dateFrom}
        onChange={(e) => onChange(e.target.value, dateTo)}
        slotProps={{ inputLabel: { shrink: true } }}
        sx={{ width: 160 }}
      />
      <TextField
        type="date"
        size="small"
        label="To"
        value={dateTo}
        onChange={(e) => onChange(dateFrom, e.target.value)}
        slotProps={{ inputLabel: { shrink: true } }}
        sx={{ width: 160 }}
      />
    </Stack>
  );
};

export default DateRangeFilter;
