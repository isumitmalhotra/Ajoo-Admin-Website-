import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import type {
  PayoutInitiatePayload,
  PayoutRejectPayload,
  ActionState,
} from "../../../pages/admin/finance/types";

const initialState: ActionState = {
  loading: false,
  success: false,
  error: null,
};

export const initiatePayout = createAsyncThunk<
  { payoutId: number; status: string },
  PayoutInitiatePayload,
  { rejectValue: string }
>("finance/initiatePayout", async (payload, { rejectWithValue }) => {
  try {
    const res = await api.post(ADMINENDPOINTS.FINANCE_PAYOUT_INITIATE, payload);
    return res.data.data;
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to initiate payout"
      );
    }
    return rejectWithValue("Failed to initiate payout");
  }
});

export const approvePayout = createAsyncThunk<
  { status: string },
  number,
  { rejectValue: string }
>("finance/approvePayout", async (payoutId, { rejectWithValue }) => {
  try {
    const res = await api.put(
      `${ADMINENDPOINTS.FINANCE_PAYOUT_APPROVE}/${payoutId}`
    );
    return res.data.data;
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to approve payout"
      );
    }
    return rejectWithValue("Failed to approve payout");
  }
});

export const rejectPayout = createAsyncThunk<
  { status: string },
  { payoutId: number; payload: PayoutRejectPayload },
  { rejectValue: string }
>("finance/rejectPayout", async ({ payoutId, payload }, { rejectWithValue }) => {
  try {
    const res = await api.put(
      `${ADMINENDPOINTS.FINANCE_PAYOUT_REJECT}/${payoutId}`,
      payload
    );
    return res.data.data;
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to reject payout"
      );
    }
    return rejectWithValue("Failed to reject payout");
  }
});

const payoutActionSlice = createSlice({
  name: "payoutAction",
  initialState,
  reducers: {
    resetPayoutAction: () => initialState,
  },
  extraReducers: (builder) => {
    builder
      // Initiate
      .addCase(initiatePayout.pending, (state) => {
        state.loading = true;
        state.success = false;
        state.error = null;
      })
      .addCase(initiatePayout.fulfilled, (state) => {
        state.loading = false;
        state.success = true;
      })
      .addCase(initiatePayout.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
      })
      // Approve
      .addCase(approvePayout.pending, (state) => {
        state.loading = true;
        state.success = false;
        state.error = null;
      })
      .addCase(approvePayout.fulfilled, (state) => {
        state.loading = false;
        state.success = true;
      })
      .addCase(approvePayout.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
      })
      // Reject
      .addCase(rejectPayout.pending, (state) => {
        state.loading = true;
        state.success = false;
        state.error = null;
      })
      .addCase(rejectPayout.fulfilled, (state) => {
        state.loading = false;
        state.success = true;
      })
      .addCase(rejectPayout.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
      });
  },
});

export const { resetPayoutAction } = payoutActionSlice.actions;
export default payoutActionSlice.reducer;
