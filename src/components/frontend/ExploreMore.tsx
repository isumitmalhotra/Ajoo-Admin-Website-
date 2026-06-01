import React from "react";
import { Box, Typography } from "@mui/material";

const destinations = [
  {
    id: 1,
    img: "https://images.unsplash.com/photo-1564501049412-61c2a3083791?auto=format&fit=crop&w=800&q=80",
    title: "Shimla",
    count: "240+ stays",
    large: true,
  },
  {
    id: 2,
    img: "https://images.unsplash.com/photo-1544735716-ea9ef35b8885?auto=format&fit=crop&w=600&q=80",
    title: "Manali",
    count: "180+ stays",
    large: false,
  },
  {
    id: 3,
    img: "https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?auto=format&fit=crop&w=600&q=80",
    title: "Goa",
    count: "320+ stays",
    large: false,
  },
  {
    id: 4,
    img: "https://images.unsplash.com/photo-1477587458883-47145ed94245?auto=format&fit=crop&w=600&q=80",
    title: "Jaipur",
    count: "150+ stays",
    large: false,
  },
  {
    id: 5,
    img: "https://images.unsplash.com/photo-1587474260584-136574528ed5?auto=format&fit=crop&w=600&q=80",
    title: "Delhi",
    count: "410+ stays",
    large: false,
  },
];

const ExploreMore: React.FC = () => {
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
              fontSize: 36,
              letterSpacing: "-0.025em",
              color: "#1B2447",
              "& em": { fontStyle: "italic", color: "#C16345", fontWeight: 500 },
            }}
            component="h2"
          >
            Explore <Box component="em">destinations</Box>
          </Typography>
          <Typography sx={{ fontSize: 14, color: "#6B7390", mt: "6px" }}>
            Hand-picked cities for your next getaway
          </Typography>
        </Box>
        <Typography
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

      {/* Destinations grid */}
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
            sx={{
              position: "relative",
              borderRadius: "18px",
              overflow: "hidden",
              cursor: "pointer",
              bgcolor: "#D9CFB8",
              gridRow: dest.large ? { md: "1 / 3" } : undefined,
              minHeight: { xs: "160px", md: dest.large ? "auto" : "auto" },
              "&:hover img": { transform: "scale(1.04)" },
            }}
          >
            <Box
              component="img"
              src={dest.img}
              alt={dest.title}
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
                background: "linear-gradient(180deg, transparent 40%, rgba(26,43,34,.85) 100%)",
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
              <Typography sx={{ fontSize: 12, opacity: 0.85, mt: "4px", letterSpacing: "0.04em", textTransform: "uppercase" }}>
                {dest.count}
              </Typography>
            </Box>
          </Box>
        ))}
      </Box>
    </Box>
  );
};

export default ExploreMore;
