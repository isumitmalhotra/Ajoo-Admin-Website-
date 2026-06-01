import React, { useEffect, useState, useRef } from "react";
import {
  Box,
  Typography,
  IconButton,
  Card,
  Button,
  InputBase,
} from "@mui/material";
import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";

import "leaflet/dist/leaflet.css";
import MyLocationIcon from "@mui/icons-material/MyLocation";
import FilterListIcon from "@mui/icons-material/FilterList";
import FilterDropdown from "./FilterDropdown";
import MarkerPulse from "./MarkerPulse";
import HotelMarkers from "./HotelMarkers";

import L from "leaflet";
import "leaflet/dist/leaflet.css";

import prebooking from "../../assets/provided asset/booking.png";
import crown1 from "../../assets/provided asset/LUX.png";
import single from "../../assets/provided asset/single.png";
import couple3 from "../../assets/provided asset/couple.png";
import family from "../../assets/provided asset/family.png";
import sharing from "../../assets/provided asset/sharing.png";
import party from "../../assets/provided asset/party.png";

const categories = [
  { img: single, label: "Single" },
  { img: couple3, label: "Couple" },
  { img: family, label: "Family" },
  { img: sharing, label: "Sharing" },
  { img: party, label: "Party" },
];

const MapandFilter: React.FC = () => {
  const mapRef = useRef<any>(null);

  const [location, setLocation] = useState<{ lat: number; lng: number } | null>(
    null
  );
  const [address, setAddress] = useState<string>("");
  const [showFilter, setShowFilter] = useState(false);
  const [error, setError] = useState<string>("");
  console.log(address);
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

  // const markerColor = "#1B2447";
  const hotelIcon = new L.DivIcon({
    className: "custom-hotel-marker",
    html: `
    <div style="
      background-color: #1B2447;
      color: #FFFAF0;
      border-radius: 50%;
      width: 36px;
      height: 36px;
      display: flex;
      align-items: center;
      justify-content: center;
      border: 2px solid white;
      box-shadow: 0 0 6px rgba(0,0,0,0.3);
      font-size: 18px;
      cursor: pointer;
    ">
      🏠
    </div>
  `,
    // iconAnchor: [18, 36],
    // popupAnchor: [0, -36],
    iconSize: [38, 48],
    iconAnchor: [19, 48],
    popupAnchor: [0, -45],
  });

  useEffect(() => {
    if (location) {
      // ✅ Dummy nearby hotels data (same shape as future API)
      const dummyHotels = [
        {
          id: 1,
          name: "Himalayan View Resort",
          price: 3200,
          lat: location.lat + 0.01,
          lng: location.lng + 0.01,
          image: "https://images.unsplash.com/photo-1566073771259-6a8506099945",
        },
        {
          id: 2,
          name: "Mountain Breeze Inn",
          price: 2800,
          lat: location.lat - 0.008,
          lng: location.lng + 0.009,
          image: "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb",
        },
        {
          id: 3,
          name: "Snow Valley Retreat",
          price: 4000,
          lat: location.lat + 0.007,
          lng: location.lng - 0.006,
          image: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c",
        },
        {
          id: 4,
          name: "River Edge Lodge",
          price: 2600,
          lat: location.lat - 0.009,
          lng: location.lng - 0.005,
          image: "https://images.unsplash.com/photo-1578683010236-d716f9a3f461",
        },
      ];

      // ✅ Simulate API call delay
      setTimeout(() => setHotels(dummyHotels), 1000);
    }
  }, [location]);
  // const [showFilters, setShowFilters] = useState(false);

  const markerIcon = new L.Icon({
    iconUrl:
      "https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-red.png",
    shadowUrl:
      "[https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png](https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png)",
    iconSize: [32, 48],
    iconAnchor: [16, 48],
  });

  // const isMobile = useMediaQuery("(max-width:600px)");

  useEffect(() => {
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setLocation({
            lat: position.coords.latitude,
            lng: position.coords.longitude,
          });
        },
        () => setError("Location access denied. Showing fallback location.")
      );
    } else {
      setError("Geolocation not supported by your browser.");
    }
  }, []);
  useEffect(() => {
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const { latitude, longitude } = pos.coords;
        const loc = { lat: latitude, lng: longitude };
        setLocation(loc);

        // ✅ Reverse Geocode to get address
        fetch(
          `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}`
        )
          .then((res) => res.json())
          .then((data) => {
            setAddress(data.display_name || "Current Location");
          })
          .catch(() => setAddress("Unable to fetch address"));
      },
      (err) => {
        setError("Unable to access location");
        console.error(err);
      }
    );
  }, []);

  return (
    <>
      {/* ── Floating search bar ── */}
      <Box sx={{ padding: { xs: "0 20px", md: "0 48px" }, mt: { xs: "-8px", md: "-12px" }, position: "relative", zIndex: 10 }}>
        <Box
          sx={{
            maxWidth: 1100,
            margin: "0 auto",
            bgcolor: "#FFFAF0",
            borderRadius: "999px",
            padding: "8px",
            display: "flex",
            alignItems: "stretch",
            boxShadow: "0 12px 40px rgba(27,36,71,.12)",
            border: "1px solid #D9CFB8",
            flexWrap: { xs: "wrap", sm: "nowrap" },
            gap: { xs: "4px", sm: 0 },
          }}
        >
          {/* Where field */}
          <Box
            sx={{
              flex: 1,
              padding: "14px 24px",
              borderRight: { xs: "none", sm: "1px solid #D9CFB8" },
              cursor: "pointer",
              transition: "0.2s",
              borderRadius: "999px",
              "&:hover": { bgcolor: "rgba(27,36,71,.03)" },
            }}
          >
            <Typography sx={{ fontSize: 11, fontWeight: 600, color: "#1B2447", letterSpacing: "0.04em", textTransform: "uppercase", mb: "4px" }}>
              Where
            </Typography>
            <Typography sx={{ fontSize: 14, color: "#6B7390" }}>
              {address || "Search destinations…"}
            </Typography>
          </Box>

          {/* Category field */}
          <Box
            sx={{
              flex: 1,
              padding: "14px 24px",
              borderRight: { xs: "none", sm: "1px solid #D9CFB8" },
              cursor: "pointer",
              transition: "0.2s",
              borderRadius: "999px",
              "&:hover": { bgcolor: "rgba(27,36,71,.03)" },
            }}
          >
            <Typography sx={{ fontSize: 11, fontWeight: 600, color: "#1B2447", letterSpacing: "0.04em", textTransform: "uppercase", mb: "4px" }}>
              Type
            </Typography>
            <Typography sx={{ fontSize: 14, color: "#6B7390" }}>All categories</Typography>
          </Box>

          {/* Guests field */}
          <Box
            sx={{
              flex: 1,
              padding: "14px 24px",
              cursor: "pointer",
              transition: "0.2s",
              borderRadius: "999px",
              "&:hover": { bgcolor: "rgba(27,36,71,.03)" },
            }}
          >
            <Typography sx={{ fontSize: 11, fontWeight: 600, color: "#1B2447", letterSpacing: "0.04em", textTransform: "uppercase", mb: "4px" }}>
              Guests
            </Typography>
            <Typography sx={{ fontSize: 14, color: "#6B7390" }}>Add guests</Typography>
          </Box>

          {/* Search CTA */}
          <Button
            sx={{
              bgcolor: "#C16345",
              color: "#fff",
              border: 0,
              padding: "0 28px",
              borderRadius: "999px",
              fontWeight: 600,
              fontSize: 14,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              gap: "8px",
              transition: "0.2s",
              textTransform: "none",
              flexShrink: 0,
              minWidth: 100,
              "&:hover": { bgcolor: "#A8512F" },
            }}
          >
            🔍 Search
          </Button>
        </Box>
      </Box>

      {/* ── Category chips ── */}
      <Box sx={{ padding: { xs: "32px 20px 8px", md: "48px 48px 8px" }, maxWidth: 1320, margin: "0 auto" }}>
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
          {categories.map((cat, index) => (
            <Box
              key={index}
              sx={{
                flexShrink: 0,
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                gap: "8px",
                padding: "14px 18px",
                borderRadius: "14px",
                cursor: "pointer",
                border: "1px solid transparent",
                minWidth: "96px",
                transition: "0.2s",
                "&:hover": { bgcolor: "#FFFAF0", borderColor: "#D9CFB8" },
              }}
            >
              <Box
                component="img"
                src={cat.img}
                alt={cat.label}
                sx={{ width: 32, height: 32, objectFit: "contain" }}
              />
              <Typography
                sx={{
                  fontSize: 12,
                  fontWeight: 500,
                  color: "#3D4670",
                  whiteSpace: "nowrap",
                }}
              >
                {cat.label}
              </Typography>
            </Box>
          ))}
        </Box>
      </Box>

      {/* ── Action buttons row ── */}
      <Box
        sx={{
          maxWidth: 1320,
          margin: "0 auto",
          padding: { xs: "0 20px 24px", md: "0 48px 24px" },
          display: "flex",
          gap: "12px",
        }}
      >
        <Button
          variant="contained"
          startIcon={<Box component="img" src={prebooking} alt="Prebooking" sx={{ width: 22, height: 22 }} />}
          sx={{
            bgcolor: "#1B2447",
            textTransform: "none",
            fontSize: { xs: "0.8rem", sm: "0.9rem" },
            fontWeight: 600,
            borderRadius: "10px",
            padding: "10px 20px",
            "&:hover": { bgcolor: "#2A356B" },
          }}
        >
          <Box sx={{ display: { xs: "none", sm: "inline" } }}>Prebooking</Box>
          <Box sx={{ display: { xs: "inline", sm: "none" } }}>Resv</Box>
        </Button>

        <Button
          variant="outlined"
          startIcon={<Box component="img" src={crown1} alt="Luxury" sx={{ width: 22, height: 22 }} />}
          sx={{
            borderColor: "#1B2447",
            color: "#1B2447",
            textTransform: "none",
            fontSize: { xs: "0.8rem", sm: "0.9rem" },
            fontWeight: 600,
            borderRadius: "10px",
            padding: "10px 20px",
            "&:hover": { bgcolor: "rgba(27,36,71,0.05)", borderColor: "#1B2447" },
          }}
        >
          <Box sx={{ display: { xs: "none", sm: "inline" } }}>Luxury Homes</Box>
          <Box sx={{ display: { xs: "inline", sm: "none" } }}>Lux</Box>
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
            <Box sx={{ height: "100%", display: "flex", alignItems: "center", justifyContent: "center", flexDirection: "column", color: "#1B2447", backgroundColor: "#FFFAF0", textAlign: "center", p: 2 }}>
              <Typography variant="h6" sx={{ mb: 1 }}>
                {error ? "Location Error" : "Fetching your location..."}
              </Typography>
              <Typography variant="body2" sx={{ color: "#6B7390" }}>
                {error || "Please allow location access to view the map."}
              </Typography>
            </Box>
          )}
        </Card>
      </Box>

    </>
  );
};

export default MapandFilter;
