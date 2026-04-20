import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../services/api";
import { ADMINENDPOINTS } from "../../services/endpoints";

export interface HostBooking {
  booking_id: number;
  property_name?: string;
  guest_name?: string;
  check_in?: string;
  check_out?: string;
  amount?: number;
  status?: string;
  created_at?: string;
}

export interface HostBookingsFilters {
  search: string;
  status: string;
  dateFrom: string;
  dateTo: string;
}

interface HostBookingsState {
  data: HostBooking[];
  loading: boolean;
  error: string | null;
  totalPages: number;
  currentPage: number;
  totalRecords: number;
  filters: HostBookingsFilters;
}

const initialState: HostBookingsState = {
  data: [],
  loading: false,
  error: null,
  totalPages: 1,
  currentPage: 1,
  totalRecords: 0,
  filters: {
    search: "",
    status: "",
    dateFrom: "",
    dateTo: "",
  },
};

export const fetchHostBookings = createAsyncThunk<
  {
    rows: HostBooking[];
    totalPages: number;
    currentPage: number;
    totalRecords: number;
  },
  {
    page?: number;
    limit?: number;
    search?: string;
    status?: string;
    dateFrom?: string;
    dateTo?: string;
    sortBy?: string;
    sortOrder?: "asc" | "desc";
  } | undefined,
  { rejectValue: string }
>("hostBookings/fetch", async (payload, { rejectWithValue }) => {
  try {
    const res = await api.post(ADMINENDPOINTS.HOST_PORTAL_BOOKINGS, {
      page: payload?.page || 1,
      limit: payload?.limit || 10,
      search: payload?.search || "",
      status: payload?.status || "",
      dateFrom: payload?.dateFrom || "",
      dateTo: payload?.dateTo || "",
      sortBy: payload?.sortBy || "created_at",
      sortOrder: payload?.sortOrder || "desc",
    });

    const dataNode = res.data?.data || {};
    const rows = Array.isArray(dataNode?.data)
      ? dataNode.data
      : Array.isArray(dataNode)
      ? dataNode
      : [];

    return {
      rows,
      totalPages: Number(dataNode?.totalPages || 1),
      currentPage: Number(dataNode?.currentPage || payload?.page || 1),
      totalRecords: Number(dataNode?.totalRecords || rows.length || 0),
    };
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      if (!err.response) {
        return rejectWithValue(
          "Unable to reach host backend service. Please verify API server is running."
        );
      }

      if (err.response.status === 404) {
        return rejectWithValue(
          "Host bookings endpoint is not available on current backend."
        );
      }

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
  reducers: {
    setHostBookingsFilters(state, action) {
      state.filters = {
        ...state.filters,
        ...action.payload,
      };
    },
    resetHostBookingsFilters(state) {
      state.filters = initialState.filters;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchHostBookings.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchHostBookings.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload.rows;
        state.totalPages = action.payload.totalPages;
        state.currentPage = action.payload.currentPage;
        state.totalRecords = action.payload.totalRecords;
      })
      .addCase(fetchHostBookings.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed to fetch host bookings";
      });
  },
});

export const { setHostBookingsFilters, resetHostBookingsFilters } =
  hostBookingsSlice.actions;
export default hostBookingsSlice.reducer;
