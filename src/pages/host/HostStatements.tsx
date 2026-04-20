import { Paper, Typography } from "@mui/material";

export default function HostStatements() {
  return (
    <Paper sx={{ p: 3, borderRadius: 2 }} elevation={0}>
      <Typography variant="h6" fontWeight={700}>
        Host Statements
      </Typography>
      <Typography variant="body2" color="text.secondary" mt={1}>
        HMS-3004: statements list and download actions will be added here.
      </Typography>
    </Paper>
  );
}
