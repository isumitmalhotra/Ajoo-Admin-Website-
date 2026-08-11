import React from "react";
import { Box, Typography } from "@mui/material";
import { useNavigate } from "react-router-dom";
import LocalCafeIcon from "@mui/icons-material/LocalCafe";
import RestaurantIcon from "@mui/icons-material/Restaurant";
import LocalMallIcon from "@mui/icons-material/LocalMall";
import HikingIcon from "@mui/icons-material/Hiking";
import CameraAltIcon from "@mui/icons-material/CameraAlt";
import NightlifeIcon from "@mui/icons-material/Nightlife";

import shimlaImg from "../../assets/provided asset/shimlahimachal.jpg";
import chandigarhImg from "../../assets/provided asset/chandigarh.jpg";
import punjabImg from "../../assets/provided asset/punjab.jpg";

// North-India focused destinations (Himachal + Tricity belt).
const destinations = [
  { id: 1, img: shimlaImg, title: "Shimla", region: "Himachal Pradesh", large: true },
  { id: 2, img: chandigarhImg, title: "Chandigarh", region: "The Tricity", large: false },
  { id: 3, img: punjabImg, title: "Mohali", region: "Punjab", large: false },
  { id: 4, img: chandigarhImg, title: "Panchkula", region: "Haryana", large: false },
  { id: 5, img: punjabImg, title: "Zirakpur", region: "Punjab", large: false },
];

// "Places to visit" quick-explore chips.
const placesToVisit = [
  { label: "Cafés", icon: <LocalCafeIcon /> },
  { label: "Restaurants", icon: <RestaurantIcon /> },
  { label: "Malls", icon: <LocalMallIcon /> },
  { label: "Treks", icon: <HikingIcon /> },
  { label: "Sightseeing", icon: <CameraAltIcon /> },
  { label: "Nightlife", icon: <NightlifeIcon /> },
];

const ExploreMore: React.FC = () => {
  const navigate = useNavigate();

  const goToCity = (city: string) =>
    navigate(`/property/list?location=${encodeURIComponent(city)}`);

  return (
    <Box sx={{ padding: { xs: "48px 20px", md: "64px 48px" }, bgcolor: "#EFE7D6" }}>
      {/* Section header */}
      <Box
        sx={{
          maxWidth: 1320,
          margin: "0 auto",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "flex-end",
          mb: "24px",
        }}
      >
        <Box>
          <Typography
            sx={{
              fontFamily: "'Fraunces', serif",
              fontWeight: 400,
              fontSize: { xs: 28, md: 36 },
              letterSpacing: "-0.025em",
              color: "#1B2447",
              "& em": { fontStyle: "italic", color: "#C16345", fontWeight: 500 },
            }}
            component="h2"
          >
            Explore <Box component="em">North India</Box>
          </Typography>
          <Typography sx={{ fontSize: 14, color: "#6B7390", mt: "6px" }}>
            Hand-picked stays across Himachal & the Tricity
          </Typography>
        </Box>
        <Typography
          onClick={() => navigate("/property/list")}
          sx={{
            fontSize: 14,
            fontWeight: 600,
            color: "#1B2447",
            cursor: "pointer",
            display: { xs: "none", sm: "flex" },
            alignItems: "center",
            gap: "6px",
            "&:hover": { color: "#C16345" },
          }}
        >
          View all →
        </Typography>
      </Box>

      {/* Destinations grid — each card filters listings by city */}
      <Box
        sx={{
          maxWidth: 1320,
          margin: "0 auto",
          display: "grid",
          gridTemplateColumns: { xs: "1fr 1fr", md: "1.4fr 1fr 1fr" },
          gridTemplateRows: { xs: "auto", md: "1fr 1fr" },
          gap: "16px",
          height: { xs: "auto", md: "520px" },
        }}
      >
        {destinations.map((dest) => (
          <Box
            key={dest.id}
            onClick={() => goToCity(dest.title)}
            sx={{
              position: "relative",
              borderRadius: "18px",
              overflow: "hidden",
              cursor: "pointer",
              bgcolor: "#D9CFB8",
              gridRow: dest.large ? { md: "1 / 3" } : undefined,
              minHeight: { xs: "160px", md: "auto" },
              "&:hover img": { transform: "scale(1.04)" },
            }}
          >
            <Box
              component="img"
              src={dest.img}
              alt={dest.title}
              loading="lazy"
              onError={(e) => {
                // Never show a broken-image icon — fall back to a known asset.
                (e.currentTarget as HTMLImageElement).src = punjabImg;
              }}
              sx={{
                width: "100%",
                height: "100%",
                objectFit: "cover",
                transition: "transform 0.6s ease",
                display: "block",
              }}
            />
            {/* Dark overlay */}
            <Box
              sx={{
                position: "absolute",
                inset: 0,
                background:
                  "linear-gradient(180deg, transparent 40%, rgba(26,43,34,.85) 100%)",
                padding: "24px",
                display: "flex",
                flexDirection: "column",
                justifyContent: "flex-end",
                color: "#F5F1EA",
              }}
            >
              <Typography
                sx={{
                  fontFamily: "'Fraunces', serif",
                  fontWeight: 500,
                  fontSize: dest.large ? { xs: 22, md: 32 } : 22,
                  letterSpacing: "-0.01em",
                }}
              >
                {dest.title}
              </Typography>
              <Typography
                sx={{
                  fontSize: 12,
                  opacity: 0.85,
                  mt: "4px",
                  letterSpacing: "0.04em",
                  textTransform: "uppercase",
                }}
              >
                {dest.region}
              </Typography>
            </Box>
          </Box>
        ))}
      </Box>

      {/* Places to visit nearby */}
      <Box sx={{ maxWidth: 1320, margin: "0 auto", mt: { xs: "40px", md: "56px" } }}>
        <Typography
          sx={{
            fontFamily: "'Fraunces', serif",
            fontWeight: 400,
            fontSize: { xs: 22, md: 28 },
            letterSpacing: "-0.02em",
            color: "#1B2447",
            mb: "4px",
          }}
          component="h3"
        >
          Places to visit
        </Typography>
        <Typography sx={{ fontSize: 14, color: "#6B7390", mb: "20px" }}>
          Cafés, food, shopping and treks around your stay
        </Typography>

        <Box
          sx={{
            display: "flex",
            gap: { xs: "12px", md: "16px" },
            overflowX: "auto",
            pb: "8px",
            scrollbarWidth: "none",
            "&::-webkit-scrollbar": { display: "none" },
          }}
        >
          {placesToVisit.map((p) => (
            <Box
              key={p.label}
              sx={{
                flexShrink: 0,
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
                gap: "10px",
                minWidth: { xs: "96px", md: "120px" },
                padding: { xs: "16px 12px", md: "22px 16px" },
                borderRadius: "16px",
                bgcolor: "#FFFAF0",
                border: "1px solid #D9CFB8",
                cursor: "pointer",
                transition: "0.2s",
                "&:hover": {
                  transform: "translateY(-3px)",
                  boxShadow: "0 10px 28px rgba(27,36,71,.12)",
                  borderColor: "#1B2447",
                },
              }}
            >
              <Box
                sx={{
                  width: 48,
                  height: 48,
                  borderRadius: "14px",
                  display: "grid",
                  placeItems: "center",
                  bgcolor: "rgba(27,36,71,.06)",
                  color: "#1B2447",
                  "& svg": { fontSize: 26 },
                }}
              >
                {p.icon}
              </Box>
              <Typography
                sx={{
                  fontSize: 13,
                  fontWeight: 600,
                  color: "#3D4670",
                  whiteSpace: "nowrap",
                }}
              >
                {p.label}
              </Typography>
            </Box>
          ))}
        </Box>
      </Box>
    </Box>
  );
};

export default ExploreMore;
