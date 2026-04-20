// Uses VITE_API_BASE_URL from environment; falls back to localhost for local dev
export const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:8000";