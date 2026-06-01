import { Box, Typography } from "@mui/material";
import {
  Security,
  EventAvailable,
  LocalOffer,
  SupportAgent,
} from "@mui/icons-material";

const features = [
  {
    icon: <Security sx={{ width: 22, height: 22 }} />,
    title: "Easy & Quick Bookings",
    description: "Search, book, and confirm stays in just a few clicks.",
  },
  {
    icon: <EventAvailable sx={{ width: 22, height: 22 }} />,
    title: "Local & Unique Stays",
    description: "Live with families, experience culture, not just hotels.",
  },
  {
    icon: <LocalOffer sx={{ width: 22, height: 22 }} />,
    title: "Safe & Verified",
    description: "Every property and host is checked with government rules.",
  },
  {
    icon: <SupportAgent sx={{ width: 22, height: 22 }} />,
    title: "24×7 Support",
    description: "Instant help via WhatsApp, app, or call anytime.",
  },
];

const WhyChooseUs = () => {
  return (
    <Box
      sx={{
        bgcolor: "#1B2447",
        color: "#F5F1EA",
        padding: { xs: "48px 20px", md: "64px 48px" },
      }}
    >
      <Box
        sx={{
          maxWidth: 1320,
          margin: "0 auto",
          display: "grid",
          gridTemplateColumns: { xs: "1fr", md: "1fr 2fr" },
          gap: { xs: "40px", md: "64px" },
          alignItems: "center",
        }}
      >
        {/* Left — heading */}
        <Box>
          <Typography
            sx={{
              fontFamily: "'Fraunces', serif",
              fontWeight: 400,
              fontSize: 36,
              lineHeight: 1.1,
              letterSpacing: "-0.02em",
              "& em": { fontStyle: "italic", color: "#C16345" },
            }}
            component="h3"
          >
            Why guests love{" "}
            <Box component="em">aajoo</Box>Homes
          </Typography>
          <Typography
            sx={{
              fontSize: 14,
              opacity: 0.7,
              mt: "12px",
              maxWidth: 300,
              lineHeight: 1.6,
            }}
          >
            We connect travelers with verified local hosts across India — safe,
            simple, and unforgettable.
          </Typography>
        </Box>

        {/* Right — 2×2 features grid */}
        <Box
          sx={{
            display: "grid",
            gridTemplateColumns: "repeat(2, 1fr)",
            gap: { xs: "24px", md: "32px 48px" },
          }}
        >
          {features.map((f) => (
            <Box key={f.title} sx={{ display: "flex", gap: "14px", alignItems: "flex-start" }}>
              {/* Icon box */}
              <Box
                sx={{
                  width: 44,
                  height: 44,
                  borderRadius: "12px",
                  bgcolor: "rgba(245,241,234,.08)",
                  display: "grid",
                  placeItems: "center",
                  flexShrink: 0,
                  color: "#F5F1EA",
                }}
              >
                {f.icon}
              </Box>
              <Box>
                <Typography
                  sx={{
                    fontFamily: "'Fraunces', serif",
                    fontWeight: 500,
                    fontSize: 18,
                    mb: "4px",
                    letterSpacing: "-0.01em",
                    color: "#F5F1EA",
                  }}
                >
                  {f.title}
                </Typography>
                <Typography sx={{ fontSize: 13, opacity: 0.65, lineHeight: 1.6, color: "#F5F1EA" }}>
                  {f.description}
                </Typography>
              </Box>
            </Box>
          ))}
        </Box>
      </Box>
    </Box>
  );
};

export default WhyChooseUs;
