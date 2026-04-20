import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import type {
  CashFlowReportResponse,
  ReportFilterPayload,
  DetailState,
} from "../../../pages/admin/finance/types";

const initialState: DetailState<CashFlowReportResponse> = {
  data: null,
  loading: false,
  error: null,
};

export const fetchCashFlowReport = createAsyncThunk<
  CashFlowReportResponse,
  ReportFilterPayload,
  { rejectValue: string }
>("finance/fetchCashFlowReport", async (payload, { rejectWithValue }) => {
  try {
    const res = await api.post(
      ADMINENDPOINTS.FINANCE_REPORT_CASHFLOW,
      payload
    );
    return res.data.data;
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch cash flow report"
      );
    }
    return rejectWithValue("Failed to fetch cash flow report");
  }
});

const cashFlowReportSlice = createSlice({
  name: "cashFlowReport",
  initialState,
  reducers: {
    resetCashFlowReport: () => initialState,
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchCashFlowReport.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchCashFlowReport.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetchCashFlowReport.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
      });
  },
});

export const { resetCashFlowReport } = cashFlowReportSlice.actions;
export default cashFlowReportSlice.reducer;
