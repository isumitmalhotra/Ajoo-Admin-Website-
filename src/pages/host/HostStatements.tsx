import { useEffect, useMemo, useState } from "react";
import {
  Alert,
  Box,
  Button,
  Chip,
  CircularProgress,
  MenuItem,
  Paper,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import DownloadRoundedIcon from "@mui/icons-material/DownloadRounded";
import { useAppDispatch, useAppSelector } from "../../app/hooks";
import { fetchHostStatements } from "../../features/host/hostStatements.slice";

const formatINR = (amount: number) => `INR ${amount.toLocaleString("en-IN")}`;

export default function HostStatements() {
  const dispatch = useAppDispatch();
  const { items, loading, error } = useAppSelector((state) => state.hostStatements);
  const [statusFilter, setStatusFilter] = useState<"ALL" | "READY" | "PROCESSING">("ALL");

  useEffect(() => {
    dispatch(fetchHostStatements());
  }, [dispatch]);

  const rows = useMemo(() => {
    if (statusFilter === "ALL") return items;
    return items.filter((row) => row.status === statusFilter);
  }, [statusFilter, items]);

  return (
    <Stack spacing={2}>
      <Paper
        elevation={0}
        sx={{
          p: 2.6,
          borderRadius: "1rem",
          border: "1px solid #FFFAF0",
          boxShadow: "0 12px 28px rgba(17,24,39,0.05)",
        }}
      >
        <Stack
          direction={{ xs: "column", sm: "row" }}
          spacing={1.4}
          alignItems={{ xs: "flex-start", sm: "center" }}
          justifyContent="space-between"
        >
          <Box>
            <Typography variant="h6" fontWeight={800} color="#111827">
              Host Statements
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Download monthly payout statements and review deductions clearly.
            </Typography>
          </Box>
          <TextField
            select
            size="small"
            label="Status"
            value={statusFilter}
            onChange={(event) =>
              setStatusFilter(event.target.value as "ALL" | "READY" | "PROCESSING")
            }
            sx={{ minWidth: 160 }}
          >
            <MenuItem value="ALL">All</MenuItem>
            <MenuItem value="READY">Ready</MenuItem>
            <MenuItem value="PROCESSING">Processing</MenuItem>
          </TextField>
        </Stack>
      </Paper>

      {error && (
        <Alert severity="error" sx={{ borderRadius: "0.8rem" }}>
          {error}
        </Alert>
      )}

      {loading ? (
        <Paper
          elevation={0}
          sx={{
            p: 6,
            borderRadius: "1rem",
            border: "1px solid #FFFAF0",
            display: "flex",
            justifyContent: "center",
          }}
        >
          <CircularProgress size={28} sx={{ color: "#2A356B" }} />
        </Paper>
      ) : (
      <Paper
        elevation={0}
        sx={{ p: 2.2, borderRadius: "1rem", border: "1px solid #FFFAF0", overflowX: "auto" }}
      >
        <table style={{ width: "100%", borderCollapse: "collapse" }}>
          <thead>
            <tr>
              {["Statement", "Period", "Generated On", "Bookings", "Gross", "Deductions", "Net", "Status", ""].map(
                (header) => (
                  <th
                    key={header}
                    style={{
                      textAlign: "left",
                      padding: "11px 10px",
                      borderBottom: "1px solid #e5e7eb",
                      color: "#6b7280",
                      fontSize: "0.8rem",
                    }}
                  >
                    {header}
                  </th>
                )
              )}
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.id}>
                <td style={{ padding: "11px 10px", borderBottom: "1px solid #f3f4f6", fontWeight: 700 }}>
                  {row.id}
                </td>
                <td style={{ padding: "11px 10px", borderBottom: "1px solid #f3f4f6" }}>{row.period}</td>
                <td style={{ padding: "11px 10px", borderBottom: "1px solid #f3f4f6" }}>
                  {new Date(row.generatedOn).toLocaleDateString("en-IN")}
                </td>
                <td style={{ padding: "11px 10px", borderBottom: "1px solid #f3f4f6" }}>{row.totalBookings}</td>
                <td style={{ padding: "11px 10px", borderBottom: "1px solid #f3f4f6" }}>{formatINR(row.grossEarnings)}</td>
                <td style={{ padding: "11px 10px", borderBottom: "1px solid #f3f4f6", color: "#b45309" }}>
                  {formatINR(row.deductions)}
                </td>
                <td style={{ padding: "11px 10px", borderBottom: "1px solid #f3f4f6", fontWeight: 700 }}>
                  {formatINR(row.netPayout)}
                </td>
                <td style={{ padding: "11px 10px", borderBottom: "1px solid #f3f4f6" }}>
                  <Chip
                    size="small"
                    label={row.status}
                    sx={{
                      bgcolor: row.status === "READY" ? "#dcfce7" : "#fef3c7",
                      color: row.status === "READY" ? "#166534" : "#92400e",
                    }}
                  />
                </td>
                <td style={{ padding: "11px 10px", borderBottom: "1px solid #f3f4f6" }}>
                  <Button
                    size="small"
                    variant="outlined"
                    disabled={row.status !== "READY"}
                    startIcon={<DownloadRoundedIcon fontSize="small" />}
                  >
                    Download
                  </Button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {rows.length === 0 && (
          <Typography variant="body2" color="text.secondary" sx={{ p: 2 }}>
            {items.length === 0
              ? "No statements available yet. Your monthly payout statements will appear here."
              : "No statements found for the selected filter."}
          </Typography>
        )}
      </Paper>
      )}
    </Stack>
  );
}
