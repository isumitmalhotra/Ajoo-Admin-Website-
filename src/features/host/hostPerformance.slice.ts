import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../services/api";
import { ADMINENDPOINTS } from "../../services/endpoints";
import { extractApiData } from "../../services/apiContracts";

// B-04 mock-first. Real backend wired in B-08 (A-07: /host/performance/summary).
const USE_HOST_MOCKS = import.meta.env.VITE_USE_HOST_MOCKS === "true";

export type PeriodKey = "30D" | "90D";

export interface PerformanceSnapshot {
  occupancy: number;
  rating: number;
  cancellationRate: number;
  responseTimeHours: number;
  revenueTrend: number[];
  labels: string[];
  channelSplit: number[];
}

export type PerformanceData = Record<PeriodKey, PerformanceSnapshot>;

const MOCK_PERFORMANCE: PerformanceData = {
  "30D": {
    occupancy: 76,
    rating: 4.6,
    cancellationRate: 3.8,
    responseTimeHours: 1.9,
    revenueTrend: [56000, 62000, 59000, 67000],
    labels: ["W1", "W2", "W3", "W4"],
    channelSplit: [44, 31, 25],
  },
  "90D": {
    occupancy: 72,
    rating: 4.5,
    cancellationRate: 4.2,
    responseTimeHours: 2.3,
    revenueTrend: [168000, 182000, 194000],
    labels: ["Jan", "Feb", "Mar"],
    channelSplit: [41, 34, 25],
  },
};

interface HostPerformanceState {
  data: PerformanceData | null;
  loading: boolean;
  error: string | null;
}

const initialState: HostPerformanceState = {
  data: null,
  loading: false,
  error: null,
};

const num = (v: unknown) => {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
};

// A-07 returns one 90-day window as { occupancy/revenue/cancellations/ratings:
// { current, previous, trend[] } }. The FE page expects a per-period snapshot,
// so we project the single real window onto both 30D and 90D keys (trend arrays
// flow through; responseTime/channelSplit aren't provided by the backend yet).
const toSnapshot = (d: any): PerformanceSnapshot => {
  const revTrend: number[] = Array.isArray(d?.revenue?.trend) ? d.revenue.trend.map(num) : [];
  return {
    occupancy: num(d?.occupancy?.current),
    rating: num(d?.ratings?.current),
    cancellationRate: num(d?.cancellations?.current),
    responseTimeHours: num(d?.responseTimeHours),
    revenueTrend: revTrend,
    labels: revTrend.map((_, i) => `P${i + 1}`),
    channelSplit: Array.isArray(d?.channelSplit) ? d.channelSplit.map(num) : [],
  };
};

export const fetchHostPerformance = createAsyncThunk<
  PerformanceData | null,
  void,
  { rejectValue: string }
>("hostPerformance/fetch", async (_, { rejectWithValue }) => {
  if (USE_HOST_MOCKS) return MOCK_PERFORMANCE;
  try {
    const res = await api.get(ADMINENDPOINTS.HOST_PORTAL_PERFORMANCE_SUMMARY);
    const data = extractApiData<any>(res.data);
    if (!data || typeof data !== "object") return null;
    const snapshot = toSnapshot(data);
    return { "30D": snapshot, "90D": snapshot };
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to load performance data"
      );
    }
    return rejectWithValue("Failed to load performance data");
  }
});

const hostPerformanceSlice = createSlice({
  name: "hostPerformance",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchHostPerformance.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchHostPerformance.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetchHostPerformance.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed to load performance data";
        state.data = null;
      });
  },
});

export default hostPerformanceSlice.reducer;
