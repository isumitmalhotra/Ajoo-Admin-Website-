// AdminNotifySidebar.tsx — Admin Notification Center (B-02, mock-first)
import { useEffect, useMemo, useState } from "react";
import {
  Box,
  Drawer,
  Stack,
  Typography,
  Chip,
  IconButton,
  Button,
  Divider,
} from "@mui/material";
import { X, Bell, CalendarCheck, Users, Home, Settings2, CheckCheck } from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import {
  fetchAdminNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  type NotificationCategory,
} from "../../../features/admin/notifications/notifications.slice";

interface AdminNotifySidebarProps {
  open: boolean;
  toggle: (open: boolean) => void;
}

type FilterKey = "All" | NotificationCategory;

const FILTERS: FilterKey[] = ["All", "Bookings", "Users", "Hosts", "System"];

const CATEGORY_META: Record<NotificationCategory, { icon: LucideIcon; bg: string; fg: string }> = {
  Bookings: { icon: CalendarCheck, bg: "#dcfce7", fg: "#166534" },
  Users: { icon: Users, bg: "#dbeafe", fg: "#1e40af" },
  Hosts: { icon: Home, bg: "#f3e8ff", fg: "#6b21a8" },
  System: { icon: Settings2, bg: "#ffedd5", fg: "#9a3412" },
};

const relativeTime = (iso: string) => {
  const diffMs = Date.now() - new Date(iso).getTime();
  const mins = Math.round(diffMs / 60_000);
  if (mins < 1) return "just now";
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.round(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.round(hrs / 24);
  return `${days}d ago`;
};

export default function AdminNotifySidebar({ open, toggle }: AdminNotifySidebarProps) {
  const dispatch = useAppDispatch();
  const { items } = useAppSelector((state) => state.adminNotifications);
  const [filter, setFilter] = useState<FilterKey>("All");

  useEffect(() => {
    if (open) {
      dispatch(fetchAdminNotifications());
    }
  }, [open, dispatch]);

  const filtered = useMemo(
    () => (filter === "All" ? items : items.filter((n) => n.category === filter)),
    [items, filter]
  );

  const unreadCount = useMemo(() => items.filter((n) => !n.read).length, [items]);

  return (
    <Drawer anchor="right" open={open} onClose={() => toggle(false)}>
      <Box sx={{ width: { xs: 320, sm: 380 }, height: "100%", display: "flex", flexDirection: "column" }}>
        {/* Header */}
        <Box
          sx={{
            background: "linear-gradient(135deg, #6d28d9 0%, #3D4670 60%, #C16345 100%)",
            color: "#fff",
            px: 2.25,
            py: 2,
          }}
        >
          <Stack direction="row" alignItems="center" justifyContent="space-between">
            <Stack direction="row" alignItems="center" spacing={1}>
              <Bell size={20} />
              <Typography variant="h6" fontWeight={800}>
                Notifications
              </Typography>
              {unreadCount > 0 && (
                <Chip
                  label={`${unreadCount} new`}
                  size="small"
                  sx={{ bgcolor: "rgba(255,255,255,0.2)", color: "#fff", fontWeight: 700, height: 22 }}
                />
              )}
            </Stack>
            <IconButton size="small" onClick={() => toggle(false)} sx={{ color: "#fff" }}>
              <X size={18} />
            </IconButton>
          </Stack>
        </Box>

        {/* Filter chips */}
        <Stack
          direction="row"
          spacing={0.75}
          sx={{ px: 2, py: 1.25, flexWrap: "wrap", rowGap: 0.75, borderBottom: "1px solid #f1f5f9" }}
        >
          {FILTERS.map((f) => {
            const active = filter === f;
            return (
              <Chip
                key={f}
                label={f}
                size="small"
                onClick={() => setFilter(f)}
                sx={{
                  fontWeight: 600,
                  cursor: "pointer",
                  bgcolor: active ? "#6d28d9" : "#f3f4f6",
                  color: active ? "#fff" : "#4b5563",
                  "&:hover": { bgcolor: active ? "#5b21b6" : "#e5e7eb" },
                }}
              />
            );
          })}
        </Stack>

        {/* List */}
        <Box sx={{ flex: 1, overflowY: "auto" }}>
          {filtered.length > 0 ? (
            filtered.map((n, i) => {
              const meta = CATEGORY_META[n.category];
              const Icon = meta.icon;
              return (
                <Box key={n.id}>
                  {i > 0 && <Divider />}
                  <Box
                    onClick={() => !n.read && dispatch(markNotificationRead(n.id))}
                    sx={{
                      display: "flex",
                      gap: 1.25,
                      px: 2,
                      py: 1.5,
                      cursor: n.read ? "default" : "pointer",
                      bgcolor: n.read ? "#fff" : "#faf5ff",
                      transition: "background .15s ease",
                      "&:hover": { bgcolor: n.read ? "#f9fafb" : "#f3e8ff" },
                    }}
                  >
                    <Box
                      sx={{
                        width: 34,
                        height: 34,
                        borderRadius: "0.6rem",
                        bgcolor: meta.bg,
                        display: "grid",
                        placeItems: "center",
                        flexShrink: 0,
                      }}
                    >
                      <Icon size={16} color={meta.fg} />
                    </Box>
                    <Box sx={{ flex: 1, minWidth: 0 }}>
                      <Stack direction="row" justifyContent="space-between" alignItems="center" spacing={1}>
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
                    {!n.read && (
                      <Box sx={{ width: 8, height: 8, borderRadius: "50%", bgcolor: "#6d28d9", mt: 0.75, flexShrink: 0 }} />
                    )}
                  </Box>
                </Box>
              );
            })
          ) : (
            <Stack alignItems="center" justifyContent="center" spacing={1.5} sx={{ height: "100%", px: 3, py: 6 }}>
              <Box sx={{ width: 56, height: 56, borderRadius: "50%", bgcolor: "#f3f4f6", display: "grid", placeItems: "center" }}>
                <Bell size={26} color="#9ca3af" />
              </Box>
              <Typography variant="body2" fontWeight={600} color="#374151">
                You're all caught up
              </Typography>
              <Typography variant="caption" color="text.secondary" textAlign="center">
                {filter === "All"
                  ? "No notifications yet. New activity will show up here."
                  : `No ${filter.toLowerCase()} notifications right now.`}
              </Typography>
            </Stack>
          )}
        </Box>

        {/* Footer */}
        {items.length > 0 && (
          <>
            <Divider />
            <Box sx={{ p: 1.5 }}>
              <Button
                fullWidth
                size="small"
                startIcon={<CheckCheck size={16} />}
                onClick={() => dispatch(markAllNotificationsRead())}
                disabled={unreadCount === 0}
                sx={{
                  textTransform: "none",
                  fontWeight: 700,
                  color: "#6d28d9",
                  "&:hover": { bgcolor: "#faf5ff" },
                }}
              >
                Mark all as read
              </Button>
            </Box>
          </>
        )}
      </Box>
    </Drawer>
  );
}
