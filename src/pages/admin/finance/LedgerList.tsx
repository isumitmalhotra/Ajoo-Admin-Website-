import { useEffect, useState, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import { fetchLedgerList } from "../../../features/admin/finance/ledgerList.slice";
import {
  Box,
  Paper,
  Typography,
  TextField,
  MenuItem,
  Stack,
  IconButton,
  Tooltip,
} from "@mui/material";
import { Pagination } from "../../../components";
import { TableLoader } from "../../../components/admin/common/TableLoader";
import TransactionTypeChip from "../../../components/admin/finance/TransactionTypeChip";
import FinanceStatusChip from "../../../components/admin/finance/FinanceStatusChip";
import DateRangeFilter from "../../../components/admin/finance/DateRangeFilter";
import ExportButton from "../../../components/admin/finance/ExportButton";
import FinanceEmptyState from "../../../components/admin/finance/FinanceEmptyState";
import FinanceErrorAlert from "../../../components/admin/finance/FinanceErrorAlert";
import LedgerDetailDrawer from "../../../components/admin/finance/LedgerDetailDrawer";
import type { TransactionType, LedgerStatus, LedgerEntry } from "./types";
import { formatINR } from "./utils";
import { Search, Eye } from "lucide-react";
import { useDebounce } from "../../../hooks/useDebounce";
import { MOCK_LEDGER_ENTRIES } from "./mockData";

const USE_DEV_FINANCE_MOCKS =
  import.meta.env.DEV &&
  import.meta.env.VITE_USE_FINANCE_MOCKS === "true";

const TRANSACTION_TYPES: { value: string; label: string }[] = [
  { value: "", label: "All Types" },
  { value: "GUEST_PAYMENT", label: "Guest Payment" },
  { value: "HOST_EARNING", label: "Host Earning" },
  { value: "PLATFORM_COMMISSION", label: "Commission" },
  { value: "TAX_COLLECTED", label: "Tax Collected" },
  { value: "REFUND", label: "Refund" },
  { value: "PAYOUT", label: "Payout" },
  { value: "ADJUSTMENT", label: "Adjustment" },
];

const STATUS_OPTIONS: { value: string; label: string }[] = [
  { value: "", label: "All Status" },
  { value: "COMPLETED", label: "Completed" },
  { value: "PENDING", label: "Pending" },
  { value: "FAILED", label: "Failed" },
  { value: "REVERSED", label: "Reversed" },
];

const LedgerList = () => {
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const { data: apiData, loading, error, totalPages, currentPage } = useAppSelector(
    (state) => state.ledgerList
  );

  const [filters, setFilters] = useState({
    search: "",
    transactionType: "" as TransactionType | "",
    status: "" as LedgerStatus | "",
    dateFrom: "",
    dateTo: "",
    limit: 10,
  });

  // Drawer state
  const [drawerEntry, setDrawerEntry] = useState<LedgerEntry | null>(null);

  // Debounced search
  const debouncedSearch = useDebounce(filters.search, 400);

  useEffect(() => {
    dispatch(fetchLedgerList({ page: 1, limit: 10 }));
  }, [dispatch]);

  // Auto-search on debounced search term change
  useEffect(() => {
    if (debouncedSearch !== undefined) {
      dispatch(fetchLedgerList(buildPayload(1)));
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debouncedSearch]);

  const buildPayload = useCallback(
    (page = 1) => ({
      page,
      limit: filters.limit,
      ...(filters.search && { search: filters.search }),
      ...(filters.transactionType && {
        transactionType: filters.transactionType as TransactionType,
      }),
      ...(filters.status && { status: filters.status as LedgerStatus }),
      ...(filters.dateFrom && { dateFrom: filters.dateFrom }),
      ...(filters.dateTo && { dateTo: filters.dateTo }),
    }),
    [filters]
  );

  const handleSearch = () => {
    dispatch(fetchLedgerList(buildPayload(1)));
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") handleSearch();
  };

  const handleDateChange = (from: string, to: string) => {
    setFilters((prev) => ({ ...prev, dateFrom: from, dateTo: to }));
  };

  const rows =
    apiData && apiData.length > 0
      ? apiData
      : USE_DEV_FINANCE_MOCKS
      ? MOCK_LEDGER_ENTRIES
      : [];

  return (
    <>
      <Typography variant="h5" fontWeight={600} color="#374151" mb={3}>
        Transaction Ledger
      </Typography>

      {/* ================= FILTERS ================= */}
      <Paper sx={{ p: 2, borderRadius: "0.75rem", mb: 3 }}>
        <Stack
          direction={{ xs: "column", md: "row" }}
          spacing={2}
          alignItems="center"
        >
          <TextField
            size="small"
            placeholder="Search by reference, description..."
            value={filters.search}
            onChange={(e) =>
              setFilters((prev) => ({ ...prev, search: e.target.value }))
            }
            onKeyDown={handleKeyDown}
            slotProps={{
              input: {
                startAdornment: <Search size={16} style={{ marginRight: 8, color: "#9ca3af" }} />,
              },
            }}
            sx={{ minWidth: 240 }}
          />

          <TextField
            select
            size="small"
            value={filters.transactionType}
            onChange={(e) =>
              setFilters((prev) => ({
                ...prev,
                transactionType: e.target.value as TransactionType | "",
              }))
            }
            sx={{ minWidth: 160 }}
          >
            {TRANSACTION_TYPES.map((t) => (
              <MenuItem key={t.value} value={t.value}>
                {t.label}
              </MenuItem>
            ))}
          </TextField>

          <TextField
            select
            size="small"
            value={filters.status}
            onChange={(e) =>
              setFilters((prev) => ({
                ...prev,
                status: e.target.value as LedgerStatus | "",
              }))
            }
            sx={{ minWidth: 140 }}
          >
            {STATUS_OPTIONS.map((s) => (
              <MenuItem key={s.value} value={s.value}>
                {s.label}
              </MenuItem>
            ))}
          </TextField>

          <DateRangeFilter
            dateFrom={filters.dateFrom}
            dateTo={filters.dateTo}
            onChange={handleDateChange}
          />

          <Box
            onClick={handleSearch}
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
            Search
          </Box>

          <ExportButton
            headers={["Date", "Type", "Entry", "Host/Guest", "Description", "Amount", "Balance", "Status", "Reference"]}
            rows={rows.map((r) => [
              new Date(r.created_at).toLocaleDateString("en-IN"),
              r.transaction_type,
              r.entry_type,
              r.host_name || r.user_name || "",
              r.description,
              r.amount,
              r.balance_after,
              r.status,
              r.reference_id,
            ])}
            filename="ledger-transactions"
          />
        </Stack>
      </Paper>

      {/* ================= TABLE ================= */}
      <Paper sx={{ p: 3, borderRadius: "0.75rem" }}>
        {loading ? (
          <TableLoader text="Loading ledger entries..." minHeight={300} />
        ) : error && !USE_DEV_FINANCE_MOCKS ? (
          <FinanceErrorAlert message={error} onRetry={() => dispatch(fetchLedgerList({ page: 1, limit: 10 }))} />
        ) : rows.length === 0 ? (
          <FinanceEmptyState variant="default" message="No ledger entries found. Financial records will appear here as bookings are processed." />
        ) : (
          <Box sx={{ overflowX: "auto" }}>
            <table style={{ width: "100%", borderCollapse: "collapse" }}>
              <thead>
                <tr>
                  {[
                    "Date",
                    "Type",
                    "Host / Guest",
                    "Description",
                    "Amount",
                    "Balance",
                    "Status",
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
                {rows.map((entry) => (
                  <tr
                    key={entry.ledger_id}
                    style={{ cursor: "pointer" }}
                    onClick={() => setDrawerEntry(entry)}
                    onMouseEnter={(e) =>
                      (e.currentTarget.style.backgroundColor = "#f9fafb")
                    }
                    onMouseLeave={(e) =>
                      (e.currentTarget.style.backgroundColor = "transparent")
                    }
                  >
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
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                      }}
                    >
                      <TransactionTypeChip type={entry.transaction_type} />
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                      }}
                    >
                      {entry.host_name && (
                        <Tooltip title="View Host Ledger">
                          <Typography
                            component="span"
                            sx={{
                              fontSize: "0.85rem",
                              color: "#881f9b",
                              cursor: "pointer",
                              "&:hover": { textDecoration: "underline" },
                            }}
                            onClick={(e) => {
                              e.stopPropagation();
                              navigate(
                                `/admin/finance/ledgers/host/${entry.host_id}`
                              );
                            }}
                          >
                            {entry.host_name}
                          </Typography>
                        </Tooltip>
                      )}
                      {entry.host_name && entry.user_name && " / "}
                      {entry.user_name && (
                        <Tooltip title="View Guest Ledger">
                          <Typography
                            component="span"
                            sx={{
                              fontSize: "0.85rem",
                              color: "#2563eb",
                              cursor: "pointer",
                              "&:hover": { textDecoration: "underline" },
                            }}
                            onClick={(e) => {
                              e.stopPropagation();
                              navigate(
                                `/admin/finance/ledgers/guest/${entry.user_id}`
                              );
                            }}
                          >
                            {entry.user_name}
                          </Typography>
                        </Tooltip>
                      )}
                      {!entry.host_name && !entry.user_name && "—"}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        maxWidth: 220,
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
                          entry.entry_type === "CREDIT"
                            ? "#16a34a"
                            : "#dc2626",
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
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                      }}
                    >
                      <FinanceStatusChip status={entry.status} />
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                      }}
                    >
                      <Tooltip title="View Details">
                        <IconButton
                          size="small"
                          onClick={(e) => {
                            e.stopPropagation();
                            setDrawerEntry(entry);
                          }}
                        >
                          <Eye size={16} />
                        </IconButton>
                      </Tooltip>
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
              dispatch(fetchLedgerList(buildPayload(page)))
            }
          />
        )}
      </Paper>

      {/* ================= DETAIL DRAWER ================= */}
      <LedgerDetailDrawer
        open={!!drawerEntry}
        entry={drawerEntry}
        onClose={() => setDrawerEntry(null)}
      />
    </>
  );
};

export default LedgerList;
