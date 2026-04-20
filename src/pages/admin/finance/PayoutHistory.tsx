import { useEffect, useState, useMemo } from "react";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import { fetchPayoutList } from "../../../features/admin/finance/payoutList.slice";
import {
  Box,
  Paper,
  Typography,
  Stack,
  Tabs,
  Tab,
  Tooltip,
  Chip,
} from "@mui/material";
import { Pagination } from "../../../components";
import { TableLoader } from "../../../components/admin/common/TableLoader";
import FinanceStatusChip from "../../../components/admin/finance/FinanceStatusChip";
import ExportButton from "../../../components/admin/finance/ExportButton";
import FinanceEmptyState from "../../../components/admin/finance/FinanceEmptyState";
import FinanceErrorAlert from "../../../components/admin/finance/FinanceErrorAlert";
import type { PayoutStatus } from "./types";
import { formatINR } from "./utils";
import { ArrowLeft } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { MOCK_PAYOUTS } from "./mockData";

const USE_DEV_FINANCE_MOCKS =
  import.meta.env.DEV &&
  import.meta.env.VITE_USE_FINANCE_MOCKS === "true";

const TAB_STATUS: (PayoutStatus | "")[] = ["", "COMPLETED", "FAILED"];
const TAB_LABELS = ["All History", "Completed", "Failed"];

const PayoutHistory = () => {
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const { data, loading, error, totalPages, currentPage } = useAppSelector(
    (state) => state.payoutList
  );

  const [activeTab, setActiveTab] = useState(0);

  const buildPayload = (page = 1) => ({
    page,
    limit: 10,
    status: (TAB_STATUS[activeTab] || undefined) as PayoutStatus | undefined,
  });

  useEffect(() => {
    dispatch(fetchPayoutList(buildPayload(1)));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dispatch, activeTab]);

  const allRows = useMemo(() => {
    if (data && data.length > 0) return data;
    if (USE_DEV_FINANCE_MOCKS) return MOCK_PAYOUTS;
    return [];
  }, [data]);

  // Client-side filter for mock data (API handles this server-side)
  const rows = useMemo(() => {
    const status = TAB_STATUS[activeTab];
    if (!status) return allRows;
    return allRows.filter((p) => p.status === status);
  }, [allRows, activeTab]);

  // Summary counts
  const completedCount = allRows.filter((p) => p.status === "COMPLETED").length;
  const failedCount = allRows.filter((p) => p.status === "FAILED").length;
  const totalPaid = allRows
    .filter((p) => p.status === "COMPLETED")
    .reduce((sum, p) => sum + p.amount, 0);

  return (
    <>
      {/* ================= HEADER ================= */}
      <Stack direction="row" alignItems="center" spacing={1.5} mb={1}>
        <Tooltip title="Back to Payout Queue">
          <Box
            onClick={() => navigate("/admin/finance/payouts")}
            sx={{
              cursor: "pointer",
              p: 0.5,
              borderRadius: "50%",
              "&:hover": { bgcolor: "#f3e8ff" },
            }}
          >
            <ArrowLeft size={20} color="#881f9b" />
          </Box>
        </Tooltip>
        <Typography variant="h5" fontWeight={600} color="#374151">
          Payout History
        </Typography>
        <Box sx={{ ml: "auto" }}>
          <ExportButton
            headers={["Host", "Period", "Amount", "Method", "Status", "Initiated", "Completed", "Failure Reason"]}
            rows={rows.map((p) => [
              p.host_name,
              `${new Date(p.period_start).toLocaleDateString("en-IN")} - ${new Date(p.period_end).toLocaleDateString("en-IN")}`,
              p.amount,
              p.payout_method,
              p.status,
              new Date(p.initiated_at).toLocaleDateString("en-IN"),
              p.completed_at ? new Date(p.completed_at).toLocaleDateString("en-IN") : "—",
              p.failure_reason || "",
            ])}
            filename="payout-history"
          />
        </Box>
      </Stack>

      {/* ================= SUMMARY CARDS ================= */}
      <Stack direction="row" spacing={2} mb={3} flexWrap="wrap">
        <Paper
          sx={{
            p: 2,
            borderRadius: "0.75rem",
            flex: 1,
            minWidth: 180,
            textAlign: "center",
          }}
        >
          <Typography variant="h5" fontWeight={700} color="#16a34a">
            {formatINR(totalPaid)}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Total Paid Out
          </Typography>
        </Paper>
        <Paper
          sx={{
            p: 2,
            borderRadius: "0.75rem",
            flex: 1,
            minWidth: 180,
            textAlign: "center",
          }}
        >
          <Typography variant="h5" fontWeight={700} color="#881f9b">
            {completedCount}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Completed
          </Typography>
        </Paper>
        <Paper
          sx={{
            p: 2,
            borderRadius: "0.75rem",
            flex: 1,
            minWidth: 180,
            textAlign: "center",
          }}
        >
          <Typography variant="h5" fontWeight={700} color="#dc2626">
            {failedCount}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Failed
          </Typography>
        </Paper>
      </Stack>

      {/* ================= TABS ================= */}
      <Paper sx={{ borderRadius: "0.75rem", mb: 3 }}>
        <Tabs
          value={activeTab}
          onChange={(_, v) => setActiveTab(v)}
          sx={{
            px: 2,
            "& .MuiTab-root": { textTransform: "none", fontWeight: 500 },
            "& .Mui-selected": { color: "#881f9b" },
            "& .MuiTabs-indicator": { backgroundColor: "#881f9b" },
          }}
        >
          {TAB_LABELS.map((label) => (
            <Tab key={label} label={label} />
          ))}
        </Tabs>
      </Paper>

      {/* ================= TABLE ================= */}
      <Paper sx={{ p: 3, borderRadius: "0.75rem" }}>
        {loading ? (
          <TableLoader text="Loading payout history..." minHeight={300} />
        ) : error && !USE_DEV_FINANCE_MOCKS ? (
          <FinanceErrorAlert message={error} onRetry={() => dispatch(fetchPayoutList({ page: 1, limit: 10, status: "COMPLETED" }))} />
        ) : rows.length === 0 ? (
          <FinanceEmptyState variant="payouts" message="No payout history found." />
        ) : (
          <Box sx={{ overflowX: "auto" }}>
            <table style={{ width: "100%", borderCollapse: "collapse" }}>
              <thead>
                <tr>
                  {[
                    "Host",
                    "Period",
                    "Amount",
                    "Method",
                    "Initiated",
                    "Completed",
                    "Status",
                    "Details",
                  ].map((h) => (
                    <th
                      key={h}
                      style={{
                        textAlign: "left",
                        padding: "10px 12px",
                        borderBottom: "2px solid #e5e7eb",
                        fontSize: "0.8rem",
                        fontWeight: 600,
                        color: "#6b7280",
                        whiteSpace: "nowrap",
                      }}
                    >
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {rows.map((payout) => (
                  <tr key={payout.payout_id}>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        fontWeight: 500,
                      }}
                    >
                      {payout.host_name}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        whiteSpace: "nowrap",
                      }}
                    >
                      {new Date(payout.period_start).toLocaleDateString(
                        "en-IN",
                        { day: "2-digit", month: "short" }
                      )}{" "}
                      –{" "}
                      {new Date(payout.period_end).toLocaleDateString("en-IN", {
                        day: "2-digit",
                        month: "short",
                      })}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        fontWeight: 600,
                        color: "#374151",
                      }}
                    >
                      {formatINR(payout.amount)}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                      }}
                    >
                      {payout.payout_method === "BANK_TRANSFER"
                        ? "Bank"
                        : "UPI"}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        whiteSpace: "nowrap",
                      }}
                    >
                      {new Date(payout.initiated_at).toLocaleDateString(
                        "en-IN",
                        { day: "2-digit", month: "short", year: "2-digit" }
                      )}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        whiteSpace: "nowrap",
                      }}
                    >
                      {payout.completed_at
                        ? new Date(payout.completed_at).toLocaleDateString(
                            "en-IN",
                            {
                              day: "2-digit",
                              month: "short",
                              year: "2-digit",
                            }
                          )
                        : "—"}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                      }}
                    >
                      <FinanceStatusChip status={payout.status} />
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.8rem",
                        color: "#6b7280",
                      }}
                    >
                      {payout.status === "FAILED" && payout.failure_reason ? (
                        <Tooltip title={payout.failure_reason}>
                          <Chip
                            label="View Reason"
                            size="small"
                            color="error"
                            variant="outlined"
                            sx={{ cursor: "pointer", fontSize: "0.75rem" }}
                          />
                        </Tooltip>
                      ) : (
                        <Typography variant="caption" color="text.secondary">
                          {payout.initiated_by === "ADMIN"
                            ? "Manual"
                            : "Auto"}
                        </Typography>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Box>
        )}

        {totalPages > 1 && (
          <Pagination
            count={totalPages}
            page={currentPage}
            onChange={(_, page) =>
              dispatch(fetchPayoutList(buildPayload(page)))
            }
          />
        )}
      </Paper>
    </>
  );
};

export default PayoutHistory;
