import { useEffect, useMemo, useState, type MouseEvent } from "react";
import {
  AppBar,
  Avatar,
  Badge,
  Box,
  Chip,
  Divider,
  IconButton,
  Menu,
  MenuItem,
  Popover,
  Stack,
  Toolbar,
  Typography,
} from "@mui/material";
import AccountCircleRoundedIcon from "@mui/icons-material/AccountCircleRounded";
import LogoutRoundedIcon from "@mui/icons-material/LogoutRounded";
import PersonRoundedIcon from "@mui/icons-material/PersonRounded";
import { Bell } from "lucide-react";
import storage from "../../styles/utils/storage";
import { useLocation, useNavigate } from "react-router-dom";
import { useAppDispatch, useAppSelector } from "../../app/hooks";
import {
  fetchHostNotifications,
  markHostNotificationRead,
} from "../../features/host/hostNotifications.slice";

const relativeTime = (iso: string) => {
  const mins = Math.round((Date.now() - new Date(iso).getTime()) / 60000);
  if (mins < 1) return "just now";
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.round(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  return `${Math.round(hrs / 24)}d ago`;
};

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
  const [notifyAnchor, setNotifyAnchor] = useState<null | HTMLElement>(null);
  const location = useLocation();
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  const { items } = useAppSelector((state) => state.hostNotifications);
  const unreadCount = useMemo(() => items.filter((n) => !n.read).length, [items]);

  // Fetch on mount + poll every 30s (B-13) against A-14 /host/notifications/search.
  useEffect(() => {
    dispatch(fetchHostNotifications());
    const interval = setInterval(() => dispatch(fetchHostNotifications()), 30_000);
    return () => clearInterval(interval);
  }, [dispatch]);

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
            sx={{ bgcolor: "#FFFAF0", color: "#1B2447", fontWeight: 700, border: "1px solid #D9CFB8" }}
          />

          <IconButton
            size="small"
            onClick={(e) => setNotifyAnchor(e.currentTarget)}
            aria-label="Open notifications"
            sx={{ color: "#4b5563" }}
          >
            <Badge
              badgeContent={unreadCount}
              color="error"
              sx={{ "& .MuiBadge-badge": { fontSize: "0.6rem", height: 15, minWidth: 15 } }}
            >
              <Bell size={19} />
            </Badge>
          </IconButton>

          <Popover
            open={Boolean(notifyAnchor)}
            anchorEl={notifyAnchor}
            onClose={() => setNotifyAnchor(null)}
            anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
            transformOrigin={{ vertical: "top", horizontal: "right" }}
            PaperProps={{ sx: { width: 340, maxHeight: 420, borderRadius: "0.9rem", mt: 0.5 } }}
          >
            <Box sx={{ px: 2, py: 1.5, borderBottom: "1px solid #f1f5f9" }}>
              <Typography variant="subtitle2" fontWeight={800} color="#111827">
                Notifications {unreadCount > 0 ? `(${unreadCount} new)` : ""}
              </Typography>
            </Box>
            {items.length === 0 ? (
              <Box sx={{ px: 2, py: 4, textAlign: "center" }}>
                <Typography variant="body2" color="text.secondary">
                  You're all caught up.
                </Typography>
              </Box>
            ) : (
              <Box sx={{ overflowY: "auto", maxHeight: 340 }}>
                {items.map((n, i) => (
                  <Box key={n.id}>
                    {i > 0 && <Divider />}
                    <Box
                      onClick={() => !n.read && dispatch(markHostNotificationRead(n.id))}
                      sx={{
                        px: 2,
                        py: 1.25,
                        cursor: n.read ? "default" : "pointer",
                        bgcolor: n.read ? "#fff" : "#faf5ff",
                        "&:hover": { bgcolor: n.read ? "#f9fafb" : "#f3e8ff" },
                      }}
                    >
                      <Stack direction="row" justifyContent="space-between" spacing={1}>
                        <Typography variant="body2" fontWeight={700} color="#111827" noWrap>
                          {n.title}
                        </Typography>
                        <Typography variant="caption" color="text.secondary" sx={{ flexShrink: 0 }}>
                          {relativeTime(n.createdAt)}
                        </Typography>
                      </Stack>
                      <Typography variant="caption" color="text.secondary" sx={{ display: "block", mt: 0.25 }}>
                        {n.message}
                      </Typography>
                    </Box>
                  </Box>
                ))}
              </Box>
            )}
          </Popover>

          <Avatar sx={{ width: 30, height: 30, bgcolor: "#1B2447", fontSize: "0.9rem" }}>H</Avatar>
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
