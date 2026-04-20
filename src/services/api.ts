import axios from "axios";
import { API_BASE_URL } from "../configs/apiConfigs";

const api = axios.create({
  baseURL: API_BASE_URL,
});

/* ================= REQUEST INTERCEPTOR ================= */
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem("adminToken");

    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    return config;
  },
  (error) => Promise.reject(error)
);

/* ================= RESPONSE INTERCEPTOR ================= */
api.interceptors.response.use(
  (response) => {
    // 🟡 Case: backend sends success=false with session expired
    if (
      response.data?.success === false &&
      typeof response.data?.message === "string" &&
      response.data.message.toLowerCase().includes("session expired")
    ) {
      handleLogout();
      return Promise.reject(response);
    }

    return response;
  },
  (error) => {
    // 🔴 Case: token missing / invalid / expired (401)
    if (error.response?.status === 401) {
      handleLogout();
    }

    return Promise.reject(error);
  }
);

/* ================= LOGOUT HANDLER ================= */
function handleLogout() {
  localStorage.removeItem("adminToken");

  // Optional: clear other auth-related data
  localStorage.removeItem("adminUser");

  // Redirect to login
  window.location.replace("/admin/login");
}

export default api;
