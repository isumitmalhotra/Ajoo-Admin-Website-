import React from "react";
import { Box, Typography, Button } from "@mui/material";
import { useNavigate } from "react-router-dom";
const trust = [
  { n: "12K+", l: "Properties" },
  { n: "4.9★", l: "Avg Rating" },
  { n: "98%", l: "Satisfaction" },
];

const HeroSection: React.FC = () => {
  const navigate = useNavigate();

  return (
    <Box
      sx={{
        padding: { xs: "40px 20px 24px", md: "56px 48px 24px" },
        background: "linear-gradient(180deg, #EFE7D6 0%, #EFE7D6 100%)",
      }}
    >
      <Box
        sx={{
          maxWidth: 1320,
          margin: "0 auto",
          display: "grid",
          gridTemplateColumns: { xs: "1fr", md: "1.05fr 1fr" },
          gap: { xs: "32px", md: "48px" },
          alignItems: "center",
        }}
      >
        {/* Left — text */}
        <Box>
          {/* Tag pill */}
          <Box
            sx={{
              display: "inline-flex",
              alignItems: "center",
              gap: "8px",
              background: "rgba(27,36,71,0.06)",
              color: "#1B2447",
              padding: "6px 12px",
              borderRadius: "999px",
              fontSize: 12,
              fontWeight: 500,
              letterSpacing: "0.04em",
              textTransform: "uppercase",
              mb: "20px",
            }}
          >
            <Box
              sx={{
                width: 6,
                height: 6,
                borderRadius: "50%",
                bgcolor: "#C16345",
                boxShadow: "0 0 0 0 rgba(193,99,69,.6)",
                animation: "pulse 2s infinite",
                "@keyframes pulse": {
                  "0%,100%": { boxShadow: "0 0 0 0 rgba(193,99,69,.6)" },
                  "50%": { boxShadow: "0 0 0 8px rgba(193,99,69,0)" },
                },
              }}
            />
            India's Trusted Homestay Platform
          </Box>

          {/* Hero title */}
          <Typography
            component="h1"
            sx={{
              fontFamily: "'Fraunces', serif",
              fontWeight: 400,
              fontSize: { xs: "clamp(36px,8vw,56px)", md: "clamp(44px,5vw,68px)" },
              lineHeight: 1.02,
              letterSpacing: "-0.035em",
              color: "#1B2447",
              mb: "20px",
            }}
          >
            Find your perfect{" "}
            <Box component="em" sx={{ fontStyle: "italic", color: "#C16345", fontWeight: 500 }}>
              home
            </Box>{" "}
            <Box
              component="span"
              sx={{
                position: "relative",
                display: "inline-block",
                "&::after": {
                  content: '""',
                  position: "absolute",
                  left: 0,
                  right: 0,
                  bottom: "0.08em",
                  height: "0.12em",
                  background: "#C16345",
                  opacity: 0.35,
                  borderRadius: "2px",
                },
              }}
            >
              away from home
            </Box>
          </Typography>

          {/* Subtitle */}
          <Typography
            sx={{
              fontSize: 17,
              lineHeight: 1.55,
              color: "#3D4670",
              maxWidth: 520,
              mb: "32px",
            }}
          >
            Discover handpicked homestays across India. Book with confidence,
            experience culture, and create memories that last a lifetime.
          </Typography>

          {/* CTAs */}
          <Box sx={{ display: "flex", gap: "12px", flexWrap: "wrap" }}>
            <Button
              onClick={() => navigate("/property/list")}
              variant="contained"
              sx={{
                bgcolor: "#1B2447",
                color: "#FFFAF0",
                padding: "14px 28px",
                borderRadius: "10px",
                fontSize: 15,
                fontWeight: 600,
                textTransform: "none",
                letterSpacing: "0.01em",
                "&:hover": { bgcolor: "#2A356B" },
              }}
            >
              Explore Stays
            </Button>
            <Button
              onClick={() => navigate("/become-a-host")}
              variant="outlined"
              sx={{
                borderColor: "#D9CFB8",
                color: "#1B2447",
                padding: "14px 28px",
                borderRadius: "10px",
                fontSize: 15,
                fontWeight: 600,
                textTransform: "none",
                "&:hover": { bgcolor: "rgba(27,36,71,0.05)", borderColor: "#1B2447" },
              }}
            >
              Become a Host
            </Button>
          </Box>

          {/* Trust strip */}
          <Box
            sx={{
              display: "flex",
              gap: "28px",
              mt: "36px",
              pt: "24px",
              borderTop: "1px solid #D9CFB8",
            }}
          >
            {trust.map((t) => (
              <Box key={t.l} sx={{ display: "flex", flexDirection: "column", gap: "2px" }}>
                <Typography
                  sx={{
                    fontFamily: "'Fraunces', serif",
                    fontSize: 24,
                    fontWeight: 600,
                    color: "#1B2447",
                    letterSpacing: "-0.02em",
                    lineHeight: 1,
                  }}
                >
                  {t.n}
                </Typography>
                <Typography
                  sx={{
                    fontSize: 11,
                    color: "#6B7390",
                    letterSpacing: "0.06em",
                    textTransform: "uppercase",
                    fontWeight: 600,
                  }}
                >
                  {t.l}
                </Typography>
              </Box>
            ))}
          </Box>
        </Box>

        {/* Right — image collage */}
        <Box
          sx={{
            position: "relative",
            height: { xs: 280, md: 520 },
            display: { xs: "none", md: "block" },
          }}
        >
          {/* Main image card */}
          <Box
            sx={{
              position: "absolute",
              top: 0,
              left: 0,
              width: "62%",
              height: "68%",
              borderRadius: "16px",
              overflow: "hidden",
              boxShadow: "0 12px 40px rgba(27,36,71,.12)",
              transform: "rotate(-1.5deg)",
              bgcolor: "#D9CFB8",
            }}
          >
            <Box
              component="img"
              src="https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80"
              alt="Featured property"
              sx={{ width: "100%", height: "100%", objectFit: "cover" }}
            />
          </Box>

          {/* Second image card */}
          <Box
            sx={{
              position: "absolute",
              bottom: 0,
              right: 0,
              width: "55%",
              height: "55%",
              borderRadius: "16px",
              overflow: "hidden",
              boxShadow: "0 12px 40px rgba(27,36,71,.12)",
              transform: "rotate(2deg)",
              bgcolor: "#D9CFB8",
            }}
          >
            <Box
              component="img"
              src="https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80"
              alt="Property interior"
              sx={{ width: "100%", height: "100%", objectFit: "cover" }}
            />
          </Box>

          {/* Badge 1 — rating */}
          <Box
            sx={{
              position: "absolute",
              top: "42%",
              right: "-10px",
              bgcolor: "#FFFAF0",
              borderRadius: "14px",
              padding: "14px 16px",
              boxShadow: "0 12px 40px rgba(27,36,71,.12)",
              display: "flex",
              alignItems: "center",
              gap: "12px",
              zIndex: 2,
            }}
          >
            <Box
              sx={{
                width: 36,
                height: 36,
                borderRadius: "10px",
                bgcolor: "rgba(27,36,71,0.08)",
                display: "grid",
                placeItems: "center",
                color: "#1B2447",
                fontSize: 18,
              }}
            >
              ⭐
            </Box>
            <Box>
              <Typography sx={{ fontSize: 13, fontWeight: 600, color: "#1B2447", lineHeight: 1.1 }}>
                4.9 / 5 Rating
              </Typography>
              <Typography sx={{ fontSize: 11, color: "#6B7390", mt: "2px" }}>
                2,400+ reviews
              </Typography>
            </Box>
          </Box>

          {/* Badge 2 — bookings */}
          <Box
            sx={{
              position: "absolute",
              bottom: "-12px",
              left: "8%",
              bgcolor: "#FFFAF0",
              borderRadius: "14px",
              padding: "14px 16px",
              boxShadow: "0 12px 40px rgba(27,36,71,.12)",
              display: "flex",
              alignItems: "center",
              gap: "12px",
              zIndex: 2,
            }}
          >
            <Box
              sx={{
                width: 36,
                height: 36,
                borderRadius: "10px",
                bgcolor: "rgba(27,36,71,0.08)",
                display: "grid",
                placeItems: "center",
                color: "#1B2447",
                fontSize: 18,
              }}
            >
              🏠
            </Box>
            <Box>
              <Typography sx={{ fontSize: 13, fontWeight: 600, color: "#1B2447", lineHeight: 1.1 }}>
                12,000+ Properties
              </Typography>
              <Typography sx={{ fontSize: 11, color: "#6B7390", mt: "2px" }}>
                Across India
              </Typography>
            </Box>
          </Box>
        </Box>
      </Box>
    </Box>
  );
};

export default HeroSection;
