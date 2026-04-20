import { useEffect, useState } from "react";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import { fetchTaxReport } from "../../../features/admin/finance/taxReport.slice";
import {
  Box,
  Paper,
  Typography,
  TextField,
  MenuItem,
  Stack,
} from "@mui/material";
import { TableLoader } from "../../../components/admin/common/TableLoader";
import DateRangeFilter from "../../../components/admin/finance/DateRangeFilter";
import ExportButton from "../../../components/admin/finance/ExportButton";
import FinanceEmptyState from "../../../components/admin/finance/FinanceEmptyState";
import FinanceErrorAlert from "../../../components/admin/finance/FinanceErrorAlert";
import type { ReportGroupBy, TaxReportResponse } from "./types";
import { formatINR } from "./utils";
import ReportTabNav from "../../../components/admin/finance/ReportTabNav";
import { MOCK_TAX_REPORT } from "./mockData";

const USE_DEV_FINANCE_MOCKS =
  import.meta.env.DEV &&
  import.meta.env.VITE_USE_FINANCE_MOCKS === "true";

const GROUP_OPTIONS: { value: ReportGroupBy; label: string }[] = [
  { value: "month", label: "Monthly" },
  { value: "week", label: "Weekly" },
];

const TaxSummary = () => {
  const dispatch = useAppDispatch();
  const { data: apiData, loading, error } = useAppSelector((state) => state.taxReport);

  const data: TaxReportResponse =
    apiData && apiData.data.length > 0
      ? apiData
      : USE_DEV_FINANCE_MOCKS
      ? MOCK_TAX_REPORT
      : { data: [], totals: { gstCollected: 0, gstPayable: 0, tdsDeducted: 0 } };

  const [filters, setFilters] = useState({
    dateFrom: new Date(new Date().getFullYear(), 0, 1)
      .toISOString()
      .split("T")[0],
    dateTo: new Date().toISOString().split("T")[0],
    groupBy: "month" as ReportGroupBy,
  });

  const handleGenerate = () => {
    dispatch(
      fetchTaxReport({
        dateFrom: filters.dateFrom,
        dateTo: filters.dateTo,
        groupBy: filters.groupBy,
      })
    );
  };

  useEffect(() => {
    handleGenerate();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <>
      <Typography variant="h5" fontWeight={600} color="#374151" mb={3}>
        Financial Reports
      </Typography>

      <ReportTabNav />

      {/* ================= FILTERS ================= */}
      <Paper sx={{ p: 2, borderRadius: "0.75rem", mb: 3 }}>
        <Stack
          direction={{ xs: "column", md: "row" }}
          spacing={2}
          alignItems="center"
        >
          <DateRangeFilter
            dateFrom={filters.dateFrom}
            dateTo={filters.dateTo}
            onChange={(from, to) =>
              setFilters((p) => ({ ...p, dateFrom: from, dateTo: to }))
            }
          />

          <TextField
            select
            size="small"
            value={filters.groupBy}
            onChange={(e) =>
              setFilters((p) => ({
                ...p,
                groupBy: e.target.value as ReportGroupBy,
              }))
            }
            sx={{ minWidth: 130 }}
          >
            {GROUP_OPTIONS.map((o) => (
              <MenuItem key={o.value} value={o.value}>
                {o.label}
              </MenuItem>
            ))}
          </TextField>

          <Box
            onClick={handleGenerate}
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
            Generate
          </Box>

          <ExportButton
            headers={["Period", "GST Collected", "GST Payable", "TDS Deducted"]}
            rows={(data?.data ?? []).map((r) => [r.period, r.gstCollected, r.gstPayable, r.tdsDeducted])}
            filename="tax-summary"
          />
        </Stack>
      </Paper>

      {/* ================= TOTALS ================= */}
      {data?.totals && (
        <Box
          sx={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
            gap: 2,
            mb: 3,
          }}
        >
          {[
            {
              label: "GST Collected",
              value: formatINR(data.totals.gstCollected),
              color: "#881f9b",
            },
            {
              label: "GST Payable",
              value: formatINR(data.totals.gstPayable),
              color: "#dc2626",
            },
            {
              label: "TDS Deducted",
              value: formatINR(data.totals.tdsDeducted),
              color: "#2563eb",
            },
          ].map((stat) => (
            <Paper
              key={stat.label}
              sx={{ p: 3, borderRadius: "0.75rem", textAlign: "center" }}
            >
              <Typography variant="h4" fontWeight={700} color={stat.color}>
                {stat.value}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {stat.label}
              </Typography>
            </Paper>
          ))}
        </Box>
      )}

      {/* ================= TABLE ================= */}
      <Paper sx={{ p: 3, borderRadius: "0.75rem" }}>
        {loading ? (
          <TableLoader text="Generating tax report..." minHeight={300} />
        ) : error && !USE_DEV_FINANCE_MOCKS ? (
          <FinanceErrorAlert message={error} onRetry={handleGenerate} />
        ) : data?.data && data.data.length > 0 ? (
          <Box sx={{ overflowX: "auto" }}>
            <table style={{ width: "100%", borderCollapse: "collapse" }}>
              <thead>
                <tr>
                  {[
                    "Period",
                    "GST Collected",
                    "GST Payable",
                    "TDS Deducted",
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
                      }}
                    >
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {data.data.map((row) => (
                  <tr key={row.period}>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        fontWeight: 500,
                      }}
                    >
                      {row.period}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        fontWeight: 600,
                        color: "#881f9b",
                      }}
                    >
                      {formatINR(row.gstCollected)}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        fontWeight: 600,
                        color: "#dc2626",
                      }}
                    >
                      {formatINR(row.gstPayable)}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        fontWeight: 600,
                        color: "#2563eb",
                      }}
                    >
                      {formatINR(row.tdsDeducted)}
                    </td>
                  </tr>
                ))}
                {/* TOTALS ROW */}
                <tr style={{ backgroundColor: "#f9fafb" }}>
                  <td
                    style={{
                      padding: "10px 12px",
                      fontWeight: 700,
                      fontSize: "0.85rem",
                    }}
                  >
                    TOTAL
                  </td>
                  <td
                    style={{
                      padding: "10px 12px",
                      fontWeight: 700,
                      fontSize: "0.85rem",
                      color: "#881f9b",
                    }}
                  >
                    {formatINR(data.totals.gstCollected)}
                  </td>
                  <td
                    style={{
                      padding: "10px 12px",
                      fontWeight: 700,
                      fontSize: "0.85rem",
                      color: "#dc2626",
                    }}
                  >
                    {formatINR(data.totals.gstPayable)}
                  </td>
                  <td
                    style={{
                      padding: "10px 12px",
                      fontWeight: 700,
                      fontSize: "0.85rem",
                      color: "#2563eb",
                    }}
                  >
                    {formatINR(data.totals.tdsDeducted)}
                  </td>
                </tr>
              </tbody>
            </table>
          </Box>
        ) : (
          <FinanceEmptyState variant="reports" />
        )}
      </Paper>
    </>
  );
};

export default TaxSummary;
