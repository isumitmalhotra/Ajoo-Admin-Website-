import { Box, Typography, Grid, Container } from "@mui/material";
import {
  Security,
  EventAvailable,
  LocalOffer,
  SupportAgent,
} from "@mui/icons-material";

const features = [
  {
    icon: <Security sx={{ fontSize: 40, color: "#1B2447" }} />,
    title: "Easy & Quick Bookings",
    description: "Search, book, and confirm stays in just a few clicks.",
    link: "#",
  },
  {
    icon: <EventAvailable sx={{ fontSize: 40, color: "#1B2447" }} />,
    title: "Local & Unique Stays",
    description: "Live with families, experience culture, not just hotels.",
    link: "#",
  },
  {
    icon: <LocalOffer sx={{ fontSize: 40, color: "#1B2447" }} />,
    title: "Safe & Verified",
    description: "Every property and host is checked with government rules.",
    link: "#",
  },
  // {
  //   icon: <SupportAgent sx={{ fontSize: 40, color: "#1B2447" }} />,
  //   title: "Affordable Prices",
  //   description:
  //     "Transparent, budget-friendly stays with no hidden charges.",
  //   link: "#",
  // },
  {
    icon: <SupportAgent sx={{ fontSize: 40, color: "#1B2447" }} />,
    title: "24x7 Support",
    description: "Instant help via WhatsApp, app, or call anytime.",
    link: "#",
  },
];

const WhyChooseUs = () => {
  return (
    <Container sx={{ py: 6 }}>
      {/* Heading */}
      <Typography
        variant="h4"
        fontWeight="bold"
        color="#1B2447"
        gutterBottom
        textAlign="center"
      >
        Why Choose Us?
      </Typography>
      <Typography
        variant="h6" // bigger than body1 (use h6 for slightly larger)
        mb={6}
        sx={{
          maxWidth: "800px",
          mx: "auto",
          textAlign: "center",
          fontSize: { xs: "1rem", sm: "1.2rem", md: "1.4rem" }, // responsive sizing
          fontFamily: "'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
          fontWeight: 400,
          lineHeight: 1.6,
          color: "#444", // softer text color
        }}
      >
        At{" "}
        <Box component="span" sx={{ color: "#1B2447", fontWeight: "bold" }}>
          AAJAO
        </Box>
        , we bring together travelers and local hosts on one trusted Indian
        homestay platform. Whether you’re booking a stay or listing your
        property, here’s why you’ll love us
      </Typography>

      {/* Features */}
      <Grid container spacing={3}>
        {features.map((feature, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
            <Box
              sx={{
                textAlign: "center",
                p: 3,
                borderRadius: 3,
                bgcolor: "#fff",
                boxShadow: 3,
                height: "100%",
                display: "flex",
                flexDirection: "column",
                justifyContent: "space-between",
              }}
            >
              {/* Icon */}
              <Box>{feature.icon}</Box>

              {/* Title */}
              <Typography
                variant="h6"
                fontWeight="bold"
                color="text.primary"
                mt={2}
              >
                {feature.title}
              </Typography>

              {/* Description */}
              <Typography
                variant="body2"
                color="text.secondary"
                sx={{ my: 2, flexGrow: 1 }}
              >
                {feature.description}
              </Typography>

              {/* Link Button */}
              {/* <Button
                href={feature.link}
                sx={{
                  color: "#1B2447",
                  textTransform: "none",
                  fontWeight: "bold",
                  "&:hover": { textDecoration: "underline" },
                }}
              >
                Read More →
              </Button> */}
            </Box>
          </Grid>
        ))}
      </Grid>
    </Container>
  );
};

export default WhyChooseUs;
