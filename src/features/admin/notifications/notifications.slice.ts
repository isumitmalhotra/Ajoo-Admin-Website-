import { createAsyncThunk, createSlice, type PayloadAction } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";

// ── Types ─────────────────────────────────────────────────────────────────
export type NotificationCategory = "Bookings" | "Users" | "Hosts" | "System";

export interface AdminNotification {
  id: number;
  category: NotificationCategory;
  title: string;
  message: string;
  createdAt: string; // ISO timestamp
  read: boolean;
}

interface NotificationsState {
  items: AdminNotification[];
  loading: boolean;
  error: string | null;
}

// Mock-first for B-02. Real fetch + polling is wired in B-09 once A-14 ships
// the GET /admin/notifications/search endpoint. Toggle with VITE_USE_NOTIFY_MOCKS.
const USE_NOTIFY_MOCKS = import.meta.env.VITE_USE_NOTIFY_MOCKS === "true";

const minutesAgo = (mins: number) =>
  new Date(Date.now() - mins * 60_000).toISOString();

const MOCK_NOTIFICATIONS: AdminNotification[] = [
  {
    id: 1,
    category: "Bookings",
    title: "New booking confirmed",
    message: "Priya Sharma booked “Hillside Villa, Manali” for 3 nights.",
    createdAt: minutesAgo(4),
    read: false,
  },
  {
    id: 2,
    category: "Hosts",
    title: "Host awaiting approval",
    message: "Rohan Mehta submitted host onboarding and needs review.",
    createdAt: minutesAgo(22),
    read: false,
  },
  {
    id: 3,
    category: "System",
    title: "Payout batch processed",
    message: "12 host payouts totalling ₹2,40,000 completed successfully.",
    createdAt: minutesAgo(90),
    read: false,
  },
  {
    id: 4,
    category: "Users",
    title: "KYC in review",
    message: "Guest Aman Gupta entered manual KYC review.",
    createdAt: minutesAgo(180),
    read: true,
  },
  {
    id: 5,
    category: "Bookings",
    title: "Booking cancelled",
    message: "“Lakeview Cottage, Nainital” booking #4187 was cancelled by guest.",
    createdAt: minutesAgo(320),
    read: true,
  },
];

const initialState: NotificationsState = {
  items: USE_NOTIFY_MOCKS ? MOCK_NOTIFICATIONS : [],
  loading: false,
  error: null,
};

// Maps a backend `tbl_notifications` row (A-14, ntf_* columns) to the FE type.
const mapCategory = (raw: unknown): NotificationCategory => {
  const v = String(raw ?? "").toLowerCase();
  if (v.includes("book")) return "Bookings";
  if (v.includes("host")) return "Hosts";
  if (v.includes("user") || v.includes("guest") || v.includes("kyc")) return "Users";
  return "System";
};

const normalizeNotification = (r: any): AdminNotification => ({
  id: Number(r.ntf_id ?? r.id),
  category: mapCategory(r.ntf_category ?? r.ntf_type ?? r.category),
  title: String(r.ntf_title ?? r.title ?? "Notification"),
  message: String(r.ntf_message ?? r.message ?? ""),
  createdAt: String(r.ntf_created_at ?? r.createdAt ?? new Date().toISOString()),
  read: Number(r.ntf_is_read ?? r.read ?? 0) === 1 || r.read === true,
});

// Thunk: mock-first. With mocks ON, returns the local list. With mocks OFF it
// hits A-14's GET /admin/notifications/search → { items, unreadCount, ... }.
// A 404 (pre-deploy) yields an empty list rather than crashing the drawer.
export const fetchAdminNotifications = createAsyncThunk<
  AdminNotification[],
  void,
  { rejectValue: string }
>("adminNotifications/fetch", async (_, { rejectWithValue }) => {
  if (USE_NOTIFY_MOCKS) {
    return MOCK_NOTIFICATIONS;
  }
  try {
    const res = await api.get(ADMINENDPOINTS.ADMIN_NOTIFICATIONS_SEARCH);
    const data = res.data?.data ?? {};
    const items = Array.isArray(data) ? data : data.items ?? [];
    return items.map(normalizeNotification);
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      if (err.response?.status === 404) return [];
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch notifications"
      );
    }
    return rejectWithValue("Failed to fetch notifications");
  }
});

// Real mark-read (A-14 PUT /admin/notifications/:id/read). Optimistic: the
// reducer flips state immediately; the PUT is best-effort (mock mode is a no-op).
export const markNotificationRead = createAsyncThunk<
  number,
  number,
  { rejectValue: string }
>("adminNotifications/markRead", async (id, { dispatch }) => {
  dispatch(markRead(id));
  if (!USE_NOTIFY_MOCKS) {
    try {
      await api.put(`${ADMINENDPOINTS.ADMIN_NOTIFICATIONS_READ}/${id}/read`);
    } catch {
      // best-effort; keep the optimistic local state
    }
  }
  return id;
});

// Mark every currently-unread notification read (optimistic + per-id PUT).
export const markAllNotificationsRead = createAsyncThunk<
  void,
  void,
  { state: { adminNotifications: NotificationsState } }
>("adminNotifications/markAllRead", async (_, { dispatch, getState }) => {
  const unread = getState().adminNotifications.items.filter((n) => !n.read);
  dispatch(markAllRead());
  if (!USE_NOTIFY_MOCKS) {
    await Promise.all(
      unread.map((n) =>
        api.put(`${ADMINENDPOINTS.ADMIN_NOTIFICATIONS_READ}/${n.id}/read`).catch(() => undefined)
      )
    );
  }
});

const notificationsSlice = createSlice({
  name: "adminNotifications",
  initialState,
  reducers: {
    markRead(state, action: PayloadAction<number>) {
      const item = state.items.find((n) => n.id === action.payload);
      if (item) item.read = true;
    },
    markAllRead(state) {
      state.items.forEach((n) => {
        n.read = true;
      });
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchAdminNotifications.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchAdminNotifications.fulfilled, (state, action) => {
        state.loading = false;
        state.items = action.payload;
      })
      .addCase(fetchAdminNotifications.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed to fetch notifications";
        // keep whatever items we already had; empty list is a valid state
      });
  },
});

export const { markRead, markAllRead } = notificationsSlice.actions;
export default notificationsSlice.reducer;
