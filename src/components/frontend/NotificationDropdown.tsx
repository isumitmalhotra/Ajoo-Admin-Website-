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

const MotionBadge = motion(Badge);

const NotificationDropdown: React.FC = () => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [notifications, setNotifications] = useState(
    Array.from({ length: 20 }, (_, i) => ({
      id: i + 1,
      message: [
        "Your booking at Aajoo Homestay is confirmed!",
        "New offers available near your area.",
        "Host responded to your inquiry.",
        "Your payment has been successfully processed.",
        "Aajoo added new homestays in Manali — explore now!",
        "Check-in reminder: Your stay begins tomorrow at 2 PM.",
        "New message from your host.",
        "Your review was posted successfully.",
        "Special discount: 15% off on weekend stays!",
        "Your profile has been verified successfully.",
        "Your booking request has been declined by the host.",
        "Aajoo rewards: You earned ₹250 travel credits!",
        "Your stay at Hillside Cottage has ended — rate your experience.",
        "New homestay listings added in Shimla!",
        "Host 'The Cozy Den' updated their prices recently.",
        "You have unread messages in your inbox.",
        "Security alert: New login detected from a different device.",
        "Aajoo newsletter: Discover top-rated stays this month!",
        "Your refund has been initiated for canceled booking.",
        "Reminder: Complete your profile to get personalized offers.",
      ][i],
      read: i < 18, // simulate last two as unread initially
    }))
  );

  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));
  const [shake, setShake] = useState(false);

  const unreadCount = notifications.filter((n) => !n.read).length;
  const open = Boolean(anchorEl);

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
  };

  const handleClose = () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
    setAnchorEl(null);
  };

  const markAsRead = (id: number) => {
    setNotifications((prev) =>
      prev.map((n) => (n.id === id ? { ...n, read: true } : n))
    );
  };

  const markAllAsRead = () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
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
                          "&:hover": { bgcolor: "#fce4ec" },
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
                              "&:hover": { bgcolor: "#fce4ec" },
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
