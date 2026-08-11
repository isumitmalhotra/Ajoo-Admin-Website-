// Customer-facing API layer — wraps the user axios client (src/axios/axios.ts,
// which injects the Bearer token and returns the response envelope directly).
//
// Every backend response is the standard envelope { success, message, data }.
// The axios interceptor already returns `response.data` (the envelope), so here
// `await axios.x(...)` yields the envelope and we unwrap `.data` from it.
//
// Endpoints are the real, deployed backend routes (see LAUNCH_READINESS_AUDIT.md § 6).
import { axios } from "../axios/axios";

export interface ApiProperty {
  property_id: number;
  property_name: string;
  property_address?: string;
  property_city?: string;
  property_desc?: string;
  property_price: number | string;
  property_latitude?: number | string;
  property_longitude?: number | string;
  property_host_id?: number;
  category_titles?: string[] | null;
  amenities?: string[] | null;
  tags?: string[] | null;
  coverImage?: string | null;
  images?: string[];
  distance?: number;
  [key: string]: unknown;
}

// The axios interceptor returns the envelope; unwrap its `.data`.
const unwrap = (env: unknown): any => {
  const e = env as { data?: unknown } | undefined;
  return e && typeof e === "object" && "data" in e ? (e as any).data : e;
};

// ── Properties ──────────────────────────────────────────────────────────────

export const searchProperties = async (params: {
  latitude: number;
  longitude: number;
  category?: string | number;
  radius?: number;
}): Promise<ApiProperty[]> => {
  const env = await axios.post("/properties/search", params);
  const data = unwrap(env);
  return (data?.property ?? (Array.isArray(data) ? data : [])) as ApiProperty[];
};

export const getProperty = async (propId: number | string): Promise<ApiProperty | null> => {
  const env = await axios.get(`/properties/${propId}`);
  const data = unwrap(env);
  const p = data?.property ?? data ?? null;
  return (Array.isArray(p) ? p[0] ?? null : p) as ApiProperty | null;
};

// Public host profile for the property-detail "Meet your host" block.
// GET /properties/host/:hostId → { host: { name, image, city, propertyCount, memberSince } }
export const getHostProfile = async (hostId: number | string): Promise<any | null> => {
  const env = await axios.get(`/properties/host/${hostId}`);
  const data = unwrap(env);
  return data?.host ?? null;
};

export const getPropertyReviews = async (propertyId: number | string): Promise<any[]> => {
  const env = await axios.post("/properties/reviews/list", { propertyId });
  const data = unwrap(env);
  return (data?.reviews ?? (Array.isArray(data) ? data : [])) as any[];
};

// Toggle save/unsave for a property. Backend validates `propId` (not
// `propertyId`) and treats each call as a toggle, returning "success" when
// saved and "property unsave" when removed.
export const saveProperty = (propertyId: number | string) =>
  axios.post("/properties/user-saveProp", { propId: propertyId });

export const getSavedProperties = async (): Promise<any[]> => {
  const env = await axios.post("/user/saved-properties", {});
  const data = unwrap(env);
  // Backend returns { count, property: [...] } (singular key).
  return (data?.property ?? data?.properties ?? (Array.isArray(data) ? data : [])) as any[];
};

// Public property categories — GET /common/categories → { categories: [{cat_id, cat_title}] }
export const getCategories = async (): Promise<{ cat_id: number; cat_title: string }[]> => {
  const env = await axios.get("/common/categories");
  const data = unwrap(env);
  return (data?.categories ?? (Array.isArray(data) ? data : [])) as {
    cat_id: number;
    cat_title: string;
  }[];
};

// ── Bookings ────────────────────────────────────────────────────────────────

export const getMyBookings = async (): Promise<any[]> => {
  const env = await axios.get("/user/booking-history");
  const data = unwrap(env);
  return (Array.isArray(data) ? data : data?.bookings ?? []) as any[];
};

export const getOngoingBookings = async (): Promise<any[]> => {
  const env = await axios.post("/user/ongoing/bookings", {});
  const data = unwrap(env);
  return (Array.isArray(data) ? data : data?.bookings ?? []) as any[];
};

export const cancelBooking = (bookingId: number | string) =>
  axios.post("/user/cancel/booking", { bookingId: String(bookingId) });

// Pay Now for a pending (pay-on-arrival / COD) booking → returns a Razorpay order.
export const createOngoingPaymentOrder = async (
  bookingId: number | string
): Promise<{ id: string; amount: number; currency?: string } | null> => {
  const env = await axios.post("/user/ongoing/bookings/payment/create", {
    bookingId: String(bookingId),
  });
  const data = unwrap(env);
  return (data?.order ?? data ?? null) as any;
};

// Confirm a Razorpay payment with the backend.
export const verifyBookingPayment = (payload: {
  paymentId: string;
  orderId: string;
  signature: string;
}) => axios.post("/create/payment-verify", payload);

// ── User profile ────────────────────────────────────────────────────────────

export const getUserDetail = async (): Promise<any | null> => {
  const env = await axios.get("/user/detail");
  const data = unwrap(env);
  return data?.user ?? data ?? null;
};

export const updateUser = (payload: Record<string, unknown>) =>
  axios.post("/user/update", payload);

// ── Auth / registration ──────────────────────────────────────────────────────

// Public KYC document types for the signup ID step → [{ d_id, d_title }].
export const getDocumentTypes = async (): Promise<
  { id: number; title: string }[]
> => {
  const env = await axios.get("/common/documents/list");
  const data = unwrap(env);
  const rows = (Array.isArray(data) ? data : data?.documents ?? []) as any[];
  return rows
    .map((d) => ({ id: Number(d.d_id ?? d.id), title: d.d_title ?? d.title ?? d.name }))
    .filter((d) => !Number.isNaN(d.id) && d.title);
};

// Multipart signup → backend creates the user, sends the OTP email, returns { userId }.
export const signupUser = (form: FormData) => axios.post("/user/signup", form);

export const verifySignupOtp = (payload: { userId: number | string; otp: string }) =>
  axios.post("/user/verify-otp", {
    userId: Number(payload.userId),
    otp: String(payload.otp),
  });

export const resendSignupOtp = (userId: number | string) =>
  axios.post("/user/otp-again", { userId: Number(userId) });

// ── Notifications ─────────────────────────────────────────────────────────────

export const getUserNotifications = async (): Promise<any[]> => {
  const env = await axios.get("/user/notification/Listing");
  const data = unwrap(env);
  return (Array.isArray(data) ? data : data?.notifications ?? []) as any[];
};

// Backend expects `notificationId` as an array of numeric ids and marks each
// matching row read. Accepts a single id or a list.
export const markUserNotificationRead = (ids: number | string | Array<number | string>) => {
  const list = (Array.isArray(ids) ? ids : [ids]).map((v) => Number(v)).filter((v) => !Number.isNaN(v));
  return axios.post("/user/notification/mark-read", { notificationId: list });
};
