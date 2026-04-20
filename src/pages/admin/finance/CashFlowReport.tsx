import { useEffect, useState } from "react";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import { fetchCashFlowReport } from "../../../features/admin/finance/cashFlowReport.slice";
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
import type { ReportGroupBy, CashFlowReportResponse } from "./types";
import { formatINR } from "./utils";
import ReportTabNav from "../../../components/admin/finance/ReportTabNav";
import { MOCK_CASHFLOW_REPORT } from "./mockData";

const USE_DEV_FINANCE_MOCKS =
  import.meta.env.DEV &&
  import.meta.env.VITE_USE_FINANCE_MOCKS === "true";

const GROUP_OPTIONS: { value: ReportGroupBy; label: string }[] = [
  { value: "day", label: "Daily" },
  { value: "week", label: "Weekly" },
  { value: "month", label: "Monthly" },
];

const CashFlowReport = () => {
  const dispatch = useAppDispatch();
  const { data: apiData, loading, error } = useAppSelector((state) => state.cashFlowReport);

  const data: CashFlowReportResponse =
    apiData && apiData.data.length > 0
      ? apiData
      : USE_DEV_FINANCE_MOCKS
      ? MOCK_CASHFLOW_REPORT
      : { data: [], totals: { totalInflow: 0, totalOutflow: 0, netFlow: 0 } };

  const [filters, setFilters] = useState({
    dateFrom: new Date(new Date().getFullYear(), 0, 1)
      .toISOString()
      .split("T")[0],
    dateTo: new Date().toISOString().split("T")[0],
    groupBy: "month" as ReportGroupBy,
  });

  const handleGenerate = () => {
    dispatch(
      fetchCashFlowReport({
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
            headers={["Period", "Inflow", "Outflow", "Net Flow"]}
            rows={(data?.data ?? []).map((r) => [r.period, r.inflow, r.outflow, r.netFlow])}
            filename="cashflow-report"
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
              label: "Total Inflow",
              value: formatINR(data.totals.totalInflow),
              color: "#16a34a",
            },
            {
              label: "Total Outflow",
              value: formatINR(data.totals.totalOutflow),
              color: "#dc2626",
            },
            {
              label: "Net Cash Flow",
              value: formatINR(data.totals.netFlow),
              color:
                data.totals.netFlow >= 0 ? "#16a34a" : "#dc2626",
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
          <TableLoader text="Generating cash flow report..." minHeight={300} />
        ) : error && !USE_DEV_FINANCE_MOCKS ? (
          <FinanceErrorAlert message={error} onRetry={handleGenerate} />
        ) : data?.data && data.data.length > 0 ? (
          <Box sx={{ overflowX: "auto" }}>
            <table style={{ width: "100%", borderCollapse: "collapse" }}>
              <thead>
                <tr>
                  {["Period", "Inflow", "Outflow", "Net Flow"].map((h) => (
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
                        color: "#16a34a",
                      }}
                    >
                      {formatINR(row.inflow)}
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
                      {formatINR(row.outflow)}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        fontWeight: 700,
                        color: row.netFlow >= 0 ? "#16a34a" : "#dc2626",
                      }}
                    >
                      {row.netFlow >= 0 ? "+" : ""}
                      {formatINR(row.netFlow)}
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
                      color: "#16a34a",
                    }}
                  >
                    {formatINR(data.totals.totalInflow)}
                  </td>
                  <td
                    style={{
                      padding: "10px 12px",
                      fontWeight: 700,
                      fontSize: "0.85rem",
                      color: "#dc2626",
                    }}
                  >
                    {formatINR(data.totals.totalOutflow)}
                  </td>
                  <td
                    style={{
                      padding: "10px 12px",
                      fontWeight: 700,
                      fontSize: "0.85rem",
                      color:
                        data.totals.netFlow >= 0 ? "#16a34a" : "#dc2626",
                    }}
                  >
                    {data.totals.netFlow >= 0 ? "+" : ""}
                    {formatINR(data.totals.netFlow)}
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

export default CashFlowReport;
