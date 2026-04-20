import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import type {
  ReconciliationResolvePayload,
  ActionState,
} from "../../../pages/admin/finance/types";

const initialState: ActionState = {
  loading: false,
  success: false,
  error: null,
};

export const resolveReconciliation = createAsyncThunk<
  { status: string },
  { reconId: number; payload: ReconciliationResolvePayload },
  { rejectValue: string }
>(
  "finance/resolveReconciliation",
  async ({ reconId, payload }, { rejectWithValue }) => {
    try {
      const res = await api.put(
        `${ADMINENDPOINTS.FINANCE_RECONCILIATION_RESOLVE}/${reconId}`,
        payload
      );
      return res.data.data;
    } catch (err: unknown) {
      if (axios.isAxiosError(err)) {
        return rejectWithValue(
          err.response?.data?.message || "Failed to resolve reconciliation"
        );
      }
      return rejectWithValue("Failed to resolve reconciliation");
    }
  }
);

export const runReconciliation = createAsyncThunk<
  { jobId: string; status: string },
  { dateFrom: string; dateTo: string },
  { rejectValue: string }
>("finance/runReconciliation", async (payload, { rejectWithValue }) => {
  try {
    const res = await api.post(
      ADMINENDPOINTS.FINANCE_RECONCILIATION_RUN,
      payload
    );
    return res.data.data;
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to run reconciliation"
      );
    }
    return rejectWithValue("Failed to run reconciliation");
  }
});

const reconciliationResolveSlice = createSlice({
  name: "reconciliationResolve",
  initialState,
  reducers: {
    resetReconciliationResolve: () => initialState,
  },
  extraReducers: (builder) => {
    builder
      .addCase(resolveReconciliation.pending, (state) => {
        state.loading = true;
        state.success = false;
        state.error = null;
      })
      .addCase(resolveReconciliation.fulfilled, (state) => {
        state.loading = false;
        state.success = true;
      })
      .addCase(resolveReconciliation.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
      })
      .addCase(runReconciliation.pending, (state) => {
        state.loading = true;
        state.success = false;
        state.error = null;
      })
      .addCase(runReconciliation.fulfilled, (state) => {
        state.loading = false;
        state.success = true;
      })
      .addCase(runReconciliation.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
      });
  },
});

export const { resetReconciliationResolve } = reconciliationResolveSlice.actions;
export default reconciliationResolveSlice.reducer;
