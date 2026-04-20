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
    <Paper sx={{ borderRadius: "0.75rem", mb: 3 }}>
      <Tabs
        value={activeIndex === -1 ? 0 : activeIndex}
        onChange={(_, v) => navigate(REPORT_TABS[v].path)}
        sx={{
          px: 2,
          "& .MuiTab-root": { textTransform: "none", fontWeight: 500 },
          "& .Mui-selected": { color: "#881f9b" },
          "& .MuiTabs-indicator": { backgroundColor: "#881f9b" },
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
