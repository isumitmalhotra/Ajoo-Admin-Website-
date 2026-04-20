import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import type { FinanceDashboardData } from "../../../pages/admin/finance/types";
import type { DetailState } from "../../../pages/admin/finance/types";

const initialState: DetailState<FinanceDashboardData> = {
  data: null,
  loading: false,
  error: null,
};

export const fetchFinanceDashboard = createAsyncThunk<
  FinanceDashboardData,
  void,
  { rejectValue: string }
>("finance/fetchDashboard", async (_, { rejectWithValue }) => {
  try {
    const res = await api.get(ADMINENDPOINTS.FINANCE_DASHBOARD);
    return res.data.data;
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch finance dashboard"
      );
    }
    return rejectWithValue("Failed to fetch finance dashboard");
  }
});

const financeDashboardSlice = createSlice({
  name: "financeDashboard",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchFinanceDashboard.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchFinanceDashboard.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetchFinanceDashboard.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
      });
  },
});

export default financeDashboardSlice.reducer;
