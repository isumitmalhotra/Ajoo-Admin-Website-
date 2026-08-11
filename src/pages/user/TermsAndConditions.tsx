import React from "react";
import { Box, Container, Typography, useTheme, useMediaQuery } from "@mui/material";
import GavelIcon from "@mui/icons-material/Gavel";
import CheckCircleOutlineIcon from "@mui/icons-material/CheckCircleOutline";
import Reveal from "../../components/frontend/Reveal";
import termsTopImage from "../../assets/hotel.jpg";

const INDIGO = "#1B2447";
const TERRA = "#C16345";
const CREAM = "#FFFAF0";
const BG = "#EFE7D6";
const BORDER = "#D9CFB8";
const MUTED = "#6B7390";

const TermsAndConditions: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const sections = [
    { title: "1. Definitions", points: ["“User/Guest” – any individual using aajoo to search, book, or stay at a listed property.", "“Host” – property owner/operator who lists accommodation on aajoo.", "“Property” – homestay, guesthouse, or accommodation unit listed on aajoo.", "“Platform” – aajoo’s website, mobile application, and related services."] },
    { title: "2. Eligibility", points: ["Users must be 18 years or older and legally competent to contract under Indian law.", "Hosts must be the legal owners/operators of the property or have authorization.", "Both users and hosts must provide accurate, complete, and verifiable information."] },
    { title: "3. Responsibilities of users (guests)", points: ["Provide valid government ID at check-in.", "Respect the host’s property rules and local laws.", "Avoid illegal, fraudulent, or disruptive activities.", "Be responsible for personal belongings and safety during the stay.", "Any property damage caused during the stay is the user’s liability."] },
    { title: "4. Responsibilities of hosts", points: ["Ensure the property is registered with State Tourism Departments where applicable.", "Comply with local laws, fire safety, sanitation, police intimation, and taxation.", "Provide true descriptions, photos, and pricing of the property.", "Maintain the property in a safe, clean, and habitable condition.", "Do not discriminate against guests on any basis.", "Accept all bookings/payments exclusively through the aajoo platform.", "Respond promptly and courteously to guest queries or complaints."] },
    { title: "5. Booking & payments", points: ["All bookings must be made via the aajoo platform.", "Payments are processed securely and remitted to hosts after platform commission, GST, and charges.", "Refunds/cancellations are governed by aajoo’s Cancellation Policy.", "Off-platform payments or fraudulent bookings may result in account termination."] },
    { title: "6. Prohibited activities", points: ["Using the platform for fraudulent, illegal, or harmful purposes.", "Uploading false, misleading, or offensive content.", "Circumventing the platform by paying outside aajoo.", "Harassment, abuse, or threats against other users, hosts, or aajoo staff."] },
    { title: "7. Data protection & privacy", points: ["aajoo collects and processes personal data per its Privacy Policy.", "Data may be shared with hosts, payment providers, or authorities only as required by law.", "Both parties must keep their login details confidential."] },
    { title: "8. Liability & disclaimers", points: ["aajoo is an intermediary and does not own or operate properties.", "Hosts are solely responsible for the legality, safety, and quality of their properties.", "Users are responsible for their own safety, belongings, and conduct.", "aajoo is not liable for accidents, theft, loss, or damages during a stay."] },
    { title: "9. Suspension & termination", points: ["aajoo may suspend or terminate accounts for fraud or breach of these terms.", "Users/hosts may delete their accounts via written notice or in-app options."] },
    { title: "10. Governing law & disputes", points: ["These terms are governed by the laws of India.", "Disputes are subject to the jurisdiction of courts in Shimla or Chandigarh, as applicable.", "Parties shall first attempt to resolve disputes amicably."] },
    { title: "11. Updates to terms", points: ["aajoo may modify or update these terms at any time.", "Continued use after updates implies acceptance of the revised terms."] },
  ];

  return (
    <Box sx={{ bgcolor: BG }}>
      {/* Hero */}
      <Box sx={{ position: "relative", height: isMobile ? 190 : 280, backgroundImage: `url(${termsTopImage})`, backgroundSize: "cover", backgroundPosition: "center" }}>
        <Box sx={{ position: "absolute", inset: 0, background: "linear-gradient(180deg, rgba(27,36,71,.35) 0%, rgba(27,36,71,.78) 100%)", display: "flex", flexDirection: "column", justifyContent: "center", alignItems: "center", color: CREAM, textAlign: "center", px: 2 }}>
          <GavelIcon sx={{ fontSize: 38, mb: 1, color: "#E9B79E" }} />
          <Typography sx={{ fontFamily: "'Fraunces', serif", fontWeight: 400, letterSpacing: "-0.02em", fontSize: { xs: "1.8rem", md: "2.6rem" } }}>
            Terms &amp; Conditions
          </Typography>
          <Typography sx={{ mt: 0.5, opacity: 0.9, fontSize: { xs: "0.85rem", md: "1rem" } }}>
            The rules of using the aajoo platform.
          </Typography>
        </Box>
      </Box>

      <Container maxWidth="md" sx={{ py: { xs: 4, md: 6 } }}>
        <Reveal>
          <Typography sx={{ textAlign: "center", color: MUTED, mb: 5, lineHeight: 1.7, maxWidth: 720, mx: "auto" }}>
            These Terms govern your use of the aajoo app and platform, operated by Aajoo Homes Private Limited.
            By accessing the platform, registering, or transacting, you agree to be bound by these terms.
          </Typography>
        </Reveal>

        {sections.map((section, index) => (
          <Reveal key={index} delay={Math.min(index * 0.03, 0.25)}>
            <Box sx={{ mb: 2.5, p: { xs: 2.5, md: 3.5 }, borderRadius: "16px", bgcolor: CREAM, border: `1px solid ${BORDER}`, boxShadow: "0 1px 2px rgba(27,36,71,.04)" }}>
              <Typography sx={{ fontFamily: "'Fraunces', serif", fontWeight: 500, fontSize: { xs: 18, md: 20 }, color: INDIGO, mb: 1.5 }}>
                {section.title}
              </Typography>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 1 }}>
                {section.points.map((point, i) => (
                  <Box key={i} sx={{ display: "flex", gap: 1, alignItems: "flex-start" }}>
                    <CheckCircleOutlineIcon sx={{ color: TERRA, fontSize: 18, mt: 0.3, flexShrink: 0 }} />
                    <Typography sx={{ color: MUTED, lineHeight: 1.65, fontSize: "0.95rem" }}>{point}</Typography>
                  </Box>
                ))}
              </Box>
            </Box>
          </Reveal>
        ))}
      </Container>
    </Box>
  );
};

export default TermsAndConditions;
