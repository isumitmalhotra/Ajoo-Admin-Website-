import { useEffect } from "react";
import {
  Alert,
  AlertTitle,
  Box,
  Button,
  Chip,
  MenuItem,
  Paper,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import { useAppDispatch, useAppSelector } from "../../app/hooks";
import {
  fetchHostEarnings,
  type HostEarningsData,
  type HostPayoutRow,
} from "../../features/host/hostEarnings.slice";
import { useMemo, useState } from "react";
import { API_BASE_URL } from "../../configs/apiConfigs";

const USE_DEV_HOST_MOCKS =
  import.meta.env.DEV && import.meta.env.VITE_USE_HOST_MOCKS === "true";

const MOCK_EARNINGS: HostEarningsData = {
  totalEarnings: 186500,
  pendingPayouts: 27500,
  settledPayouts: 159000,
  lastPayoutAmount: 18300,
  nextPayoutDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString(),
  payoutHistory: [
    {
      payout_id: 501,
      booking_id: 9901,
      amount: 18300,
      status: "COMPLETED",
      payout_date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
      reference_id: "PAY-501",
    },
    {
      payout_id: 502,
      booking_id: 9904,
      amount: 11200,
      status: "PENDING",
      payout_date: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
      reference_id: "PAY-502",
    },
    {
      payout_id: 503,
      booking_id: 9910,
      amount: 9200,
      status: "COMPLETED",
      payout_date: new Date(Date.now() - 12 * 24 * 60 * 60 * 1000).toISOString(),
      reference_id: "PAY-503",
    },
    {
      payout_id: 504,
      booking_id: 9913,
      amount: 14750,
      status: "ON_HOLD",
      payout_date: new Date(Date.now() - 6 * 24 * 60 * 60 * 1000).toISOString(),
      reference_id: "PAY-504",
    },
  ],
};

const toNumber = (value: unknown) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
};

const normalizePayoutRows = (value: unknown): HostPayoutRow[] => {
  if (!Array.isArray(value)) return [];

  return value.map((row: any) => ({
    payout_id: row?.payout_id || row?.payoutId || row?.id,
    booking_id: row?.booking_id || row?.bookingId,
    amount: toNumber(row?.amount),
    status: String(row?.status || row?.payout_status || "PENDING").toUpperCase(),
    payout_date: row?.payout_date || row?.payoutDate || row?.created_at || null,
    reference_id: row?.reference_id || row?.referenceId || row?.utr || "-",
  }));
};

const normalizeEarnings = (raw: HostEarningsData | null): HostEarningsData => {
  const data = raw || {};

  return {
    totalEarnings: toNumber((data as any)?.totalEarnings ?? (data as any)?.total_earnings),
    pendingPayouts: toNumber((data as any)?.pendingPayouts ?? (data as any)?.pending_payouts),
    settledPayouts: toNumber((data as any)?.settledPayouts ?? (data as any)?.settled_payouts),
    lastPayoutAmount: toNumber(
      (data as any)?.lastPayoutAmount ?? (data as any)?.last_payout_amount
    ),
    nextPayoutDate: (data as any)?.nextPayoutDate || (data as any)?.next_payout_date || "",
    payoutHistory: normalizePayoutRows(
      (data as any)?.payoutHistory || (data as any)?.payout_history || (data as any)?.recentPayouts
    ),
  };
};

const statusChipColor = (
  status: string
): "success" | "warning" | "error" | "info" | "default" => {
  const normalized = status.toLowerCase();
  if (normalized === "completed") return "success";
  if (normalized === "pending") return "warning";
  if (normalized === "on_hold") return "error";
  if (normalized === "processing") return "info";
  return "default";
};

const statusLabel = (status: string) =>
  status
    .toLowerCase()
    .replace(/_/g, " ")
    .replace(/\b\w/g, (char) => char.toUpperCase());

export default function HostEarnings() {
  const dispatch = useAppDispatch();
  const { data, loading, error } = useAppSelector((state) => state.hostEarnings);
  const [statusFilter, setStatusFilter] = useState("ALL");

  useEffect(() => {
    dispatch(fetchHostEarnings());
  }, [dispatch]);

  const showMockData = Boolean(error) && USE_DEV_HOST_MOCKS;
  const effectiveData = normalizeEarnings(showMockData ? MOCK_EARNINGS : data);

  const isConnectivityIssue =
    Boolean(error) && /unable to reach|network|failed to fetch|connect/i.test(error || "");

  const filteredPayouts = useMemo(() => {
    const rows = effectiveData.payoutHistory || [];
    if (statusFilter === "ALL") return rows;
    return rows.filter((row) => (row.status || "").toUpperCase() === statusFilter);
  }, [effectiveData.payoutHistory, statusFilter]);

  const handleRetry = () => {
    dispatch(fetchHostEarnings());
  };

  return (
    <Stack spacing={2.5}>
      <Paper sx={{ p: 3, borderRadius: 2 }} elevation={0}>
        <Typography variant="h6" fontWeight={700}>
          Earnings and Payouts
        </Typography>
        <Typography variant="body2" color="text.secondary" mt={0.5}>
          Summary of host earnings, payout progress, and settlement history.
        </Typography>

        {error && !showMockData && (
          <Alert
            sx={{ mt: 2 }}
            severity="warning"
            action={
              <Button color="inherit" size="small" onClick={handleRetry}>
                Retry
              </Button>
            }
          >
            <AlertTitle>Host earnings data unavailable</AlertTitle>
            <Typography variant="body2">{error}</Typography>
            {isConnectivityIssue && (
              <Typography variant="caption" sx={{ display: "block", mt: 0.5 }}>
                Check backend availability and API base URL: {API_BASE_URL}
              </Typography>
            )}
          </Alert>
        )}

        {error && showMockData && (
          <Alert sx={{ mt: 2 }} severity="info" action={<Button color="inherit" size="small" onClick={handleRetry}>Retry API</Button>}>
            Backend host earnings API is unavailable. Showing local mock earnings data.
          </Alert>
        )}

        <Box
          sx={{
            mt: 2,
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(210px, 1fr))",
            gap: 1.5,
          }}
        >
          <Paper variant="outlined" sx={{ p: 1.5 }}>
            <Typography variant="caption" color="text.secondary">
              Total Earnings
            </Typography>
            <Typography variant="h6" fontWeight={700}>
              INR {loading && !showMockData ? "..." : effectiveData.totalEarnings ?? 0}
            </Typography>
          </Paper>

          <Paper variant="outlined" sx={{ p: 1.5 }}>
            <Typography variant="caption" color="text.secondary">
              Pending Payouts
            </Typography>
            <Typography variant="h6" fontWeight={700}>
              INR {loading && !showMockData ? "..." : effectiveData.pendingPayouts ?? 0}
            </Typography>
          </Paper>

          <Paper variant="outlined" sx={{ p: 1.5 }}>
            <Typography variant="caption" color="text.secondary">
              Settled Payouts
            </Typography>
            <Typography variant="h6" fontWeight={700}>
              INR {loading && !showMockData ? "..." : effectiveData.settledPayouts ?? 0}
            </Typography>
          </Paper>

          <Paper variant="outlined" sx={{ p: 1.5 }}>
            <Typography variant="caption" color="text.secondary">
              Last Payout
            </Typography>
            <Typography variant="h6" fontWeight={700}>
              INR {loading && !showMockData ? "..." : effectiveData.lastPayoutAmount ?? 0}
            </Typography>
            <Typography variant="caption" color="text.secondary" display="block" mt={0.5}>
              Next: {effectiveData.nextPayoutDate ? new Date(effectiveData.nextPayoutDate).toLocaleDateString() : "-"}
            </Typography>
          </Paper>
        </Box>
      </Paper>

      <Paper sx={{ p: 3, borderRadius: 2 }} elevation={0}>
        <Stack
          direction={{ xs: "column", sm: "row" }}
          spacing={1.5}
          alignItems={{ xs: "flex-start", sm: "center" }}
          justifyContent="space-between"
        >
          <Typography variant="subtitle1" fontWeight={700}>
            Payout History
          </Typography>
          <TextField
            select
            size="small"
            label="Status"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            sx={{ minWidth: 180 }}
          >
            <MenuItem value="ALL">All</MenuItem>
            <MenuItem value="COMPLETED">Completed</MenuItem>
            <MenuItem value="PENDING">Pending</MenuItem>
            <MenuItem value="ON_HOLD">On Hold</MenuItem>
            <MenuItem value="PROCESSING">Processing</MenuItem>
          </TextField>
        </Stack>

        {loading && !showMockData ? (
          <Typography variant="body2" color="text.secondary" mt={1.5}>
            Loading payout history...
          </Typography>
        ) : filteredPayouts.length === 0 ? (
          <Typography variant="body2" color="text.secondary" mt={1.5}>
            No payout records found for the selected filter.
          </Typography>
        ) : (
          <Box sx={{ mt: 2, overflowX: "auto" }}>
            <table style={{ width: "100%", borderCollapse: "collapse" }}>
              <thead>
                <tr>
                  {["Payout ID", "Booking", "Amount", "Status", "Payout Date", "Reference"].map(
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
                {filteredPayouts.map((row, index) => (
                  <tr key={`${row.payout_id || "payout"}-${index}`}>
                    <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                      #{row.payout_id || "-"}
                    </td>
                    <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                      #{row.booking_id || "-"}
                    </td>
                    <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                      INR {row.amount ?? 0}
                    </td>
                    <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                      <Chip
                        size="small"
                        label={statusLabel(String(row.status || "PENDING"))}
                        color={statusChipColor(String(row.status || "PENDING"))}
                        variant="outlined"
                      />
                    </td>
                    <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                      {row.payout_date ? new Date(row.payout_date).toLocaleDateString() : "-"}
                    </td>
                    <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                      {row.reference_id || "-"}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Box>
        )}
      </Paper>
    </Stack>
  );
}
