import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import type {
  ReconciliationRecord,
  ReconciliationSummary,
  ReconciliationSearchPayload,
} from "../../../pages/admin/finance/types";

interface ReconciliationListState {
  data: ReconciliationRecord[];
  summary: ReconciliationSummary;
  totalRecords: number;
  currentPage: number;
  totalPages: number;
  loading: boolean;
  error: string | null;
}

const initialState: ReconciliationListState = {
  data: [],
  summary: { matched: 0, variance: 0, pending: 0 },
  totalRecords: 0,
  currentPage: 1,
  totalPages: 1,
  loading: false,
  error: null,
};

export const fetchReconciliationList = createAsyncThunk<
  {
    records: ReconciliationRecord[];
    summary: ReconciliationSummary;
    totalRecords: number;
    currentPage: number;
    totalPages: number;
  },
  ReconciliationSearchPayload | void,
  { rejectValue: string }
>("finance/fetchReconciliationList", async (payload, { rejectWithValue }) => {
  try {
    const res = await api.post(
      ADMINENDPOINTS.FINANCE_RECONCILIATION_SEARCH,
      payload ?? { page: 1, limit: 10 }
    );
    const d = res.data.data;
    return {
      records: d.records,
      summary: d.summary,
      totalRecords: d.totalRecords,
      currentPage: d.currentPage,
      totalPages: d.totalPages,
    };
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      if (err.response?.status === 404) {
        return {
          records: [],
          summary: { matched: 0, variance: 0, pending: 0 },
          totalRecords: 0,
          currentPage: (payload as ReconciliationSearchPayload)?.page ?? 1,
          totalPages: 1,
        };
      }
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch reconciliation records"
      );
    }
    return rejectWithValue("Failed to fetch reconciliation records");
  }
});

const reconciliationListSlice = createSlice({
  name: "reconciliationList",
  initialState,
  reducers: {
    resetReconciliationList: () => initialState,
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchReconciliationList.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchReconciliationList.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload.records;
        state.summary = action.payload.summary;
        state.totalRecords = action.payload.totalRecords;
        state.currentPage = action.payload.currentPage;
        state.totalPages = action.payload.totalPages;
      })
      .addCase(fetchReconciliationList.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
        state.data = [];
      });
  },
});

export const { resetReconciliationList } = reconciliationListSlice.actions;
export default reconciliationListSlice.reducer;
