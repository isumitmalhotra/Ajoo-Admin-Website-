import React from "react";
import { Box, Typography, Container, Button, useTheme, useMediaQuery } from "@mui/material";
import { Link } from "react-router-dom";
import SavingsIcon from "@mui/icons-material/Savings";
import VerifiedUserIcon from "@mui/icons-material/VerifiedUser";
import ChatIcon from "@mui/icons-material/Chat";
import TuneIcon from "@mui/icons-material/Tune";
import LockIcon from "@mui/icons-material/Lock";
import StarIcon from "@mui/icons-material/Star";
import HomeWorkIcon from "@mui/icons-material/HomeWork";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import SupportAgentIcon from "@mui/icons-material/SupportAgent";
import CampaignIcon from "@mui/icons-material/Campaign";
import { AppBreadcrumbs } from "../../components";
import Reveal from "../../components/frontend/Reveal";
import termsTopImage from "../../assets/hotel.jpg";

const INDIGO = "#1B2447";
const TERRA = "#C16345";
const CREAM = "#FFFAF0";
const BG = "#EFE7D6";
const BORDER = "#D9CFB8";
const MUTED = "#6B7390";

const benefits = [
  { icon: <SavingsIcon />, title: "Zero listing fees", desc: "List your property for free and reach travellers instantly — no setup or hidden fees, so you earn more from every booking." },
  { icon: <VerifiedUserIcon />, title: "Verified guests", desc: "Our verified guest system ensures you host genuine travellers — peace of mind and a safer hosting experience." },
  { icon: <ChatIcon />, title: "Direct communication", desc: "Chat or call your guests directly through secure in-app messaging — simple, personal and transparent." },
  { icon: <TuneIcon />, title: "You control pricing", desc: "Set your own rates, offer seasonal discounts, or negotiate directly with guests using aajoo's smart pricing tools." },
  { icon: <LockIcon />, title: "Secure payments", desc: "Receive hassle-free payments through aajoo's secure gateway — protected, fast and fully transparent." },
  { icon: <StarIcon />, title: "Reputation & reviews", desc: "Grow your profile with guest feedback and ratings. Higher ratings mean more visibility and more bookings." },
  { icon: <HomeWorkIcon />, title: "All property types", desc: "A cozy room, hillside cottage, or family villa — aajoo welcomes all stays, from couples to families and groups." },
  { icon: <TrendingUpIcon />, title: "Smart growth tools", desc: "Booking calendar, earnings tracking, cancellation management and ranking boosts — all from one dashboard." },
  { icon: <SupportAgentIcon />, title: "Local host support", desc: "Our team works closely with hosts across Shimla, Chandigarh, Mohali and Panchkula to keep you compliant." },
  { icon: <CampaignIcon />, title: "Marketing that works", desc: "We promote your listing through digital marketing, partnerships and regional tourism networks." },
];

const WhyHostsListWithAajoo: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  return (
    <Box sx={{ bgcolor: BG }}>
      {/* Hero */}
      <Box sx={{ position: "relative", height: isMobile ? 230 : 380, backgroundImage: `url(${termsTopImage})`, backgroundSize: "cover", backgroundPosition: "center" }}>
        <Box sx={{ position: "absolute", inset: 0, background: "linear-gradient(180deg, rgba(27,36,71,.4) 0%, rgba(27,36,71,.8) 100%)", display: "flex", flexDirection: "column", justifyContent: "center", alignItems: "center", color: CREAM, textAlign: "center", px: 2 }}>
          <Typography sx={{ fontFamily: "'Fraunces', serif", fontWeight: 400, letterSpacing: "-0.02em", fontSize: { xs: "1.9rem", md: "3rem" } }}>
            Why hosts list with <Box component="span" sx={{ fontStyle: "italic", color: "#E9B79E" }}>aajoo</Box>
          </Typography>
          <Typography sx={{ mt: 1.5, opacity: 0.95, maxWidth: 680, fontSize: { xs: "0.9rem", md: "1.05rem" } }}>
            More than a booking app — a platform that connects local hosts with real travellers, built on trust,
            transparency and technology.
          </Typography>
        </Box>
      </Box>

      <Container maxWidth="lg" sx={{ py: { xs: 4, md: 6 } }}>
        <Box sx={{ mb: 4 }}>
          <AppBreadcrumbs items={[{ label: "Home", link: "/" }, { label: "Why Host with aajoo" }]} />
        </Box>

        {/* Benefits grid */}
        <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", sm: "1fr 1fr" }, gap: 3 }}>
          {benefits.map((item, index) => (
            <Reveal key={index} delay={Math.min(index * 0.04, 0.3)}>
              <Box sx={{ bgcolor: CREAM, borderRadius: "18px", p: 3, border: `1px solid ${BORDER}`, height: "100%", transition: "0.25s", "&:hover": { transform: "translateY(-5px)", boxShadow: "0 12px 30px rgba(27,36,71,.12)", borderColor: INDIGO } }}>
                <Box sx={{ display: "flex", alignItems: "center", gap: 1.5, mb: 1.5 }}>
                  <Box sx={{ width: 46, height: 46, borderRadius: "14px", bgcolor: "rgba(193,99,69,.12)", color: TERRA, display: "grid", placeItems: "center", "& svg": { fontSize: 24 } }}>
                    {item.icon}
                  </Box>
                  <Typography sx={{ fontWeight: 700, color: INDIGO, fontSize: "1.05rem" }}>{item.title}</Typography>
                </Box>
                <Typography sx={{ fontSize: "0.95rem", color: MUTED, lineHeight: 1.65 }}>{item.desc}</Typography>
              </Box>
            </Reveal>
          ))}
        </Box>

        {/* Message + CTA */}
        <Reveal>
          <Box sx={{ mt: 6, textAlign: "center", bgcolor: CREAM, p: { xs: 3, md: 5 }, borderRadius: "20px", border: `1px solid ${BORDER}`, boxShadow: "0 8px 24px rgba(27,36,71,.06)" }}>
            <Typography sx={{ fontFamily: "'Fraunces', serif", fontStyle: "italic", fontWeight: 400, fontSize: { xs: "1.1rem", md: "1.4rem" }, color: INDIGO, maxWidth: 760, mx: "auto", lineHeight: 1.6 }}>
              "aajoo believes every home has a story. By joining aajoo, you're not just listing a space — you're
              opening your doors to the world and turning hospitality into opportunity."
            </Typography>
            <Button component={Link} to="/become-a-host" variant="contained" sx={{ mt: 3, bgcolor: INDIGO, textTransform: "none", fontWeight: 600, borderRadius: "10px", px: 3.5, py: 1.1, "&:hover": { bgcolor: "#2A356B" } }}>
              Become a Host
            </Button>
          </Box>
        </Reveal>
      </Container>
    </Box>
  );
};

export default WhyHostsListWithAajoo;
