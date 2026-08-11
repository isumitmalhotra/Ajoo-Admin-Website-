import { createAsyncThunk, createSlice, type PayloadAction } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../services/api";
import { ADMINENDPOINTS } from "../../services/endpoints";

// B-13 — host notifications dropdown. Backed by A-14 /host/notifications/*.
export type HostNotificationCategory = "Bookings" | "Payouts" | "KYC" | "System";

export interface HostNotification {
  id: number;
  category: HostNotificationCategory;
  title: string;
  message: string;
  createdAt: string;
  read: boolean;
}

interface HostNotificationsState {
  items: HostNotification[];
  loading: boolean;
  error: string | null;
}

const initialState: HostNotificationsState = {
  items: [],
  loading: false,
  error: null,
};

const mapCategory = (raw: unknown): HostNotificationCategory => {
  const v = String(raw ?? "").toLowerCase();
  if (v.includes("book")) return "Bookings";
  if (v.includes("payout") || v.includes("earn")) return "Payouts";
  if (v.includes("kyc") || v.includes("verif")) return "KYC";
  return "System";
};

const normalize = (r: any): HostNotification => ({
  id: Number(r.ntf_id ?? r.id),
  category: mapCategory(r.ntf_category ?? r.ntf_type ?? r.category),
  title: String(r.ntf_title ?? r.title ?? "Notification"),
  message: String(r.ntf_message ?? r.message ?? ""),
  createdAt: String(r.ntf_created_at ?? r.createdAt ?? new Date().toISOString()),
  read: Number(r.ntf_is_read ?? r.read ?? 0) === 1 || r.read === true,
});

export const fetchHostNotifications = createAsyncThunk<
  HostNotification[],
  void,
  { rejectValue: string }
>("hostNotifications/fetch", async (_, { rejectWithValue }) => {
  try {
    const res = await api.get(ADMINENDPOINTS.HOST_NOTIFICATIONS_SEARCH);
    const data = res.data?.data ?? {};
    const items = Array.isArray(data) ? data : data.items ?? [];
    return items.map(normalize);
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      if (err.response?.status === 404) return [];
      return rejectWithValue(err.response?.data?.message || "Failed to load notifications");
    }
    return rejectWithValue("Failed to load notifications");
  }
});

export const markHostNotificationRead = createAsyncThunk<number, number>(
  "hostNotifications/markRead",
  async (id, { dispatch }) => {
    dispatch(hostMarkReadLocal(id));
    try {
      await api.put(`${ADMINENDPOINTS.HOST_NOTIFICATIONS_READ}/${id}/read`);
    } catch {
      // best-effort; keep optimistic state
    }
    return id;
  }
);

const slice = createSlice({
  name: "hostNotifications",
  initialState,
  reducers: {
    hostMarkReadLocal(state, action: PayloadAction<number>) {
      const item = state.items.find((n) => n.id === action.payload);
      if (item) item.read = true;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchHostNotifications.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchHostNotifications.fulfilled, (state, action) => {
        state.loading = false;
        state.items = action.payload;
      })
      .addCase(fetchHostNotifications.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed to load notifications";
      });
  },
});

export const { hostMarkReadLocal } = slice.actions;
export default slice.reducer;
