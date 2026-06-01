import React from "react";
import {
  Box,
  Typography,
  Breadcrumbs,
  Link,
  Paper,
  Divider,
  useMediaQuery,
  useTheme,
} from "@mui/material";
import NavigateNextIcon from "@mui/icons-material/NavigateNext";
import termsTopImage from "../../assets/hotel.jpg";
import termsBottomImage from "../../assets/hotel.jpg";

const PrivacyPolicy: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  return (
    <Box sx={{ bgcolor: "#fafafa", minHeight: "100vh", pb: 6 }}>
   {/* Top Banner */}
<Box
  sx={{
    position: "relative",
    height: isMobile ? "150px" : "250px", // Smaller height
    backgroundImage: `url(${termsTopImage})`,
    backgroundSize: "cover",
    backgroundPosition: "center",
    borderBottomLeftRadius: "40px",
    borderBottomRightRadius: "40px",
    overflow: "hidden",
  }}
>
  <Box
    sx={{
      position: "absolute",
      inset: 0,
      bgcolor: "rgba(0, 0, 0, 0.35)",
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
      variant={isMobile ? "h6" : "h4"}   // Reduced size
      fontWeight={700}
      sx={{ letterSpacing: 0.5 }}
    >
      AAJOO PRIVACY POLICY
    </Typography>

    <Typography
      variant="body2"      // Smaller subtitle
      sx={{
        mt: 0.5,
        fontWeight: 300,
        opacity: 0.9,
      }}
    >
      Your privacy, our responsibility.
    </Typography>
  </Box>
</Box>


      {/* Breadcrumbs */}
      <Box sx={{ maxWidth: "1100px", mx: "auto", mt: 3, px: 2 }}>
        <Breadcrumbs
          separator={<NavigateNextIcon fontSize="small" />}
          aria-label="breadcrumb"
        >
          <Link underline="hover" color="inherit" href="/">
            Home
          </Link>
          <Typography color="text.primary">Privacy Policy</Typography>
        </Breadcrumbs>
      </Box>

      {/* Content */}
      <Box
        sx={{
          maxWidth: "1100px",
          mx: "auto",
          mt: 4,
          px: isMobile ? 2 : 4,
          display: "flex",
          flexDirection: "column",
          gap: 4,
        }}
      >
        {/* Intro Section */}
        <Paper
          elevation={3}
          sx={{
            p: isMobile ? 3 : 5,
            borderRadius: "20px",
            background: "linear-gradient(135deg, #ffffff, #f5f5f5)",
          }}
        >
          <Typography variant="h6" fontWeight={700} gutterBottom>
            Company: Aajoo Homes Private Limited (“Aajoo”, “we”, “us”, or “our”)
          </Typography>
          <Typography variant="body1" sx={{ mb: 1 }}>
            Applicable For: Aajoo App Users and Hosts
          </Typography>
          <Divider sx={{ my: 2 }} />
          <Typography variant="body1">
            Aajoo respects your privacy. This Privacy Policy explains how we
            collect, use, store, and protect your personal information when you
            use the Aajoo app or website — whether as a User (guest/traveler) or
            a Host (property owner). By using Aajoo, you agree to this Privacy
            Policy and consent to the collection and use of your data as
            described below.
          </Typography>
        </Paper>
        {/* Sectioned Content */}
        {[
          {
            title: "1. INFORMATION WE COLLECT",
            content: `We collect personal data to provide better services for Users (Guests) and Hosts. This includes basic details, location, and verification information as required for smooth bookings and payments.`,
          },
          {
            title: "2. HOW WE USE YOUR INFORMATION",
            content: `Your data helps us create accounts, process bookings, verify hosts, and prevent fraud. It also improves your app experience and ensures compliance with government norms.`,
          },
          {
            title: "3. DATA SHARING & THIRD PARTIES",
            content: `We never sell or rent your information. Only trusted third parties such as payment gateways, KYC verifiers, and tourism authorities may access necessary data under strict security protocols.`,
          },
          {
            title: "4. DATA STORAGE & SECURITY",
            content: `Your data is safely stored on encrypted servers with restricted access and regular security audits. In case of any breach, both users and authorities are promptly notified as per the DPDP Act 2023.`,
          },
          {
            title: "5. USER RIGHTS",
            content: `You can access, correct, or delete your personal data at any time. Email contactus@aajoohomes.com to exercise your rights under the DPDP Act.`,
          },
          {
            title: "6. ACCOUNT DELETION",
            content: `Once deleted, all personal and KYC data is erased within 7 days unless required by law. Transactional and tax-related data may be retained for compliance.`,
          },
          {
            title: "7. COOKIES POLICY",
            content: `Cookies are used for login sessions, analytics, and better recommendations. You can disable cookies in your browser settings.`,
          },
          {
            title: "8. CHANGES TO THIS POLICY",
            content: `This Privacy Policy may be updated periodically. The latest version will always be available on our website and app.`,
          },
          {
            title: "9. CONTACT US",
            content: `For privacy-related queries or complaints, email us at contactus@aajoohomes.com.`,
          },
        ].map((section, index) => (
          <Paper
            key={index}
            elevation={1}
            sx={{
              p: isMobile ? 2.2 : 3.5,
              borderRadius: "14px",
              borderLeft: "4px solid #1B2447",
              background: "#fff",
              transition: "transform 0.25s",
              "&:hover": { transform: "translateY(-3px)" },
            }}
          >
            <Typography variant="subtitle1" fontWeight={700} gutterBottom>
              {section.title}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {section.content}
            </Typography>
          </Paper>
        ))}

        {/* Bottom Banner */}
        <Box
          sx={{
            mt: 6,
            height: isMobile ? "200px" : "300px",
            backgroundImage: `url(${termsBottomImage})`,
            backgroundSize: "cover",
            backgroundPosition: "center",
            borderRadius: "30px",
            position: "relative",
            overflow: "hidden",
          }}
        >
          <Box
            sx={{
              position: "absolute",
              inset: 0,
              bgcolor: "rgba(0, 0, 0, 0.4)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              flexDirection: "column",
              color: "#fff",
              textAlign: "center",
              px: 2,
            }}
          >
            <Typography variant={isMobile ? "h6" : "h4"} fontWeight={600}>
              Aajoo — Protecting Your Privacy, Empowering Your Experience
            </Typography>
            <Typography variant="subtitle1" sx={{ mt: 1 }}>
              We collect only what’s necessary, keep it secure, and never misuse
              your data.
            </Typography>
          </Box>
        </Box>
      </Box>
    </Box>
  );
};

export default PrivacyPolicy;
