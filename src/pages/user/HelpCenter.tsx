import {
  Box,
  Container,
  Typography,
  useMediaQuery,
  useTheme,
  Button,
} from "@mui/material";
import RocketLaunchIcon from "@mui/icons-material/RocketLaunch";
import HomeWorkIcon from "@mui/icons-material/HomeWork";
import SupportAgentIcon from "@mui/icons-material/SupportAgent";
import WhatsAppIcon from "@mui/icons-material/WhatsApp";
import HelpOutlineIcon from "@mui/icons-material/HelpOutline";
import { AppBreadcrumbs } from "../../components";
import Reveal from "../../components/frontend/Reveal";
import termsTopImage from "../../assets/hotel.jpg";

const INDIGO = "#1B2447";
const TERRA = "#C16345";
const CREAM = "#FFFAF0";
const BG = "#EFE7D6";
const BORDER = "#D9CFB8";
const MUTED = "#6B7390";

const SUPPORT_WHATSAPP = "919999999999"; // TODO: real support number

const sections = [
  {
    title: "Getting Started",
    icon: <RocketLaunchIcon />,
    items: [
      { q: "What is aajoo?", a: "aajoo connects travellers with local hosts offering authentic homestays and unique experiences." },
      { q: "How to sign up", a: "Register using your email or Google account as a guest or host within minutes." },
      { q: "How to list your property", a: "Follow our step-by-step listing guide with tips on descriptions, pricing and images." },
      { q: "How to book a stay", a: "Search, filter and book verified properties with instant confirmation." },
    ],
  },
  {
    title: "Hosting with aajoo",
    icon: <HomeWorkIcon />,
    items: [
      { q: "Crafting the perfect listing", a: "Highlight unique features, upload good photos and write engaging descriptions." },
      { q: "Host responsibilities", a: "Maintain cleanliness, communicate clearly and ensure guest comfort." },
      { q: "Preparing your home", a: "Provide essentials, check safety devices and add personal touches." },
      { q: "Getting paid", a: "aajoo supports multiple payout methods with secure transactions." },
    ],
  },
  {
    title: "Guest Support",
    icon: <SupportAgentIcon />,
    items: [
      { q: "Guest responsibilities", a: "Respect property rules, treat hosts courteously and follow guidelines." },
      { q: "Safety during your stay", a: "Ensure safe check-ins, keep emergency contacts handy and report issues." },
      { q: "Refunds & cancellations", a: "Check your booking's cancellation policy for refund eligibility." },
      { q: "Contact your host", a: "Use aajoo's secure messaging to reach your host directly." },
    ],
  },
];

const HelpCenter = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const openSupport = () =>
    window.open(`https://wa.me/${SUPPORT_WHATSAPP}?text=${encodeURIComponent("Hi aajoo support, I need help.")}`, "_blank");

  return (
    <Box sx={{ bgcolor: BG }}>
      {/* Hero */}
      <Box
        sx={{
          position: "relative",
          height: isMobile ? 220 : 340,
          backgroundImage: `url(${termsTopImage})`,
          backgroundSize: "cover",
          backgroundPosition: "center",
        }}
      >
        <Box
          sx={{
            position: "absolute",
            inset: 0,
            background: "linear-gradient(180deg, rgba(27,36,71,.35) 0%, rgba(27,36,71,.78) 100%)",
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
            alignItems: "center",
            color: CREAM,
            textAlign: "center",
            px: 2,
          }}
        >
          <Typography sx={{ fontFamily: "'Fraunces', serif", fontWeight: 400, letterSpacing: "-0.02em", fontSize: { xs: "2rem", md: "3rem" } }}>
            Help <Box component="span" sx={{ fontStyle: "italic", color: "#E9B79E" }}>Center</Box>
          </Typography>
          <Typography sx={{ mt: 1, opacity: 0.95, fontSize: { xs: "0.9rem", md: "1.05rem" } }}>
            Answers, support and guidance for your aajoo experience.
          </Typography>
        </Box>
      </Box>

      <Box sx={{ px: { xs: 2, md: 8 }, pt: 2 }}>
        <AppBreadcrumbs items={[{ label: "Home", link: "/" }, { label: "Help Center" }]} />
      </Box>

      <Container maxWidth="lg" sx={{ py: { xs: 4, md: 7 } }}>
        {sections.map((section, index) => (
          <Reveal key={index} delay={index * 0.05}>
            <Box
              sx={{
                p: { xs: 2.5, md: 4 },
                mb: 4,
                borderRadius: "18px",
                bgcolor: CREAM,
                border: `1px solid ${BORDER}`,
                boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)",
              }}
            >
              <Box sx={{ display: "flex", alignItems: "center", gap: 1.5, mb: 3 }}>
                <Box sx={{ width: 46, height: 46, borderRadius: "14px", bgcolor: "rgba(193,99,69,.12)", color: TERRA, display: "grid", placeItems: "center", "& svg": { fontSize: 24 } }}>
                  {section.icon}
                </Box>
                <Typography sx={{ fontFamily: "'Fraunces', serif", fontWeight: 400, fontSize: { xs: 22, md: 26 }, color: INDIGO, letterSpacing: "-0.01em" }}>
                  {section.title}
                </Typography>
              </Box>

              <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", md: "1fr 1fr" }, gap: { xs: 2.5, md: 3 } }}>
                {section.items.map((item, idx) => (
                  <Box key={idx} sx={{ display: "flex", gap: 1.25, alignItems: "flex-start" }}>
                    <HelpOutlineIcon sx={{ color: INDIGO, fontSize: 20, mt: 0.3, flexShrink: 0 }} />
                    <Box>
                      <Typography sx={{ fontWeight: 700, color: INDIGO, mb: 0.5 }}>{item.q}</Typography>
                      <Typography sx={{ color: MUTED, lineHeight: 1.65, fontSize: "0.95rem" }}>{item.a}</Typography>
                    </Box>
                  </Box>
                ))}
              </Box>
            </Box>
          </Reveal>
        ))}

        <Reveal>
          <Box sx={{ textAlign: "center", mt: 2, p: 3, borderRadius: "18px", bgcolor: "rgba(27,36,71,.04)", border: `1px dashed ${BORDER}` }}>
            <Typography sx={{ color: INDIGO, fontWeight: 600 }}>
              Still need help? Email{" "}
              <Box component="a" href="mailto:contactus@aajoohomes.com" sx={{ color: TERRA, fontWeight: 700, textDecoration: "none" }}>
                contactus@aajoohomes.com
              </Box>
            </Typography>
          </Box>
        </Reveal>
      </Container>

      {/* Floating support button → WhatsApp */}
      <Button
        variant="contained"
        startIcon={<WhatsAppIcon />}
        onClick={openSupport}
        sx={{
          position: "fixed",
          bottom: 20,
          right: 20,
          zIndex: 2000,
          backgroundColor: "#25D366",
          borderRadius: "50px",
          px: 3,
          py: 1.3,
          fontWeight: 700,
          "&:hover": { backgroundColor: "#1ebe5d" },
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
