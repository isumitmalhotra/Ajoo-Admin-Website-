import { useEffect } from "react";
import {
  Alert,
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  MenuItem,
  Paper,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import { useAppDispatch, useAppSelector } from "../../app/hooks";
import {
  fetchHostBookings,
  resetHostBookingsFilters,
  setHostBookingsFilters,
} from "../../features/host/hostBookings.slice";
import { Pagination } from "../../components";
import { useState } from "react";

export default function HostBookings() {
  const dispatch = useAppDispatch();
  const { data, loading, error, totalPages, currentPage, filters } = useAppSelector(
    (state) => state.hostBookings
  );
  const [selectedBooking, setSelectedBooking] = useState<any | null>(null);

  const loadPage = (page: number) => {
    dispatch(
      fetchHostBookings({
        page,
        limit: 10,
        search: filters.search,
        status: filters.status,
        dateFrom: filters.dateFrom,
        dateTo: filters.dateTo,
      })
    );
  };

  useEffect(() => {
    loadPage(1);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dispatch]);

  const handleFilter = () => {
    loadPage(1);
  };

  const handleReset = () => {
    dispatch(resetHostBookingsFilters());
    setTimeout(() => loadPage(1), 0);
  };

  return (
    <Paper sx={{ p: 3, borderRadius: 2 }} elevation={0}>
      <Typography variant="h6" fontWeight={700}>
        Host Bookings
      </Typography>

      <Stack direction={{ xs: "column", md: "row" }} spacing={1.5} mt={2}>
        <TextField
          size="small"
          label="Search"
          value={filters.search}
          onChange={(e) =>
            dispatch(setHostBookingsFilters({ search: e.target.value }))
          }
          sx={{ minWidth: 220 }}
        />

        <TextField
          size="small"
          select
          label="Status"
          value={filters.status}
          onChange={(e) =>
            dispatch(setHostBookingsFilters({ status: e.target.value }))
          }
          sx={{ minWidth: 160 }}
        >
          <MenuItem value="">All</MenuItem>
          <MenuItem value="PENDING">Pending</MenuItem>
          <MenuItem value="CONFIRMED">Confirmed</MenuItem>
          <MenuItem value="COMPLETED">Completed</MenuItem>
          <MenuItem value="CANCELLED">Cancelled</MenuItem>
        </TextField>

        <TextField
          size="small"
          type="date"
          label="From"
          value={filters.dateFrom}
          onChange={(e) =>
            dispatch(setHostBookingsFilters({ dateFrom: e.target.value }))
          }
          slotProps={{ inputLabel: { shrink: true } }}
        />

        <TextField
          size="small"
          type="date"
          label="To"
          value={filters.dateTo}
          onChange={(e) =>
            dispatch(setHostBookingsFilters({ dateTo: e.target.value }))
          }
          slotProps={{ inputLabel: { shrink: true } }}
        />

        <Button variant="contained" onClick={handleFilter} sx={{ bgcolor: "#881f9b" }}>
          Apply
        </Button>
        <Button variant="outlined" onClick={handleReset}>
          Reset
        </Button>
      </Stack>

      {error && (
        <Alert sx={{ mt: 2 }} severity="warning">
          {error}
        </Alert>
      )}

      {loading ? (
        <Typography variant="body2" color="text.secondary" mt={1}>
          Loading host bookings...
        </Typography>
      ) : data.length === 0 ? (
        <Typography variant="body2" color="text.secondary" mt={1}>
          No bookings found for this host account.
        </Typography>
      ) : (
        <Box sx={{ mt: 2, overflowX: "auto" }}>
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr>
                {["Booking", "Property", "Guest", "Check-in", "Check-out", "Amount", "Status", ""].map(
                  (head) => (
                    <th
                      key={head}
                      style={{
                        textAlign: "left",
                        padding: "10px",
                        borderBottom: "1px solid #e5e7eb",
                        color: "#6b7280",
                        fontSize: "0.8rem",
                      }}
                    >
                      {head}
                    </th>
                  )
                )}
              </tr>
            </thead>
            <tbody>
              {data.map((booking: any) => (
                <tr key={booking.booking_id}>
                  <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                    #{booking.booking_id}
                  </td>
                  <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                    {booking.property_name || "-"}
                  </td>
                  <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                    {booking.guest_name || "-"}
                  </td>
                  <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                    {booking.check_in ? new Date(booking.check_in).toLocaleDateString() : "-"}
                  </td>
                  <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                    {booking.check_out ? new Date(booking.check_out).toLocaleDateString() : "-"}
                  </td>
                  <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                    INR {booking.amount ?? 0}
                  </td>
                  <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                    {booking.status || "-"}
                  </td>
                  <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                    <Button
                      size="small"
                      variant="outlined"
                      onClick={() => setSelectedBooking(booking)}
                    >
                      View
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Box>
      )}

      <Box sx={{ mt: 2, display: "flex", justifyContent: "center" }}>
        <Pagination
          count={Math.max(totalPages, 1)}
          page={Math.max(currentPage, 1)}
          onChange={(_, page) => loadPage(page)}
        />
      </Box>

      <Dialog
        open={Boolean(selectedBooking)}
        onClose={() => setSelectedBooking(null)}
        fullWidth
        maxWidth="sm"
      >
        <DialogTitle>Booking Detail</DialogTitle>
        <DialogContent dividers>
          {selectedBooking && (
            <Stack spacing={1.2}>
              <Typography><strong>ID:</strong> #{selectedBooking.booking_id}</Typography>
              <Typography><strong>Property:</strong> {selectedBooking.property_name || "-"}</Typography>
              <Typography><strong>Guest:</strong> {selectedBooking.guest_name || "-"}</Typography>
              <Typography><strong>Status:</strong> {selectedBooking.status || "-"}</Typography>
              <Typography>
                <strong>Check-in:</strong> {selectedBooking.check_in ? new Date(selectedBooking.check_in).toLocaleDateString() : "-"}
              </Typography>
              <Typography>
                <strong>Check-out:</strong> {selectedBooking.check_out ? new Date(selectedBooking.check_out).toLocaleDateString() : "-"}
              </Typography>
              <Typography><strong>Amount:</strong> INR {selectedBooking.amount ?? 0}</Typography>
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSelectedBooking(null)}>Close</Button>
        </DialogActions>
      </Dialog>
    </Paper>
  );
}
