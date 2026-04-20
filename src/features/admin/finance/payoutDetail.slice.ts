import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import type { Payout, DetailState } from "../../../pages/admin/finance/types";

const initialState: DetailState<Payout> = {
  data: null,
  loading: false,
  error: null,
};

export const fetchPayoutDetail = createAsyncThunk<
  Payout,
  number,
  { rejectValue: string }
>("finance/fetchPayoutDetail", async (payoutId, { rejectWithValue }) => {
  try {
    const res = await api.get(
      `${ADMINENDPOINTS.FINANCE_PAYOUT_BY_ID}/${payoutId}`
    );
    return res.data.data;
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch payout detail"
      );
    }
    return rejectWithValue("Failed to fetch payout detail");
  }
});

const payoutDetailSlice = createSlice({
  name: "payoutDetail",
  initialState,
  reducers: {
    resetPayoutDetail: () => initialState,
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchPayoutDetail.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchPayoutDetail.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetchPayoutDetail.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
      });
  },
});

export const { resetPayoutDetail } = payoutDetailSlice.actions;
export default payoutDetailSlice.reducer;
