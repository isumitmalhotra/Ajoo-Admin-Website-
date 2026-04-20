import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import type {
  CommissionReportResponse,
  ReportFilterPayload,
  DetailState,
} from "../../../pages/admin/finance/types";

const initialState: DetailState<CommissionReportResponse> = {
  data: null,
  loading: false,
  error: null,
};

export const fetchCommissionReport = createAsyncThunk<
  CommissionReportResponse,
  ReportFilterPayload,
  { rejectValue: string }
>("finance/fetchCommissionReport", async (payload, { rejectWithValue }) => {
  try {
    const res = await api.post(
      ADMINENDPOINTS.FINANCE_REPORT_COMMISSION,
      payload
    );
    return res.data.data;
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch commission report"
      );
    }
    return rejectWithValue("Failed to fetch commission report");
  }
});

const commissionReportSlice = createSlice({
  name: "commissionReport",
  initialState,
  reducers: {
    resetCommissionReport: () => initialState,
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchCommissionReport.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchCommissionReport.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetchCommissionReport.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
      });
  },
});

export const { resetCommissionReport } = commissionReportSlice.actions;
export default commissionReportSlice.reducer;
