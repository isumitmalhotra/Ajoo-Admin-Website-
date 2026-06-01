import { Box, Typography } from "@mui/material";
import { WhyChooseUs } from "../../components";

import mission from "../../assets/provided asset/mission.png";
import vision from "../../assets/provided asset/vision.png";
import aboutus2 from "../../assets/UI/aboutUs2.jpg";
import bestus from "../../assets/UI/bestus.jpg";

const AboutUs = () => {
  return (
    <>
      {/* ---------- Hero Section ---------- */}
      <Box
        sx={{
          py: { xs: 5, sm: 6 },
          px: 2,
          textAlign: "center",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          background: "#fafafa",
        }}
      >
        <Typography
          variant="h2"
          sx={{
            color: "#1B2447",
            fontWeight: 700,
            fontSize: { xs: "1.8rem", sm: "2.4rem", md: "3rem" },
            mb: 2,
            fontFamily: "Poppins, sans-serif",
          }}
        >
          About Us
        </Typography>

        <Typography
          sx={{
            maxWidth: 1200,
            mx: "auto",
            fontSize: { xs: "0.95rem", sm: "1.1rem", md: "1.2rem" },
            color: "#444",
            lineHeight: 1.6,
            px: { xs: 1, sm: 3 },
            fontFamily: "Poppins, sans-serif",
          }}
        >
          Welcome to AAJOO, the ultimate platform redefining the way you find
          and book accommodations!
        </Typography>
      </Box>

      {/* ---------- Why Choose Section ---------- */}
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          gap: { xs: 3, sm: 4 },
          flexWrap: "wrap",
          px: { xs: 2, sm: 4, md: 8 },
          py: { xs: 4, sm: 6 },
          textAlign: { xs: "center", md: "left" },
        }}
      >
        <Box sx={{ flex: 1, minWidth: 320 }}>
          <Typography
            sx={{
              fontFamily: "Inter, sans-serif",
              fontSize: { xs: "1.1rem", sm: "1.3rem", md: "1.8rem" },
              lineHeight: 1.7,
              color: "#444",
              maxWidth: 700,
              mx: "auto",
              fontWeight: 400,
              letterSpacing: 0.2,
            }}
          >
            At AAJOO, we believe that where you stay should be more than just a
            place to sleep—it should be affordable, convenient, and tailored to
            your unique preferences. That’s why we’ve built a platform that
            connects users with the perfect spaces, offering everything from
            cozy budget rooms to luxurious properties, all optimized for walking
            distance and affordability.
          </Typography>
        </Box>

        <Box
          sx={{
            flex: 1,
            minWidth: 320,
            display: "flex",
            justifyContent: "center",
          }}
        >
          <Box
            component="img"
            src={aboutus2}
            alt="About Aajoo"
            sx={{
              width: "100%",
              height: "auto",
              borderRadius: "12px",
              objectFit: "cover",
              maxWidth: 600,
            }}
          />
        </Box>
      </Box>

      {/* WhyChooseUs Component */}
      <WhyChooseUs />

      {/* ---------- Our Mission Section ---------- */}
      <Box
        sx={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          flexWrap: "wrap",
          px: { xs: "5%", sm: "10%" },
          py: { xs: 5, sm: 8 },
          gap: 4,
          textAlign: { xs: "center", md: "left" },
        }}
      >
        <Box sx={{ flex: 1, minWidth: 280 }}>
          <Typography
            sx={{
              fontSize: { xs: "1.6rem", sm: "2rem" },
              fontWeight: 600,
              mb: 2,
              color: "#222",
              fontFamily: "Poppins, sans-serif",
            }}
          >
            Our Mission
          </Typography>
          <Typography
            sx={{
              fontSize: { xs: "1rem", sm: "1.1rem" },
              lineHeight: 1.6,
              color: "#555",
              fontFamily: "Poppins, sans-serif",
            }}
          >
            To empower every Indian with extra space in their homes to become a
            host, while ensuring safe, affordable, and authentic stays for
            travelers. We aim to digitally connect guests with
            government-registered homestays, supporting local families,
            preserving culture, and boosting sustainable rural tourism across
            India
          </Typography>
        </Box>

        <Box
          sx={{
            flex: 1,
            minWidth: 280,
            display: "flex",
            justifyContent: "center",
          }}
        >
          <Box
            component="img"
            src={mission}
            alt="Mission"
            sx={{
              width: "80%",
              maxWidth: 400,
              borderRadius: "12px",
              boxShadow: "0 8px 20px rgba(0,0,0,0.15)",
              transition: "transform 0.3s ease",
              "&:hover": { transform: "scale(1.05)" },
            }}
          />
        </Box>
      </Box>

      {/* ---------- Our Vision Section ---------- */}
      <Box
        sx={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          flexWrap: "wrap",
          px: { xs: "5%", sm: "10%" },
          py: { xs: 5, sm: 8 },
          gap: 4,
          textAlign: { xs: "center", md: "left" },
          flexDirection: { xs: "column-reverse", md: "row" },
        }}
      >
        <Box
          sx={{
            flex: 1,
            minWidth: 280,
            display: "flex",
            justifyContent: "center",
          }}
        >
          <Box
            component="img"
            src={vision}
            alt="Vision"
            sx={{
              width: "80%",
              maxWidth: 400,
              borderRadius: "12px",
              boxShadow: "0 8px 20px rgba(0,0,0,0.15)",
              transition: "transform 0.3s ease",
              "&:hover": { transform: "scale(1.05)" },
            }}
          />
        </Box>

        <Box sx={{ flex: 1, minWidth: 280 }}>
          <Typography
            sx={{
              fontSize: { xs: "1.6rem", sm: "2rem" },
              fontWeight: 600,
              mb: 2,
              color: "#222",
              fontFamily: "Poppins, sans-serif",
            }}
          >
            Our Vision
          </Typography>
          <Typography
            sx={{
              fontSize: { xs: "1rem", sm: "1.1rem" },
              lineHeight: 1.6,
              color: "#555",
              fontFamily: "Poppins, sans-serif",
            }}
          >
            To make Aajoo the trusted Indian platform for homestays, recognized
            for Supporting local hosts Helping families generate extra income by
            renting safe, verified rooms. Safe & reliable stays Working
            hand-in-hand with Tourism Departments to ensure compliance with
            homestay laws, guest safety, and hygiene standards. Boosting rural
            tourism Bringing global travelers into India’s villages, hill
            stations, and heritage towns, thereby supporting community-led
            development. Digital inclusion Training small-town hosts to use
            simple digital tools for managing their listings, bookings, and
            guest experiences.
          </Typography>
        </Box>
      </Box>

      {/* ---------- Why Aajoo is Different Section ---------- */}
      <Box
        sx={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          flexDirection: { xs: "column-reverse", md: "row" },
          p: { xs: 3, sm: 4, md: "40px 60px" },
          borderRadius: "16px",
          backgroundColor: "#fff",
          boxShadow: "0 4px 15px rgba(0,0,0,0.1)",
          my: { xs: 5, sm: 7 },
          mx: "auto",
          maxWidth: 1200,
          gap: { xs: 3, sm: 4, md: 6 },
          textAlign: { xs: "center", md: "left" },
        }}
      >
        <Box
          sx={{
            width: { xs: "100%", md: "50%" },
            height: { xs: "auto", md: 450 },
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <Box
            component="img"
            src={bestus}
            alt="Why Aajoo is Different"
            sx={{
              width: "100%",
              height: "100%",
              objectFit: "cover",
              borderRadius: "14px",
            }}
          />
        </Box>

        <Box
          sx={{
            width: { xs: "100%", md: "50%" },
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
          }}
        >
          <Typography
            sx={{
              fontSize: { xs: "1.8rem", sm: "2rem", md: "2.5rem" },
              color: "#1B2447",
              fontWeight: 700,
              mb: 3,
              fontFamily: "Poppins, sans-serif",
            }}
          >
            What Makes Us Different?
          </Typography>

          <Box
            component="ul"
            sx={{
              listStyle: "none",
              p: 0,
              m: 0,
              color: "#444",
              fontSize: { xs: "0.95rem", sm: "1rem", md: "1.1rem" },
              lineHeight: 1.6,
              fontFamily: "Inter, sans-serif",
              borderLeft: { xs: "none", md: "3px solid #1B2447" },
              pl: { xs: 0, md: 3 },
              textAlign: { xs: "left", md: "left" },
            }}
          >
            {[
              {
                title: "Walking Distance Optimization:",
                desc: "Find rooms near your workplace, school, or favorite spots, saving time and effort.",
              },
              {
                title: "Price Negotiation:",
                desc: "Enjoy the flexibility of negotiating rates to suit your budget.",
              },
              {
                title: "Luxurious Options:",
                desc: "From elegant suites to premium homes, our luxurious properties cater to those who seek indulgence.",
              },
              {
                title: "Safety and Trust:",
                desc: "Verified hosts and properties, along with SOS features, ensure a secure environment for everyone.",
              },
              {
                title: "Feedback-Driven:",
                desc: "Dual feedback systems guarantee quality and trust between renters and hosts.",
              },
            ].map((item, index) => (
              <Box
                key={index}
                component="li"
                sx={{
                  position: "relative",
                  mb: 2.2,
                  pl: { xs: 3, md: 2 },
                  "&::before": {
                    content: '"•"',
                    position: "absolute",
                    left: { xs: 0, md: -18 },
                    color: "#1B2447",
                    fontSize: "26px",
                    lineHeight: "20px",
                  },
                }}
              >
                <strong>{item.title} </strong>
                {item.desc}
              </Box>
            ))}
          </Box>
        </Box>
      </Box>

      {/* ---------- For Hosts & Users Section ---------- */}
      <Box
        sx={{
          backgroundColor: "#fff",
          py: { xs: 6, md: 10 },
          px: { xs: 3, md: 10 },
          mt: 8,
          boxShadow: "0 6px 20px rgba(0, 0, 0, 0.08)",
          borderRadius: "16px",
          maxWidth: "1200px",
          mx: "auto",
        }}
      >
        <Typography
          variant="h3"
          sx={{
            fontWeight: 700,
            color: "#1B2447",
            textAlign: "center",
            mb: 6,
            fontSize: { xs: "1.8rem", md: "2.5rem" },
            fontFamily: "Poppins, sans-serif",
          }}
        >
          Join the AAJOO Community
        </Typography>

        <Box
          sx={{
            display: "flex",
            flexDirection: { xs: "column", md: "row" },
            gap: 4,
            justifyContent: "space-between",
            alignItems: "stretch",
            mb: 6,
          }}
        >
          {/* For Hosts */}
          <Box
            sx={{
              flex: 1,
              p: 3,
              border: "1px solid #eee",
              borderRadius: "14px",
              boxShadow: "0 4px 10px rgba(0, 0, 0, 0.08)",
              backgroundColor: "#fafafa",
              transition: "transform 0.3s ease, box-shadow 0.3s ease",
              "&:hover": {
                transform: "translateY(-6px)",
                boxShadow: "0 6px 15px rgba(0, 0, 0, 0.15)",
              },
            }}
          >
            <Typography
              variant="h5"
              sx={{
                fontWeight: 600,
                color: "#1B2447",
                mb: 2,
                textAlign: "center",
              }}
            >
              For Hosts
            </Typography>
            <Typography
              sx={{
                color: "#555",
                lineHeight: 1.7,
                textAlign: "center",
                fontSize: "1rem",
              }}
            >
              AAJOO makes it easy for property owners to list spaces, set
              prices, and earn income. Whether you own a single room or a luxury
              villa, we provide the tools to reach potential renters
              effortlessly.
            </Typography>
          </Box>

          {/* For Users */}
          <Box
            sx={{
              flex: 1,
              p: 3,
              border: "1px solid #eee",
              borderRadius: "14px",
              boxShadow: "0 4px 10px rgba(0, 0, 0, 0.08)",
              backgroundColor: "#fafafa",
              transition: "transform 0.3s ease, box-shadow 0.3s ease",
              "&:hover": {
                transform: "translateY(-6px)",
                boxShadow: "0 6px 15px rgba(0, 0, 0, 0.15)",
              },
            }}
          >
            <Typography
              variant="h5"
              sx={{
                fontWeight: 600,
                color: "#1B2447",
                mb: 2,
                textAlign: "center",
              }}
            >
              For Users
            </Typography>
            <Typography
              sx={{
                color: "#555",
                lineHeight: 1.7,
                textAlign: "center",
                fontSize: "1rem",
              }}
            >
              Whether you’re a traveller, professional, or family, AAJOO offers
              the flexibility to book accommodations that fit your needs.
              Explore rooms, negotiate prices, and enjoy a hassle-free
              experience with just a few clicks.
            </Typography>
          </Box>
        </Box>

        {/* Join Us Call-to-Action */}
        <Box sx={{ textAlign: "center", mt: 6 }}>
          <Typography
            sx={{
              fontWeight: 600,
              fontSize: { xs: "1.2rem", md: "1.4rem" },
              color: "#333",
              maxWidth: "800px",
              mx: "auto",
              lineHeight: 1.7,
            }}
          >
            Be part of the AAJOO community and experience the difference.
            Whether you’re searching for a place to stay or hosting a property,
            we’re here to make it simple, safe, and rewarding.
          </Typography>

          <Typography
            sx={{
              mt: 3,
              fontSize: { xs: "1rem", md: "1.1rem" },
              fontWeight: 600,
              color: "#1B2447",
              fontFamily: "Poppins, sans-serif",
            }}
          >
            AAJOO – AAJAO AAJOO MEIN, MILE APNO KA SAATH FIR SE
          </Typography>
        </Box>
      </Box>
    </>
  );
};

export default AboutUs;
