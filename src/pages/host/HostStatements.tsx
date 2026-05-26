import { useMemo, useState } from "react";
import {
  Box,
  Button,
  Chip,
  MenuItem,
  Paper,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import DownloadRoundedIcon from "@mui/icons-material/DownloadRounded";

type StatementRow = {
  id: string;
  period: string;
  generatedOn: string;
  totalBookings: number;
  grossEarnings: number;
  deductions: number;
  netPayout: number;
  status: "READY" | "PROCESSING";
};

const MOCK_STATEMENTS: StatementRow[] = [
  {
    id: "STM-2405",
    period: "May 2026",
    generatedOn: "2026-05-13",
    totalBookings: 18,
    grossEarnings: 214000,
    deductions: 32000,
    netPayout: 182000,
    status: "READY",
  },
  {
    id: "STM-2404",
    period: "Apr 2026",
    generatedOn: "2026-04-12",
    totalBookings: 16,
    grossEarnings: 196500,
    deductions: 27600,
    netPayout: 168900,
    status: "READY",
  },
  {
    id: "STM-2403",
    period: "Mar 2026",
    generatedOn: "2026-03-11",
    totalBookings: 14,
    grossEarnings: 173400,
    deductions: 24600,
    netPayout: 148800,
    status: "PROCESSING",
  },
];

const formatINR = (amount: number) => `INR ${amount.toLocaleString("en-IN")}`;

export default function HostStatements() {
  const [statusFilter, setStatusFilter] = useState<"ALL" | "READY" | "PROCESSING">("ALL");

  const rows = useMemo(() => {
    if (statusFilter === "ALL") return MOCK_STATEMENTS;
    return MOCK_STATEMENTS.filter((row) => row.status === statusFilter);
  }, [statusFilter]);

  return (
    <Stack spacing={2}>
      <Paper
        elevation={0}
        sx={{
          p: 2.6,
          borderRadius: "1rem",
          border: "1px solid #ede9fe",
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

      <Paper
        elevation={0}
        sx={{ p: 2.2, borderRadius: "1rem", border: "1px solid #ede9fe", overflowX: "auto" }}
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
            No statements found for the selected filter.
          </Typography>
        )}
      </Paper>
    </Stack>
  );
}
