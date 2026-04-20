// Use VITE_API_BASE_URL when available, then fallback to VITE_API_URL for backward compatibility.
export const API_BASE_URL =
	import.meta.env.VITE_API_BASE_URL ||
	import.meta.env.VITE_API_URL ||
	"http://localhost:8000";
