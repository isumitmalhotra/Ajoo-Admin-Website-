import { createSlice } from "@reduxjs/toolkit";
import { adminLogin } from "./adminAuth.thunk";
import type { AppRole, RbacClaims } from "../../../services/apiContracts";
import {
  clearAdminSession,
  getAdminClaims,
  getAdminPermissions,
  getAdminRoles,
  getAdminToken,
  getAdminUser,
  setAdminClaims,
  setAdminPermissions,
  setAdminRoles,
  setAdminToken,
  setAdminUser,
} from "../../../services/adminSession";

interface AdminAuthState {
  loading: boolean;
  admin: Record<string, unknown> | null;
  token: string | null;
  claims: RbacClaims | null;
  roles: AppRole[];
  permissions: string[];
  isAuthenticated: boolean;

  // 🔔 Snackbar state
  snackbarOpen: boolean;
  snackbarMessage: string;
  snackbarSeverity: "success" | "error" | "warning" | "info";
}

const initialState: AdminAuthState = {
  loading: false,
  admin: getAdminUser(),
  token: getAdminToken(),
  claims: getAdminClaims(),
  roles: getAdminRoles(),
  permissions: getAdminPermissions(),
  isAuthenticated: !!getAdminToken(),

  snackbarOpen: false,
  snackbarMessage: "",
  snackbarSeverity: "info",
};

const adminAuthSlice = createSlice({
  name: "adminAuth",
  initialState,
  reducers: {
    logout(state) {
      state.admin = null;
      state.token = null;
      state.claims = null;
      state.roles = [];
      state.permissions = [];
      state.isAuthenticated = false;
      clearAdminSession();
    },

    // 🔔 Close snackbar
    closeSnackbar(state) {
      state.snackbarOpen = false;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(adminLogin.pending, (state) => {
        state.loading = true;
      })

      .addCase(adminLogin.fulfilled, (state, action) => {
        state.loading = false;
        state.admin = action.payload.admin;
        state.token = action.payload.token;
        state.claims = action.payload.claims;
        state.roles = action.payload.roles;
        state.permissions = action.payload.permissions;
        state.isAuthenticated = true;

        setAdminToken(action.payload.token);
        setAdminUser(action.payload.admin);
        setAdminClaims(action.payload.claims);
        setAdminRoles(action.payload.roles);
        setAdminPermissions(action.payload.permissions);

        // ✅ SHOW SUCCESS SNACKBAR
        state.snackbarOpen = true;
        state.snackbarMessage = action.payload.message || "Login successful";
        state.snackbarSeverity = "success";
      })

      .addCase(adminLogin.rejected, (state, action) => {
        state.loading = false;
        state.isAuthenticated = false;
        state.claims = null;
        state.roles = [];
        state.permissions = [];

        // ❌ SHOW ERROR SNACKBAR
        state.snackbarOpen = true;
        state.snackbarMessage =
          typeof action.payload === "string" ? action.payload : "Invalid email or password";
        state.snackbarSeverity = "error";
      });
  },
});

export const { logout, closeSnackbar } = adminAuthSlice.actions;
export default adminAuthSlice.reducer;
