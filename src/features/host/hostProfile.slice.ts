import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../services/api";
import { ADMINENDPOINTS } from "../../services/endpoints";

export interface HostProfileData {
  fullName?: string;
  email?: string;
  phone?: string;
  city?: string;
  bankName?: string;
  accountNumber?: string;
  upiId?: string;
  ifscCode?: string;
}

export interface HostProfilePayload {
  fullName: string;
  email: string;
  phone: string;
  city: string;
  bankName: string;
  accountNumber: string;
  upiId: string;
  ifscCode: string;
}

interface HostProfileState {
  data: HostProfileData | null;
  loading: boolean;
  error: string | null;
  updateLoading: boolean;
  updateError: string | null;
  updateSuccess: string | null;
}

const initialState: HostProfileState = {
  data: null,
  loading: false,
  error: null,
  updateLoading: false,
  updateError: null,
  updateSuccess: null,
};

const normalizeProfile = (raw: any): HostProfileData => ({
  fullName: raw?.fullName || raw?.full_name || raw?.user_fullName || "",
  email: raw?.email || raw?.user_email || raw?.userCred?.cred_user_email || "",
  phone: raw?.phone || raw?.user_pnumber || raw?.mobile || "",
  city: raw?.city || raw?.user_city || "",
  bankName: raw?.bankName || raw?.bank_name || "",
  accountNumber: raw?.accountNumber || raw?.account_number || "",
  upiId: raw?.upiId || raw?.upi_id || "",
  ifscCode: raw?.ifscCode || raw?.ifsc_code || "",
});

export const fetchHostProfile = createAsyncThunk<
  HostProfileData,
  void,
  { rejectValue: string }
>("hostProfile/fetch", async (_, { rejectWithValue }) => {
  try {
    const res = await api.get(ADMINENDPOINTS.HOST_PORTAL_PROFILE);
    return normalizeProfile(res.data?.data || {});
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      if (!err.response) {
        return rejectWithValue(
          "Unable to reach host backend service. Please verify API server is running."
        );
      }

      if (err.response.status === 404) {
        return rejectWithValue(
          "Host profile endpoint is not available on current backend."
        );
      }

      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch host profile"
      );
    }

    return rejectWithValue("Failed to fetch host profile");
  }
});

export const updateHostProfile = createAsyncThunk<
  HostProfileData,
  HostProfilePayload,
  { rejectValue: string }
>("hostProfile/update", async (payload, { rejectWithValue }) => {
  try {
    const res = await api.post(ADMINENDPOINTS.HOST_PORTAL_PROFILE_UPDATE, payload);
    return normalizeProfile(res.data?.data || payload);
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      if (!err.response) {
        return rejectWithValue(
          "Unable to reach host backend service. Please verify API server is running."
        );
      }

      if (err.response.status === 404) {
        return rejectWithValue(
          "Host profile update endpoint is not available on current backend."
        );
      }

      return rejectWithValue(
        err.response?.data?.message || "Failed to update host profile"
      );
    }

    return rejectWithValue("Failed to update host profile");
  }
});

const hostProfileSlice = createSlice({
  name: "hostProfile",
  initialState,
  reducers: {
    clearHostProfileUpdateState(state) {
      state.updateLoading = false;
      state.updateError = null;
      state.updateSuccess = null;
    },
    setLocalHostProfile(state, action) {
      state.data = {
        ...(state.data || {}),
        ...normalizeProfile(action.payload),
      };
      state.updateSuccess = "Host profile saved locally (mock mode).";
      state.updateError = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchHostProfile.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchHostProfile.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetchHostProfile.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed to fetch host profile";
      })
      .addCase(updateHostProfile.pending, (state) => {
        state.updateLoading = true;
        state.updateError = null;
        state.updateSuccess = null;
      })
      .addCase(updateHostProfile.fulfilled, (state, action) => {
        state.updateLoading = false;
        state.updateError = null;
        state.updateSuccess = "Host profile updated successfully.";
        state.data = {
          ...(state.data || {}),
          ...action.payload,
        };
      })
      .addCase(updateHostProfile.rejected, (state, action) => {
        state.updateLoading = false;
        state.updateError = action.payload || "Failed to update host profile";
      });
  },
});

export const { clearHostProfileUpdateState, setLocalHostProfile } = hostProfileSlice.actions;
export default hostProfileSlice.reducer;
