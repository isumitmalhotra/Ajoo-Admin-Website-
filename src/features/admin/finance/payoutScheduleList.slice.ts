import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import type {
  PayoutSchedule,
  PayoutScheduleSearchPayload,
  PayoutScheduleCreatePayload,
  PayoutScheduleUpdatePayload,
  PaginatedState,
} from "../../../pages/admin/finance/types";

interface PayoutScheduleState extends PaginatedState<PayoutSchedule> {
  actionLoading: boolean;
  actionSuccess: boolean;
  actionError: string | null;
}

const initialState: PayoutScheduleState = {
  data: [],
  totalRecords: 0,
  currentPage: 1,
  totalPages: 1,
  loading: false,
  error: null,
  actionLoading: false,
  actionSuccess: false,
  actionError: null,
};

export const fetchPayoutSchedules = createAsyncThunk<
  {
    schedules: PayoutSchedule[];
    totalRecords: number;
    currentPage: number;
    totalPages: number;
  },
  PayoutScheduleSearchPayload | void,
  { rejectValue: string }
>("finance/fetchPayoutSchedules", async (payload, { rejectWithValue }) => {
  try {
    const res = await api.post(
      ADMINENDPOINTS.FINANCE_PAYOUT_SCHEDULE_SEARCH,
      payload ?? { page: 1, limit: 10 }
    );
    const d = res.data.data;
    return {
      schedules: d.schedules,
      totalRecords: d.totalRecords,
      currentPage: d.currentPage,
      totalPages: d.totalPages,
    };
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      if (err.response?.status === 404) {
        return {
          schedules: [],
          totalRecords: 0,
          currentPage: (payload as PayoutScheduleSearchPayload)?.page ?? 1,
          totalPages: 1,
        };
      }
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch payout schedules"
      );
    }
    return rejectWithValue("Failed to fetch payout schedules");
  }
});

export const createPayoutSchedule = createAsyncThunk<
  PayoutSchedule,
  PayoutScheduleCreatePayload,
  { rejectValue: string }
>("finance/createPayoutSchedule", async (payload, { rejectWithValue }) => {
  try {
    const res = await api.post(
      ADMINENDPOINTS.FINANCE_PAYOUT_SCHEDULE_CREATE,
      payload
    );
    return res.data.data;
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to create payout schedule"
      );
    }
    return rejectWithValue("Failed to create payout schedule");
  }
});

export const updatePayoutSchedule = createAsyncThunk<
  PayoutSchedule,
  { scheduleId: number; payload: PayoutScheduleUpdatePayload },
  { rejectValue: string }
>(
  "finance/updatePayoutSchedule",
  async ({ scheduleId, payload }, { rejectWithValue }) => {
    try {
      const res = await api.put(
        `${ADMINENDPOINTS.FINANCE_PAYOUT_SCHEDULE_UPDATE}/${scheduleId}`,
        payload
      );
      return res.data.data;
    } catch (err: unknown) {
      if (axios.isAxiosError(err)) {
        return rejectWithValue(
          err.response?.data?.message || "Failed to update payout schedule"
        );
      }
      return rejectWithValue("Failed to update payout schedule");
    }
  }
);

const payoutScheduleListSlice = createSlice({
  name: "payoutScheduleList",
  initialState,
  reducers: {
    resetPayoutScheduleAction: (state) => {
      state.actionLoading = false;
      state.actionSuccess = false;
      state.actionError = null;
    },
  },
  extraReducers: (builder) => {
    builder
      // Fetch
      .addCase(fetchPayoutSchedules.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchPayoutSchedules.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload.schedules;
        state.totalRecords = action.payload.totalRecords;
        state.currentPage = action.payload.currentPage;
        state.totalPages = action.payload.totalPages;
      })
      .addCase(fetchPayoutSchedules.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
        state.data = [];
      })
      // Create
      .addCase(createPayoutSchedule.pending, (state) => {
        state.actionLoading = true;
        state.actionSuccess = false;
        state.actionError = null;
      })
      .addCase(createPayoutSchedule.fulfilled, (state) => {
        state.actionLoading = false;
        state.actionSuccess = true;
      })
      .addCase(createPayoutSchedule.rejected, (state, action) => {
        state.actionLoading = false;
        state.actionError = action.payload || "Failed";
      })
      // Update
      .addCase(updatePayoutSchedule.pending, (state) => {
        state.actionLoading = true;
        state.actionSuccess = false;
        state.actionError = null;
      })
      .addCase(updatePayoutSchedule.fulfilled, (state) => {
        state.actionLoading = false;
        state.actionSuccess = true;
      })
      .addCase(updatePayoutSchedule.rejected, (state, action) => {
        state.actionLoading = false;
        state.actionError = action.payload || "Failed";
      });
  },
});

export const { resetPayoutScheduleAction } = payoutScheduleListSlice.actions;
export default payoutScheduleListSlice.reducer;
