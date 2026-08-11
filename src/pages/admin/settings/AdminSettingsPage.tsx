import { useState, type SyntheticEvent } from "react";
import { Box, Paper, Stack, Typography, Tabs, Tab } from "@mui/material";
import { Settings as SettingsIcon } from "lucide-react";
import PlatformTab from "./tabs/PlatformTab";
import NotificationsTab from "./tabs/NotificationsTab";
import SecurityTab from "./tabs/SecurityTab";
import IntegrationsTab from "./tabs/IntegrationsTab";

const TABS = [
  { label: "Platform", render: () => <PlatformTab /> },
  { label: "Notifications", render: () => <NotificationsTab /> },
  { label: "Security", render: () => <SecurityTab /> },
  { label: "Integrations", render: () => <IntegrationsTab /> },
];

const AdminSettingsPage = () => {
  const [tab, setTab] = useState(0);

  const handleChange = (_e: SyntheticEvent, value: number) => setTab(value);

  return (
    <Box sx={{ width: "100%", minHeight: "100%" }}>
      <Paper
        sx={{
          background: "linear-gradient(135deg, #6d28d9 0%, #3D4670 42%, #C16345 100%)",
          borderRadius: "1.1rem",
          p: { xs: 2.5, md: 3.2 },
          mb: 3,
          color: "#fff",
          border: "1px solid rgba(255,255,255,0.2)",
          boxShadow: "0 14px 32px rgba(124,58,237,0.35)",
        }}
      >
        <Stack direction="row" spacing={1.5} alignItems="center">
          <Box
            sx={{
              width: 44,
              height: 44,
              borderRadius: "0.8rem",
              bgcolor: "rgba(255,255,255,0.15)",
              display: "grid",
              placeItems: "center",
              flexShrink: 0,
            }}
          >
            <SettingsIcon size={22} color="#fff" />
          </Box>
          <Box>
            <Typography variant="overline" sx={{ opacity: 0.9, letterSpacing: 0.8 }}>
              Administration
            </Typography>
            <Typography variant="h4" fontWeight={800} sx={{ lineHeight: 1.1 }}>
              Platform Settings
            </Typography>
            <Typography variant="body2" sx={{ opacity: 0.85, mt: 0.6 }}>
              Configure branding, notifications, security and integrations.
            </Typography>
          </Box>
        </Stack>
      </Paper>

      <Paper
        sx={{
          borderRadius: "1rem",
          border: "1px solid #ede9fe",
          boxShadow: "0 12px 28px rgba(17,24,39,0.06)",
          mb: 2.5,
          px: { xs: 1, md: 2 },
        }}
      >
        <Tabs
          value={tab}
          onChange={handleChange}
          variant="scrollable"
          scrollButtons="auto"
          sx={{
            "& .MuiTab-root": {
              textTransform: "none",
              fontWeight: 600,
              color: "#64748b",
              minHeight: 52,
            },
            "& .Mui-selected": { color: "#6d28d9 !important" },
            "& .MuiTabs-indicator": { backgroundColor: "#6d28d9", height: 3, borderRadius: 3 },
          }}
        >
          {TABS.map((t) => (
            <Tab key={t.label} label={t.label} />
          ))}
        </Tabs>
      </Paper>

      <Box>{TABS[tab].render()}</Box>
    </Box>
  );
};

export default AdminSettingsPage;
