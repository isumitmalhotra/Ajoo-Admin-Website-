import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../services/api";
import { ADMINENDPOINTS } from "../../services/endpoints";

interface HostDashboardData {
  monthEarnings?: number;
  activeListings?: number;
  upcomingBookings?: number;
  occupancyRate?: number;
}

interface HostDashboardState {
  data: HostDashboardData | null;
  loading: boolean;
  error: string | null;
}

const initialState: HostDashboardState = {
  data: null,
  loading: false,
  error: null,
};

export const fetchHostDashboard = createAsyncThunk<
  HostDashboardData,
  void,
  { rejectValue: string }
>("hostDashboard/fetch", async (_, { rejectWithValue }) => {
  try {
    const res = await api.get(ADMINENDPOINTS.HOST_PORTAL_DASHBOARD);
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
          "Host dashboard endpoint is not available on current backend."
        );
      }

      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch host dashboard"
      );
    }

    return rejectWithValue("Failed to fetch host dashboard");
  }
});

const hostDashboardSlice = createSlice({
  name: "hostDashboard",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchHostDashboard.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchHostDashboard.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetchHostDashboard.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed to fetch host dashboard";
      });
  },
});

export default hostDashboardSlice.reducer;
