import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import { extractApiData } from "../../../services/apiContracts";

// B-07 mock-stub. A-08 ships GET /admin/host/performance/summary?hostId=. With
// VITE_USE_HOST_MOCKS=true (or before A-08 lands) we serve a deterministic mock
// derived from hostId so the Performance tab is demoable now.
const USE_HOST_MOCKS = import.meta.env.VITE_USE_HOST_MOCKS === "true";

export type PerfWindow = "30D" | "90D";

export interface AdminHostPerformance {
  occupancy: number;
  earnings: number;
  cancellations: number;
  rating: number;
  responseTimeHours: number;
  totalBookings: number;
}

interface AdminHostPerformanceState {
  data: AdminHostPerformance | null;
  loading: boolean;
  error: string | null;
}

const initialState: AdminHostPerformanceState = {
  data: null,
  loading: false,
  error: null,
};

const mockFor = (hostId: number, window: PerfWindow): AdminHostPerformance => {
  const is30 = window === "30D";
  const seed = (hostId % 7) + 1;
  return {
    occupancy: is30 ? 68 + seed : 64 + seed,
    earnings: (is30 ? 150000 : 430000) + seed * 4200,
    cancellations: is30 ? seed : seed * 3,
    rating: Number((4.2 + (seed % 5) * 0.15).toFixed(1)),
    responseTimeHours: Number((1.5 + (seed % 4) * 0.4).toFixed(1)),
    totalBookings: is30 ? 8 + seed : 24 + seed * 2,
  };
};

export const fetchAdminHostPerformance = createAsyncThunk<
  AdminHostPerformance,
  { hostId: number; window: PerfWindow },
  { rejectValue: string }
>("adminHostPerformance/fetch", async ({ hostId, window }, { rejectWithValue }) => {
  if (USE_HOST_MOCKS) return mockFor(hostId, window);
  try {
    const res = await api.get(ADMINENDPOINTS.ADMIN_HOST_PERFORMANCE_SUMMARY, {
      params: { hostId, window },
    });
    const data = extractApiData<AdminHostPerformance>(res.data);
    return data ?? mockFor(hostId, window);
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      // Pre-A-08 the endpoint 404s — fall back to a mock so the tab still renders.
      if (err.response?.status === 404) return mockFor(hostId, window);
      return rejectWithValue(
        err.response?.data?.message || "Failed to load host performance"
      );
    }
    return rejectWithValue("Failed to load host performance");
  }
});

const slice = createSlice({
  name: "adminHostPerformance",
  initialState,
  reducers: {
    resetAdminHostPerformance() {
      return initialState;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchAdminHostPerformance.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchAdminHostPerformance.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetchAdminHostPerformance.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed to load host performance";
        state.data = null;
      });
  },
});

export const { resetAdminHostPerformance } = slice.actions;
export default slice.reducer;
