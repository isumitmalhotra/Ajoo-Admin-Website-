import React from "react";
import {
  Box,
  Container,
  Typography,
  Card,
  CardContent,
  useTheme,
  useMediaQuery,
} from "@mui/material";
import termsTopImage from "../../assets/hotel.jpg";
import termsBottomImage from "../../assets/hotel.jpg";

const TermsAndConditions: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const sections = [
    {
      title: "1. Definitions",
      points: [
        "“User/Guest” – any individual using Aajoo to search, book, or stay at a listed property.",
        "“Host” – property owner/operator who lists accommodation on Aajoo.",
        "“Property” – homestay, guesthouse, or accommodation unit listed on Aajoo.",
        "“Platform” – Aajoo’s website, mobile application, and related services.",
      ],
    },
    {
      title: "2. Eligibility",
      points: [
        "Users must be 18 years or older and legally competent to contract under Indian law.",
        "Hosts must be the legal owners/operators of the property or have authorization.",
        "Both Users and Hosts must provide accurate, complete, and verifiable information.",
      ],
    },
    {
      title: "3. Responsibilities of Users (Guests)",
      points: [
        "Provide valid government ID at the time of check-in.",
        "Respect Host’s property rules and local laws.",
        "Avoid illegal, fraudulent, or disruptive activities.",
        "Be responsible for personal belongings and safety during the stay.",
        "Any property damage caused during stay shall be the User’s liability.",
      ],
    },
    {
      title: "4. Responsibilities of Hosts",
      points: [
        "Ensure the property is registered with the State Tourism Departments, where applicable (e.g., Himachal Pradesh Homestay Rules 2025).",
        "Comply with local laws, fire safety, sanitation, police intimation, and taxation requirements.",
        "Provide true and accurate descriptions, photos, and pricing of the property.",
        "Maintain the property in a safe, clean, and habitable condition.",
        "Not discriminate against guests on the basis of religion, caste, gender, or background.",
        "Accept all bookings/payments exclusively through the Aajoo platform.",
        "Respond promptly and courteously to guest queries or complaints.",
      ],
    },
    {
      title: "5. Booking & Payments",
      points: [
        "All bookings must be made via the Aajoo app/platform.",
        "Payments are processed securely by Aajoo and remitted to Hosts after deducting applicable platform commission, GST, and charges.",
        "Refunds/cancellations are governed by Aajoo’s Cancellation Policy, updated periodically.",
        "Any off-platform payments or fraudulent bookings may result in account termination.",
      ],
    },
    {
      title: "6. Prohibited Activities",
      points: [
        "Use the platform for fraudulent, illegal, or harmful purposes.",
        "Upload false, misleading, or offensive content.",
        "Circumvent the platform by making/accepting payments outside Aajoo.",
        "Engage in harassment, abuse, or threats against other users, hosts, or Aajoo staff.",
      ],
    },
    {
      title: "7. Data Protection & Privacy",
      points: [
        "Aajoo collects and processes personal data as per its Privacy Policy.",
        "Data may be shared with Hosts, payment providers, or authorities only as required by law.",
        "Both Users and Hosts must maintain confidentiality of their login details.",
      ],
    },
    {
      title: "8. Liability & Disclaimers",
      points: [
        "Aajoo is an intermediary platform and does not own or operate properties.",
        "Hosts are solely responsible for the legality, safety, and quality of their properties.",
        "Users are responsible for their own safety, belongings, and conduct.",
        "Aajoo shall not be liable for accidents, theft, loss, or damages during a stay.",
        "Aajoo is not responsible for false representations by Hosts or misconduct by Guests.",
      ],
    },
    {
      title: "9. Suspension & Termination",
      points: [
        "Aajoo may suspend or terminate accounts of Users/Hosts for fraudulent activities or breach of these Terms.",
        "Users/Hosts may delete their accounts by providing written notice or using in-app options.",
      ],
    },
    {
      title: "10. Governing Law & Dispute Resolution",
      points: [
        "These Terms are governed by the laws of India.",
        "Any disputes shall be subject to the exclusive jurisdiction of courts in Shimla or Chandigarh, as applicable.",
        "Parties shall first attempt to resolve disputes amicably before approaching courts.",
      ],
    },
    {
      title: "11. Updates to Terms",
      points: [
        "Aajoo reserves the right to modify or update these Terms at any time.",
        "Continued use of the platform after updates implies acceptance of the revised Terms.",
      ],
    },
  ];

  return (
    <Box sx={{ bgcolor: "#fff8fa", py: { xs: 6, md: 10 } }}>
      <Container maxWidth="md">
        {/* Header Image */}
        <Box
          sx={{
            width: "100%",
            height: isMobile ? 180 : 300,
            borderRadius: 4,
            overflow: "hidden",
            mb: 6,
            boxShadow: "0 8px 20px rgba(193,67,101,0.15)",
          }}
        >
          <Box
            component="img"
            src={termsTopImage}
            alt="Aajoo Terms Banner"
            sx={{
              width: "100%",
              height: "100%",
              objectFit: "cover",
            }}
          />
        </Box>

        {/* Title Section */}
        <Typography
          variant="h4"
          align="center"
          fontWeight={700}
          sx={{ color: "#1B2447", mb: 2 }}
        >
          📜 Aajoo – Terms & Conditions
        </Typography>
        <Typography
          align="center"
          sx={{
            maxWidth: "80%",
            mx: "auto",
            color: "text.secondary",
            mb: 6,
          }}
        >
          These Terms & Conditions (“Terms”) govern the use of the Aajoo App and
          Platform, operated by Aajoo Homes Private Limited (“Aajoo,” “we,”
          “our,” “us”). By accessing or using the app, registering as a User or
          Host, or engaging in any transactions through the platform, you
          (“User,” “Guest,” or “Host”) agree to be bound by these Terms.
        </Typography>

        {/* Content Section */}
        {sections.map((section, index) => (
          <Card
            key={index}
            elevation={0}
            sx={{
              mb: 3,
              borderRadius: 3,
              bgcolor: "#ffffff",
              border: "1px solid #f3c8d2",
              boxShadow: "0 4px 15px rgba(193,67,101,0.05)",
              transition: "all 0.3s ease",
              "&:hover": { boxShadow: "0 8px 25px rgba(193,67,101,0.12)" },
            }}
          >
            <CardContent>
              <Typography
                variant="h6"
                fontWeight={700}
                sx={{ color: "#1B2447", mb: 1.5 }}
              >
                {section.title}
              </Typography>
              {section.points.map((point, i) => (
                <Typography
                  key={i}
                  variant="body1"
                  sx={{
                    mb: 1,
                    color: "text.secondary",
                    lineHeight: 1.7,
                  }}
                >
                  • {point}
                </Typography>
              ))}
            </CardContent>
          </Card>
        ))}

        {/* Footer Image */}
        <Box
          sx={{
            width: "100%",
            height: isMobile ? 160 : 280,
            borderRadius: 4,
            overflow: "hidden",
            mt: 8,
            boxShadow: "0 8px 20px rgba(193,67,101,0.15)",
          }}
        >
          <Box
            component="img"
            src={termsBottomImage}
            alt="Aajoo Policy Image"
            sx={{
              width: "100%",
              height: "100%",
              objectFit: "cover",
            }}
          />
        </Box>
      </Container>
    </Box>
  );
};

export default TermsAndConditions;
