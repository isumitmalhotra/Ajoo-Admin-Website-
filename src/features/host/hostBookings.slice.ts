import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../services/api";
import { ADMINENDPOINTS } from "../../services/endpoints";

interface HostBooking {
  booking_id: number;
  property_name?: string;
  check_in?: string;
  check_out?: string;
  status?: string;
}

interface HostBookingsState {
  data: HostBooking[];
  loading: boolean;
  error: string | null;
}

const initialState: HostBookingsState = {
  data: [],
  loading: false,
  error: null,
};

export const fetchHostBookings = createAsyncThunk<
  HostBooking[],
  { page?: number; limit?: number } | undefined,
  { rejectValue: string }
>("hostBookings/fetch", async (payload, { rejectWithValue }) => {
  try {
    const res = await api.post(ADMINENDPOINTS.HOST_PORTAL_BOOKINGS, {
      page: payload?.page || 1,
      limit: payload?.limit || 10,
    });

    const rows = res.data?.data?.data || res.data?.data || [];
    return Array.isArray(rows) ? rows : [];
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch host bookings"
      );
    }

    return rejectWithValue("Failed to fetch host bookings");
  }
});

const hostBookingsSlice = createSlice({
  name: "hostBookings",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchHostBookings.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchHostBookings.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetchHostBookings.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed to fetch host bookings";
      });
  },
});

export default hostBookingsSlice.reducer;
