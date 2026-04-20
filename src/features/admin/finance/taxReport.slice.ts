import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import type {
  TaxReportResponse,
  ReportFilterPayload,
  DetailState,
} from "../../../pages/admin/finance/types";

const initialState: DetailState<TaxReportResponse> = {
  data: null,
  loading: false,
  error: null,
};

export const fetchTaxReport = createAsyncThunk<
  TaxReportResponse,
  ReportFilterPayload,
  { rejectValue: string }
>("finance/fetchTaxReport", async (payload, { rejectWithValue }) => {
  try {
    const res = await api.post(ADMINENDPOINTS.FINANCE_REPORT_TAX, payload);
    return res.data.data;
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch tax report"
      );
    }
    return rejectWithValue("Failed to fetch tax report");
  }
});

const taxReportSlice = createSlice({
  name: "taxReport",
  initialState,
  reducers: {
    resetTaxReport: () => initialState,
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchTaxReport.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchTaxReport.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetchTaxReport.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
      });
  },
});

export const { resetTaxReport } = taxReportSlice.actions;
export default taxReportSlice.reducer;
