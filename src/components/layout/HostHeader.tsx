import { useMemo, useState, type MouseEvent } from "react";
import {
  AppBar,
  Avatar,
  Box,
  Chip,
  IconButton,
  Menu,
  MenuItem,
  Toolbar,
  Typography,
} from "@mui/material";
import AccountCircleRoundedIcon from "@mui/icons-material/AccountCircleRounded";
import LogoutRoundedIcon from "@mui/icons-material/LogoutRounded";
import PersonRoundedIcon from "@mui/icons-material/PersonRounded";
import storage from "../../styles/utils/storage";
import { useLocation, useNavigate } from "react-router-dom";

const titleByPath: Array<{ key: string; title: string }> = [
  { key: "/host/bookings", title: "Host Bookings" },
  { key: "/host/earnings", title: "Host Earnings" },
  { key: "/host/performance", title: "Host Performance" },
  { key: "/host/statements", title: "Host Statements" },
  { key: "/host/profile", title: "Host Profile" },
  { key: "/host/support", title: "Host Support" },
  { key: "/host/communication", title: "Host Communication" },
];

export const HostHeader = () => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const location = useLocation();
  const navigate = useNavigate();

  const handleMenuOpen = (event: MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleMenuClose = () => setAnchorEl(null);

  const handleProfileClick = () => {
    handleMenuClose();
    navigate("/host/profile");
  };

  const handleLogoutClick = () => {
    handleMenuClose();
    storage.clearToken();
    localStorage.removeItem("adminToken");
    navigate("/");
  };

  const title = useMemo(() => {
    const match = titleByPath.find((item) => location.pathname.includes(item.key));
    return match?.title || "Host Dashboard";
  }, [location.pathname]);

  return (
    <AppBar
      position="sticky"
      elevation={0}
      sx={{
        background: "rgba(255,255,255,0.92)",
        backdropFilter: "blur(10px)",
        borderBottom: "1px solid #e5e7eb",
      }}
    >
      <Toolbar sx={{ minHeight: "4.35rem !important", justifyContent: "space-between", px: 3 }}>
        <Box>
          <Typography variant="h6" sx={{ color: "#111827", fontWeight: 800 }}>
            {title}
          </Typography>
          <Typography variant="caption" sx={{ color: "#6b7280" }}>
            {new Date().toLocaleDateString("en-IN", {
              day: "2-digit",
              month: "short",
              year: "numeric",
            })}
          </Typography>
        </Box>

        <Box sx={{ display: "flex", alignItems: "center", gap: 1.2 }}>
          <Chip
            size="small"
            label="Host Workspace"
            sx={{ bgcolor: "#ede9fe", color: "#5b21b6", fontWeight: 700 }}
          />
          <Avatar sx={{ width: 30, height: 30, bgcolor: "#6d28d9", fontSize: "0.9rem" }}>H</Avatar>
          <IconButton size="small" onClick={handleMenuOpen} sx={{ color: "#4b5563" }}>
            <AccountCircleRoundedIcon />
          </IconButton>
          <Menu
            anchorEl={anchorEl}
            open={Boolean(anchorEl)}
            onClose={handleMenuClose}
            anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
            transformOrigin={{ vertical: "top", horizontal: "right" }}
          >
            <MenuItem onClick={handleProfileClick}>
              <PersonRoundedIcon fontSize="small" style={{ marginRight: 8 }} />
              Profile
            </MenuItem>
            <MenuItem onClick={handleLogoutClick}>
              <LogoutRoundedIcon fontSize="small" style={{ marginRight: 8 }} />
              Logout
            </MenuItem>
          </Menu>
        </Box>
      </Toolbar>
    </AppBar>
  );
};
