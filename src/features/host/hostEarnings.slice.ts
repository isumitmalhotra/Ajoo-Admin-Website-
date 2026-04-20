import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../services/api";
import { ADMINENDPOINTS } from "../../services/endpoints";

export interface HostPayoutRow {
  payout_id?: number;
  booking_id?: number;
  amount?: number;
  status?: string;
  payout_date?: string;
  reference_id?: string;
}

export interface HostEarningsData {
  totalEarnings?: number;
  pendingPayouts?: number;
  settledPayouts?: number;
  lastPayoutAmount?: number;
  nextPayoutDate?: string;
  payoutHistory?: HostPayoutRow[];
}

interface HostEarningsState {
  data: HostEarningsData | null;
  loading: boolean;
  error: string | null;
}

const initialState: HostEarningsState = {
  data: null,
  loading: false,
  error: null,
};

export const fetchHostEarnings = createAsyncThunk<
  HostEarningsData,
  void,
  { rejectValue: string }
>("hostEarnings/fetch", async (_, { rejectWithValue }) => {
  try {
    const res = await api.get(ADMINENDPOINTS.HOST_PORTAL_EARNINGS);
    return res.data?.data || {};
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      if (!err.response) {
        return rejectWithValue(
          "Unable to reach host backend service. Please verify API server is running."
        );
      }

      if (err.response.status === 404) {
        return rejectWithValue(
          "Host earnings endpoint is not available on current backend."
        );
      }

      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch host earnings"
      );
    }

    return rejectWithValue("Failed to fetch host earnings");
  }
});

const hostEarningsSlice = createSlice({
  name: "hostEarnings",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchHostEarnings.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchHostEarnings.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetchHostEarnings.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed to fetch host earnings";
      });
  },
});

export default hostEarningsSlice.reducer;
