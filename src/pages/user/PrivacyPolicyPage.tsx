import React from "react";
import { Box, Typography, Breadcrumbs, Link, Divider, useMediaQuery, useTheme } from "@mui/material";
import NavigateNextIcon from "@mui/icons-material/NavigateNext";
import ShieldIcon from "@mui/icons-material/Shield";
import Reveal from "../../components/frontend/Reveal";
import termsTopImage from "../../assets/hotel.jpg";

const INDIGO = "#1B2447";
const TERRA = "#C16345";
const CREAM = "#FFFAF0";
const BG = "#EFE7D6";
const BORDER = "#D9CFB8";
const MUTED = "#6B7390";

const sections = [
  { title: "Information we collect", content: "We collect personal data to provide better services for guests and hosts — basic details, location, and verification information needed for smooth bookings and payments." },
  { title: "How we use your information", content: "Your data helps us create accounts, process bookings, verify hosts, and prevent fraud. It also improves your experience and ensures compliance with government norms." },
  { title: "Data sharing & third parties", content: "We never sell or rent your information. Only trusted third parties such as payment gateways, KYC verifiers, and tourism authorities may access necessary data under strict security protocols." },
  { title: "Data storage & security", content: "Your data is stored on encrypted servers with restricted access and regular security audits. In case of a breach, users and authorities are promptly notified per the DPDP Act 2023." },
  { title: "Your rights", content: "You can access, correct, or delete your personal data at any time. Email contactus@aajoohomes.com to exercise your rights under the DPDP Act." },
  { title: "Account deletion", content: "Once deleted, all personal and KYC data is erased within 7 days unless required by law. Transactional and tax-related data may be retained for compliance." },
  { title: "Cookies policy", content: "Cookies are used for login sessions, analytics, and better recommendations. You can disable cookies in your browser settings." },
  { title: "Changes to this policy", content: "This Privacy Policy may be updated periodically. The latest version will always be available on our website and app." },
  { title: "Contact us", content: "For privacy-related queries or complaints, email us at contactus@aajoohomes.com." },
];

const PrivacyPolicy: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  return (
    <Box sx={{ bgcolor: BG, minHeight: "100vh", pb: 6 }}>
      {/* Hero */}
      <Box sx={{ position: "relative", height: isMobile ? 190 : 280, backgroundImage: `url(${termsTopImage})`, backgroundSize: "cover", backgroundPosition: "center" }}>
        <Box sx={{ position: "absolute", inset: 0, background: "linear-gradient(180deg, rgba(27,36,71,.35) 0%, rgba(27,36,71,.78) 100%)", display: "flex", flexDirection: "column", justifyContent: "center", alignItems: "center", color: CREAM, textAlign: "center", px: 2 }}>
          <ShieldIcon sx={{ fontSize: 40, mb: 1, color: "#E9B79E" }} />
          <Typography sx={{ fontFamily: "'Fraunces', serif", fontWeight: 400, letterSpacing: "-0.02em", fontSize: { xs: "1.8rem", md: "2.6rem" } }}>
            Privacy Policy
          </Typography>
          <Typography sx={{ mt: 0.5, opacity: 0.9, fontSize: { xs: "0.85rem", md: "1rem" } }}>
            Your privacy, our responsibility.
          </Typography>
        </Box>
      </Box>

      {/* Breadcrumb */}
      <Box sx={{ maxWidth: 1000, mx: "auto", mt: 3, px: 2 }}>
        <Breadcrumbs separator={<NavigateNextIcon fontSize="small" />} aria-label="breadcrumb">
          <Link underline="hover" color={MUTED} href="/">Home</Link>
          <Typography sx={{ color: INDIGO, fontWeight: 600 }}>Privacy Policy</Typography>
        </Breadcrumbs>
      </Box>

      <Box sx={{ maxWidth: 1000, mx: "auto", mt: 4, px: isMobile ? 2 : 4, display: "flex", flexDirection: "column", gap: 3 }}>
        {/* Intro */}
        <Reveal>
          <Box sx={{ p: { xs: 3, md: 4 }, borderRadius: "18px", bgcolor: CREAM, border: `1px solid ${BORDER}`, boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)" }}>
            <Typography sx={{ fontFamily: "'Fraunces', serif", fontWeight: 500, fontSize: 20, color: INDIGO }}>
              Aajoo Homes Private Limited ("aajoo", "we", "us")
            </Typography>
            <Typography sx={{ color: MUTED, mb: 1 }}>Applicable to aajoo app users and hosts.</Typography>
            <Divider sx={{ my: 2 }} />
            <Typography sx={{ color: "#3D4670", lineHeight: 1.75 }}>
              aajoo respects your privacy. This policy explains how we collect, use, store, and protect your
              personal information when you use the aajoo app or website — as a guest or a host. By using aajoo,
              you agree to this policy and consent to the use of your data as described below.
            </Typography>
          </Box>
        </Reveal>

        {/* Sections */}
        {sections.map((section, index) => (
          <Reveal key={index} delay={Math.min(index * 0.04, 0.3)}>
            <Box sx={{ p: { xs: 2.5, md: 3.5 }, borderRadius: "14px", bgcolor: CREAM, border: `1px solid ${BORDER}`, borderLeft: `4px solid ${TERRA}`, display: "flex", gap: 2, transition: "transform 0.25s", "&:hover": { transform: "translateY(-3px)" } }}>
              <Box sx={{ flexShrink: 0, width: 34, height: 34, borderRadius: "10px", bgcolor: "rgba(193,99,69,.12)", color: TERRA, display: "grid", placeItems: "center", fontWeight: 700, fontSize: 14 }}>
                {index + 1}
              </Box>
              <Box>
                <Typography sx={{ fontWeight: 700, color: INDIGO, mb: 0.5 }}>{section.title}</Typography>
                <Typography sx={{ color: MUTED, lineHeight: 1.7, fontSize: "0.95rem" }}>{section.content}</Typography>
              </Box>
            </Box>
          </Reveal>
        ))}

        {/* Bottom banner */}
        <Reveal>
          <Box sx={{ mt: 3, height: isMobile ? 180 : 260, backgroundImage: `url(${termsTopImage})`, backgroundSize: "cover", backgroundPosition: "center", borderRadius: "20px", position: "relative", overflow: "hidden" }}>
            <Box sx={{ position: "absolute", inset: 0, background: "linear-gradient(180deg, rgba(27,36,71,.4) 0%, rgba(27,36,71,.7) 100%)", display: "flex", alignItems: "center", justifyContent: "center", flexDirection: "column", color: CREAM, textAlign: "center", px: 2 }}>
              <Typography sx={{ fontFamily: "'Fraunces', serif", fontWeight: 400, fontSize: { xs: "1.2rem", md: "1.8rem" } }}>
                Protecting your privacy, empowering your experience
              </Typography>
              <Typography sx={{ mt: 1, opacity: 0.9, fontSize: { xs: "0.85rem", md: "1rem" } }}>
                We collect only what's necessary, keep it secure, and never misuse your data.
              </Typography>
            </Box>
          </Box>
        </Reveal>
      </Box>
    </Box>
  );
};

export default PrivacyPolicy;
