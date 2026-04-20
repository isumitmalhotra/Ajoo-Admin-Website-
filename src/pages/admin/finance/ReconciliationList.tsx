import { useEffect, useMemo, useState } from "react";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import { fetchReconciliationList } from "../../../features/admin/finance/reconciliationList.slice";
import {
  resolveReconciliation,
  resetReconciliationResolve,
} from "../../../features/admin/finance/reconciliationResolve.slice";
import {
  Box,
  Paper,
  Typography,
  TextField,
  MenuItem,
  Stack,
  Tooltip,
  Chip,
  IconButton,
} from "@mui/material";
import { Pagination } from "../../../components";
import { TableLoader } from "../../../components/admin/common/TableLoader";
import FinanceStatusChip from "../../../components/admin/finance/FinanceStatusChip";
import ExportButton from "../../../components/admin/finance/ExportButton";
import FinanceEmptyState from "../../../components/admin/finance/FinanceEmptyState";
import FinanceErrorAlert from "../../../components/admin/finance/FinanceErrorAlert";
import ReconciliationResolveModal from "../../../components/admin/finance/ReconciliationResolveModal";
import type {
  ReconciliationRecord,
  ReconciliationStatus,
  ReconciliationAction,
} from "./types";
import { formatINR } from "./utils";
import { ArrowLeft, ShieldCheck, AlertTriangle, Clock, CheckCircle, Eye } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useNotificationStore } from "../../../components/toast";
import { MOCK_RECON_RECORDS } from "./mockData";

const USE_DEV_FINANCE_MOCKS =
  import.meta.env.DEV &&
  import.meta.env.VITE_USE_FINANCE_MOCKS === "true";

const STATUS_OPTIONS: { value: string; label: string }[] = [
  { value: "", label: "All Statuses" },
  { value: "MATCHED", label: "Matched" },
  { value: "VARIANCE", label: "Variance" },
  { value: "PENDING", label: "Pending" },
  { value: "RESOLVED", label: "Resolved" },
];

const ReconciliationList = () => {
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const { addNotification } = useNotificationStore();

  const { data, loading, error, totalPages, currentPage } = useAppSelector(
    (state) => state.reconciliationList
  );
  const resolveState = useAppSelector((state) => state.reconciliationResolve);

  const [statusFilter, setStatusFilter] = useState<ReconciliationStatus | "">("");
  const [resolveModal, setResolveModal] = useState<{
    open: boolean;
    record: ReconciliationRecord | null;
  }>({ open: false, record: null });

  useEffect(() => {
    dispatch(fetchReconciliationList({ page: 1, limit: 20 }));
  }, [dispatch]);

  // Handle resolve success/error
  useEffect(() => {
    if (resolveState.success) {
      addNotification({
        type: "success",
        title: "Reconciliation record resolved successfully",
      });
      setResolveModal({ open: false, record: null });
      dispatch(resetReconciliationResolve());
      dispatch(fetchReconciliationList({ page: currentPage, limit: 20 }));
    }
    if (resolveState.error) {
      addNotification({ type: "error", title: resolveState.error });
      dispatch(resetReconciliationResolve());
    }
  }, [resolveState.success, resolveState.error, addNotification, dispatch, currentPage]);

  const rows = useMemo(() => {
    const source =
      data && data.length > 0
        ? data
        : USE_DEV_FINANCE_MOCKS
        ? MOCK_RECON_RECORDS
        : [];
    if (!statusFilter) return source;
    return source.filter((r) => r.status === statusFilter);
  }, [data, statusFilter]);

  const summaryFromRows = useMemo(() => {
    const source =
      data && data.length > 0
        ? data
        : USE_DEV_FINANCE_MOCKS
        ? MOCK_RECON_RECORDS
        : [];
    return {
      matched: source.filter((r) => r.status === "MATCHED").length,
      variance: source.filter((r) => r.status === "VARIANCE").length,
      pending: source.filter((r) => r.status === "PENDING").length,
      resolved: source.filter((r) => r.status === "RESOLVED").length,
    };
  }, [data]);

  const handleResolve = (action: ReconciliationAction, notes: string) => {
    if (!resolveModal.record) return;
    dispatch(
      resolveReconciliation({
        reconId: resolveModal.record.recon_id,
        payload: { action, notes },
      })
    );
  };

  const summaryCards = [
    { label: "Matched", value: summaryFromRows.matched, icon: ShieldCheck, color: "#16a34a", bg: "#f0fdf4" },
    { label: "Variances", value: summaryFromRows.variance, icon: AlertTriangle, color: "#ea580c", bg: "#fff7ed" },
    { label: "Pending", value: summaryFromRows.pending, icon: Clock, color: "#2563eb", bg: "#eff6ff" },
    { label: "Resolved", value: summaryFromRows.resolved, icon: CheckCircle, color: "#7c3aed", bg: "#f3e8ff" },
  ];

  return (
    <>
      {/* ================= HEADER ================= */}
      <Stack direction="row" alignItems="center" spacing={2} mb={3}>
        <IconButton onClick={() => navigate("/admin/finance/reconciliation")} size="small">
          <ArrowLeft size={20} />
        </IconButton>
        <Typography variant="h5" fontWeight={600} color="#374151">
          Reconciliation Records
        </Typography>
      </Stack>

      {/* ================= SUMMARY CARDS ================= */}
      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))",
          gap: 2,
          mb: 3,
        }}
      >
        {summaryCards.map((card) => {
          const Icon = card.icon;
          return (
            <Paper
              key={card.label}
              sx={{
                p: 2.5,
                borderRadius: "0.75rem",
                bgcolor: card.bg,
                display: "flex",
                alignItems: "center",
                gap: 2,
              }}
            >
              <Icon size={24} color={card.color} />
              <Box>
                <Typography variant="h5" fontWeight={700} color={card.color}>
                  {card.value}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {card.label}
                </Typography>
              </Box>
            </Paper>
          );
        })}
      </Box>

      {/* ================= FILTER ================= */}
      <Paper sx={{ p: 2, borderRadius: "0.75rem", mb: 3 }}>
        <Stack direction={{ xs: "column", sm: "row" }} spacing={2} alignItems="center">
          <TextField
            select
            size="small"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as ReconciliationStatus | "")}
            sx={{ minWidth: 180 }}
          >
            {STATUS_OPTIONS.map((opt) => (
              <MenuItem key={opt.value} value={opt.value}>
                {opt.label}
              </MenuItem>
            ))}
          </TextField>
          <ExportButton
            headers={["Booking", "Property", "Host", "Expected", "Payment", "Payout", "Variance", "Status", "Notes", "Date"]}
            rows={rows.map((r) => [
              r.booking_id,
              r.property_name || "",
              r.host_name || "",
              r.expected_amount,
              r.payment_amount,
              r.payout_amount,
              r.variance,
              r.status,
              r.notes || "",
              new Date(r.created_at).toLocaleDateString("en-IN"),
            ])}
            filename="reconciliation-records"
          />
        </Stack>
      </Paper>

      {/* ================= TABLE ================= */}
      <Paper sx={{ p: 3, borderRadius: "0.75rem" }}>
        {loading ? (
          <TableLoader text="Loading reconciliation records..." minHeight={300} />
        ) : error && !USE_DEV_FINANCE_MOCKS ? (
          <FinanceErrorAlert message={error} onRetry={() => dispatch(fetchReconciliationList({ page: 1, limit: 10 }))} />
        ) : rows.length === 0 ? (
          <FinanceEmptyState variant="search" message="No reconciliation records match the selected filter." />
        ) : (
          <Box sx={{ overflowX: "auto" }}>
            <table style={{ width: "100%", borderCollapse: "collapse" }}>
              <thead>
                <tr>
                  {[
                    "Booking",
                    "Property",
                    "Host",
                    "Expected",
                    "Payment",
                    "Payout",
                    "Variance",
                    "Status",
                    "Notes",
                    "Date",
                    "",
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
                {rows.map((rec) => (
                  <tr key={rec.recon_id}>
                    <td style={tdStyle}>
                      <Typography variant="body2" fontWeight={500}>
                        #{rec.booking_id}
                      </Typography>
                    </td>
                    <td style={tdStyle}>
                      <Typography variant="body2">
                        {rec.property_name || "—"}
                      </Typography>
                    </td>
                    <td style={tdStyle}>
                      <Typography variant="body2">
                        {rec.host_name || "—"}
                      </Typography>
                    </td>
                    <td style={tdStyle}>
                      {formatINR(rec.expected_amount)}
                    </td>
                    <td style={tdStyle}>
                      {formatINR(rec.payment_amount)}
                    </td>
                    <td style={tdStyle}>
                      {formatINR(rec.payout_amount)}
                    </td>
                    <td
                      style={{
                        ...tdStyle,
                        fontWeight: 600,
                        color: rec.variance !== 0 ? "#dc2626" : "#16a34a",
                      }}
                    >
                      {rec.variance !== 0 ? formatINR(Math.abs(rec.variance)) : "—"}
                    </td>
                    <td style={tdStyle}>
                      <FinanceStatusChip status={rec.status} />
                    </td>
                    <td style={tdStyle}>
                      {rec.notes ? (
                        <Tooltip title={rec.notes}>
                          <Chip
                            label="View"
                            size="small"
                            variant="outlined"
                            icon={<Eye size={12} />}
                            sx={{ fontSize: "0.7rem", cursor: "pointer" }}
                          />
                        </Tooltip>
                      ) : (
                        "—"
                      )}
                    </td>
                    <td style={{ ...tdStyle, whiteSpace: "nowrap" }}>
                      {new Date(rec.created_at).toLocaleDateString("en-IN", {
                        day: "2-digit",
                        month: "short",
                        year: "2-digit",
                      })}
                    </td>
                    <td style={tdStyle}>
                      {rec.status === "VARIANCE" && (
                        <Box
                          onClick={() =>
                            setResolveModal({ open: true, record: rec })
                          }
                          sx={{
                            bgcolor: "#881f9b",
                            color: "#fff",
                            px: 2,
                            py: 0.5,
                            borderRadius: "0.375rem",
                            cursor: "pointer",
                            fontWeight: 500,
                            fontSize: "0.75rem",
                            textAlign: "center",
                            "&:hover": { bgcolor: "#7115bd" },
                          }}
                        >
                          Resolve
                        </Box>
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
              dispatch(fetchReconciliationList({ page, limit: 20 }))
            }
          />
        )}
      </Paper>

      {/* ================= RESOLVE MODAL ================= */}
      <ReconciliationResolveModal
        open={resolveModal.open}
        record={resolveModal.record}
        loading={resolveState.loading}
        onResolve={handleResolve}
        onClose={() => setResolveModal({ open: false, record: null })}
      />
    </>
  );
};

const tdStyle: React.CSSProperties = {
  padding: "10px 12px",
  borderBottom: "1px solid #f3f4f6",
  fontSize: "0.85rem",
};

export default ReconciliationList;
