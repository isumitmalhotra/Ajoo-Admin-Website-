import React, { useEffect, useState, useRef } from "react";
import {
  Box,
  Typography,
  IconButton,
  Card,
  Button,
  InputBase,
  Menu,
  MenuItem,
  Popover,
} from "@mui/material";
import { useNavigate } from "react-router-dom";
import { searchProperties, getCategories } from "../../services/customerApi";
import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";

import "leaflet/dist/leaflet.css";
import MyLocationIcon from "@mui/icons-material/MyLocation";
import FilterListIcon from "@mui/icons-material/FilterList";
import EventAvailableIcon from "@mui/icons-material/EventAvailable";
import DiamondIcon from "@mui/icons-material/Diamond";
import SearchIcon from "@mui/icons-material/Search";
import FilterDropdown from "./FilterDropdown";
import MarkerPulse from "./MarkerPulse";
import HotelMarkers from "./HotelMarkers";

import L from "leaflet";
import "leaflet/dist/leaflet.css";

interface CategoryOption {
  cat_id: number;
  cat_title: string;
}

const MapandFilter: React.FC = () => {
  const mapRef = useRef<any>(null);
  const navigate = useNavigate();

  const [location, setLocation] = useState<{ lat: number; lng: number } | null>(
    null
  );
  const [address, setAddress] = useState<string>("");
  const [showFilter, setShowFilter] = useState(false);

  // ── Search bar state (Where / Type / Guests) ──
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState("All categories");
  const [guests, setGuests] = useState(0);
  const [typeAnchor, setTypeAnchor] = useState<null | HTMLElement>(null);
  const [guestAnchor, setGuestAnchor] = useState<null | HTMLElement>(null);

  // Real property categories — GET /common/categories (Villa, Apartment, …).
  const [categoryOptions, setCategoryOptions] = useState<CategoryOption[]>([]);
  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const rows = await getCategories();
        if (!cancelled) setCategoryOptions(rows);
      } catch {
        if (!cancelled) setCategoryOptions([]);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  // Seed the Where field from the resolved address once (user can still edit).
  useEffect(() => {
    if (address) setQuery((prev) => prev || address);
  }, [address]);

  const handleSearch = () => {
    const params = new URLSearchParams();
    if (query.trim()) params.set("location", query.trim());
    if (category && category !== "All categories") params.set("category", category);
    if (guests > 0) params.set("guests", String(guests));
    navigate(`/property/list${params.toString() ? `?${params.toString()}` : ""}`);
  };

  const handleCategoryPick = (label: string) => {
    setCategory(label);
    setTypeAnchor(null);
    const params = new URLSearchParams();
    if (query.trim()) params.set("location", query.trim());
    if (label !== "All categories") params.set("category", label);
    if (guests > 0) params.set("guests", String(guests));
    navigate(`/property/list${params.toString() ? `?${params.toString()}` : ""}`);
  };
  // Geolocation errors now fall back silently to Goa centroid — see useEffect below.
  // `error` state retained as a constant for legacy placeholder UI that no longer fires in practice.
  const error = "";
  const [hotels, setHotels] = useState<
    {
      id: number;
      name: string;
      price: number;
      lat: number;
      lng: number;
      image: string;
    }[]
  >([]);

  // Clean teardrop pin with a home glyph (replaces the old emoji marker).
  const pinSvg = (fill: string) => `
    <svg width="34" height="44" viewBox="0 0 34 44" xmlns="http://www.w3.org/2000/svg" style="filter: drop-shadow(0 3px 4px rgba(27,36,71,.35));">
      <path d="M17 0C7.6 0 0 7.6 0 17c0 11.9 17 27 17 27s17-15.1 17-27C34 7.6 26.4 0 17 0z" fill="${fill}"/>
      <circle cx="17" cy="17" r="12" fill="#FFFAF0"/>
      <path d="M17 9.5l-7.2 6.1h2.1V23h3.7v-4.2h2.8V23h3.7v-7.4h2.1z" fill="${fill}"/>
    </svg>`;

  const hotelIcon = new L.DivIcon({
    className: "custom-hotel-marker",
    html: pinSvg("#1B2447"),
    iconSize: [34, 44],
    iconAnchor: [17, 44],
    popupAnchor: [0, -42],
  });

  useEffect(() => {
    if (!location) return;
    let cancelled = false;
    (async () => {
      try {
        const rows = await searchProperties({ latitude: location.lat, longitude: location.lng });
        if (cancelled) return;
        setHotels(
          rows.map((p) => ({
            id: p.property_id,
            name: p.property_name,
            price: Number(p.property_price) || 0,
            lat: Number(p.property_latitude) || location.lat,
            lng: Number(p.property_longitude) || location.lng,
            image:
              p.coverImage ||
              (p.images && p.images.length > 0 ? p.images[0] : "") ||
              "https://images.unsplash.com/photo-1566073771259-6a8506099945",
          }))
        );
      } catch {
        if (!cancelled) setHotels([]);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [location]);
  // const [showFilters, setShowFilters] = useState(false);

  // "You are here" pin in the terracotta accent (no external image / broken shadow).
  const markerIcon = new L.DivIcon({
    className: "custom-location-marker",
    html: pinSvg("#C16345"),
    iconSize: [34, 44],
    iconAnchor: [17, 44],
    popupAnchor: [0, -42],
  });

  // const isMobile = useMediaQuery("(max-width:600px)");

  // Fallback location: Goa (default browsing region for AajooHomes)
  const FALLBACK_LOCATION = { lat: 15.4909, lng: 73.8278 };

  useEffect(() => {
    if (!("geolocation" in navigator)) {
      setLocation(FALLBACK_LOCATION);
      setAddress("Goa, India");
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const { latitude, longitude } = pos.coords;
        const loc = { lat: latitude, lng: longitude };
        setLocation(loc);

        // Reverse geocode → keep it short like the app (City, State).
        fetch(
          `https://nominatim.openstreetmap.org/reverse?format=json&addressdetails=1&lat=${latitude}&lon=${longitude}`
        )
          .then((res) => res.json())
          .then((data) => {
            const a = data.address || {};
            const city =
              a.city || a.town || a.village || a.suburb || a.county || "";
            const short =
              [city, a.state].filter(Boolean).join(", ") ||
              (data.display_name ? data.display_name.split(",")[0] : "") ||
              "Current Location";
            setAddress(short);
          })
          .catch(() => setAddress("Current Location"));
      },
      () => {
        // Geolocation denied or unavailable — silently fall back to default region
        setLocation(FALLBACK_LOCATION);
        setAddress("Goa, India");
      }
    );
  }, []);

  return (
    <>
      {/* ── Floating search bar ── */}
      <Box sx={{ padding: { xs: "0 16px", md: "0 48px" }, mt: { xs: "16px", md: "-12px" }, position: "relative", zIndex: 10 }}>
        <Box
          sx={{
            maxWidth: 1100,
            margin: "0 auto",
            bgcolor: "#FFFAF0",
            // Pill on desktop; clean rounded card (NOT a giant oval) when the
            // fields stack on mobile.
            borderRadius: { xs: "20px", sm: "999px" },
            padding: "8px",
            display: "flex",
            flexDirection: { xs: "column", sm: "row" },
            alignItems: "stretch",
            boxShadow: "0 12px 40px rgba(27,36,71,.12)",
            border: "1px solid #D9CFB8",
            gap: { xs: "2px", sm: 0 },
          }}
        >
          {/* Where field — editable */}
          <Box
            sx={{
              flex: 1,
              padding: { xs: "8px 16px", sm: "10px 24px" },
              borderRight: { xs: "none", sm: "1px solid #D9CFB8" },
              borderBottom: { xs: "1px solid #EFE7D6", sm: "none" },
              transition: "0.2s",
              borderRadius: { xs: "12px", sm: "999px" },
              "&:hover": { bgcolor: "rgba(27,36,71,.03)" },
            }}
          >
            <Typography sx={{ fontSize: 11, fontWeight: 600, color: "#1B2447", letterSpacing: "0.04em", textTransform: "uppercase", mb: "2px" }}>
              Where
            </Typography>
            <InputBase
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => { if (e.key === "Enter") handleSearch(); }}
              placeholder="Search destinations…"
              sx={{ fontSize: 14, color: "#1B2447", width: "100%", "& input::placeholder": { color: "#6B7390", opacity: 1 } }}
            />
          </Box>

          {/* Category field — opens dropdown */}
          <Box
            onClick={(e) => setTypeAnchor(e.currentTarget)}
            sx={{
              flex: 1,
              padding: { xs: "8px 16px", sm: "14px 24px" },
              borderRight: { xs: "none", sm: "1px solid #D9CFB8" },
              borderBottom: { xs: "1px solid #EFE7D6", sm: "none" },
              cursor: "pointer",
              transition: "0.2s",
              borderRadius: { xs: "12px", sm: "999px" },
              "&:hover": { bgcolor: "rgba(27,36,71,.03)" },
            }}
          >
            <Typography sx={{ fontSize: 11, fontWeight: 600, color: "#1B2447", letterSpacing: "0.04em", textTransform: "uppercase", mb: "4px" }}>
              Type
            </Typography>
            <Typography sx={{ fontSize: 14, textTransform: "capitalize", color: category === "All categories" ? "#6B7390" : "#1B2447" }}>{category}</Typography>
          </Box>
          <Menu anchorEl={typeAnchor} open={Boolean(typeAnchor)} onClose={() => setTypeAnchor(null)}>
            {["All categories", ...categoryOptions.map((c) => c.cat_title)].map((label) => (
              <MenuItem key={label} selected={label === category} onClick={() => handleCategoryPick(label)} sx={{ fontSize: 14, textTransform: "capitalize" }}>
                {label}
              </MenuItem>
            ))}
          </Menu>

          {/* Guests field — opens counter */}
          <Box
            onClick={(e) => setGuestAnchor(e.currentTarget)}
            sx={{
              flex: 1,
              padding: { xs: "8px 16px", sm: "14px 24px" },
              cursor: "pointer",
              transition: "0.2s",
              borderRadius: { xs: "12px", sm: "999px" },
              "&:hover": { bgcolor: "rgba(27,36,71,.03)" },
            }}
          >
            <Typography sx={{ fontSize: 11, fontWeight: 600, color: "#1B2447", letterSpacing: "0.04em", textTransform: "uppercase", mb: "4px" }}>
              Guests
            </Typography>
            <Typography sx={{ fontSize: 14, color: guests > 0 ? "#1B2447" : "#6B7390" }}>
              {guests > 0 ? `${guests} guest${guests > 1 ? "s" : ""}` : "Add guests"}
            </Typography>
          </Box>
          <Popover
            anchorEl={guestAnchor}
            open={Boolean(guestAnchor)}
            onClose={() => setGuestAnchor(null)}
            anchorOrigin={{ vertical: "bottom", horizontal: "center" }}
            transformOrigin={{ vertical: "top", horizontal: "center" }}
          >
            <Box sx={{ display: "flex", alignItems: "center", gap: "16px", padding: "12px 16px" }}>
              <Typography sx={{ fontSize: 14, fontWeight: 600, color: "#1B2447" }}>Guests</Typography>
              <Box sx={{ display: "flex", alignItems: "center", gap: "12px" }}>
                <IconButton size="small" disabled={guests <= 0} onClick={() => setGuests((g) => Math.max(0, g - 1))} sx={{ border: "1px solid #D9CFB8" }}>−</IconButton>
                <Typography sx={{ minWidth: 20, textAlign: "center", fontSize: 15, color: "#1B2447" }}>{guests}</Typography>
                <IconButton size="small" onClick={() => setGuests((g) => g + 1)} sx={{ border: "1px solid #D9CFB8" }}>+</IconButton>
              </Box>
            </Box>
          </Popover>

          {/* Search CTA */}
          <Button
            onClick={handleSearch}
            sx={{
              bgcolor: "#C16345",
              color: "#fff",
              border: 0,
              padding: { xs: "12px 28px", sm: "0 28px" },
              borderRadius: { xs: "12px", sm: "999px" },
              fontWeight: 600,
              fontSize: 14,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: "8px",
              transition: "0.2s",
              textTransform: "none",
              flexShrink: 0,
              width: { xs: "100%", sm: "auto" },
              mt: { xs: "4px", sm: 0 },
              minWidth: { sm: 110 },
              "&:hover": { bgcolor: "#A8512F" },
            }}
            startIcon={<SearchIcon />}
          >
            Search
          </Button>
        </Box>
      </Box>

      {/* ── Category chips (real property categories) ── */}
      {categoryOptions.length > 0 && (
        <Box sx={{ padding: { xs: "20px 16px 8px", md: "40px 48px 8px" }, maxWidth: 1320, margin: "0 auto" }}>
          <Box
            sx={{
              display: "flex",
              gap: "8px",
              overflowX: "auto",
              pb: "8px",
              scrollbarWidth: "none",
              "&::-webkit-scrollbar": { display: "none" },
            }}
          >
            {categoryOptions.map((cat) => {
              const active = category === cat.cat_title;
              return (
                <Box
                  key={cat.cat_id}
                  onClick={() => handleCategoryPick(cat.cat_title)}
                  sx={{
                    flexShrink: 0,
                    display: "flex",
                    alignItems: "center",
                    gap: "6px",
                    padding: "9px 18px",
                    borderRadius: "999px",
                    cursor: "pointer",
                    border: "1px solid",
                    borderColor: active ? "#1B2447" : "#D9CFB8",
                    bgcolor: active ? "#1B2447" : "#FFFAF0",
                    transition: "0.2s",
                    "&:hover": { borderColor: "#1B2447" },
                  }}
                >
                  <Typography
                    sx={{
                      fontSize: 13,
                      fontWeight: 600,
                      color: active ? "#FFFAF0" : "#3D4670",
                      whiteSpace: "nowrap",
                      textTransform: "capitalize",
                    }}
                  >
                    {cat.cat_title}
                  </Typography>
                </Box>
              );
            })}
          </Box>
        </Box>
      )}

      {/* ── Feature buttons row ── */}
      <Box
        sx={{
          maxWidth: 1320,
          margin: "0 auto",
          padding: { xs: "0 16px 24px", md: "0 48px 24px" },
          display: "flex",
          gap: "12px",
        }}
      >
        <Button
          variant="contained"
          startIcon={<EventAvailableIcon />}
          sx={{
            flex: { xs: 1, sm: "0 0 auto" },
            bgcolor: "#1B2447",
            textTransform: "none",
            fontSize: { xs: "0.85rem", sm: "0.9rem" },
            fontWeight: 600,
            borderRadius: "12px",
            padding: "10px 22px",
            "&:hover": { bgcolor: "#2A356B" },
          }}
        >
          Prebooking
        </Button>

        <Button
          variant="contained"
          startIcon={<DiamondIcon />}
          sx={{
            flex: { xs: 1, sm: "0 0 auto" },
            background: "linear-gradient(135deg, #C16345 0%, #A8512F 100%)",
            color: "#fff",
            textTransform: "none",
            fontSize: { xs: "0.85rem", sm: "0.9rem" },
            fontWeight: 700,
            borderRadius: "12px",
            padding: "10px 22px",
            boxShadow: "0 6px 18px rgba(193,99,69,.30)",
            "&:hover": { background: "linear-gradient(135deg, #A8512F 0%, #8f4427 100%)" },
          }}
        >
          Luxury Homes
        </Button>
      </Box>

      {/* ── Map section ── */}
      <Box sx={{ width: "100%", padding: { xs: "0 20px 32px", md: "0 48px 48px" } }}>
        <Card
          sx={{
            width: "100%",
            height: { xs: 300, sm: 400, md: 500 },
            borderRadius: "18px",
            overflow: "hidden",
            boxShadow: "0 12px 40px rgba(27,36,71,.12)",
            border: "1px solid #D9CFB8",
            position: "relative",
          }}
        >
          {location ? (
            <>
              <MapContainer
                center={location}
                zoom={14}
                style={{ width: "100%", height: "100%" }}
                scrollWheelZoom
                ref={mapRef}
              >
                <TileLayer
                  attribution='&copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a>'
                  url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                />
                <Marker position={location} icon={markerIcon}>
                  <Popup>Your Current Location</Popup>
                </Marker>
                <MarkerPulse coordinates={[location.lat, location.lng]} />
                <HotelMarkers hotels={hotels} hotelIcon={hotelIcon} />
              </MapContainer>

              {/* Map chrome controls */}
              <Box
                sx={{
                  position: "absolute",
                  top: 10,
                  right: 10,
                  zIndex: 1000,
                  display: "flex",
                  gap: "8px",
                  alignItems: "center",
                }}
              >
                {/* Location display */}
                <Box
                  sx={{
                    display: "flex",
                    alignItems: "center",
                    bgcolor: "#FFFAF0",
                    borderRadius: "999px",
                    border: "1px solid #D9CFB8",
                    boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)",
                    px: 2,
                    py: 0.6,
                    minWidth: { xs: "120px", sm: "220px" },
                    maxWidth: "280px",
                  }}
                >
                  <InputBase
                    value={address}
                    disabled
                    sx={{ fontSize: { xs: "0.7rem", sm: "0.82rem" }, color: "#3D4670", width: "100%" }}
                  />
                </Box>

                {/* Filter button */}
                <Box sx={{ position: "relative" }}>
                  <IconButton
                    onClick={() => setShowFilter((prev) => !prev)}
                    sx={{
                      width: 38, height: 38,
                      bgcolor: "#FFFAF0",
                      border: "1px solid #D9CFB8",
                      boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)",
                      borderRadius: "10px",
                      "&:hover": { bgcolor: "#EFE7D6" },
                    }}
                  >
                    <FilterListIcon sx={{ color: "#1B2447", fontSize: 20 }} />
                  </IconButton>
                  {showFilter && (
                    <Box sx={{ position: "absolute", top: "110%", right: 0, zIndex: 1100, bgcolor: "#FFFAF0", borderRadius: "12px", boxShadow: "0 12px 40px rgba(27,36,71,.12)", border: "1px solid #D9CFB8", overflow: "hidden" }}>
                      <FilterDropdown onApply={() => setShowFilter(false)} />
                    </Box>
                  )}
                </Box>

                {/* Recenter button */}
                <IconButton
                  onClick={() => { if (mapRef.current) mapRef.current.setView(location, 14); }}
                  sx={{
                    width: 38, height: 38,
                    bgcolor: "#FFFAF0",
                    border: "1px solid #D9CFB8",
                    boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)",
                    borderRadius: "10px",
                    "&:hover": { bgcolor: "#EFE7D6" },
                  }}
                >
                  <MyLocationIcon sx={{ color: "#1B2447", fontSize: 20 }} />
                </IconButton>
              </Box>
            </>
          ) : (
            <Box sx={{ height: "100%", display: "flex", alignItems: "center", justifyContent: "center", flexDirection: "column", gap: "16px", bgcolor: "#EFE7D6", textAlign: "center", p: "32px" }}>
              <Box sx={{ width: 64, height: 64, borderRadius: "16px", bgcolor: "rgba(27,36,71,0.08)", display: "grid", placeItems: "center", fontSize: 28 }}>
                📍
              </Box>
              <Box>
                <Typography sx={{ fontFamily: "'Fraunces', serif", fontSize: 20, fontWeight: 400, letterSpacing: "-0.015em", color: "#1B2447", mb: "6px" }}>
                  {error ? "Location unavailable" : "Finding your location…"}
                </Typography>
                <Typography sx={{ fontSize: 14, color: "#6B7390", maxWidth: 300, lineHeight: 1.6 }}>
                  {error
                    ? "Enable location access in your browser to see nearby stays on the map."
                    : "Please allow location access to view properties near you."}
                </Typography>
              </Box>
              {error && (
                <Box
                  component="button"
                  onClick={() => window.location.reload()}
                  sx={{ display: "inline-flex", alignItems: "center", gap: "6px", padding: "8px 16px", borderRadius: "10px", border: "1px solid #D9CFB8", bgcolor: "#FFFAF0", fontSize: 13, fontWeight: 500, color: "#1B2447", cursor: "pointer", transition: "0.2s", "&:hover": { bgcolor: "#1B2447", color: "#FFFAF0", borderColor: "#1B2447" } }}
                >
                  Try again
                </Box>
              )}
            </Box>
          )}
        </Card>
      </Box>

    </>
  );
};

export default MapandFilter;
