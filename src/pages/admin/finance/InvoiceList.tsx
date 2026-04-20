import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import { fetchInvoiceList } from "../../../features/admin/finance/invoiceList.slice";
import {
  Box,
  Paper,
  Typography,
  TextField,
  MenuItem,
  Stack,
  Chip,
  IconButton,
  Tooltip,
} from "@mui/material";
import { Pagination } from "../../../components";
import { TableLoader } from "../../../components/admin/common/TableLoader";
import FinanceStatusChip from "../../../components/admin/finance/FinanceStatusChip";
import ExportButton from "../../../components/admin/finance/ExportButton";
import FinanceEmptyState from "../../../components/admin/finance/FinanceEmptyState";
import FinanceErrorAlert from "../../../components/admin/finance/FinanceErrorAlert";
import type { InvoiceType } from "./types";
import { formatINR } from "./utils";
import { Download } from "lucide-react";
import { useState } from "react";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import { MOCK_INVOICES } from "./mockData";

const USE_DEV_FINANCE_MOCKS =
  import.meta.env.DEV &&
  import.meta.env.VITE_USE_FINANCE_MOCKS === "true";

const TYPE_OPTIONS: { value: string; label: string }[] = [
  { value: "", label: "All Types" },
  { value: "BOOKING_RECEIPT", label: "Booking Receipt" },
  { value: "HOST_COMMISSION", label: "Host Commission" },
  { value: "PAYOUT_STATEMENT", label: "Payout Statement" },
];

const InvoiceList = () => {
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const { data, loading, error, totalPages, currentPage } = useAppSelector(
    (state) => state.invoiceList
  );

  const [filters, setFilters] = useState({
    invoiceType: "" as InvoiceType | "",
    limit: 10,
  });

  useEffect(() => {
    dispatch(fetchInvoiceList({ page: 1, limit: 10 }));
  }, [dispatch]);

  const buildPayload = (page = 1) => ({
    page,
    limit: filters.limit,
    ...(filters.invoiceType && { invoiceType: filters.invoiceType as InvoiceType }),
  });

  const handleSearch = () => {
    dispatch(fetchInvoiceList(buildPayload(1)));
  };

  const handleDownload = async (invoiceId: number) => {
    try {
      const res = await api.get(
        `${ADMINENDPOINTS.FINANCE_INVOICE_DOWNLOAD}/${invoiceId}`,
        { responseType: "blob" }
      );
      const url = window.URL.createObjectURL(new Blob([res.data]));
      const link = document.createElement("a");
      link.href = url;
      link.setAttribute("download", `invoice-${invoiceId}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);
    } catch {
      // Error handled silently — toast can be added later
    }
  };

  const rows =
    data && data.length > 0
      ? data
      : USE_DEV_FINANCE_MOCKS
      ? MOCK_INVOICES
      : [];

  const typeColors: Record<string, { bg: string; color: string }> = {
    BOOKING_RECEIPT: { bg: "#dbeafe", color: "#1d4ed8" },
    HOST_COMMISSION: { bg: "#f3e8ff", color: "#7c3aed" },
    PAYOUT_STATEMENT: { bg: "#dcfce7", color: "#16a34a" },
  };

  return (
    <>
      <Typography variant="h5" fontWeight={600} color="#374151" mb={3}>
        Invoices
      </Typography>

      {/* ================= FILTERS ================= */}
      <Paper sx={{ p: 2, borderRadius: "0.75rem", mb: 3 }}>
        <Stack direction={{ xs: "column", sm: "row" }} spacing={2} alignItems="center">
          <TextField
            select
            size="small"
            value={filters.invoiceType}
            onChange={(e) =>
              setFilters((p) => ({
                ...p,
                invoiceType: e.target.value as InvoiceType | "",
              }))
            }
            sx={{ minWidth: 180 }}
          >
            {TYPE_OPTIONS.map((t) => (
              <MenuItem key={t.value} value={t.value}>
                {t.label}
              </MenuItem>
            ))}
          </TextField>

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
            Filter
          </Box>
          <ExportButton
            headers={["Invoice #", "Type", "Host", "Guest", "Subtotal", "Tax", "Total", "Status", "Date"]}
            rows={rows.map((inv) => [
              inv.invoice_number,
              inv.invoice_type.replace(/_/g, " "),
              inv.host_name || "",
              inv.user_name || "",
              inv.subtotal,
              inv.tax_amount,
              inv.total,
              inv.status,
              new Date(inv.created_at).toLocaleDateString("en-IN"),
            ])}
            filename="invoices"
          />
        </Stack>
      </Paper>

      {/* ================= TABLE ================= */}
      <Paper sx={{ p: 3, borderRadius: "0.75rem" }}>
        {loading ? (
          <TableLoader text="Loading invoices..." minHeight={300} />
        ) : error && !USE_DEV_FINANCE_MOCKS ? (
          <FinanceErrorAlert message={error} onRetry={() => dispatch(fetchInvoiceList({ page: 1, limit: 10 }))} />
        ) : rows.length === 0 ? (
          <FinanceEmptyState variant="invoices" />
        ) : (
          <Box sx={{ overflowX: "auto" }}>
            <table style={{ width: "100%", borderCollapse: "collapse" }}>
              <thead>
                <tr>
                  {[
                    "Invoice #",
                    "Type",
                    "Host / Guest",
                    "Subtotal",
                    "Tax",
                    "Total",
                    "Status",
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
                {rows.map((inv) => {
                  const tc = typeColors[inv.invoice_type] ?? {
                    bg: "#f3f4f6",
                    color: "#374151",
                  };
                  return (
                    <tr key={inv.invoice_id}>
                      <td
                        style={{
                          padding: "10px 12px",
                          borderBottom: "1px solid #f3f4f6",
                          fontSize: "0.85rem",
                          fontWeight: 600,
                          fontFamily: "monospace",
                          color: "#881f9b",
                          cursor: "pointer",
                        }}
                        onClick={() => navigate(`/admin/finance/invoices/${inv.invoice_id}`)}
                      >
                        {inv.invoice_number}
                      </td>
                      <td
                        style={{
                          padding: "10px 12px",
                          borderBottom: "1px solid #f3f4f6",
                        }}
                      >
                        <Chip
                          label={inv.invoice_type.replace(/_/g, " ")}
                          size="small"
                          sx={{
                            bgcolor: tc.bg,
                            color: tc.color,
                            fontWeight: 500,
                            fontSize: "0.7rem",
                          }}
                        />
                      </td>
                      <td
                        style={{
                          padding: "10px 12px",
                          borderBottom: "1px solid #f3f4f6",
                          fontSize: "0.85rem",
                        }}
                      >
                        {inv.host_name || inv.user_name || "—"}
                      </td>
                      <td
                        style={{
                          padding: "10px 12px",
                          borderBottom: "1px solid #f3f4f6",
                          fontSize: "0.85rem",
                        }}
                      >
                        {formatINR(inv.subtotal)}
                      </td>
                      <td
                        style={{
                          padding: "10px 12px",
                          borderBottom: "1px solid #f3f4f6",
                          fontSize: "0.85rem",
                        }}
                      >
                        {formatINR(inv.tax_amount)}
                      </td>
                      <td
                        style={{
                          padding: "10px 12px",
                          borderBottom: "1px solid #f3f4f6",
                          fontSize: "0.85rem",
                          fontWeight: 600,
                        }}
                      >
                        {formatINR(inv.total)}
                      </td>
                      <td
                        style={{
                          padding: "10px 12px",
                          borderBottom: "1px solid #f3f4f6",
                        }}
                      >
                        <FinanceStatusChip status={inv.status} />
                      </td>
                      <td
                        style={{
                          padding: "10px 12px",
                          borderBottom: "1px solid #f3f4f6",
                          fontSize: "0.85rem",
                          whiteSpace: "nowrap",
                        }}
                      >
                        {new Date(inv.created_at).toLocaleDateString("en-IN", {
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
                        <Tooltip title="Download PDF">
                          <IconButton
                            size="small"
                            onClick={() => handleDownload(inv.invoice_id)}
                          >
                            <Download size={16} />
                          </IconButton>
                        </Tooltip>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </Box>
        )}

        {totalPages > 1 && (
          <Pagination
            count={totalPages}
            page={currentPage}
            onChange={(_, page) =>
              dispatch(fetchInvoiceList(buildPayload(page)))
            }
          />
        )}
      </Paper>
    </>
  );
};

export default InvoiceList;
