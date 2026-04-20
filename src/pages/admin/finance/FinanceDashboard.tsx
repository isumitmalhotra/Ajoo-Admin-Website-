import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import { fetchFinanceDashboard } from "../../../features/admin/finance/financeDashboard.slice";
import { Box, Paper, Stack, Typography, Chip, Alert } from "@mui/material";
import { TableLoader } from "../../../components/admin/common/TableLoader";
import {
  AdminLineChart,
  AdmindPieChart,
  AdminGaugeChart,
} from "../../../components";
import FinanceKPICard from "../../../components/admin/finance/FinanceKPICard";
import TransactionTypeChip from "../../../components/admin/finance/TransactionTypeChip";
import FinanceStatusChip from "../../../components/admin/finance/FinanceStatusChip";
import FinanceEmptyState from "../../../components/admin/finance/FinanceEmptyState";
import type { FinanceDashboardData, LedgerEntry } from "./types";
import { formatINR } from "./utils";
import {
  IndianRupee,
  TrendingUp,
  Wallet,
  Clock,
} from "lucide-react";

const sectionCard = {
  p: 3,
  borderRadius: "1rem",
  mb: 3,
  display: "flex",
  flexWrap: "wrap" as const,
  gap: 3,
};

const USE_DEV_FINANCE_MOCKS =
  import.meta.env.DEV &&
  import.meta.env.VITE_USE_FINANCE_MOCKS === "true";

const MOCK_DASHBOARD: FinanceDashboardData = {
  totalRevenue: 1250000,
  totalCommission: 187500,
  totalPayouts: 1020000,
  pendingPayouts: 32000,
  revenueGrowth: 12.4,
  commissionGrowth: 8.1,
  monthlyRevenue: [
    { month: "Oct", revenue: 170000, commission: 25500, payouts: 138000 },
    { month: "Nov", revenue: 185000, commission: 27750, payouts: 149500 },
    { month: "Dec", revenue: 210000, commission: 31500, payouts: 168500 },
    { month: "Jan", revenue: 198000, commission: 29700, payouts: 161000 },
    { month: "Feb", revenue: 232000, commission: 34800, payouts: 188500 },
    { month: "Mar", revenue: 255000, commission: 38250, payouts: 214500 },
  ],
  categoryBreakdown: [
    { category: "Hotels", revenue: 650000, percentage: 52 },
    { category: "Villas", revenue: 390000, percentage: 31 },
    { category: "Apartments", revenue: 210000, percentage: 17 },
  ],
  recentTransactions: [
    {
      ledger_id: 901,
      booking_id: 4101,
      host_id: 22,
      user_id: 301,
      transaction_type: "GUEST_PAYMENT",
      entry_type: "CREDIT",
      amount: 8500,
      balance_after: 8500,
      reference_id: "TXN-901",
      description: "Guest booking payment",
      status: "COMPLETED",
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
    {
      ledger_id: 902,
      booking_id: 4102,
      host_id: 24,
      user_id: 302,
      transaction_type: "HOST_EARNING",
      entry_type: "CREDIT",
      amount: 6400,
      balance_after: 14900,
      reference_id: "TXN-902",
      description: "Host earning release",
      status: "COMPLETED",
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
  ],
  reconciliationSummary: { matched: 45, variance: 7, pending: 12 },
};

const FinanceDashboard = () => {
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const { data: apiData, loading, error } = useAppSelector((state) => state.financeDashboard);

  useEffect(() => {
    dispatch(fetchFinanceDashboard());
  }, [dispatch]);

  const data: FinanceDashboardData = apiData ??
    (USE_DEV_FINANCE_MOCKS
      ? MOCK_DASHBOARD
      : {
          totalRevenue: 0,
          totalCommission: 0,
          totalPayouts: 0,
          pendingPayouts: 0,
          revenueGrowth: 0,
          commissionGrowth: 0,
          monthlyRevenue: [],
          categoryBreakdown: [],
          recentTransactions: [],
          reconciliationSummary: { matched: 0, variance: 0, pending: 0 },
        });

  if (loading) {
    return <TableLoader text="Loading finance dashboard..." minHeight={400} />;
  }

  if (error && !USE_DEV_FINANCE_MOCKS) {
    return <Alert severity="error">{error}</Alert>;
  }

  const kpis = [
    {
      label: "Total Revenue",
      value: data?.totalRevenue ?? 0,
      growth: data?.revenueGrowth ?? 0,
      icon: IndianRupee,
      color: "#16a34a",
    },
    {
      label: "Platform Commission",
      value: data?.totalCommission ?? 0,
      growth: data?.commissionGrowth ?? 0,
      icon: TrendingUp,
      color: "#881f9b",
    },
    {
      label: "Total Payouts",
      value: data?.totalPayouts ?? 0,
      icon: Wallet,
      color: "#2563eb",
    },
    {
      label: "Pending Payouts",
      value: data?.pendingPayouts ?? 0,
      icon: Clock,
      color: "#ea580c",
    },
  ];

  /* Chart data */
  const months = data?.monthlyRevenue?.map((m) => m.month) ?? [];
  const revenueData = data?.monthlyRevenue?.map((m) => m.revenue) ?? [];
  const commissionData = data?.monthlyRevenue?.map((m) => m.commission) ?? [];

  const pieData =
    data?.categoryBreakdown?.map((c, i) => ({
      id: i,
      label: c.category,
      value: c.revenue,
    })) ?? [];

  const reconTotal =
    (data?.reconciliationSummary?.matched ?? 0) +
    (data?.reconciliationSummary?.variance ?? 0) +
    (data?.reconciliationSummary?.pending ?? 0);
  const reconPercent =
    reconTotal > 0
      ? Math.round(
          ((data?.reconciliationSummary?.matched ?? 0) / reconTotal) * 100
        )
      : 0;

  return (
    <>
      {error && USE_DEV_FINANCE_MOCKS && (
        <Alert severity="warning" sx={{ mb: 2 }}>
          Backend finance API is unavailable. Showing local mock dashboard data.
        </Alert>
      )}

      {/* ================= HERO HEADER ================= */}
      <Paper
        sx={{
          background:
            "linear-gradient(135deg, #881f9b 0%, #a855f7 50%, #9333ea 100%)",
          borderRadius: "1rem",
          p: 4,
          mb: 4,
          color: "#fff",
        }}
      >
        <Typography variant="h6">Finance Management</Typography>
        <Typography variant="h4" fontWeight={700} mb={4}>
          Financial Overview
        </Typography>

        <Box
          sx={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))",
            gap: "1.5rem",
          }}
        >
          {kpis.map((kpi) => (
            <FinanceKPICard key={kpi.label} {...kpi} />
          ))}
        </Box>
      </Paper>

      {/* ================= CHARTS ROW ================= */}
      <Paper sx={sectionCard}>
        <Box sx={{ flex: 2, minWidth: 0 }}>
          {months.length > 0 ? (
            <AdminLineChart
              months={months}
              successfulData={revenueData}
              cancelledData={commissionData}
            />
          ) : (
            <Box sx={{ p: 4, textAlign: "center" }}>
              <Typography color="text.secondary">
                Revenue trend data will appear here once transactions are
                processed.
              </Typography>
            </Box>
          )}
        </Box>

        <Box sx={{ flex: 1, minWidth: 0 }}>
          {pieData.length > 0 ? (
            <AdmindPieChart
              title="Revenue by Category"
              data={pieData}
            />
          ) : (
            <Box sx={{ p: 4, textAlign: "center" }}>
              <Typography color="text.secondary">
                Category breakdown will appear here.
              </Typography>
            </Box>
          )}
        </Box>
      </Paper>

      {/* ================= RECONCILIATION + RECENT TRANSACTIONS ROW ================= */}
      <Paper sx={sectionCard}>
        <Box
          sx={{
            flex: 1,
            minWidth: 200,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 2,
          }}
        >
          <Typography variant="h6" fontWeight={600} color="#374151">
            Reconciliation
          </Typography>
          <AdminGaugeChart value={reconPercent} label="Matched" />
          <Stack direction="row" spacing={2}>
            <Chip
              label={`${data?.reconciliationSummary?.variance ?? 0} variances`}
              color="warning"
              size="small"
              variant="outlined"
            />
            <Chip
              label={`${data?.reconciliationSummary?.pending ?? 0} pending`}
              color="info"
              size="small"
              variant="outlined"
            />
          </Stack>
        </Box>

        <Box sx={{ flex: 3, minWidth: 0 }}>
          <Stack
            direction="row"
            justifyContent="space-between"
            alignItems="center"
            mb={2}
          >
            <Typography variant="h6" fontWeight={600} color="#374151">
              Recent Transactions
            </Typography>
            <Chip
              label="View All"
              onClick={() => navigate("/admin/finance/ledgers")}
              sx={{
                cursor: "pointer",
                color: "#881f9b",
                borderColor: "#881f9b",
              }}
              variant="outlined"
              size="small"
            />
          </Stack>

          {data?.recentTransactions && data.recentTransactions.length > 0 ? (
            <Box sx={{ overflowX: "auto" }}>
              <table style={{ width: "100%", borderCollapse: "collapse" }}>
                <thead>
                  <tr>
                    {["Date", "Type", "Description", "Amount", "Status"].map(
                      (h) => (
                        <th
                          key={h}
                          style={{
                            textAlign: "left",
                            padding: "8px 12px",
                            borderBottom: "1px solid #e5e7eb",
                            fontSize: "0.8rem",
                            fontWeight: 600,
                            color: "#6b7280",
                          }}
                        >
                          {h}
                        </th>
                      )
                    )}
                  </tr>
                </thead>
                <tbody>
                  {data.recentTransactions.slice(0, 5).map((tx: LedgerEntry) => (
                    <tr key={tx.ledger_id}>
                      <td
                        style={{
                          padding: "8px 12px",
                          borderBottom: "1px solid #f3f4f6",
                          fontSize: "0.85rem",
                        }}
                      >
                        {new Date(tx.created_at).toLocaleDateString("en-IN", {
                          day: "2-digit",
                          month: "short",
                        })}
                      </td>
                      <td
                        style={{
                          padding: "8px 12px",
                          borderBottom: "1px solid #f3f4f6",
                        }}
                      >
                        <TransactionTypeChip type={tx.transaction_type} />
                      </td>
                      <td
                        style={{
                          padding: "8px 12px",
                          borderBottom: "1px solid #f3f4f6",
                          fontSize: "0.85rem",
                          maxWidth: 200,
                          overflow: "hidden",
                          textOverflow: "ellipsis",
                          whiteSpace: "nowrap",
                        }}
                      >
                        {tx.description}
                      </td>
                      <td
                        style={{
                          padding: "8px 12px",
                          borderBottom: "1px solid #f3f4f6",
                          fontSize: "0.85rem",
                          fontWeight: 600,
                          color:
                            tx.entry_type === "CREDIT" ? "#16a34a" : "#dc2626",
                        }}
                      >
                        {tx.entry_type === "CREDIT" ? "+" : "-"}
                        {formatINR(tx.amount)}
                      </td>
                      <td
                        style={{
                          padding: "8px 12px",
                          borderBottom: "1px solid #f3f4f6",
                        }}
                      >
                        <FinanceStatusChip status={tx.status} />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </Box>
          ) : (
            <FinanceEmptyState variant="default" message="No transactions yet. Financial records will appear here as bookings are processed." />
          )}
        </Box>
      </Paper>
    </>
  );
};

export default FinanceDashboard;
