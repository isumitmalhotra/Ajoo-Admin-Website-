import {
  Box,
  Button,
  Stack,
  Typography,
  TextField,
  MenuItem,
} from "@mui/material";
import { LocalizationProvider } from "@mui/x-date-pickers/LocalizationProvider";
import { DatePicker } from "@mui/x-date-pickers/DatePicker";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";

const FOCUS_COLOR = "#1B2447";

interface Props {
  ThemeColors: { primary: string };
  filterData: any;
  handleFilterUpdate: (key: string, value: any, autoApply?: boolean) => void;
  handleFilter: () => void;
  handleClear: () => void;
  handleFormShow: () => void;

  statusList: {
    bs_id: number;
    bs_title: string;
    bs_code: string | null;
  }[];
  statusLoading: boolean;
}

const commonFieldSx = {
  minWidth: 180,
  "& .MuiOutlinedInput-root": {
    "&.Mui-focused fieldset": {
      borderColor: FOCUS_COLOR,
    },
  },
  "& .MuiInputLabel-root.Mui-focused": {
    color: FOCUS_COLOR,
  },
};

const menuProps = {
  PaperProps: {
    sx: {
      borderRadius: 2,
      mt: 1,
      "& .MuiMenuItem-root": {
        fontSize: "0.85rem",
        "&.Mui-selected": {
          backgroundColor: `${FOCUS_COLOR}15`,
          color: FOCUS_COLOR,
        },
        "&:hover": {
          backgroundColor: `${FOCUS_COLOR}10`,
        },
      },
    },
  },
};

const AdminBookingHeader = ({
  ThemeColors,
  filterData,
  handleFilterUpdate,
  handleFilter,
  handleClear,
  statusList,
  statusLoading,
}: Props) => {
  return (
    <Box mb={4}>
      {/* HEADER */}
      <Box display="flex" justifyContent="space-between" mb={3} flexWrap="wrap">
        <Typography variant="h4" fontWeight={700} color={ThemeColors.primary}>
          Bookings Management
        </Typography>
      </Box>

      {/* FILTERS */}
      <LocalizationProvider dateAdapter={AdapterDayjs}>
        <Box display="flex" gap={2} flexWrap="wrap" alignItems="center">
          {/* SEARCH */}
          <TextField
            label="Search bookings"
            size="small"
            value={filterData.keyword}
            onChange={(e) => handleFilterUpdate("keyword", e.target.value)}
            sx={{ ...commonFieldSx, minWidth: 220 }}
          />

          {/* BOOKING STATUS */}
          <TextField
            label="Booking Status"
            select
            size="small"
            value={filterData.bookingStatus}
            onChange={(e) =>
              handleFilterUpdate("bookingStatus", e.target.value, true)
            }
            sx={commonFieldSx}
            SelectProps={{ MenuProps: menuProps }}
            disabled={statusLoading}
          >
            <MenuItem value="">All</MenuItem>

            {statusList.map((status) => (
              <MenuItem key={status.bs_id} value={status.bs_id}>
                <Box display="flex" alignItems="center" gap={1}>
                  {status.bs_code && (
                    <Box
                      sx={{
                        width: 10,
                        height: 10,
                        borderRadius: "50%",
                        bgcolor: status.bs_code,
                      }}
                    />
                  )}
                  {status.bs_title}
                </Box>
              </MenuItem>
            ))}
          </TextField>

          {/* PAYMENT STATUS */}
          <TextField
            label="Payment Status"
            select
            size="small"
            value={filterData.paymentStatus}
            onChange={(e) =>
              handleFilterUpdate("paymentStatus", e.target.value, true)
            }
            sx={commonFieldSx}
            SelectProps={{ MenuProps: menuProps }}
          >
            <MenuItem value="">All</MenuItem>
            <MenuItem value="paid">Paid</MenuItem>
            <MenuItem value="unpaid">Unpaid</MenuItem>
          </TextField>

          {/* FROM DATE */}
          <DatePicker
            label="From Date"
            value={filterData.fromDate}
            onChange={(value) => handleFilterUpdate("fromDate", value, true)}
            slotProps={{
              textField: {
                size: "small",
                sx: commonFieldSx,
              },
            }}
          />

          {/* TO DATE */}
          <DatePicker
            label="To Date"
            value={filterData.toDate}
            onChange={(value) => handleFilterUpdate("toDate", value, true)}
            slotProps={{
              textField: {
                size: "small",
                sx: commonFieldSx,
              },
            }}
          />

          {/* ACTION BUTTONS */}
          <Stack direction="row" spacing={1}>
            <Button
              variant="contained"
              sx={{ backgroundColor: ThemeColors.primary }}
              onClick={handleFilter}
            >
              Search
            </Button>

            <Button
              variant="outlined"
              onClick={handleClear}
              sx={{
                borderColor: FOCUS_COLOR,
                color: FOCUS_COLOR,
                "&:hover": {
                  borderColor: FOCUS_COLOR,
                  backgroundColor: `${FOCUS_COLOR}10`,
                },
              }}
            >
              Clear
            </Button>
          </Stack>
        </Box>
      </LocalizationProvider>
    </Box>
  );
};

export default AdminBookingHeader;
