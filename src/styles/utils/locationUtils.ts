// Shared geolocation + address helpers for the onboarding flows
// (signup, host onboarding, etc.).

export interface GeoAddress {
  address: string;
  city: string;
  state: string;
  pincode: string;
  country: string;
}

export const INDIAN_STATES: string[] = [
  "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", "Goa",
  "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka", "Kerala",
  "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram", "Nagaland",
  "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana", "Tripura",
  "Uttar Pradesh", "Uttarakhand", "West Bengal",
  // Union Territories
  "Andaman and Nicobar Islands", "Chandigarh", "Dadra and Nagar Haveli and Daman and Diu",
  "Delhi", "Jammu and Kashmir", "Ladakh", "Lakshadweep", "Puducherry",
];

// Match a free-form state string (e.g. from reverse geocoding) to a known state.
export const matchIndianState = (raw?: string): string => {
  if (!raw) return "";
  const lc = raw.toLowerCase().trim();
  return (
    INDIAN_STATES.find((s) => s.toLowerCase() === lc) ||
    INDIAN_STATES.find((s) => lc.includes(s.toLowerCase()) || s.toLowerCase().includes(lc)) ||
    ""
  );
};

export const getCurrentPosition = (): Promise<{ lat: number; lng: number }> =>
  new Promise((resolve, reject) => {
    if (!("geolocation" in navigator)) {
      reject(new Error("Geolocation is not supported by your browser."));
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (p) => resolve({ lat: p.coords.latitude, lng: p.coords.longitude }),
      (err) => reject(err),
      { timeout: 8000, enableHighAccuracy: true }
    );
  });

export const reverseGeocode = async (lat: number, lng: number): Promise<GeoAddress> => {
  const res = await fetch(
    `https://nominatim.openstreetmap.org/reverse?format=json&addressdetails=1&lat=${lat}&lon=${lng}`
  );
  const data = await res.json();
  const a = data.address || {};
  const address =
    [a.house_number, a.road, a.neighbourhood, a.suburb].filter(Boolean).join(", ") ||
    (data.display_name ? data.display_name.split(",").slice(0, 2).join(", ") : "");
  return {
    address,
    city: a.city || a.town || a.village || a.county || a.suburb || "",
    state: matchIndianState(a.state) || a.state || "",
    pincode: a.postcode || "",
    country: a.country || "India",
  };
};

// One-shot helper: resolve the user's location and reverse-geocode it.
export const detectAddress = async (): Promise<GeoAddress> => {
  const { lat, lng } = await getCurrentPosition();
  return reverseGeocode(lat, lng);
};

// Forward geocode a place name (e.g. "Shimla") → coordinates. India-scoped.
export const geocodePlace = async (
  query: string
): Promise<{ lat: number; lng: number } | null> => {
  const res = await fetch(
    `https://nominatim.openstreetmap.org/search?format=json&countrycodes=in&limit=1&q=${encodeURIComponent(
      query
    )}`
  );
  const data = await res.json();
  if (Array.isArray(data) && data.length > 0) {
    return { lat: parseFloat(data[0].lat), lng: parseFloat(data[0].lon) };
  }
  return null;
};
