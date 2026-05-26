import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../services/api";
import { ADMINENDPOINTS } from "../../services/endpoints";
import { extractApiData } from "../../services/apiContracts";
import type { HostEarningsData, HostPayoutRow } from "../../pages/host/types";

export type { HostEarningsData, HostPayoutRow };

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null;

const toNumber = (value: unknown): number => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
};

const toStringOrUndefined = (value: unknown): string | undefined =>
  typeof value === "string" && value.trim().length > 0 ? value : undefined;

const normalizePayoutRow = (value: unknown): HostPayoutRow | null => {
  if (!isRecord(value)) return null;

  return {
    payout_id: toNumber(value.payout_id ?? value.payoutId ?? value.id),
    booking_id: toNumber(value.booking_id ?? value.bookingId),
    amount: toNumber(value.amount),
    status: toStringOrUndefined(value.status ?? value.payout_status),
    payout_date: toStringOrUndefined(value.payout_date ?? value.payoutDate ?? value.created_at),
    reference_id: toStringOrUndefined(value.reference_id ?? value.referenceId ?? value.utr),
  };
};

const normalizePayoutRows = (value: unknown): HostPayoutRow[] => {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => normalizePayoutRow(item))
    .filter((item): item is HostPayoutRow => item !== null);
};

const normalizeHostEarnings = (value: unknown): HostEarningsData => {
  if (!isRecord(value)) return {};

  return {
    totalEarnings: toNumber(value.totalEarnings ?? value.total_earnings),
    pendingPayouts: toNumber(value.pendingPayouts ?? value.pending_payouts),
    settledPayouts: toNumber(value.settledPayouts ?? value.settled_payouts),
    lastPayoutAmount: toNumber(value.lastPayoutAmount ?? value.last_payout_amount),
    nextPayoutDate: toStringOrUndefined(value.nextPayoutDate ?? value.next_payout_date),
    payoutHistory: normalizePayoutRows(
      value.payoutHistory ?? value.payout_history ?? value.recentPayouts
    ),
  };
};

interface HostEarningsState {
  data: HostEarningsData | null;
  loading: boolean;
  error: string | null;
}

const initialState: HostEarningsState = {
  data: null,
  loading: false,
  error: null,
};

export const fetchHostEarnings = createAsyncThunk<
  HostEarningsData,
  void,
  { rejectValue: string }
>("hostEarnings/fetch", async (_, { rejectWithValue }) => {
  try {
    const res = await api.get(ADMINENDPOINTS.HOST_PORTAL_EARNINGS);
    return normalizeHostEarnings(extractApiData<unknown>(res.data));
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      if (!err.response) {
        return rejectWithValue(
          "Unable to reach host backend service. Please verify API server is running."
        );
      }

      if (err.response.status === 404) {
        return rejectWithValue(
          "Host earnings endpoint is not available on current backend."
        );
      }

      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch host earnings"
      );
    }

    return rejectWithValue("Failed to fetch host earnings");
  }
});

const hostEarningsSlice = createSlice({
  name: "hostEarnings",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchHostEarnings.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchHostEarnings.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetchHostEarnings.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed to fetch host earnings";
      });
  },
});

export default hostEarningsSlice.reducer;
