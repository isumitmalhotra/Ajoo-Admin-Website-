import { Tabs, Tab, Paper } from "@mui/material";
import { useNavigate, useLocation } from "react-router-dom";

const REPORT_TABS = [
  { label: "Revenue", path: "/admin/finance/reports/revenue" },
  { label: "Commission", path: "/admin/finance/reports/commission" },
  { label: "Tax Summary", path: "/admin/finance/reports/tax" },
  { label: "Cash Flow", path: "/admin/finance/reports/cashflow" },
];

const ReportTabNav = () => {
  const navigate = useNavigate();
  const { pathname } = useLocation();

  const activeIndex = REPORT_TABS.findIndex((t) => pathname.startsWith(t.path));

  return (
    <Paper
      sx={{
        borderRadius: "0.85rem",
        mb: 3,
        p: 0.8,
        border: "1px solid #ede9fe",
        boxShadow: "0 8px 20px rgba(17,24,39,0.04)",
      }}
    >
      <Tabs
        value={activeIndex === -1 ? 0 : activeIndex}
        onChange={(_, v) => navigate(REPORT_TABS[v].path)}
        variant="scrollable"
        allowScrollButtonsMobile
        sx={{
          minHeight: 40,
          "& .MuiTabs-indicator": { display: "none" },
          "& .MuiTab-root": {
            textTransform: "none",
            fontWeight: 600,
            borderRadius: "0.65rem",
            minHeight: 38,
            px: 1.8,
            py: 0.65,
            color: "#6b7280",
            transition: "all .2s ease",
          },
          "& .Mui-selected": {
            color: "#6b21a8",
            bgcolor: "#faf5ff",
            border: "1px solid #d8b4fe",
          },
        }}
      >
        {REPORT_TABS.map((tab) => (
          <Tab key={tab.path} label={tab.label} />
        ))}
      </Tabs>
    </Paper>
  );
};

export default ReportTabNav;
