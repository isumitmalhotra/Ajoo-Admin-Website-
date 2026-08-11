import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import { extractApiData } from "../../../services/apiContracts";

// B-07 mock-stub. A-08 ships /admin/host/payout/{history,hold,release}. Until
// then (or with VITE_USE_HOST_MOCKS=true) hold/release toggle locally.
const USE_HOST_MOCKS = import.meta.env.VITE_USE_HOST_MOCKS === "true";

export type AdminPayoutStatus = "READY" | "ON_HOLD" | "PROCESSING" | "PAID";

export interface AdminHostPayoutRow {
  payoutId: string;
  amount: number;
  status: AdminPayoutStatus;
  date: string;
}

interface AdminHostPayoutState {
  rows: AdminHostPayoutRow[];
  loading: boolean;
  error: string | null;
  actioningId: string | null;
}

const initialState: AdminHostPayoutState = {
  rows: [],
  loading: false,
  error: null,
  actioningId: null,
};

const mockRows = (hostId: number): AdminHostPayoutRow[] => {
  const base = 14000 + (hostId % 5) * 1500;
  return [
    { payoutId: `PAY-${4800 + (hostId % 9)}`, amount: base + 14600, status: "READY", date: "2026-05-11" },
    { payoutId: `PAY-${4750 + (hostId % 9)}`, amount: base + 5300, status: "PROCESSING", date: "2026-05-06" },
    { payoutId: `PAY-${4660 + (hostId % 9)}`, amount: base + 1850, status: "ON_HOLD", date: "2026-04-28" },
  ];
};

export const fetchAdminHostPayouts = createAsyncThunk<
  AdminHostPayoutRow[],
  { hostId: number },
  { rejectValue: string }
>("adminHostPayout/fetch", async ({ hostId }, { rejectWithValue }) => {
  if (USE_HOST_MOCKS) return mockRows(hostId);
  try {
    const res = await api.get(ADMINENDPOINTS.ADMIN_HOST_PAYOUT_HISTORY, {
      params: { hostId },
    });
    const data = extractApiData<unknown>(res.data);
    return Array.isArray(data) ? (data as AdminHostPayoutRow[]) : mockRows(hostId);
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      if (err.response?.status === 404) return mockRows(hostId);
      return rejectWithValue(
        err.response?.data?.message || "Failed to load payout history"
      );
    }
    return rejectWithValue("Failed to load payout history");
  }
});

// Hold/Release — fires the real endpoint when available; resolves optimistically
// under mocks / pre-A-08. Returns the row id + resulting status.
export const setAdminHostPayoutHold = createAsyncThunk<
  { payoutId: string; status: AdminPayoutStatus },
  { payoutId: string; hold: boolean },
  { rejectValue: string }
>("adminHostPayout/setHold", async ({ payoutId, hold }, { rejectWithValue }) => {
  const nextStatus: AdminPayoutStatus = hold ? "ON_HOLD" : "READY";
  if (USE_HOST_MOCKS) return { payoutId, status: nextStatus };
  try {
    const endpoint = hold
      ? ADMINENDPOINTS.ADMIN_HOST_PAYOUT_HOLD
      : ADMINENDPOINTS.ADMIN_HOST_PAYOUT_RELEASE;
    await api.post(endpoint, { payoutId });
    return { payoutId, status: nextStatus };
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      if (err.response?.status === 404) return { payoutId, status: nextStatus };
      return rejectWithValue(
        err.response?.data?.message || "Failed to update payout"
      );
    }
    return rejectWithValue("Failed to update payout");
  }
});

const slice = createSlice({
  name: "adminHostPayout",
  initialState,
  reducers: {
    resetAdminHostPayout() {
      return initialState;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchAdminHostPayouts.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchAdminHostPayouts.fulfilled, (state, action) => {
        state.loading = false;
        state.rows = action.payload;
      })
      .addCase(fetchAdminHostPayouts.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed to load payout history";
        state.rows = [];
      })
      .addCase(setAdminHostPayoutHold.pending, (state, action) => {
        state.actioningId = action.meta.arg.payoutId;
      })
      .addCase(setAdminHostPayoutHold.fulfilled, (state, action) => {
        state.actioningId = null;
        const row = state.rows.find((r) => r.payoutId === action.payload.payoutId);
        if (row) row.status = action.payload.status;
      })
      .addCase(setAdminHostPayoutHold.rejected, (state, action) => {
        state.actioningId = null;
        state.error = action.payload || "Failed to update payout";
      });
  },
});

export const { resetAdminHostPayout } = slice.actions;
export default slice.reducer;
