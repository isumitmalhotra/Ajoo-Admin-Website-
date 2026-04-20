import { Paper, Typography } from "@mui/material";

export default function HostSupport() {
  return (
    <Paper sx={{ p: 3, borderRadius: 2 }} elevation={0}>
      <Typography variant="h6" fontWeight={700}>
        Host Support
      </Typography>
      <Typography variant="body2" color="text.secondary" mt={1}>
        HMS-4002: support tickets and communication workflow will be implemented here.
      </Typography>
    </Paper>
  );
}
