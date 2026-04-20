import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import type {
  RevenueReportResponse,
  ReportFilterPayload,
  DetailState,
} from "../../../pages/admin/finance/types";

const initialState: DetailState<RevenueReportResponse> = {
  data: null,
  loading: false,
  error: null,
};

export const fetchRevenueReport = createAsyncThunk<
  RevenueReportResponse,
  ReportFilterPayload,
  { rejectValue: string }
>("finance/fetchRevenueReport", async (payload, { rejectWithValue }) => {
  try {
    const res = await api.post(
      ADMINENDPOINTS.FINANCE_REPORT_REVENUE,
      payload
    );
    return res.data.data;
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch revenue report"
      );
    }
    return rejectWithValue("Failed to fetch revenue report");
  }
});

const revenueReportSlice = createSlice({
  name: "revenueReport",
  initialState,
  reducers: {
    resetRevenueReport: () => initialState,
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchRevenueReport.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchRevenueReport.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetchRevenueReport.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
      });
  },
});

export const { resetRevenueReport } = revenueReportSlice.actions;
export default revenueReportSlice.reducer;
