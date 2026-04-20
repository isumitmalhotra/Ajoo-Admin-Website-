import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import type {
  LedgerEntry,
  LedgerSearchPayload,
  PaginatedState,
} from "../../../pages/admin/finance/types";

const initialState: PaginatedState<LedgerEntry> = {
  data: [],
  totalRecords: 0,
  currentPage: 1,
  totalPages: 1,
  loading: false,
  error: null,
};

export const fetchLedgerList = createAsyncThunk<
  {
    ledgers: LedgerEntry[];
    totalRecords: number;
    currentPage: number;
    totalPages: number;
  },
  LedgerSearchPayload | void,
  { rejectValue: string }
>("finance/fetchLedgerList", async (payload, { rejectWithValue }) => {
  try {
    const res = await api.post(
      ADMINENDPOINTS.FINANCE_LEDGER_SEARCH,
      payload ?? { page: 1, limit: 10 }
    );
    const d = res.data.data;
    return {
      ledgers: d.ledgers,
      totalRecords: d.totalRecords,
      currentPage: d.currentPage,
      totalPages: d.totalPages,
    };
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      if (err.response?.status === 404) {
        return {
          ledgers: [],
          totalRecords: 0,
          currentPage: (payload as LedgerSearchPayload)?.page ?? 1,
          totalPages: 1,
        };
      }
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch ledger entries"
      );
    }
    return rejectWithValue("Failed to fetch ledger entries");
  }
});

const ledgerListSlice = createSlice({
  name: "ledgerList",
  initialState,
  reducers: {
    resetLedgerList: () => initialState,
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchLedgerList.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchLedgerList.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload.ledgers;
        state.totalRecords = action.payload.totalRecords;
        state.currentPage = action.payload.currentPage;
        state.totalPages = action.payload.totalPages;
      })
      .addCase(fetchLedgerList.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
        state.data = [];
      });
  },
});

export const { resetLedgerList } = ledgerListSlice.actions;
export default ledgerListSlice.reducer;
