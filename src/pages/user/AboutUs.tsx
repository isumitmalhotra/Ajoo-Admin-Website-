import { Box, Typography, Button } from "@mui/material";
import { Link } from "react-router-dom";
import DirectionsWalkIcon from "@mui/icons-material/DirectionsWalk";
import HandshakeIcon from "@mui/icons-material/Handshake";
import DiamondIcon from "@mui/icons-material/Diamond";
import VerifiedUserIcon from "@mui/icons-material/VerifiedUser";
import RateReviewIcon from "@mui/icons-material/RateReview";
import FlagIcon from "@mui/icons-material/Flag";
import VisibilityIcon from "@mui/icons-material/Visibility";
import HomeWorkIcon from "@mui/icons-material/HomeWork";
import LuggageIcon from "@mui/icons-material/Luggage";
import { WhyChooseUs } from "../../components";
import Reveal from "../../components/frontend/Reveal";

import aboutus2 from "../../assets/UI/aboutUs2.jpg";
import bestus from "../../assets/UI/bestus.jpg";

const INDIGO = "#1B2447";
const TERRA = "#C16345";
const CREAM = "#FFFAF0";
const BG = "#EFE7D6";
const BORDER = "#D9CFB8";
const MUTED = "#6B7390";

const heading = {
  fontFamily: "'Fraunces', serif",
  fontWeight: 400,
  letterSpacing: "-0.02em",
  color: INDIGO,
};

const differentiators = [
  { icon: <DirectionsWalkIcon />, title: "Walking-distance optimization", desc: "Find rooms near your workplace, school, or favourite spots — saving time and effort." },
  { icon: <HandshakeIcon />, title: "Price negotiation", desc: "Enjoy the flexibility of negotiating rates to suit your budget." },
  { icon: <DiamondIcon />, title: "Luxurious options", desc: "From elegant suites to premium homes, our luxury stays cater to those who seek indulgence." },
  { icon: <VerifiedUserIcon />, title: "Safety & trust", desc: "Verified hosts and properties, plus SOS features, keep everyone secure." },
  { icon: <RateReviewIcon />, title: "Feedback-driven", desc: "Dual feedback systems guarantee quality and trust between guests and hosts." },
];

const AboutUs = () => {
  return (
    <Box sx={{ bgcolor: BG }}>
      {/* ---------- Hero ---------- */}
      <Box
        sx={{
          py: { xs: 6, md: 9 },
          px: 3,
          textAlign: "center",
          background: "linear-gradient(180deg, #FFFAF0 0%, #EFE7D6 100%)",
          borderBottom: `1px solid ${BORDER}`,
        }}
      >
        <Reveal>
          <Typography sx={{ ...heading, fontSize: { xs: "2rem", sm: "2.6rem", md: "3.2rem" }, mb: 1.5 }}>
            About <Box component="span" sx={{ fontStyle: "italic", color: TERRA }}>aajoo</Box>
          </Typography>
          <Typography sx={{ maxWidth: 760, mx: "auto", fontSize: { xs: "0.98rem", md: "1.15rem" }, color: MUTED, lineHeight: 1.7 }}>
            The platform redefining how India finds and books authentic, affordable, government-registered homestays.
          </Typography>
        </Reveal>
      </Box>

      {/* ---------- Intro ---------- */}
      <Reveal>
        <Box
          sx={{
            display: "flex",
            alignItems: "center",
            gap: { xs: 3, md: 6 },
            flexWrap: "wrap",
            maxWidth: 1200,
            mx: "auto",
            px: { xs: 2, md: 4 },
            py: { xs: 5, md: 8 },
          }}
        >
          <Box sx={{ flex: 1, minWidth: 300 }}>
            <Typography sx={{ ...heading, fontSize: { xs: 24, md: 30 }, mb: 2 }}>
              Where you stay should feel like home
            </Typography>
            <Typography sx={{ fontSize: { xs: "1rem", md: "1.1rem" }, lineHeight: 1.8, color: "#3D4670" }}>
              At aajoo, we believe a stay should be more than a place to sleep — it should be affordable,
              convenient, and tailored to you. We connect guests with the perfect spaces, from cozy budget
              rooms to luxurious homes, all optimised for location and value.
            </Typography>
          </Box>
          <Box sx={{ flex: 1, minWidth: 300, display: "flex", justifyContent: "center" }}>
            <Box
              component="img"
              src={aboutus2}
              alt="About aajoo"
              sx={{ width: "100%", maxWidth: 560, height: { xs: 240, md: 360 }, objectFit: "cover", borderRadius: "18px", border: `1px solid ${BORDER}`, boxShadow: "0 10px 30px rgba(27,36,71,.10)" }}
            />
          </Box>
        </Box>
      </Reveal>

      <Reveal>
        <WhyChooseUs />
      </Reveal>

      {/* ---------- Mission & Vision ---------- */}
      <Box sx={{ maxWidth: 1200, mx: "auto", px: { xs: 2, md: 4 }, py: { xs: 4, md: 7 }, display: "grid", gridTemplateColumns: { xs: "1fr", md: "1fr 1fr" }, gap: 3 }}>
        {[
          { icon: <FlagIcon />, title: "Our Mission", body: "To empower every Indian with extra space to become a host, while ensuring safe, affordable and authentic stays for travellers — digitally connecting guests with government-registered homestays, supporting local families and sustainable tourism." },
          { icon: <VisibilityIcon />, title: "Our Vision", body: "To make aajoo the trusted Indian platform for homestays — supporting local hosts, ensuring safe and compliant stays, boosting rural tourism, and bringing simple digital tools to small-town hosts." },
        ].map((c, i) => (
          <Reveal key={i} delay={i * 0.08}>
            <Box sx={{ bgcolor: CREAM, border: `1px solid ${BORDER}`, borderRadius: "18px", p: { xs: 3, md: 4 }, height: "100%", boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)" }}>
              {/* Themed illustration tile (replaces the off-theme red PNG) */}
              <Box
                sx={{
                  width: "100%",
                  height: 150,
                  borderRadius: "14px",
                  mb: 2.5,
                  display: "grid",
                  placeItems: "center",
                  background: "linear-gradient(135deg, rgba(27,36,71,.06) 0%, rgba(193,99,69,.10) 100%)",
                  border: `1px solid ${BORDER}`,
                  "& svg": { fontSize: 64, color: INDIGO },
                }}
              >
                {c.icon}
              </Box>
              <Box sx={{ display: "flex", alignItems: "center", gap: 1.5, mb: 1.5 }}>
                <Box sx={{ width: 40, height: 40, borderRadius: "12px", bgcolor: "rgba(193,99,69,.12)", color: TERRA, display: "grid", placeItems: "center", "& svg": { fontSize: 22 } }}>
                  {c.icon}
                </Box>
                <Typography sx={{ ...heading, fontSize: 24 }}>{c.title}</Typography>
              </Box>
              <Typography sx={{ fontSize: "1rem", lineHeight: 1.75, color: "#3D4670" }}>{c.body}</Typography>
            </Box>
          </Reveal>
        ))}
      </Box>

      {/* ---------- What makes us different ---------- */}
      <Reveal>
        <Box sx={{ maxWidth: 1200, mx: "auto", px: { xs: 2, md: 4 }, py: { xs: 4, md: 7 } }}>
          <Box sx={{ display: "flex", flexDirection: { xs: "column-reverse", md: "row" }, alignItems: "center", gap: { xs: 3, md: 6 } }}>
            <Box sx={{ flex: 1, minWidth: 300, width: "100%" }}>
              <Typography sx={{ ...heading, fontSize: { xs: 26, md: 34 }, mb: 3 }}>What makes us different?</Typography>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                {differentiators.map((d) => (
                  <Box key={d.title} sx={{ display: "flex", gap: 2, alignItems: "flex-start" }}>
                    <Box sx={{ flexShrink: 0, width: 42, height: 42, borderRadius: "12px", bgcolor: "rgba(27,36,71,.06)", color: INDIGO, display: "grid", placeItems: "center", "& svg": { fontSize: 22 } }}>
                      {d.icon}
                    </Box>
                    <Box>
                      <Typography sx={{ fontWeight: 700, color: INDIGO }}>{d.title}</Typography>
                      <Typography sx={{ color: MUTED, fontSize: "0.95rem", lineHeight: 1.6 }}>{d.desc}</Typography>
                    </Box>
                  </Box>
                ))}
              </Box>
            </Box>
            <Box sx={{ flex: 1, minWidth: 300, width: "100%" }}>
              <Box component="img" src={bestus} alt="Why aajoo is different" sx={{ width: "100%", height: { xs: 260, md: 420 }, objectFit: "cover", borderRadius: "18px", border: `1px solid ${BORDER}`, boxShadow: "0 10px 30px rgba(27,36,71,.10)" }} />
            </Box>
          </Box>
        </Box>
      </Reveal>

      {/* ---------- Join the community ---------- */}
      <Reveal>
        <Box sx={{ maxWidth: 1200, mx: "auto", px: { xs: 2, md: 4 }, py: { xs: 5, md: 8 } }}>
          <Typography sx={{ ...heading, fontSize: { xs: 26, md: 34 }, textAlign: "center", mb: 1 }}>
            Join the <Box component="span" sx={{ fontStyle: "italic", color: TERRA }}>aajoo</Box> community
          </Typography>
          <Typography sx={{ textAlign: "center", color: MUTED, mb: 4 }}>
            Whether you're hosting a space or booking a stay — simple, safe and rewarding.
          </Typography>

          <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", md: "1fr 1fr" }, gap: 3 }}>
            {[
              { icon: <HomeWorkIcon />, title: "For Hosts", body: "List spaces, set prices and earn income. Whether it's a single room or a luxury villa, we give you the tools to reach guests effortlessly.", cta: "Become a Host", to: "/become-a-host" },
              { icon: <LuggageIcon />, title: "For Guests", body: "Traveller, professional or family — book stays that fit your needs. Explore rooms, negotiate prices, and enjoy a hassle-free experience.", cta: "Explore stays", to: "/property/list" },
            ].map((c, i) => (
              <Box key={i} sx={{ bgcolor: CREAM, border: `1px solid ${BORDER}`, borderRadius: "18px", p: { xs: 3, md: 4 }, textAlign: "center", transition: "0.25s", "&:hover": { transform: "translateY(-4px)", boxShadow: "0 12px 30px rgba(27,36,71,.12)" } }}>
                <Box sx={{ width: 56, height: 56, mx: "auto", mb: 2, borderRadius: "16px", bgcolor: "rgba(27,36,71,.06)", color: INDIGO, display: "grid", placeItems: "center", "& svg": { fontSize: 28 } }}>
                  {c.icon}
                </Box>
                <Typography sx={{ ...heading, fontSize: 22, mb: 1 }}>{c.title}</Typography>
                <Typography sx={{ color: MUTED, lineHeight: 1.7, mb: 3 }}>{c.body}</Typography>
                <Button component={Link} to={c.to} variant="contained" sx={{ bgcolor: INDIGO, textTransform: "none", fontWeight: 600, borderRadius: "10px", px: 3, "&:hover": { bgcolor: "#2A356B" } }}>
                  {c.cta}
                </Button>
              </Box>
            ))}
          </Box>

          <Typography sx={{ textAlign: "center", mt: 5, fontFamily: "'Fraunces', serif", fontStyle: "italic", fontSize: { xs: "1.05rem", md: "1.2rem" }, color: TERRA }}>
            AAJAO AAJOO MEIN, MILE APNO KA SAATH FIR SE
          </Typography>
        </Box>
      </Reveal>
    </Box>
  );
};

export default AboutUs;
