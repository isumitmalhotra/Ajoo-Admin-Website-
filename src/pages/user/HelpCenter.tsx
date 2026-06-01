import {
  Box,
  Container,
  Typography,
  Card,
  // CardContent,
  useMediaQuery,
  useTheme,
  Button,
} from "@mui/material";
// import helpcenter2 from "../../assets/UI/helpcenter2.svg";
import { AppBreadcrumbs } from "../../components";
import termsTopImage from "../../assets/hotel.jpg";
import SupportAgentIcon from "@mui/icons-material/SupportAgent";

const sections = [
  {
    title: "Getting Started",
    items: [
      {
        q: "What is Aajoo?",
        a: "Aajoo connects travelers with local hosts offering authentic homestays and unique experiences.",
      },
      {
        q: "How to Sign Up",
        a: "Register using your email or Google account as a guest or host within minutes.",
      },
      {
        q: "How to List Your Property",
        a: "Follow our step-by-step listing guide with tips on descriptions, pricing, and images.",
      },
      {
        q: "How to Book a Stay",
        a: "Search, filter, and book safe properties with instant confirmation.",
      },
    ],
  },
  {
    title: "Hosting with Aajoo",
    items: [
      {
        q: "Crafting the Perfect Listing",
        a: "Highlight unique features, upload good photos, and write engaging descriptions.",
      },
      {
        q: "Host Responsibilities",
        a: "Maintain cleanliness, communicate clearly, and ensure guest comfort.",
      },
      {
        q: "Preparing Your Home",
        a: "Provide essentials, check safety devices, and add personal touches.",
      },
      {
        q: "Getting Paid",
        a: "Aajoo supports multiple payout methods with secure transactions.",
      },
    ],
  },
  {
    title: "Guest Support",
    items: [
      {
        q: "Guest Responsibilities",
        a: "Respect property rules, treat hosts courteously, and follow guidelines.",
      },
      {
        q: "Safety During Stay",
        a: "Ensure safe check-ins, prepare emergency contacts, and report issues.",
      },
      {
        q: "Refunds & Cancellations",
        a: "Check your booking’s cancellation policy for refund eligibility.",
      },
      {
        q: "Contact Your Host",
        a: "Use Aajoo’s secure messaging system to reach your host.",
      },
    ],
  },
];

const HelpCenter = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  return (
    <Box sx={{ bgcolor: "#fff" }}>
      <Box
        sx={{
          position: "relative",
          height: isMobile ? "220px" : "360px",
          backgroundImage: `url(${termsTopImage})`,
          backgroundSize: "cover",
          backgroundPosition: "center",
          borderBottomLeftRadius: "50px",
          borderBottomRightRadius: "50px",
          overflow: "hidden",
        }}
      >
      

        {/* Dark Overlay */}
        <Box
          sx={{
            position: "absolute",
            inset: 0,
            bgcolor: "rgba(0, 0, 0, 0.45)",
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
            alignItems: "center",
            color: "#fff",
            textAlign: "center",
            px: 2,
          }}
        >
          <Typography variant={isMobile ? "h5" : "h3"} fontWeight={700}>
            HELP CENTER
          </Typography>
          <Typography variant="subtitle1" sx={{ mt: 1, fontWeight: 300 }}>
            Find answers, support, and guidance for your Aajoo experience.
          </Typography>
        </Box>
        
      </Box>
        {/* Breadcrumb */}
        <Box sx={{ ml: 10,mb: 1, mt: 1 }}>
          <AppBreadcrumbs
            items={[{ label: "Home", link: "/" }, { label: "Privacy Policy" }]}
          />
        </Box>
    
      <Container maxWidth="lg" sx={{ py: { xs: 6, md: 10 } }}>
        {sections.map((section, index) => (
          <Card
            key={index}
            elevation={4}
            sx={{
              p: { xs: 3, md: 4 },
              mb: 5,
              borderRadius: 4,
              background: "#fff5f8",
              boxShadow: "0 8px 30px rgba(193,67,101,0.15)",
            }}
          >
            <Typography
              variant="h5"
              sx={{
                fontFamily: "Poppins",
                fontWeight: 700,
                color: "#1B2447",
                mb: 3,
                textTransform: "uppercase",
                letterSpacing: 0.5,
              }}
            >
              {section.title}
            </Typography>

            {section.items.map((item, idx) => (
              <Box key={idx} sx={{ mb: 4 }}>
                <Typography
                  variant="h6"
                  fontWeight={700}
                  sx={{
                    fontFamily: "Poppins",
                    color: "#1B2447",
                    mb: 1,
                  }}
                >
                  {item.q}
                </Typography>
                <Typography
                  variant="body1"
                  sx={{
                    color: "#5a5a5a",
                    lineHeight: 1.7,
                    maxWidth: "90%",
                  }}
                >
                  {item.a}
                </Typography>
              </Box>
            ))}
          </Card>
        ))}
      </Container>

      <Box
        sx={{
          py: 4,
          textAlign: "center",
          backgroundColor: "#ffe5ec",
          color: "#1B2447",
          fontWeight: 500,
          fontSize: "0.95rem",
        }}
      >
        Need more help? Email us at{" "}
        <Box component="span" sx={{ fontWeight: 700 }}>
          contactus@aajoohomes.com
        </Box>
      </Box>

      {/* ===========================
          Floating Support Button
      ============================ */}
      <Button
        variant="contained"
        startIcon={<SupportAgentIcon />}
        sx={{
          position: "fixed",
          bottom: 20,
          right: 20,
          zIndex: 2000,
          backgroundColor: "#1B2447",
          borderRadius: "50px",
          px: 3,
          py: 1.3,
          fontWeight: 600,
          "&:hover": { backgroundColor: "#a83250" },
          textTransform: "none",
          fontSize: isMobile ? "0.85rem" : "1rem",
        }}
      >
        Need Support?
      </Button>
    </Box>
  );
};

export default HelpCenter;
