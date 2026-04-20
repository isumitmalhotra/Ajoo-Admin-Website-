import { useEffect } from "react";
import { Alert, Paper, Stack, Typography } from "@mui/material";
import { useAppDispatch, useAppSelector } from "../../app/hooks";
import { fetchHostBookings } from "../../features/host/hostBookings.slice";

export default function HostBookings() {
  const dispatch = useAppDispatch();
  const { data, loading, error } = useAppSelector((state) => state.hostBookings);

  useEffect(() => {
    dispatch(fetchHostBookings({ page: 1, limit: 10 }));
  }, [dispatch]);

  return (
    <Paper sx={{ p: 3, borderRadius: 2 }} elevation={0}>
      <Typography variant="h6" fontWeight={700}>
        Host Bookings
      </Typography>

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
        <Stack spacing={1.25} mt={2}>
          {data.slice(0, 6).map((booking) => (
            <Paper key={booking.booking_id} variant="outlined" sx={{ p: 1.5 }}>
              <Typography fontWeight={600}>
                Booking #{booking.booking_id}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {booking.property_name || "Property"} | {booking.status || "Pending"}
              </Typography>
            </Paper>
          ))}
        </Stack>
      )}
    </Paper>
  );
}
