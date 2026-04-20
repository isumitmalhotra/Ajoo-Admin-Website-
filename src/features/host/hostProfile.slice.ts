import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../services/api";
import { ADMINENDPOINTS } from "../../services/endpoints";

interface HostProfileData {
  fullName?: string;
  email?: string;
  phone?: string;
  city?: string;
  bankName?: string;
  accountNumber?: string;
  upiId?: string;
}

interface HostProfileState {
  data: HostProfileData | null;
  loading: boolean;
  error: string | null;
}

const initialState: HostProfileState = {
  data: null,
  loading: false,
  error: null,
};

export const fetchHostProfile = createAsyncThunk<
  HostProfileData,
  void,
  { rejectValue: string }
>("hostProfile/fetch", async (_, { rejectWithValue }) => {
  try {
    const res = await api.get(ADMINENDPOINTS.HOST_PORTAL_PROFILE);
    return res.data?.data || {};
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch host profile"
      );
    }

    return rejectWithValue("Failed to fetch host profile");
  }
});

const hostProfileSlice = createSlice({
  name: "hostProfile",
  initialState,
  reducers: {},
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
      });
  },
});

export default hostProfileSlice.reducer;
