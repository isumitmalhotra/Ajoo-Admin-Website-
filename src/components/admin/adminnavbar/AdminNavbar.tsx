import React, { useEffect, useState } from "react";
import {
  AppBar,
  Toolbar,
  Box,
  Typography,
  IconButton,
  Avatar,
  Button,
  Menu,
  MenuItem,
  Badge,
} from "@mui/material";
import { MenuSquareIcon, ChevronDown, Bell } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useSidebar } from "../../../context/AdminContext";
import userImg from "../../../assets/user.jpg";
import AdminNotifySidebar from "../adminNotification/AdminNotifySidebar";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import { fetchAdminNotifications } from "../../../features/admin/notifications/notifications.slice";
import { logout } from "../../../features/admin/adminAuth/adminAuth.slice";

const AdminNavbar = () => {
  const { toggleSidebar } = useSidebar();
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const unreadCount = useAppSelector((state) =>
    state.adminNotifications.items.filter((n) => !n.read).length
  );
  const admin = useAppSelector(
    (state) => state.adminAuth.admin
  ) as Record<string, unknown> | null;

  const adminName =
    (admin?.name as string) ||
    (admin?.admin_name as string) ||
    (admin?.fullName as string) ||
    "Admin User";
  const adminEmail = (admin?.email as string) || "Administrator";

  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const isMenuOpen = Boolean(anchorEl);
  const [notifyOpen, setNotifyOpen] = useState(false);

  // Seed the unread badge on mount + poll every 30s (B-09) so the badge stays
  // live against A-14's /admin/notifications/search.
  useEffect(() => {
    dispatch(fetchAdminNotifications());
    const interval = setInterval(() => {
      dispatch(fetchAdminNotifications());
    }, 30_000);
    return () => clearInterval(interval);
  }, [dispatch]);

  const handleMenuOpen = (event: React.MouseEvent<HTMLButtonElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
  };

  const handleProfile = () => {
    handleMenuClose();
    navigate("/admin/settings");
  };

  const handleLogout = () => {
    handleMenuClose();
    dispatch(logout()); // clears adminSession (token/claims/roles) via the reducer
    navigate("/admin/login", { replace: true });
  };

  return (
    <AppBar
      position="sticky"
      elevation={0}
      sx={{
        bgcolor: "#ffffff",
        borderBottom: "1px solid #e5e7eb",
        zIndex: 1201, // above sidebar
      }}
    >
      <Toolbar
        sx={{
          minHeight: "4rem",
          px: { xs: 1.5, md: "2vw" },
          display: "flex",
          justifyContent: "space-between",
        }}
      >
        {/* LEFT SECTION */}
        <Box display="flex" alignItems="center" gap={2}>
          <IconButton
            onClick={toggleSidebar}
            sx={{
              color: "#6b7280",
              borderRadius: "8px",
              "&:hover": {
                bgcolor: "#f3f4f6",
                color: "#4b5563",
              },
            }}
          >
            <MenuSquareIcon size={20} />
          </IconButton>

          <Typography
            variant="h6"
            sx={{
              fontWeight: 600,
              color: "#111827",
              fontSize: { xs: "1rem", sm: "1.25rem" },
            }}
          >
            Dashboard
          </Typography>
        </Box>

        {/* RIGHT SECTION */}
        <Box display="flex" alignItems="center" gap={1.5}>
          {/* NOTIFICATIONS */}
          <IconButton
            onClick={() => setNotifyOpen(true)}
            aria-label="Open notifications"
            sx={{
              color: "#6b7280",
              borderRadius: "8px",
              "&:hover": { bgcolor: "#f3f4f6", color: "#4b5563" },
            }}
          >
            <Badge
              badgeContent={unreadCount}
              color="error"
              overlap="circular"
              sx={{ "& .MuiBadge-badge": { fontSize: "0.65rem", height: 16, minWidth: 16 } }}
            >
              <Bell size={20} />
            </Badge>
          </IconButton>

          <Box
            display="flex"
            alignItems="center"
            gap={1.5}
            sx={{
              bgcolor: "#f9fafb",
              border: "1px solid #e5e7eb",
              borderRadius: "999px",
              px: 1.5,
              py: 0.5,
              transition: "0.2s",
              "&:hover": {
                bgcolor: "#f3f4f6",
                boxShadow: "0 2px 4px rgba(0,0,0,0.05)",
              },
            }}
          >
            <Avatar
              src={userImg}
              sx={{ width: 40, height: 40 }}
              alt="User"
            />

            {/* USER INFO */}
            <Box
              sx={{
                display: { xs: "none", sm: "flex" },
                flexDirection: "column",
              }}
            >
              <Typography
                sx={{
                  fontSize: "0.95rem",
                  fontWeight: 600,
                  color: "#111827",
                  lineHeight: 1.2,
                }}
              >
                {adminName}
              </Typography>
              <Typography
                sx={{
                  fontSize: "0.75rem",
                  color: "#6b7280",
                  lineHeight: 1.2,
                }}
              >
                {adminEmail}
              </Typography>
            </Box>

            <Button
              onClick={handleMenuOpen}
              disableElevation
              sx={{
                minWidth: "auto",
                p: 0.5,
                color: "#6b7280",
                "&:hover": {
                  color: "#374151",
                  bgcolor: "transparent",
                },
              }}
            >
              <ChevronDown size={16} />
            </Button>

            <Menu
              anchorEl={anchorEl}
              open={isMenuOpen}
              onClose={handleMenuClose}
              PaperProps={{
                sx: {
                  mt: 1,
                  borderRadius: "12px",
                  minWidth: 160,
                },
              }}
            >
              <MenuItem onClick={handleProfile}>Profile</MenuItem>
              <MenuItem onClick={handleProfile}>My Account</MenuItem>
              <MenuItem onClick={handleLogout}>Logout</MenuItem>
            </Menu>
          </Box>
        </Box>
      </Toolbar>

      <AdminNotifySidebar open={notifyOpen} toggle={setNotifyOpen} />
    </AppBar>
  );
};

export default AdminNavbar;
