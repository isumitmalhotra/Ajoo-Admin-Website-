import { useEffect } from "react";
import { Alert, Paper, Stack, Typography } from "@mui/material";
import { useAppDispatch, useAppSelector } from "../../app/hooks";
import { fetchHostProfile } from "../../features/host/hostProfile.slice";

export default function HostProfile() {
  const dispatch = useAppDispatch();
  const { data, loading, error } = useAppSelector((state) => state.hostProfile);

  useEffect(() => {
    dispatch(fetchHostProfile());
  }, [dispatch]);

  return (
    <Paper sx={{ p: 3, borderRadius: 2 }} elevation={0}>
      <Typography variant="h6" fontWeight={700}>
        Host Profile and Banking
      </Typography>

      {error && (
        <Alert sx={{ mt: 2 }} severity="warning">
          {error}
        </Alert>
      )}

      {loading ? (
        <Typography variant="body2" color="text.secondary" mt={1}>
          Loading profile...
        </Typography>
      ) : (
        <Stack spacing={1.25} mt={2}>
          <Typography variant="body2">
            <strong>Name:</strong> {data?.fullName || "-"}
          </Typography>
          <Typography variant="body2">
            <strong>Email:</strong> {data?.email || "-"}
          </Typography>
          <Typography variant="body2">
            <strong>Phone:</strong> {data?.phone || "-"}
          </Typography>
          <Typography variant="body2">
            <strong>City:</strong> {data?.city || "-"}
          </Typography>
          <Typography variant="body2">
            <strong>Bank:</strong> {data?.bankName || "-"}
          </Typography>
          <Typography variant="body2">
            <strong>Account:</strong> {data?.accountNumber || "-"}
          </Typography>
          <Typography variant="body2">
            <strong>UPI:</strong> {data?.upiId || "-"}
          </Typography>
        </Stack>
      )}
    </Paper>
  );
}
