import React, { useState, useEffect } from "react";
import {
  Box,
  IconButton,
  Popover,
  Typography,
  List,
  ListItem,
  ListItemText,
  Badge,
  Button,
  Divider,
  useMediaQuery,
  useTheme,
  Tooltip,
} from "@mui/material";
import NotificationsIcon from "@mui/icons-material/Notifications";
import DoneIcon from "@mui/icons-material/Done";
import { motion, AnimatePresence } from "framer-motion";
import {
  getUserNotifications,
  markUserNotificationRead,
} from "../../services/customerApi";
import storage from "../../styles/utils/storage";

const MotionBadge = motion.create(Badge);

interface NotificationItem {
  id: number;
  message: string;
  read: boolean;
}

const NotificationDropdown: React.FC = () => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  // Real notifications — GET /user/notification/Listing (returns unread only).
  const [notifications, setNotifications] = useState<NotificationItem[]>([]);

  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));
  const [shake, setShake] = useState(false);

  const unreadCount = notifications.filter((n) => !n.read).length;
  const open = Boolean(anchorEl);

  const loadNotifications = async () => {
    // Authenticated endpoint — skip when logged out, otherwise the 401 handler
    // redirects to "/" and the header remounts → infinite refresh loop.
    if (!storage.getToken()) return;
    try {
      const rows = await getUserNotifications();
      setNotifications(
        rows.map((n: any) => ({
          id: Number(n.un_id),
          message: n.un_message || n.un_title || "Notification",
          read: n.un_is_read === 1 || n.un_is_read === true,
        }))
      );
    } catch {
      // leave list as-is on failure
    }
  };

  // Fetch on mount so the unread badge is correct before opening.
  useEffect(() => {
    loadNotifications();
  }, []);

  // Shake animation when new unread notifications appear
  useEffect(() => {
    if (unreadCount > 0) {
      setShake(true);
      const timeout = setTimeout(() => setShake(false), 800);
      return () => clearTimeout(timeout);
    }
  }, [unreadCount]);

  const handleClick = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
    loadNotifications();
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const markAsRead = async (id: number) => {
    setNotifications((prev) =>
      prev.map((n) => (n.id === id ? { ...n, read: true } : n))
    );
    try {
      await markUserNotificationRead(id);
    } catch {
      // revert on failure
      setNotifications((prev) =>
        prev.map((n) => (n.id === id ? { ...n, read: false } : n))
      );
    }
  };

  const markAllAsRead = async () => {
    const ids = notifications.filter((n) => !n.read).map((n) => n.id);
    if (ids.length === 0) return;
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
    try {
      await markUserNotificationRead(ids);
    } catch {
      // ignore — next fetch will reconcile
    }
  };

  return (
    <Box>
      <Tooltip title="Notifications">
        <IconButton onClick={handleClick}>
          <MotionBadge
            color="error"
            badgeContent={unreadCount}
            overlap="circular"
            animate={
              shake
                ? {
                    rotate: [0, -10, 10, -10, 10, 0],
                    transition: { duration: 0.6 },
                  }
                : {}
            }
          >
            <NotificationsIcon sx={{ color: "#1B2447" }} />
          </MotionBadge>
        </IconButton>
      </Tooltip>

      <Popover
        open={open}
        anchorEl={anchorEl}
        onClose={handleClose}
        anchorOrigin={{
          vertical: "bottom",
          horizontal: "center",
        }}
        transformOrigin={{
          vertical: "top",
          horizontal: "center",
        }}
        PaperProps={{
          sx: {
            mt: 1,
            width: isMobile ? "90vw" : 360,
            borderRadius: 3,
            boxShadow: 6,
            p: 1,
            maxHeight: "70vh",
            overflow: "hidden",
            zIndex: 9999,
          },
        }}
      >
        <AnimatePresence>
          {open && (
            <motion.div
              key="dropdown"
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.25 }}
            >
              {/* Header */}
              <Box
                sx={{
                  px: 2,
                  py: 1,
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  borderBottom: "1px solid #eee",
                }}
              >
                <Typography
                  variant="subtitle1"
                  sx={{
                    fontWeight: 600,
                    color: "#1B2447",
                  }}
                >
                  Notifications
                </Typography>

                {unreadCount > 0 && (
                  <Typography
                    variant="body2"
                    sx={{
                      color: "#1B2447",
                      cursor: "pointer",
                      fontWeight: 500,
                      textDecoration: "underline",
                      "&:hover": { color: "#a83550" },
                    }}
                    onClick={markAllAsRead}
                  >
                    Mark all as read
                  </Typography>
                )}
              </Box>

              {/* Notification List */}
              {notifications.length > 0 ? (
                <List
                  dense
                  disablePadding
                  sx={{
                    overflowY: "auto",
                    maxHeight: "calc(70vh - 60px)",
                    scrollbarWidth: "thin",
                    "&::-webkit-scrollbar": { width: "6px" },
                    "&::-webkit-scrollbar-thumb": {
                      backgroundColor: "#e0e0e0",
                      borderRadius: "10px",
                    },
                  }}
                >
                  {notifications.map((notif) => (
                    <motion.div
                      key={notif.id}
                      initial={{ opacity: 0, y: 5 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ duration: 0.2, delay: notif.id * 0.02 }}
                    >
                      <ListItem
                        sx={{
                          alignItems: "flex-start",
                          bgcolor: notif.read ? "#fafafa" : "#fff5f8",
                          borderRadius: 2,
                          my: 0.5,
                          px: 2,
                          py: 1,
                          display: "flex",
                          justifyContent: "space-between",
                          flexWrap: "wrap",
                          transition: "background 0.3s",
                          "&:hover": { bgcolor: "rgba(27,36,71,.05)" },
                        }}
                      >
                        <ListItemText
                          primary={notif.message}
                          primaryTypographyProps={{
                            fontSize: "0.9rem",
                            color: notif.read ? "text.secondary" : "text.primary",
                            fontWeight: notif.read ? 400 : 500,
                          }}
                          sx={{ flex: 1, mr: 1 }}
                        />
                        {!notif.read && (
                          <Button
                            onClick={() => markAsRead(notif.id)}
                            size="small"
                            variant="text"
                            sx={{
                              color: "#1B2447",
                              textTransform: "none",
                              fontSize: "0.75rem",
                              minWidth: "auto",
                              p: 0.5,
                              "&:hover": { bgcolor: "rgba(27,36,71,.05)" },
                            }}
                            startIcon={<DoneIcon fontSize="small" />}
                          >
                            Read
                          </Button>
                        )}
                      </ListItem>
                      <Divider sx={{ my: 0.5 }} />
                    </motion.div>
                  ))}
                </List>
              ) : (
                <Typography
                  variant="body2"
                  sx={{
                    p: 3,
                    textAlign: "center",
                    color: "text.secondary",
                  }}
                >
                  No new notifications
                </Typography>
              )}
            </motion.div>
          )}
        </AnimatePresence>
      </Popover>
    </Box>
  );
};

export default NotificationDropdown;
