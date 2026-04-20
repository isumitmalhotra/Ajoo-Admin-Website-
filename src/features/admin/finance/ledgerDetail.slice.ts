import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import type { LedgerEntry, DetailState } from "../../../pages/admin/finance/types";

const initialState: DetailState<LedgerEntry> = {
  data: null,
  loading: false,
  error: null,
};

export const fetchLedgerDetail = createAsyncThunk<
  LedgerEntry,
  number,
  { rejectValue: string }
>("finance/fetchLedgerDetail", async (ledgerId, { rejectWithValue }) => {
  try {
    const res = await api.get(
      `${ADMINENDPOINTS.FINANCE_LEDGER_BY_ID}/${ledgerId}`
    );
    return res.data.data;
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch ledger detail"
      );
    }
    return rejectWithValue("Failed to fetch ledger detail");
  }
});

const ledgerDetailSlice = createSlice({
  name: "ledgerDetail",
  initialState,
  reducers: {
    resetLedgerDetail: () => initialState,
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchLedgerDetail.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchLedgerDetail.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetchLedgerDetail.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
      });
  },
});

export const { resetLedgerDetail } = ledgerDetailSlice.actions;
export default ledgerDetailSlice.reducer;
