import React from "react";
import { Link as RouterLink } from "react-router-dom";
import { Box, Typography, Link } from "@mui/material";

const Footer: React.FC = () => {
  const columns = [
    {
      heading: "Company",
      links: [
        { label: "About Us", to: "/about" },
        { label: "Contact Us", to: "/contact" },
        { label: "Become a Host", to: "/become-a-host" },
        { label: "Why Hosts List With Aajoo", to: "/Why-Hosts-List-With-Aajoo" },
        { label: "Help Center", to: "/help-center" },
      ],
    },
    {
      heading: "Legal",
      links: [
        { label: "Privacy Policy", to: "/privacy-policy" },
        { label: "Terms & Conditions", to: "/terms-condition" },
        { label: "State Regulation", to: "/state-regulation" },
        { label: "Cancellation Policy", to: "/Cancel" },
        { label: "Host Agreement", to: "/Host&Agreements" },
      ],
    },
    {
      heading: "Explore",
      links: [
        { label: "Find Your Stay", to: "/property/list" },
        { label: "FAQ", to: "/faqs" },
        { label: "User Dashboard", to: "/user-dashboard" },
      ],
    },
  ];

  return (
    <Box
      component="footer"
      sx={{
        bgcolor: "#0E1A2E",
        color: "#A8B4C8",
        padding: { xs: "48px 20px 24px", md: "64px 48px 32px" },
      }}
    >
      {/* Main grid */}
      <Box
        sx={{
          maxWidth: 1320,
          margin: "0 auto",
          display: "grid",
          gridTemplateColumns: { xs: "1fr", md: "1.4fr 1fr 1fr 1fr" },
          gap: { xs: "40px", md: "48px" },
        }}
      >
        {/* Brand column */}
        <Box>
          <Box sx={{ display: "flex", alignItems: "center", gap: "10px", mb: 2 }}>
            <Box
              sx={{
                width: 34,
                height: 34,
                borderRadius: "10px",
                background: "linear-gradient(135deg, #1B2447 0%, #2A356B 100%)",
                display: "grid",
                placeItems: "center",
                color: "#FFFAF0",
                fontFamily: "'Fraunces', serif",
                fontWeight: 700,
                fontSize: "18px",
                letterSpacing: "-0.04em",
              }}
            >
              A
            </Box>
            <Typography
              sx={{
                fontFamily: "'Fraunces', serif",
                fontWeight: 600,
                fontSize: "20px",
                letterSpacing: "-0.02em",
                color: "#F5F1EA",
              }}
            >
              aajoo
            </Typography>
          </Box>
          <Typography
            sx={{
              fontSize: 13,
              lineHeight: 1.6,
              maxWidth: 280,
              color: "#7A8099",
            }}
          >
            Discover handpicked stays across India. Book with confidence, host
            with ease — all on one trusted platform.
          </Typography>

          {/* Social icons */}
          <Box sx={{ display: "flex", gap: "12px", mt: 3 }}>
            {["f", "in", "tw"].map((icon) => (
              <Box
                key={icon}
                sx={{
                  width: 34,
                  height: 34,
                  borderRadius: "8px",
                  border: "1px solid rgba(255,255,255,0.1)",
                  display: "grid",
                  placeItems: "center",
                  cursor: "pointer",
                  fontSize: 12,
                  fontWeight: 600,
                  color: "#A8B4C8",
                  transition: "0.2s",
                  "&:hover": { borderColor: "#C16345", color: "#C16345" },
                }}
              >
                {icon}
              </Box>
            ))}
          </Box>
        </Box>

        {/* Link columns */}
        {columns.map((col) => (
          <Box key={col.heading}>
            <Typography
              sx={{
                fontFamily: "'Fraunces', serif",
                fontWeight: 500,
                fontSize: 15,
                color: "#F5F1EA",
                mb: "18px",
                letterSpacing: "-0.005em",
              }}
            >
              {col.heading}
            </Typography>
            <Box component="ul" sx={{ listStyle: "none", display: "flex", flexDirection: "column", gap: "10px" }}>
              {col.links.map((link) => (
                <Box component="li" key={link.to}>
                  <Link
                    component={RouterLink}
                    to={link.to}
                    sx={{
                      fontSize: 13,
                      color: "#A8B4C8",
                      textDecoration: "none",
                      transition: "color 0.2s",
                      "&:hover": { color: "#F5F1EA" },
                    }}
                  >
                    {link.label}
                  </Link>
                </Box>
              ))}
            </Box>
          </Box>
        ))}
      </Box>

      {/* Bottom row */}
      <Box
        sx={{
          maxWidth: 1320,
          margin: "48px auto 0",
          paddingTop: "24px",
          borderTop: "1px solid rgba(255,255,255,0.08)",
          display: "flex",
          justifyContent: "space-between",
          flexWrap: "wrap",
          gap: "8px",
          fontSize: 12,
          color: "#7A8099",
        }}
      >
        <Typography sx={{ fontSize: 12, color: "#7A8099" }}>
          © 2025 aajoo. All rights reserved.
        </Typography>
        <Box sx={{ display: "flex", gap: "24px" }}>
          <Link component={RouterLink} to="/privacy-policy" sx={{ fontSize: 12, color: "#7A8099", textDecoration: "none", "&:hover": { color: "#F5F1EA" } }}>
            Privacy
          </Link>
          <Link component={RouterLink} to="/terms-condition" sx={{ fontSize: 12, color: "#7A8099", textDecoration: "none", "&:hover": { color: "#F5F1EA" } }}>
            Terms
          </Link>
          <Link component={RouterLink} to="/sitemap" sx={{ fontSize: 12, color: "#7A8099", textDecoration: "none", "&:hover": { color: "#F5F1EA" } }}>
            Sitemap
          </Link>
        </Box>
      </Box>
    </Box>
  );
};

export default Footer;
