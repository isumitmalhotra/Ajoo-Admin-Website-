import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";

interface HostKycActionPayload {
  hostId: number;
  note?: string;
  reason?: string;
}

interface HostDetailState {
  data: any | null;
  loading: boolean;
  error: string | null;
  actionLoading: boolean;
  actionError: string | null;
  actionSuccess: string | null;
}

const initialState: HostDetailState = {
  data: null,
  loading: false,
  error: null,
  actionLoading: false,
  actionError: null,
  actionSuccess: null,
};

export const fetchHostDetail = createAsyncThunk<
  any,
  number,
  { rejectValue: string }
>("hostDetail/fetchHostDetail", async (hostId, { rejectWithValue }) => {
  try {
    const res = await api.post(ADMINENDPOINTS.USER_BY_ID, {
      userId: hostId,
    });

    return res.data?.data ?? null;
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch host detail"
      );
    }

    return rejectWithValue("Failed to fetch host detail");
  }
});

export const approveHostKyc = createAsyncThunk<
  string,
  HostKycActionPayload,
  { rejectValue: string }
>("hostDetail/approveHostKyc", async (payload, { rejectWithValue }) => {
  try {
    const res = await api.post(ADMINENDPOINTS.HOST_KYC_APPROVE, {
      hostId: payload.hostId,
      note: payload.note,
    });

    return res.data?.message || "Host KYC approved successfully";
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to approve host KYC"
      );
    }

    return rejectWithValue("Failed to approve host KYC");
  }
});

export const rejectHostKyc = createAsyncThunk<
  string,
  HostKycActionPayload,
  { rejectValue: string }
>("hostDetail/rejectHostKyc", async (payload, { rejectWithValue }) => {
  try {
    const res = await api.post(ADMINENDPOINTS.HOST_KYC_REJECT, {
      hostId: payload.hostId,
      reason: payload.reason,
    });

    return res.data?.message || "Host KYC rejected successfully";
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to reject host KYC"
      );
    }

    return rejectWithValue("Failed to reject host KYC");
  }
});

const hostDetailSlice = createSlice({
  name: "hostDetail",
  initialState,
  reducers: {
    resetHostDetail(state) {
      state.data = null;
      state.loading = false;
      state.error = null;
      state.actionLoading = false;
      state.actionError = null;
      state.actionSuccess = null;
    },
    clearHostKycActionState(state) {
      state.actionLoading = false;
      state.actionError = null;
      state.actionSuccess = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchHostDetail.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchHostDetail.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetchHostDetail.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed to fetch host detail";
      })
      .addCase(approveHostKyc.pending, (state) => {
        state.actionLoading = true;
        state.actionError = null;
        state.actionSuccess = null;
      })
      .addCase(approveHostKyc.fulfilled, (state, action) => {
        state.actionLoading = false;
        state.actionSuccess = action.payload;
        if (state.data) {
          state.data.user_isVerified = 1;
        }
      })
      .addCase(approveHostKyc.rejected, (state, action) => {
        state.actionLoading = false;
        state.actionError = action.payload || "Failed to approve host KYC";
      })
      .addCase(rejectHostKyc.pending, (state) => {
        state.actionLoading = true;
        state.actionError = null;
        state.actionSuccess = null;
      })
      .addCase(rejectHostKyc.fulfilled, (state, action) => {
        state.actionLoading = false;
        state.actionSuccess = action.payload;
        if (state.data) {
          state.data.user_isVerified = 0;
        }
      })
      .addCase(rejectHostKyc.rejected, (state, action) => {
        state.actionLoading = false;
        state.actionError = action.payload || "Failed to reject host KYC";
      });
  },
});

export const { resetHostDetail, clearHostKycActionState } = hostDetailSlice.actions;
export default hostDetailSlice.reducer;
