import { useEffect, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import { fetchFinanceDashboard } from "../../../features/admin/finance/financeDashboard.slice";
import {
  Box,
  Paper,
  Stack,
  Typography,
  Chip,
  Alert,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
} from "@mui/material";
import { TableLoader } from "../../../components/admin/common/TableLoader";
import { AdminLineChart, AdmindPieChart, AdminGaugeChart } from "../../../components";
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
  Clock3,
  ArrowRight,
  BookText,
  HandCoins,
  FileText,
  BarChart3,
} from "lucide-react";

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

  // Use mock data immediately in development
  const data: FinanceDashboardData = USE_DEV_FINANCE_MOCKS
    ? MOCK_DASHBOARD
    : (apiData ??
      {
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

  if (loading && !USE_DEV_FINANCE_MOCKS) {
    return <TableLoader text="Loading finance dashboard..." minHeight={400} />;
  }

  if (error && !USE_DEV_FINANCE_MOCKS && !apiData) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="error">{error}</Alert>
      </Box>
    );
  }

  const quickActions = [
    { label: "Ledgers", icon: BookText, path: "/admin/finance/ledgers" },
    { label: "Payout Queue", icon: HandCoins, path: "/admin/finance/payouts" },
    { label: "Invoices", icon: FileText, path: "/admin/finance/invoices" },
    { label: "Reports", icon: BarChart3, path: "/admin/finance/reports/revenue" },
  ];

  const kpis = [
    {
      label: "Total Revenue",
      value: data?.totalRevenue ?? 0,
      growth: data?.revenueGrowth ?? 0,
      icon: IndianRupee,
      color: "#dcfce7",
      helperText: "Gross collections from guest payments",
    },
    {
      label: "Platform Commission",
      value: data?.totalCommission ?? 0,
      growth: data?.commissionGrowth ?? 0,
      icon: TrendingUp,
      color: "#f3e8ff",
      helperText: "Commission earned by platform",
    },
    {
      label: "Total Payouts",
      value: data?.totalPayouts ?? 0,
      icon: Wallet,
      color: "#dbeafe",
      helperText: "Released to hosts",
    },
    {
      label: "Pending Payouts",
      value: data?.pendingPayouts ?? 0,
      icon: Clock3,
      color: "#ffedd5",
      helperText: "Awaiting approval or processing",
    },
  ];

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

  const recentTransactions = useMemo(
    () => data?.recentTransactions?.slice(0, 6) ?? [],
    [data?.recentTransactions]
  );

  const sectionSurfaceSx = {
    p: 2.5,
    borderRadius: "1rem",
    border: "1px solid #ede9fe",
    boxShadow: "0 12px 28px rgba(17,24,39,0.06)",
    height: "100%",
  } as const;

  return (
    <Box sx={{ width: "100%", minHeight: "100%" }}>
      {error && USE_DEV_FINANCE_MOCKS && (
        <Alert severity="warning" sx={{ mb: 2 }}>
          Backend finance API is unavailable. Showing local mock dashboard data.
        </Alert>
      )}

      <Paper
        sx={{
          background: "linear-gradient(135deg, #6d28d9 0%, #8b5cf6 42%, #a855f7 100%)",
          borderRadius: "1.1rem",
          p: { xs: 2.5, md: 3.2 },
          mb: 4,
          color: "#fff",
          border: "1px solid rgba(255,255,255,0.2)",
          boxShadow: "0 14px 32px rgba(124,58,237,0.35)",
        }}
      >
        <Stack
          direction={{ xs: "column", md: "row" }}
          alignItems={{ xs: "flex-start", md: "center" }}
          justifyContent="space-between"
          spacing={2}
          mb={3}
        >
          <Box>
            <Typography variant="overline" sx={{ opacity: 0.9, letterSpacing: 0.8 }}>
              Finance Management System
            </Typography>
            <Typography variant="h4" fontWeight={800} sx={{ lineHeight: 1.1 }}>
              Financial Overview
            </Typography>
            <Typography variant="body2" sx={{ opacity: 0.85, mt: 0.9 }}>
              Track cashflow, reconcile records, and move payouts with confidence.
            </Typography>
          </Box>

          <Stack direction={{ xs: "column", sm: "row" }} spacing={1}>
            <Button
              variant="contained"
              onClick={() => navigate("/admin/finance/reports/revenue")}
              endIcon={<ArrowRight size={15} />}
              sx={{
                bgcolor: "#ffffff",
                color: "#6d28d9",
                textTransform: "none",
                fontWeight: 700,
                borderRadius: "0.7rem",
                "&:hover": { bgcolor: "#f5f3ff" },
              }}
            >
              View Reports
            </Button>
            <Button
              variant="outlined"
              onClick={() => navigate("/admin/finance/payouts")}
              sx={{
                borderColor: "rgba(255,255,255,0.5)",
                color: "#ffffff",
                textTransform: "none",
                fontWeight: 700,
                borderRadius: "0.7rem",
                "&:hover": {
                  borderColor: "rgba(255,255,255,0.85)",
                  bgcolor: "rgba(255,255,255,0.08)",
                },
              }}
            >
              Open Payout Queue
            </Button>
          </Stack>
        </Stack>

        <Box
          sx={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(230px, 1fr))",
            gap: "1rem",
          }}
        >
          {kpis.map((kpi) => (
            <FinanceKPICard key={kpi.label} {...kpi} />
          ))}
        </Box>
      </Paper>

      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(165px, 1fr))",
          gap: 1.4,
          mb: 2.2,
        }}
      >
        {quickActions.map((item) => {
          const Icon = item.icon;
          return (
            <Box
              key={item.path}
              onClick={() => navigate(item.path)}
              sx={{
                p: 1.35,
                borderRadius: "0.85rem",
                border: "1px solid #e5e7eb",
                bgcolor: "#ffffff",
                display: "flex",
                alignItems: "center",
                gap: 1,
                cursor: "pointer",
                transition: "all .2s ease",
                "&:hover": {
                  borderColor: "#d8b4fe",
                  bgcolor: "#faf5ff",
                  transform: "translateY(-1px)",
                },
              }}
            >
              <Box
                sx={{
                  width: 30,
                  height: 30,
                  borderRadius: "0.65rem",
                  bgcolor: "#f5f3ff",
                  display: "grid",
                  placeItems: "center",
                }}
              >
                <Icon size={16} color="#7c3aed" />
              </Box>
              <Typography variant="body2" fontWeight={600} color="#374151">
                {item.label}
              </Typography>
            </Box>
          );
        })}
      </Box>

      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: { xs: "1fr", xl: "1.6fr 1fr" },
          gap: 2,
          mb: 2.2,
        }}
      >
        <Paper sx={sectionSurfaceSx}>
          <Stack direction="row" justifyContent="space-between" alignItems="center" mb={1.5}>
            <Typography variant="h6" fontWeight={700} color="#111827">
              Revenue vs Commission Trend
            </Typography>
            <Chip label="Monthly" size="small" sx={{ bgcolor: "#f3f4f6", color: "#374151" }} />
          </Stack>
          {months.length > 0 ? (
            <AdminLineChart
              months={months}
              successfulData={revenueData}
              cancelledData={commissionData}
            />
          ) : (
            <Box sx={{ p: 4, textAlign: "center" }}>
              <Typography color="text.secondary">
                Revenue trend data will appear here once transactions are processed.
              </Typography>
            </Box>
          )}
        </Paper>

        <Paper sx={sectionSurfaceSx}>
          <Typography variant="h6" fontWeight={700} color="#111827" mb={1.5}>
            Revenue by Category
          </Typography>
          {pieData.length > 0 ? (
            <AdmindPieChart title=" " data={pieData} />
          ) : (
            <Box sx={{ p: 4, textAlign: "center" }}>
              <Typography color="text.secondary">
                Category breakdown will appear here.
              </Typography>
            </Box>
          )}
        </Paper>
      </Box>

      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: { xs: "1fr", xl: "360px 1fr" },
          gap: 2,
        }}
      >
        <Paper
          sx={{
            ...sectionSurfaceSx,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            gap: 1.4,
          }}
        >
          <Typography variant="h6" fontWeight={700} color="#111827">
            Reconciliation
          </Typography>
          <AdminGaugeChart value={reconPercent} label="Matched" />
          <Stack direction="row" spacing={1}>
            <Chip
              label={`${data?.reconciliationSummary?.variance ?? 0} variances`}
              size="small"
              sx={{ bgcolor: "#fff7ed", color: "#9a3412", border: "1px solid #fed7aa" }}
            />
            <Chip
              label={`${data?.reconciliationSummary?.pending ?? 0} pending`}
              size="small"
              sx={{ bgcolor: "#eff6ff", color: "#1e40af", border: "1px solid #bfdbfe" }}
            />
          </Stack>
          <Button
            variant="outlined"
            onClick={() => navigate("/admin/finance/reconciliation/records")}
            sx={{
              mt: 0.5,
              textTransform: "none",
              borderRadius: "0.65rem",
              borderColor: "#d8b4fe",
              color: "#6b21a8",
              "&:hover": { borderColor: "#a855f7", bgcolor: "#faf5ff" },
            }}
          >
            Open reconciliation records
          </Button>
        </Paper>

        <Paper sx={sectionSurfaceSx}>
          <Stack
            direction="row"
            justifyContent="space-between"
            alignItems="center"
            mb={1.2}
          >
            <Typography variant="h6" fontWeight={700} color="#111827">
              Recent Transactions
            </Typography>
            <Button
              variant="text"
              size="small"
              onClick={() => navigate("/admin/finance/ledgers")}
              endIcon={<ArrowRight size={14} />}
              sx={{ textTransform: "none", color: "#7c3aed", fontWeight: 700 }}
            >
              View all
            </Button>
          </Stack>

          {recentTransactions.length > 0 ? (
            <TableContainer sx={{ border: "1px solid #f1f5f9", borderRadius: "0.8rem" }}>
              <Table size="small">
                <TableHead>
                  <TableRow sx={{ bgcolor: "#f8fafc" }}>
                    {["Date", "Type", "Description", "Amount", "Status"].map((h) => (
                      <TableCell
                        key={h}
                        sx={{ color: "#64748b", fontSize: "0.76rem", fontWeight: 700, py: 1.15 }}
                      >
                        {h}
                      </TableCell>
                    ))}
                  </TableRow>
                </TableHead>
                <TableBody>
                  {recentTransactions.map((tx: LedgerEntry) => (
                    <TableRow key={tx.ledger_id} hover>
                      <TableCell sx={{ fontSize: "0.84rem", whiteSpace: "nowrap" }}>
                        {new Date(tx.created_at).toLocaleDateString("en-IN", {
                          day: "2-digit",
                          month: "short",
                        })}
                      </TableCell>
                      <TableCell>
                        <TransactionTypeChip type={tx.transaction_type} />
                      </TableCell>
                      <TableCell sx={{ fontSize: "0.84rem", maxWidth: 260 }}>
                        <Typography
                          variant="body2"
                          sx={{
                            maxWidth: 260,
                            overflow: "hidden",
                            textOverflow: "ellipsis",
                            whiteSpace: "nowrap",
                          }}
                        >
                          {tx.description}
                        </Typography>
                      </TableCell>
                      <TableCell
                        sx={{
                          fontWeight: 700,
                          color: tx.entry_type === "CREDIT" ? "#15803d" : "#b91c1c",
                          whiteSpace: "nowrap",
                        }}
                      >
                        {tx.entry_type === "CREDIT" ? "+" : "-"}
                        {formatINR(tx.amount)}
                      </TableCell>
                      <TableCell>
                        <FinanceStatusChip status={tx.status} />
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          ) : (
            <FinanceEmptyState
              variant="default"
              message="No transactions yet. Financial records will appear here as bookings are processed."
              minHeight={220}
            />
          )}
        </Paper>
      </Box>
    </Box>
  );
};

export default FinanceDashboard;
