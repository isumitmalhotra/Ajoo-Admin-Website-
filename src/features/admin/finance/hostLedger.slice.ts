import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import type { LedgerEntry } from "../../../pages/admin/finance/types";

interface HostLedgerState {
  data: LedgerEntry[];
  balance: number;
  totalRecords: number;
  currentPage: number;
  totalPages: number;
  loading: boolean;
  error: string | null;
}

const initialState: HostLedgerState = {
  data: [],
  balance: 0,
  totalRecords: 0,
  currentPage: 1,
  totalPages: 1,
  loading: false,
  error: null,
};

interface FetchHostLedgerPayload {
  hostId: number;
  page?: number;
  limit?: number;
  dateFrom?: string;
  dateTo?: string;
}

export const fetchHostLedger = createAsyncThunk<
  {
    ledgers: LedgerEntry[];
    balance: number;
    totalRecords: number;
    currentPage: number;
    totalPages: number;
  },
  FetchHostLedgerPayload,
  { rejectValue: string }
>("finance/fetchHostLedger", async (payload, { rejectWithValue }) => {
  try {
    const { hostId, ...body } = payload;
    const res = await api.post(
      `${ADMINENDPOINTS.FINANCE_LEDGER_HOST}/${hostId}`,
      body
    );
    const d = res.data.data;
    return {
      ledgers: d.ledgers,
      balance: d.balance,
      totalRecords: d.totalRecords,
      currentPage: d.currentPage,
      totalPages: d.totalPages,
    };
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      if (err.response?.status === 404) {
        return {
          ledgers: [],
          balance: 0,
          totalRecords: 0,
          currentPage: payload.page ?? 1,
          totalPages: 1,
        };
      }
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch host ledger"
      );
    }
    return rejectWithValue("Failed to fetch host ledger");
  }
});

const hostLedgerSlice = createSlice({
  name: "hostLedger",
  initialState,
  reducers: {
    resetHostLedger: () => initialState,
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchHostLedger.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchHostLedger.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload.ledgers;
        state.balance = action.payload.balance;
        state.totalRecords = action.payload.totalRecords;
        state.currentPage = action.payload.currentPage;
        state.totalPages = action.payload.totalPages;
      })
      .addCase(fetchHostLedger.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
        state.data = [];
      });
  },
});

export const { resetHostLedger } = hostLedgerSlice.actions;
export default hostLedgerSlice.reducer;
