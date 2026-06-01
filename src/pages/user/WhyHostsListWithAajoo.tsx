import React from "react";
import {
  Box,
  Typography,
  Container,
  // Breadcrumbs,
  // Link,
  useTheme,
  useMediaQuery,
} from "@mui/material";
// import NavigateNextIcon from "@mui/icons-material/NavigateNext";
import termsTopImage from "../../assets/hotel.jpg";
import termsBottomImage from "../../assets/hotel.jpg";
import { AppBreadcrumbs } from "../../components";

const WhyHostsListWithAajoo: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const benefits = [
    {
      title: "🏠 Zero Listing Fees",
      desc: "List your property for free and reach travelers instantly. Aajoo doesn’t charge any setup or hidden fees — you earn more from every booking.",
    },
    {
      title: "👥 Connect with Verified Guests",
      desc: "Our verified guest system ensures you host genuine travelers — giving you peace of mind and a safer hosting experience.",
    },
    {
      title: "💬 Direct Communication",
      desc: "Chat or call your guests directly through secure in-app calling — make your hosting experience simple, personal, and transparent.",
    },
    {
      title: "💰 You Control Your Pricing",
      desc: "Set your own rates, offer seasonal discounts, or negotiate directly with guests using Aajoo’s smart “Negotiate Price” feature.",
    },
    {
      title: "🔒 Secure Payments",
      desc: "Receive hassle-free payments through Aajoo’s secure gateway — protected, fast, and fully transparent.",
    },
    {
      title: "⭐ Build Reputation & Reviews",
      desc: "Grow your profile with guest feedback and ratings. Higher ratings = more visibility and more bookings.",
    },
    {
      title: "🏕️ Suitable for All Property Types",
      desc: "Whether it’s a cozy room, hillside cottage, or family villa — Aajoo welcomes all types of stays including couple, family, and group-friendly homes.",
    },
    {
      title: "📈 Smart Tools for Growth",
      desc: "Access your booking calendar, track earnings, manage cancellations, and boost your property ranking — all from one simple dashboard.",
    },
    {
      title: "📍 Local Host Support",
      desc: "Aajoo’s team works closely with local hosts across Shimla, Chandigarh, Mohali, and Panchkula, helping you stay compliant with local tourism regulations.",
    },
    {
      title: "💡 Marketing That Works for You",
      desc: "Aajoo promotes your listing through digital marketing, partnerships, and regional tourism networks — helping you get discovered by more travelers.",
    },
  ];

  return (
    <Box sx={{ bgcolor: "#fff", color: "#333", py: 6 }}>
      <Container maxWidth="md">
        {/* Breadcrumb Section */}

        <Box
      sx={{
        width: "100vw",
        position: "relative",
        left: "50%",
        right: "50%",
        marginLeft: "-50vw",
        marginRight: "-50vw",
        height: isMobile ? "220px" : "380px",
        backgroundImage: `url(${termsTopImage})`,
        backgroundSize: "cover",
        backgroundPosition: "center",
        overflow: "hidden",
        mb: 3,
      }}
    >
      {/* Overlay */}
      <Box
        sx={{
          position: "absolute",
          inset: 0,
          bgcolor: "rgba(0, 0, 0, 0.45)",
          backdropFilter: "blur(2px)",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          alignItems: "center",
          color: "#fff",
          textAlign: "center",
          px: 2,
        }}
      >
        <Typography
          variant={isMobile ? "h5" : "h3"}
          fontWeight={700}
          sx={{ letterSpacing: "0.5px", fontFamily: "'Poppins', sans-serif" }}
        >
          AAJOO PRIVACY POLICY
        </Typography>

        <Typography
          variant="subtitle1"
          sx={{
            mt: 1,
            fontWeight: 300,
            opacity: 0.9,
            fontFamily: "'Inter', sans-serif",
          }}
        >
          Your privacy, our responsibility.
        </Typography>
      </Box>

      <Box
        sx={{
          position: "absolute",
          bottom: -1,
          left: 0,
          width: "100%",
          height: "60px",
          backgroundColor: "#fff",
          borderTopLeftRadius: "50px",
          borderTopRightRadius: "50px",
        }}
      />
    </Box>

    {/* Breadcrumb Below Header */}
    <Box sx={{ mb: 2, mt: 1 }}>
      <AppBreadcrumbs
        items={[
          { label: "Home", link: "/" },
          { label: "Privacy Policy" },
        ]}
      />
    </Box>

        {/* Header */}
        <Typography
          variant={isMobile ? "h5" : "h4"}
          sx={{
            fontWeight: 700,
            textAlign: "center",
            color: "#1B2447",
            mb: 2,
          }}
        >
          🌟 Why Hosts List with Aajoo
        </Typography>
        <Typography
          sx={{
            textAlign: "center",
            color: "#555",
            mb: 5,
            fontSize: isMobile ? "0.95rem" : "1.05rem",
          }}
        >
          Aajoo is more than a booking app — it’s a platform that connects local
          hosts with real travelers looking for authentic stays and experiences.
          Whether you’re a homeowner, homestay owner, or property manager, Aajoo
          helps you grow your business with trust, transparency, and technology.
        </Typography>

        {/* Benefits Section */}
        <Box
          sx={{
            display: "flex",
            flexWrap: "wrap",
            gap: 3,
            justifyContent: "center",
          }}
        >
          {benefits.map((item, index) => (
            <Box
              key={index}
              sx={{
                width: isMobile ? "100%" : "45%",
                bgcolor: "#fde7ec",
                borderRadius: 3,
                p: 3,
                boxShadow: "inset 0 0 15px rgba(193,67,101,0.1)",
                transition: "all 0.3s ease",
                "&:hover": {
                  transform: "translateY(-5px)",
                  boxShadow: "0 6px 20px rgba(193,67,101,0.25)",
                },
              }}
            >
              <Typography
                sx={{
                  fontWeight: 700,
                  color: "#1B2447",
                  mb: 1,
                  fontSize: "1rem",
                }}
              >
                {item.title}
              </Typography>
              <Typography
                sx={{
                  fontSize: "0.95rem",
                  color: "#444",
                  lineHeight: 1.6,
                }}
              >
                {item.desc}
              </Typography>
            </Box>
          ))}
        </Box>

        {/* Message Section */}
        <Box
          sx={{
            mt: 6,
            textAlign: "center",
            bgcolor: "#FFF4F7",
            p: 4,
            borderRadius: 4,
            border: "1px solid rgba(193,67,101,0.2)",
            boxShadow: "0 4px 12px rgba(193,67,101,0.15)",
          }}
        >
          <Typography
            sx={{
              fontWeight: 600,
              fontSize: isMobile ? "1rem" : "1.1rem",
              color: "#1B2447",
              mb: 2,
            }}
          >
            💬 Message to Hosts
          </Typography>
          <Typography
            sx={{
              color: "#555",
              fontSize: isMobile ? "0.9rem" : "1rem",
              lineHeight: 1.7,
            }}
          >
            “Aajoo believes every home has a story. By joining Aajoo, you’re not
            just listing a space — you’re opening your doors to the world and
            turning hospitality into opportunity.”
          </Typography>
        </Box>

        {/* Bottom Image */}
        <Box
          component="img"
          src={termsBottomImage}
          alt="Aajoo Homestay"
          sx={{
            width: "100%",
            height: isMobile ? 180 : 300,
            objectFit: "cover",
            borderRadius: 3,
            mt: 6,
            boxShadow: "0 4px 20px rgba(0,0,0,0.1)",
          }}
        />
      </Container>
    </Box>
  );
};

export default WhyHostsListWithAajoo;
