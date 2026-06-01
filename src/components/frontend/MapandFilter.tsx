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
      {/* ✅ Responsive Top Section */}
      <Box
        sx={{
          display: "flex",
          flexDirection: "column",
          width: "100%",
          minHeight: { xs: "auto", sm: 280, md: 300 },
          alignItems: "center",
          justifyContent: "space-evenly",
          p: { xs: 1.5, sm: 2 },

          borderRadius: "14px",
          boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)",
          backgroundColor: "#FFFAF0",
          border: "1px solid #D9CFB8",
          mb: { xs: 2, sm: 3 },
        }}
      >
        {/* ✅ Category Section (Aligned Left + Reduced Gap) */}
        <Box
          sx={{
            width: "100%",
            display: "flex",
            flexDirection: "row",
            flexWrap: "nowrap",
            alignItems: "center",
            justifyContent: "center",
            overflowX: "auto",
            gap: { xs: 1, sm: 1.5, md: 2 },

            py: 1,
            scrollbarWidth: "none",
            "&::-webkit-scrollbar": { display: "none" },

            px: { xs: 0.5, sm: 1 },
          }}
        >
          {categories.map((cat, index) => (
            <Box
              key={index}
              sx={{
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
                cursor: "pointer",

                flex: "0 0 auto",
                minWidth: { xs: 60, sm: 75 },
              }}
            >
              <Box
                component="img"
                src={cat.img}
                alt={cat.label}
                sx={{
                  width: { xs: 28, sm: 30 },  
                  height: { xs: 28, sm: 30 },
                  objectFit: "contain",
                }}
              />

              <Typography
                variant="body2"
                sx={{
                  color: "#1B2447",
                  fontSize: { xs: "0.65rem", sm: "0.75rem" },
                  fontWeight: 500,
                  mt: 0.4, // 🔥 reduced top gap
                  whiteSpace: "nowrap",
                  textAlign: "center",
                }}
              >
                {cat.label}
              </Typography>
            </Box>
          ))}
        </Box>

        {/* ✅ Action Buttons */}
        <Box
          sx={{
            width: "100%",
            maxWidth: 700,
            mx: "auto",
            display: "flex",
            flexDirection: "row",
            alignItems: "center",
            justifyContent: "space-between",
            gap: { xs: 1.5, sm: 3 },
          }}
        >
          {/* 🔹 Prebooking Button → "Resv" on Mobile */}
          <Button
            variant="contained"
            startIcon={
              <Box
                component="img"
                src={prebooking}
                alt="Prebooking"
                sx={{
                  width: { xs: 22, sm: 28, md: 35 },
                  height: { xs: 22, sm: 28, md: 35 },
                }}
              />
            }
            sx={{
              flex: "1",
              height: { xs: 42, sm: 50 },
              backgroundColor: "#1B2447",
              textTransform: "none",
              fontSize: { xs: "0.8rem", sm: "0.9rem" },
              fontFamily: "'Inter', system-ui, sans-serif",
              fontWeight: 600,
              borderRadius: "10px",
              "&:hover": { backgroundColor: "#2A356B" },
            }}
          >
            {/* ⬇️ Replace title on mobile */}
            <Box sx={{ display: { xs: "inline", sm: "none" } }}>Resv</Box>
            <Box sx={{ display: { xs: "none", sm: "inline" } }}>Prebooking</Box>
          </Button>

          {/* 🔹 Luxury Homes Button → "Lux" on Mobile */}
          <Button
            variant="outlined"
            startIcon={
              <Box
                component="img"
                src={crown1}
                alt="Luxury"
                sx={{
                  width: { xs: 22, sm: 28, md: 35 },
                  height: { xs: 22, sm: 28, md: 35 },
                }}
              />
            }
            sx={{
              flex: "1",
              height: { xs: 42, sm: 50 },
              borderColor: "#1B2447",
              color: "#1B2447",
              textTransform: "none",
              fontSize: { xs: "0.8rem", sm: "0.9rem" },
              fontFamily: "'Inter', system-ui, sans-serif",
              fontWeight: 600,
              borderRadius: "10px",
              "&:hover": {
                backgroundColor: "rgba(27,36,71,0.05)",
                borderColor: "#1B2447",
              },
            }}
          >
            {/* ⬇️ Replace title on mobile */}
            <Box sx={{ display: { xs: "inline", sm: "none" } }}>Lux</Box>
            <Box sx={{ display: { xs: "none", sm: "inline" } }}>
              Luxury Homes
            </Box>
          </Button>
        </Box>
      </Box>

      {/* ✅ Map Section */}
      <Box sx={{ width: "100%", p: { xs: 1, sm: 2 }, position: "relative" }}>
        <Card
          sx={{
            width: "100%",
            height: { xs: 300, sm: 400, md: 500 },
            borderRadius: "20px",
            overflow: "hidden",
            boxShadow: 4,
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

                {/* ✅ User’s location marker */}
                <Marker position={location} icon={markerIcon}>
                  <Popup>Your Current Location</Popup>
                </Marker>

                <MarkerPulse coordinates={[location.lat, location.lng]} />
                <HotelMarkers hotels={hotels} hotelIcon={hotelIcon} />
              </MapContainer>

              {/* ✅ Top-right icons container */}
              <Box
                sx={{
                  position: "absolute",
                  top: 10,
                  right: 10,
                  zIndex: 1000,
                  display: "flex",
                  gap: 1.2,
                  alignItems: "center",
                }}
              >
                {/* 🔍 Fake Search Bar */}
                <Box
                  sx={{
                    display: "flex",
                    alignItems: "center",
                    bgcolor: "#fff",
                    borderRadius: "30px",
                    boxShadow: 2,
                    px: 2,
                    py: 0.5,
                    minWidth: { xs: "140px", sm: "250px" },
                    maxWidth: "300px",
                    overflow: "hidden",
                    whiteSpace: "nowrap",
                  }}
                >
                  <InputBase
                    value={address}
                    disabled
                    sx={{
                      fontSize: { xs: "0.7rem", sm: "0.85rem" },
                      color: "#555",
                      width: "100%",
                    }}
                  />
                </Box>

                {/* 🔹 Filter Icon */}
                <Box sx={{ position: "relative" }}>
                  <IconButton
                    onClick={() => setShowFilter((prev) => !prev)}
                    sx={{
                      bgcolor: "#fff",
                      boxShadow: 2,
                      "&:hover": { bgcolor: "#f0f0f0" },
                    }}
                  >
                    <FilterListIcon sx={{ color: "#1B2447" }} />
                  </IconButton>

                  {/* 🔹 Dropdown Component */}
                  {showFilter && (
                    <Box
                      sx={{
                        position: "absolute",
                        top: "110%",
                        right: 0,
                        zIndex: 1100,
                        bgcolor: "#fff",
                        borderRadius: "12px",
                        boxShadow: 4,
                        overflow: "hidden",
                      }}
                    >
                      <FilterDropdown onApply={() => setShowFilter(false)} />
                    </Box>
                  )}
                </Box>

                {/* 🔹 Recenter Icon */}
                <IconButton
                  onClick={() => {
                    if (mapRef.current) mapRef.current.setView(location, 14);
                  }}
                  sx={{
                    bgcolor: "#fff",
                    boxShadow: 2,
                    "&:hover": { bgcolor: "#f0f0f0" },
                  }}
                >
                  <MyLocationIcon sx={{ color: "#1B2447" }} />
                </IconButton>
              </Box>
            </>
          ) : (
            <Box
              sx={{
                height: "100%",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                flexDirection: "column",
                color: "#1B2447",
                backgroundColor: "#FFFAF0",
                textAlign: "center",
                p: 2,
              }}
            >
              <Typography variant="h6" sx={{ mb: 1 }}>
                {error ? "Location Error" : "Fetching your location..."}
              </Typography>
              <Typography variant="body2" sx={{ color: "text.secondary" }}>
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
