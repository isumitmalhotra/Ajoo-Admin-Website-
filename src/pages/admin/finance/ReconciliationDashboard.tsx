import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import { fetchReconciliationList } from "../../../features/admin/finance/reconciliationList.slice";
import {
  Box,
  Paper,
  Typography,
} from "@mui/material";
import { Pagination } from "../../../components";
import { TableLoader } from "../../../components/admin/common/TableLoader";
import FinanceStatusChip from "../../../components/admin/finance/FinanceStatusChip";
import ExportButton from "../../../components/admin/finance/ExportButton";
import FinanceEmptyState from "../../../components/admin/finance/FinanceEmptyState";
import FinanceErrorAlert from "../../../components/admin/finance/FinanceErrorAlert";
import { AdminGaugeChart } from "../../../components";
import { formatINR } from "./utils";
import { ShieldCheck, AlertTriangle, Clock } from "lucide-react";
import { MOCK_RECON_RECORDS } from "./mockData";

const USE_DEV_FINANCE_MOCKS =
  import.meta.env.DEV &&
  import.meta.env.VITE_USE_FINANCE_MOCKS === "true";

const ReconciliationDashboard = () => {
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const { data, summary, loading, error, totalPages, currentPage } = useAppSelector(
    (state) => state.reconciliationList
  );

  useEffect(() => {
    dispatch(fetchReconciliationList({ page: 1, limit: 10 }));
  }, [dispatch]);

  const displaySummary =
    summary.matched + summary.variance + summary.pending > 0
      ? summary
      : {
          matched: MOCK_RECON_RECORDS.filter((r) => r.status === "MATCHED").length,
          variance: MOCK_RECON_RECORDS.filter((r) => r.status === "VARIANCE").length,
          pending: MOCK_RECON_RECORDS.filter((r) => r.status === "PENDING").length,
        };

  const total = displaySummary.matched + displaySummary.variance + displaySummary.pending;
  const matchPercent = total > 0 ? Math.round((displaySummary.matched / total) * 100) : 0;

  const rows =
    data && data.length > 0
      ? data
      : USE_DEV_FINANCE_MOCKS
      ? MOCK_RECON_RECORDS
      : [];

  const summaryCards = [
    {
      label: "Matched",
      value: displaySummary.matched,
      icon: ShieldCheck,
      color: "#16a34a",
      bg: "#f0fdf4",
    },
    {
      label: "Variances",
      value: displaySummary.variance,
      icon: AlertTriangle,
      color: "#ea580c",
      bg: "#fff7ed",
    },
    {
      label: "Pending",
      value: displaySummary.pending,
      icon: Clock,
      color: "#2563eb",
      bg: "#eff6ff",
    },
  ];

  return (
    <>
      <Typography variant="h5" fontWeight={600} color="#374151" mb={3}>
        Reconciliation
      </Typography>

      {/* View All Records link */}
      <Box sx={{ display: "flex", justifyContent: "flex-end", gap: 1, mb: 2 }}>
        <ExportButton
          headers={["Booking", "Expected", "Payment", "Payout", "Variance", "Status", "Date"]}
          rows={rows.map((r) => [
            r.booking_id,
            r.expected_amount,
            r.payment_amount,
            r.payout_amount,
            r.variance,
            r.status,
            new Date(r.created_at).toLocaleDateString("en-IN"),
          ])}
          filename="reconciliation"
        />
        <Box
          onClick={() => navigate("/admin/finance/reconciliation/records")}
          sx={{
            bgcolor: "#881f9b",
            color: "#fff",
            px: 3,
            py: 1,
            borderRadius: "0.5rem",
            cursor: "pointer",
            fontWeight: 500,
            fontSize: "0.875rem",
            "&:hover": { bgcolor: "#7115bd" },
          }}
        >
          View All Records
        </Box>
      </Box>

      {/* ================= SUMMARY CARDS ================= */}
      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
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
                p: 3,
                borderRadius: "0.75rem",
                bgcolor: card.bg,
                display: "flex",
                alignItems: "center",
                gap: 2,
              }}
            >
              <Icon size={28} color={card.color} />
              <Box>
                <Typography variant="h4" fontWeight={700} color={card.color}>
                  {card.value}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {card.label}
                </Typography>
              </Box>
            </Paper>
          );
        })}

        <Paper
          sx={{
            p: 3,
            borderRadius: "0.75rem",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <AdminGaugeChart value={matchPercent} label="Match Rate" />
        </Paper>
      </Box>

      {/* ================= TABLE ================= */}
      <Paper sx={{ p: 3, borderRadius: "0.75rem" }}>
        {loading ? (
          <TableLoader text="Loading reconciliation records..." minHeight={300} />
        ) : error && !USE_DEV_FINANCE_MOCKS ? (
          <FinanceErrorAlert message={error} onRetry={() => dispatch(fetchReconciliationList({ page: 1, limit: 10 }))} />
        ) : rows.length === 0 ? (
          <FinanceEmptyState variant="reconciliation" />
        ) : (
          <Box sx={{ overflowX: "auto" }}>
            <table style={{ width: "100%", borderCollapse: "collapse" }}>
              <thead>
                <tr>
                  {[
                    "Booking",
                    "Expected",
                    "Payment",
                    "Payout",
                    "Variance",
                    "Status",
                    "Date",
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
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        fontWeight: 500,
                      }}
                    >
                      #{rec.booking_id}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                      }}
                    >
                      {formatINR(rec.expected_amount)}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                      }}
                    >
                      {formatINR(rec.payment_amount)}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                      }}
                    >
                      {formatINR(rec.payout_amount)}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        fontWeight: 600,
                        color: rec.variance !== 0 ? "#dc2626" : "#16a34a",
                      }}
                    >
                      {rec.variance !== 0 ? formatINR(Math.abs(rec.variance)) : "—"}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                      }}
                    >
                      <FinanceStatusChip status={rec.status} />
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        whiteSpace: "nowrap",
                      }}
                    >
                      {new Date(rec.created_at).toLocaleDateString("en-IN", {
                        day: "2-digit",
                        month: "short",
                        year: "2-digit",
                      })}
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
              dispatch(fetchReconciliationList({ page, limit: 10 }))
            }
          />
        )}
      </Paper>
    </>
  );
};

export default ReconciliationDashboard;
