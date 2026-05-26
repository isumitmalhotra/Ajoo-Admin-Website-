import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../services/api";
import { ADMINENDPOINTS } from "../../services/endpoints";
import { extractApiData } from "../../services/apiContracts";
import type {
  HostBooking,
  HostBookingsFilters,
  HostBookingsListResponse,
} from "../../pages/host/types";

export type { HostBooking, HostBookingsFilters };

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null;

const toNumber = (value: unknown, fallback = 0): number => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const toStringOrUndefined = (value: unknown): string | undefined =>
  typeof value === "string" && value.trim().length > 0 ? value : undefined;

const normalizeBookingRow = (value: unknown): HostBooking | null => {
  if (!isRecord(value)) return null;
  const bookingId = toNumber(value.booking_id ?? value.bookingId ?? value.id, NaN);
  if (!Number.isFinite(bookingId)) return null;

  return {
    booking_id: bookingId,
    property_name: toStringOrUndefined(value.property_name ?? value.propertyName),
    guest_name: toStringOrUndefined(value.guest_name ?? value.guestName),
    check_in: toStringOrUndefined(value.check_in ?? value.checkIn),
    check_out: toStringOrUndefined(value.check_out ?? value.checkOut),
    amount: toNumber(value.amount),
    status: toStringOrUndefined(value.status),
    created_at: toStringOrUndefined(value.created_at ?? value.createdAt),
  };
};

const normalizeBookingRows = (value: unknown): HostBooking[] => {
  if (!Array.isArray(value)) return [];
  return value
    .map((row) => normalizeBookingRow(row))
    .filter((row): row is HostBooking => row !== null);
};

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
  HostBookingsListResponse,
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

    const dataNode = extractApiData<Record<string, unknown> | HostBooking[]>(res.data);
    const dataRecord = isRecord(dataNode) ? dataNode : null;
    const rows = normalizeBookingRows(
      dataRecord?.data ?? dataRecord?.rows ?? (Array.isArray(dataNode) ? dataNode : [])
    );

    return {
      rows,
      totalPages: toNumber(dataRecord?.totalPages, 1),
      currentPage: toNumber(dataRecord?.currentPage, payload?.page || 1),
      totalRecords: toNumber(dataRecord?.totalRecords, rows.length || 0),
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
