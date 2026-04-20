import { useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import { fetchHostLedger } from "../../../features/admin/finance/hostLedger.slice";
import {
  Box,
  Paper,
  Typography,
  Stack,
  IconButton,
  Tooltip,
} from "@mui/material";
import { Pagination } from "../../../components";
import { TableLoader } from "../../../components/admin/common/TableLoader";
import TransactionTypeChip from "../../../components/admin/finance/TransactionTypeChip";
import FinanceStatusChip from "../../../components/admin/finance/FinanceStatusChip";
import ExportButton from "../../../components/admin/finance/ExportButton";
import FinanceEmptyState from "../../../components/admin/finance/FinanceEmptyState";
import FinanceErrorAlert from "../../../components/admin/finance/FinanceErrorAlert";
import { formatINR } from "./utils";
import { ArrowLeft } from "lucide-react";
import { MOCK_HOST_LEDGER } from "./mockData";

const USE_DEV_FINANCE_MOCKS =
  import.meta.env.DEV &&
  import.meta.env.VITE_USE_FINANCE_MOCKS === "true";

const HostLedger = () => {
  const { hostId } = useParams<{ hostId: string }>();
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const { data, balance, loading, error, totalPages, currentPage } = useAppSelector(
    (state) => state.hostLedger
  );

  useEffect(() => {
    if (hostId) {
      dispatch(fetchHostLedger({ hostId: Number(hostId), page: 1, limit: 10 }));
    }
  }, [dispatch, hostId]);

  const rows =
    data && data.length > 0
      ? data
      : USE_DEV_FINANCE_MOCKS
      ? MOCK_HOST_LEDGER.rows
      : [];

  const displayBalance =
    balance > 0 ? balance : USE_DEV_FINANCE_MOCKS ? MOCK_HOST_LEDGER.balance : 0;

  return (
    <>
      <Stack direction="row" alignItems="center" spacing={2} mb={3}>
        <Tooltip title="Back to Ledgers">
          <IconButton onClick={() => navigate("/admin/finance/ledgers")}>
            <ArrowLeft size={20} />
          </IconButton>
        </Tooltip>
        <Typography variant="h5" fontWeight={600} color="#374151">
          Host Ledger
        </Typography>
        <Paper
          sx={{
            ml: "auto !important",
            px: 3,
            py: 1.5,
            borderRadius: "0.75rem",
            bgcolor: "#f0fdf4",
            border: "1px solid #bbf7d0",
          }}
        >
          <Typography variant="caption" color="text.secondary">
            Current Balance
          </Typography>
          <Typography variant="h5" fontWeight={700} color="#16a34a">
            {formatINR(displayBalance)}
          </Typography>
        </Paper>
        <ExportButton
          headers={["Date", "Type", "Description", "Entry", "Amount", "Balance", "Status"]}
          rows={rows.map((r) => [
            new Date(r.created_at).toLocaleDateString("en-IN"),
            r.transaction_type,
            r.description,
            r.entry_type,
            r.amount,
            r.balance_after,
            r.status,
          ])}
          filename={`host-${hostId}-ledger`}
        />
      </Stack>

      <Paper sx={{ p: 3, borderRadius: "0.75rem" }}>
        {loading ? (
          <TableLoader text="Loading host ledger..." minHeight={300} />
        ) : error && !USE_DEV_FINANCE_MOCKS ? (
          <FinanceErrorAlert message={error} onRetry={() => dispatch(fetchHostLedger({ hostId: Number(hostId), page: 1, limit: 10 }))} />
        ) : rows.length === 0 ? (
          <FinanceEmptyState variant="default" message="No ledger entries found for this host." />
        ) : (
          <Box sx={{ overflowX: "auto" }}>
            <table style={{ width: "100%", borderCollapse: "collapse" }}>
              <thead>
                <tr>
                  {["Date", "Type", "Description", "Amount", "Balance", "Status"].map(
                    (h) => (
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
                    )
                  )}
                </tr>
              </thead>
              <tbody>
                {rows.map((entry) => (
                  <tr key={entry.ledger_id}>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        whiteSpace: "nowrap",
                      }}
                    >
                      {new Date(entry.created_at).toLocaleDateString("en-IN", {
                        day: "2-digit",
                        month: "short",
                        year: "2-digit",
                      })}
                    </td>
                    <td style={{ padding: "10px 12px", borderBottom: "1px solid #f3f4f6" }}>
                      <TransactionTypeChip type={entry.transaction_type} />
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        maxWidth: 260,
                        overflow: "hidden",
                        textOverflow: "ellipsis",
                        whiteSpace: "nowrap",
                      }}
                    >
                      {entry.description}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        fontWeight: 600,
                        color:
                          entry.entry_type === "CREDIT" ? "#16a34a" : "#dc2626",
                        whiteSpace: "nowrap",
                      }}
                    >
                      {entry.entry_type === "CREDIT" ? "+" : "-"}{formatINR(entry.amount).replace("₹", "₹")}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        whiteSpace: "nowrap",
                      }}
                    >
                      {formatINR(entry.balance_after)}
                    </td>
                    <td style={{ padding: "10px 12px", borderBottom: "1px solid #f3f4f6" }}>
                      <FinanceStatusChip status={entry.status} />
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
              dispatch(
                fetchHostLedger({
                  hostId: Number(hostId),
                  page,
                  limit: 10,
                })
              )
            }
          />
        )}
      </Paper>
    </>
  );
};

export default HostLedger;
