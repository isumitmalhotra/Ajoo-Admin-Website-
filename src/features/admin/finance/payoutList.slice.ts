import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import type {
  Payout,
  PayoutSearchPayload,
  PaginatedState,
} from "../../../pages/admin/finance/types";

const initialState: PaginatedState<Payout> = {
  data: [],
  totalRecords: 0,
  currentPage: 1,
  totalPages: 1,
  loading: false,
  error: null,
};

export const fetchPayoutList = createAsyncThunk<
  {
    payouts: Payout[];
    totalRecords: number;
    currentPage: number;
    totalPages: number;
  },
  PayoutSearchPayload | void,
  { rejectValue: string }
>("finance/fetchPayoutList", async (payload, { rejectWithValue }) => {
  try {
    const res = await api.post(
      ADMINENDPOINTS.FINANCE_PAYOUT_SEARCH,
      payload ?? { page: 1, limit: 10 }
    );
    const d = res.data.data;
    return {
      payouts: d.payouts,
      totalRecords: d.totalRecords,
      currentPage: d.currentPage,
      totalPages: d.totalPages,
    };
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      if (err.response?.status === 404) {
        return {
          payouts: [],
          totalRecords: 0,
          currentPage: (payload as PayoutSearchPayload)?.page ?? 1,
          totalPages: 1,
        };
      }
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch payouts"
      );
    }
    return rejectWithValue("Failed to fetch payouts");
  }
});

const payoutListSlice = createSlice({
  name: "payoutList",
  initialState,
  reducers: {
    resetPayoutList: () => initialState,
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchPayoutList.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchPayoutList.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload.payouts;
        state.totalRecords = action.payload.totalRecords;
        state.currentPage = action.payload.currentPage;
        state.totalPages = action.payload.totalPages;
      })
      .addCase(fetchPayoutList.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
        state.data = [];
      });
  },
});

export const { resetPayoutList } = payoutListSlice.actions;
export default payoutListSlice.reducer;
