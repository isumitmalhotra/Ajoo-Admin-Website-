import React, { useState } from "react";
import {
  Box,
  Typography,
  Chip,
  useTheme,
  useMediaQuery,
} from "@mui/material";
import {
  Pool,
  LocalParking,
  Wifi,
  Star,
  LocationOn,
  AcUnit,
  Kitchen,
  Tv,
  Fireplace,
} from "@mui/icons-material";
import { motion } from "framer-motion";

const themeColor = "#1B2447";

// Dummy amenities
const amenitiesList = [
  { icon: Pool, label: "Pool" },
  { icon: LocalParking, label: "Parking" },
  { icon: Wifi, label: "WiFi" },
  { icon: AcUnit, label: "AC" },
  { icon: Kitchen, label: "Kitchen" },
  { icon: Tv, label: "TV" },
  { icon: Fireplace, label: "Fireplace" },
  { icon: Star, label: "5★ Rated" },
  { icon: Pool, label: "Infinity Pool" },
  { icon: Wifi, label: "High-Speed WiFi" },
];

// Split for desktop 2 columns
const splitAmenities = (items: any[]) => {
  const half = Math.ceil(items.length / 2);
  return [items.slice(0, half), items.slice(half)];
};

// Icon animation
const iconAnim = {
  initial: { opacity: 0, y: 10 },
  animate: { opacity: 1, y: 0, transition: { duration: 0.25 } },
  hover: { scale: 1.15 },
};

const PropertyBookingBox: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));
  const [price] = useState<number>(1500);

  const [col1, col2] = splitAmenities(amenitiesList);

  return (
    <Box
      sx={{
        backgroundColor: "#FFFAF0",
        borderRadius: "18px",
        border: "1px solid #D9CFB8",
        padding: isMobile ? "1.3rem" : "2rem",
        width: "100%",
        margin: "2rem auto",
        boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)",
      }}
    >
      {/* MAIN LAYOUT */}
      <Box
        sx={{
          display: "flex",
          flexDirection: isMobile ? "column" : "row",
          justifyContent: "space-between",
          alignItems: isMobile ? "center" : "flex-start",
          gap: isMobile ? 4 : 6,
        }}
      >
        {/* ---------- LEFT SECTION ---------- */}
        <Box sx={{ flex: 1, textAlign: isMobile ? "center" : "left" }}>
          <Typography
            variant="h5"
            sx={{
              color: "#222",
              fontWeight: 700,
              fontSize: isMobile ? "1.35rem" : "1.6rem",
              mb: 1.5,
            }}
          >
            Luxury Stay at Aajoo Villa
          </Typography>

          <Typography
            variant="h4"
            sx={{
              color: themeColor,
              fontWeight: 700,
              fontSize: isMobile ? "1.6rem" : "2rem",
              display: "flex",
              justifyContent: isMobile ? "center" : "flex-start",
              alignItems: "center",
              gap: 0.5,
              mb: 1,
            }}
          >
            ₹{price.toLocaleString()}
          </Typography>

          <Typography
            sx={{
              display: "flex",
              justifyContent: isMobile ? "center" : "flex-start",
              alignItems: "center",
              gap: 0.5,
              color: "#555",
              mt: 0.5,
              fontSize: isMobile ? "0.9rem" : "1rem",
            }}
          >
            <LocationOn sx={{ color: themeColor, fontSize: 20 }} /> 123 Ani Street,
            Chennai, India
          </Typography>

          <Box
            sx={{
              mt: 2,
              display: "flex",
              flexWrap: "wrap",
              justifyContent: isMobile ? "center" : "flex-start",
              gap: 1,
            }}
          >
            {["Apartment", "Luxury", "Family"].map((label) => (
              <Chip
                key={label}
                label={label}
                sx={{
                  color: "#fff",
                  bgcolor: themeColor,
                  fontSize: isMobile ? "0.75rem" : "0.85rem",
                }}
              />
            ))}
          </Box>

          {/* Rating */}
          <Box
            sx={{
              mt: 2,
              display: "flex",
              justifyContent: isMobile ? "center" : "flex-start",
              gap: 0.3,
            }}
          >
            {[...Array(5)].map((_, i) => (
              <Star key={i} sx={{ color: "#FFD700", fontSize: 22 }} />
            ))}
          </Box>
        </Box>

        {/* ---------- RIGHT SECTION (Amenities) ---------- */}
        <Box
          sx={{
            display: "flex",
            flexDirection: isMobile ? "column" : "row",
            gap: isMobile ? 2 : 6,
            minWidth: isMobile ? "100%" : "45%",
          }}
        >
          {/* MOBILE VIEW — Multi Column Grid */}
          {isMobile && (
            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: "repeat(auto-fill, minmax(130px, 1fr))",
                gap: 2,
                width: "100%",
              }}
            >
              {amenitiesList.map((item, i) => {
                const Icon = item.icon;
                return (
                  <motion.div
                    key={i}
                    variants={iconAnim}
                    initial="initial"
                    animate="animate"
                    whileHover="hover"
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: 10,
                      cursor: "pointer",
                      padding: "4px 0",
                    }}
                  >
                    <Icon sx={{ color: themeColor, fontSize: 22 }} />
                    <Typography sx={{ color: "#444", fontSize: "0.9rem" }}>
                      {item.label}
                    </Typography>
                  </motion.div>
                );
              })}
            </Box>
          )}

          {/* DESKTOP — 2 Columns */}
          {!isMobile && (
            <>
              {/* Column 1 */}
              <Box
                sx={{
                  display: "flex",
                  flexDirection: "column",
                  gap: 2,
                }}
              >
                {col1.map((item, i) => {
                  const Icon = item.icon;
                  return (
                    <motion.div
                      key={i}
                      variants={iconAnim}
                      initial="initial"
                      animate="animate"
                      whileHover="hover"
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: 10,
                        cursor: "pointer",
                      }}
                    >
                      <Icon sx={{ color: themeColor, fontSize: 22 }} />
                      <Typography sx={{ color: "#444" }}>{item.label}</Typography>
                    </motion.div>
                  );
                })}
              </Box>

              {/* Column 2 */}
              <Box
                sx={{
                  display: "flex",
                  flexDirection: "column",
                  gap: 2,
                }}
              >
                {col2.map((item, i) => {
                  const Icon = item.icon;
                  return (
                    <motion.div
                      key={i}
                      variants={iconAnim}
                      initial="initial"
                      animate="animate"
                      whileHover="hover"
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: 10,
                        cursor: "pointer",
                      }}
                    >
                      <Icon sx={{ color: themeColor, fontSize: 22 }} />
                      <Typography sx={{ color: "#444" }}>{item.label}</Typography>
                    </motion.div>
                  );
                })}
              </Box>
            </>
          )}
        </Box>
      </Box>
    </Box>
  );
};

export default PropertyBookingBox;
