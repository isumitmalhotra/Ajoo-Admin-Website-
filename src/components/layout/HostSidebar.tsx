import {
  Box,
  Divider,
  Drawer,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Typography,
} from "@mui/material";
import type { ReactNode } from "react";
import SpaceDashboardRoundedIcon from "@mui/icons-material/SpaceDashboardRounded";
import EventNoteRoundedIcon from "@mui/icons-material/EventNoteRounded";
import AccountBalanceWalletRoundedIcon from "@mui/icons-material/AccountBalanceWalletRounded";
import InsightsRoundedIcon from "@mui/icons-material/InsightsRounded";
import DescriptionRoundedIcon from "@mui/icons-material/DescriptionRounded";
import SupportAgentRoundedIcon from "@mui/icons-material/SupportAgentRounded";
import ForumRoundedIcon from "@mui/icons-material/ForumRounded";
import PersonRoundedIcon from "@mui/icons-material/PersonRounded";
import AddHomeRoundedIcon from "@mui/icons-material/AddHomeRounded";
import PrivacyTipRoundedIcon from "@mui/icons-material/PrivacyTipRounded";
import { NavLink } from "react-router-dom";

const drawerWidth = 260;

type MenuItemConfig = {
  text: string;
  path: string;
  icon: ReactNode;
};

const primaryMenuItems: MenuItemConfig[] = [
  { text: "Dashboard", icon: <SpaceDashboardRoundedIcon />, path: "/host/dashboard" },
  { text: "Bookings", icon: <EventNoteRoundedIcon />, path: "/host/bookings" },
  { text: "Earnings", icon: <AccountBalanceWalletRoundedIcon />, path: "/host/earnings" },
  { text: "Performance", icon: <InsightsRoundedIcon />, path: "/host/performance" },
  { text: "Statements", icon: <DescriptionRoundedIcon />, path: "/host/statements" },
  { text: "Support", icon: <SupportAgentRoundedIcon />, path: "/host/support" },
  { text: "Communication", icon: <ForumRoundedIcon />, path: "/host/communication" },
  { text: "Profile", icon: <PersonRoundedIcon />, path: "/host/profile" },
];

const utilityMenuItems: MenuItemConfig[] = [
  { text: "Add Property", icon: <AddHomeRoundedIcon />, path: "/admin/properties/form" },
  { text: "Privacy Policy", icon: <PrivacyTipRoundedIcon />, path: "/Privacy-Policy" },
];

export const HostSidebar = () => {
  const renderItem = (item: MenuItemConfig) => (
    <ListItemButton
      key={item.text}
      component={NavLink}
      to={item.path}
      sx={{
        borderRadius: "0.75rem",
        mx: 1.25,
        mb: 0.4,
        color: "rgba(255,255,255,0.86)",
        "&:hover": {
          bgcolor: "rgba(255,255,255,0.1)",
        },
        "&.active": {
          bgcolor: "rgba(255,255,255,0.18)",
          color: "#ffffff",
          border: "1px solid rgba(255,255,255,0.24)",
          boxShadow: "0 6px 18px rgba(0,0,0,0.18)",
        },
      }}
    >
      <ListItemIcon sx={{ color: "inherit", minWidth: 34 }}>{item.icon}</ListItemIcon>
      <ListItemText
        primary={item.text}
        primaryTypographyProps={{ fontSize: "0.92rem", fontWeight: 600 }}
      />
    </ListItemButton>
  );

  return (
    <Drawer
      variant="permanent"
      sx={{
        width: drawerWidth,
        flexShrink: 0,
        "& .MuiDrawer-paper": {
          width: drawerWidth,
          boxSizing: "border-box",
          border: "none",
          color: "#fff",
          background:
            "linear-gradient(176deg, #4c1d95 0%, #6d28d9 36%, #7c3aed 100%)",
        },
      }}
    >
      <Box sx={{ px: 2.2, py: 2.3 }}>
        <Typography variant="overline" sx={{ opacity: 0.76, letterSpacing: 1.2 }}>
          HMS Workspace
        </Typography>
        <Typography variant="h6" sx={{ fontWeight: 800, lineHeight: 1.15 }}>
          Host Portal
        </Typography>
      </Box>

      <Divider sx={{ borderColor: "rgba(255,255,255,0.2)" }} />

      <List sx={{ mt: 1 }}>{primaryMenuItems.map(renderItem)}</List>

      <Typography
        variant="caption"
        sx={{ px: 2.2, pt: 1.8, pb: 0.4, color: "rgba(255,255,255,0.65)", fontWeight: 600 }}
      >
        Utilities
      </Typography>
      <List sx={{ pt: 0.3 }}>{utilityMenuItems.map(renderItem)}</List>
    </Drawer>
  );
};
