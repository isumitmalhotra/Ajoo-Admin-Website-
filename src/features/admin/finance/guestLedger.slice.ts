import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import type { LedgerEntry } from "../../../pages/admin/finance/types";

interface GuestLedgerState {
  data: LedgerEntry[];
  totalSpent: number;
  totalRecords: number;
  currentPage: number;
  totalPages: number;
  loading: boolean;
  error: string | null;
}

const initialState: GuestLedgerState = {
  data: [],
  totalSpent: 0,
  totalRecords: 0,
  currentPage: 1,
  totalPages: 1,
  loading: false,
  error: null,
};

interface FetchGuestLedgerPayload {
  userId: number;
  page?: number;
  limit?: number;
  dateFrom?: string;
  dateTo?: string;
}

export const fetchGuestLedger = createAsyncThunk<
  {
    ledgers: LedgerEntry[];
    totalSpent: number;
    totalRecords: number;
    currentPage: number;
    totalPages: number;
  },
  FetchGuestLedgerPayload,
  { rejectValue: string }
>("finance/fetchGuestLedger", async (payload, { rejectWithValue }) => {
  try {
    const { userId, ...body } = payload;
    const res = await api.post(
      `${ADMINENDPOINTS.FINANCE_LEDGER_USER}/${userId}`,
      body
    );
    const d = res.data.data;
    return {
      ledgers: d.ledgers,
      totalSpent: d.totalSpent ?? 0,
      totalRecords: d.totalRecords,
      currentPage: d.currentPage,
      totalPages: d.totalPages,
    };
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      if (err.response?.status === 404) {
        return {
          ledgers: [],
          totalSpent: 0,
          totalRecords: 0,
          currentPage: payload.page ?? 1,
          totalPages: 1,
        };
      }
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch guest ledger"
      );
    }
    return rejectWithValue("Failed to fetch guest ledger");
  }
});

const guestLedgerSlice = createSlice({
  name: "guestLedger",
  initialState,
  reducers: {
    resetGuestLedger: () => initialState,
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchGuestLedger.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchGuestLedger.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload.ledgers;
        state.totalSpent = action.payload.totalSpent;
        state.totalRecords = action.payload.totalRecords;
        state.currentPage = action.payload.currentPage;
        state.totalPages = action.payload.totalPages;
      })
      .addCase(fetchGuestLedger.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload ?? "Failed to fetch guest ledger";
      });
  },
});

export const { resetGuestLedger } = guestLedgerSlice.actions;
export default guestLedgerSlice.reducer;
