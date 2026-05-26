import { createAsyncThunk } from "@reduxjs/toolkit";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import { setMessage, showLoader } from "../../ui/ui.slice";
import { parseAdminAuthPayload, type AppRole } from "../../../services/apiContracts";
import type { RbacClaims } from "../../../services/apiContracts";

interface LoginPayload {
  username?: string;
  email?: string;
  password: string;
}

interface AdminLoginResult {
  admin: Record<string, unknown>;
  token: string;
  roles: AppRole[];
  permissions: string[];
  claims: RbacClaims | null;
  message: string;
}

const DEV_BYPASS_ENABLED =
  import.meta.env.DEV &&
  (import.meta.env.VITE_ENABLE_DEV_ADMIN_BYPASS === "true" ||
    import.meta.env.VITE_ADMIN_BYPASS === "true");

const DEV_BYPASS_EMAIL =
  import.meta.env.VITE_DEV_ADMIN_EMAIL || "admin@aajao.test";

const DEV_BYPASS_PASSWORD =
  import.meta.env.VITE_DEV_ADMIN_PASSWORD || "Admin@12345";

export const adminLogin = createAsyncThunk<
  AdminLoginResult,
  LoginPayload,
  { rejectValue: string }
>(
  "adminAuth/login",
  async (payload: LoginPayload, { dispatch, rejectWithValue }) => {
    try {
      dispatch(showLoader());

      // Dev-only shortcut when backend is unavailable.
      if (DEV_BYPASS_ENABLED) {
        if (
          payload.username === DEV_BYPASS_EMAIL &&
          payload.password === DEV_BYPASS_PASSWORD
        ) {
          const devAdmin = {
            id: 1,
            email: DEV_BYPASS_EMAIL,
            name: "Dev Test Admin",
            role: "admin",
          };

          return {
            admin: devAdmin,
            token: "dev-admin-token",
            roles: ["admin"],
            permissions: [
              "admin:*",
              "finance:*",
              "hosts:*",
              "users:*",
              "properties:*",
              "bookings:*",
            ],
            claims: {
              sub: "1",
              role: "admin",
              permissions: ["admin:*", "finance:*"],
            },
            message: "Dev login successful (bypass mode)",
          };
        }

        return rejectWithValue(
          "Invalid dev credentials. Use configured DEV admin email/password."
        );
      }

      const res = await api.post(ADMINENDPOINTS.ADMIN_LOGIN, payload);
      const parsed = parseAdminAuthPayload(res.data);
      if (!parsed) {
        return rejectWithValue("Invalid admin auth response payload");
      }
      dispatch(
        setMessage({
          message: parsed.message || "Login successful",
          severity: "success",
        })
      );
      return {
        admin: parsed.admin,
        token: parsed.token,
        roles: parsed.roles,
        permissions: parsed.permissions,
        claims: parsed.claims,
        message: parsed.message || "Login successful",
      };

    } catch (err: unknown) {
      const message =
        typeof err === "object" &&
        err !== null &&
        "response" in err &&
        typeof (err as { response?: { data?: { message?: string } } }).response?.data?.message ===
          "string"
          ? (err as { response?: { data?: { message?: string } } }).response?.data?.message ||
            "Login failed"
          : "Login failed";

      dispatch(
        setMessage({
          message,
          severity: "error",
        })
      );

      return rejectWithValue(message);
    }
  }
);
