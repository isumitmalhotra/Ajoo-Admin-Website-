import { createAsyncThunk } from "@reduxjs/toolkit";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import { setMessage, showLoader } from "../../ui/ui.slice";

interface LoginPayload {
  username: string;
  password: string;
}

const DEV_BYPASS_ENABLED =
  import.meta.env.DEV &&
  import.meta.env.VITE_ENABLE_DEV_ADMIN_BYPASS === "true";

const DEV_BYPASS_EMAIL =
  import.meta.env.VITE_DEV_ADMIN_EMAIL || "admin@aajao.test";

const DEV_BYPASS_PASSWORD =
  import.meta.env.VITE_DEV_ADMIN_PASSWORD || "Admin@12345";

export const adminLogin = createAsyncThunk(
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
            message: "Dev login successful (bypass mode)",
          };
        }

        return rejectWithValue(
          "Invalid dev credentials. Use configured DEV admin email/password."
        );
      }

      const res = await api.post(ADMINENDPOINTS.ADMIN_LOGIN, payload);
      console.log(res.data, "admin login response");

      dispatch(
        setMessage({
          message: res.data.message,
          severity: "success",
        })
      );

      // return res.data.data;
      return {
        admin: res.data.data.admin,
        token: res.data.data.token,
        message: res.data.message,
      };
      
    } catch (err: any) {
      const message = err.response?.data?.message || "Login failed";

      dispatch(
        setMessage({
          message,
          severity: "error",
        })
      );

      return rejectWithValue(message);
    } 
    // finally {
    //   dispatch(hideLoader());
    // }
  }
);
