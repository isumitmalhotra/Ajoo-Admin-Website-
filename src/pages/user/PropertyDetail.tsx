import React, { useState, useEffect, useRef } from "react";
import "slick-carousel/slick/slick.css";
import "slick-carousel/slick/slick-theme.css";

import {
  Box,
  Typography,
  IconButton,
  Breadcrumbs,
  Link,
  Button,
  Rating,
  Avatar,
} from "@mui/material";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
// import PhoneIcon from "@mui/icons-material/Phone";
import PermIdentityIcon from "@mui/icons-material/PermIdentity";
import "leaflet/dist/leaflet.css";
import "../../styles/user/PropertyDetail.css";
import Slider from "react-slick";
import { Roomimages } from "../../styles/utils/reusableData";
import {
  PropertyBookingBox,
  PropDetailMap,
  CancellationPolicyModal,
  BookingSection,
  ExploreMore,
  PropertyGallery,
  HostDetailsModal,
} from "../../components";
import { reviews, sliderSettings } from "../../styles/utils/reusableData";

export const PropertyDetail: React.FC = () => {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [open, setOpen] = useState(false);
  const [rules] = useState<string[]>([
    "No smoking inside the property.",
    "Pets are not allowed.",
    "Please respect quiet hours after 10 PM.",
  ]);
  const user = {
    name: "Rahul Sharma",
    image:
      "https://images.unsplash.com/photo-1603415526960-f7e0328f2b1a?auto=format&fit=crop&w=500&q=80",
    contact: "+91 98765 43210",
    address: "Shimla, Himachal Pradesh, India",
    propertyCount: 5,
  };

  const bookingBoxRef = useRef<HTMLDivElement | null>(null);
  const INITIAL_TOP = 150;
  const GAP_FROM_FOOTER = 24;

  useEffect(() => {
    const handleScrollOrResize = () => {
      const box = bookingBoxRef.current;
      const footer = document.querySelector("footer");

      if (!box) return;
      const mobileBreakpoint = 900;
      if (window.innerWidth <= mobileBreakpoint) {
        box.style.position = "";
        box.style.top = "";
        return;
      }

      if (!footer) {
        box.style.position = "fixed";
        box.style.top = `${INITIAL_TOP}px`;
        return;
      }

      box.style.position = "fixed";
      const bookingHeight = box.offsetHeight;
      const footerRect = footer.getBoundingClientRect();
      const initialBottom = INITIAL_TOP + bookingHeight;
      const footerTop = footerRect.top;

      if (initialBottom > footerTop - GAP_FROM_FOOTER) {
        const adjustedTop = Math.max(
          -100,
          footerTop - GAP_FROM_FOOTER - bookingHeight
        );
        box.style.top = `${adjustedTop}px`;
      } else {
        box.style.top = `${INITIAL_TOP}px`;
      }
    };

    handleScrollOrResize();
    window.addEventListener("scroll", handleScrollOrResize, { passive: true });
    window.addEventListener("resize", handleScrollOrResize);

    return () => {
      window.removeEventListener("scroll", handleScrollOrResize);
      window.removeEventListener("resize", handleScrollOrResize);
    };
  }, []);

  return (
    <>
      <Box
        sx={{
          px: { xs: "20px", md: "48px" },
          pt: { xs: "24px", md: "32px" },
          pb: 0,
          maxWidth: 1600,
          margin: "0 auto",
          bgcolor: "#EFE7D6",
          fontFamily: "'Inter', system-ui, sans-serif",
        }}
      >
        {/* Breadcrumb */}
        <Box
          sx={{
            display: "flex",
            alignItems: "center",
            gap: 1,
            mb: { xs: 2, sm: 3 },
            flexWrap: "wrap",
          }}
        >
          <IconButton sx={{ color: "#1B2447" }}>
            <ArrowBackIcon />
          </IconButton>

          <Breadcrumbs
            aria-label="breadcrumb"
            sx={{ "& .MuiBreadcrumbs-separator": { color: "#6B7390" } }}
          >
            <Link
              underline="hover"
              href="/"
              sx={{ fontSize: 13, color: "#6B7390", "&:hover": { color: "#1B2447" } }}
            >
              Home
            </Link>
            <Link
              underline="hover"
              href="/property/list"
              sx={{ fontSize: 13, color: "#6B7390", "&:hover": { color: "#1B2447" } }}
            >
              Listings
            </Link>
            <Typography sx={{ fontSize: 13, color: "#1B2447", fontWeight: 500 }}>
              Property Detail
            </Typography>
          </Breadcrumbs>
        </Box>

        {/* Property title — POC: fs 42, lh 1.05, letter-spacing -0.025em */}
        <Box sx={{ mb: { xs: 2, sm: 3 } }}>
          <Typography
            component="h1"
            sx={{
              fontFamily: "'Fraunces', serif",
              fontWeight: 400,
              fontSize: { xs: 28, md: 42 },
              lineHeight: 1.05,
              letterSpacing: "-0.025em",
              color: "#1B2447",
              mb: "12px",
            }}
          >
            Luxury Sea View Apartment
          </Typography>
          <Box sx={{ display: "flex", alignItems: "center", gap: "8px", flexWrap: "wrap" }}>
            {/* Verified pill — POC: padding 4 10, fs 12, success green */}
            <Box
              sx={{
                display: "inline-flex",
                alignItems: "center",
                gap: "5px",
                bgcolor: "rgba(63,107,78,.1)",
                color: "#3F6B4E",
                padding: "4px 10px",
                borderRadius: "999px",
                fontSize: 12,
                fontWeight: 600,
              }}
            >
              <Box sx={{ width: 6, height: 6, borderRadius: "50%", bgcolor: "#3F6B4E" }} />
              Verified
            </Box>
            {/* Action chips — POC: padding 8 12 */}
            {["Share", "Save", "Map"].map((action) => (
              <Box
                key={action}
                sx={{
                  display: "inline-flex",
                  alignItems: "center",
                  padding: "8px 12px",
                  border: "1px solid #D9CFB8",
                  borderRadius: "999px",
                  fontSize: 12,
                  fontWeight: 500,
                  color: "#3D4670",
                  cursor: "pointer",
                  bgcolor: "#FFFAF0",
                  transition: "0.2s",
                  "&:hover": { borderColor: "#1B2447", bgcolor: "rgba(27,36,71,.04)" },
                }}
              >
                {action}
              </Box>
            ))}
          </Box>
        </Box>

        {/* MAIN GRID */}
        <Box
          sx={{
            display: "grid",
            gridTemplateColumns: { xs: "1fr", md: "1.5fr 1fr" },
            gap: { xs: 3, md: 4 },
            alignItems: "flex-start",
            position: "relative",
          }}
        >
          {/* LEFT SECTION */}
          <Box
            sx={{
              display: "flex",
              flexDirection: "column",
              gap: { xs: 2, sm: 3 },
              overflowX: "hidden",
              backgroundColor: "#FFFAF0",
              border: "1px solid #D9CFB8",
              p: { xs: 1.5, sm: 2 },
              borderRadius: "14px",
              boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)",
              mr: { md: 3 },
            }}
          >
            {/* Main Image */}
            <Box
              component="img"
              src="/room1.jpg"
              alt="cover"
              sx={{
                width: "100%",
                height: { xs: 220, sm: 300, md: 400 },
                objectFit: "cover",
                borderRadius: 2,
              }}
            />

            {/* Slick Slider */}
            <Box
              sx={{
                width: "100%",
                overflow: "hidden", // prevent horizontal scroll
                ".slick-slider": { width: "100%" },
                ".slick-slide": { px: 0.5 },
                ".slick-track": { display: "flex", alignItems: "center" },
                mb: 1,
              }}
            >
              <Slider {...sliderSettings}>
                {Roomimages.map((img, i) => (
                  <Box
                    key={i}
                    component="img"
                    src={img}
                    alt={`room${i}`}
                    sx={{
                      width: "100%",
                      height: { xs: 100, sm: 120, md: 140 },
                      objectFit: "cover",
                      borderRadius: 2,
                      cursor: "pointer",
                      transition: "transform 0.3s",
                      "&:hover": { transform: "scale(1.05)" },
                    }}
                  />
                ))}
              </Slider>
            </Box>

            <PropertyBookingBox />
          </Box>

          {/* RIGHT SECTION (Sticky) */}
          <Box ref={bookingBoxRef} className="sticky-booking-box">
            <BookingSection />
          </Box>
        </Box>

        {/* Property Description */}
        <Box
          sx={{
            mt: 5,
            p: { xs: 2, sm: 3 },
            backgroundColor: "#FFFAF0",
            border: "1px solid #D9CFB8",
            borderRadius: "14px",
            boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)",
            maxWidth: { md: "65%" },
          }}
        >
          <Typography
            sx={{
              fontFamily: "'Fraunces', serif",
              fontSize: { xs: 20, sm: 24 },
              fontWeight: 400,
              letterSpacing: "-0.02em",
              color: "#1B2447",
              mb: "16px",
            }}
          >
            Property Description
          </Typography>

          <Typography
            sx={{
              fontSize: { xs: 14, sm: 16 },
              lineHeight: 1.8,
              color: "#6B7390",
              mb: 3,
            }}
          >
            This luxury apartment offers a perfect blend of comfort and
            elegance. Located in the heart of Chennai, it features spacious
            rooms, modern interiors, and access to premium amenities such as a
            swimming pool, parking facilities, and high-speed WiFi.
          </Typography>

          <Button
            variant="outlined"
            sx={{
              borderColor: "#1B2447",
              color: "#1B2447",
              borderRadius: "8px",
              px: 3,
              py: 1,
              fontWeight: 600,
              textTransform: "none",
              "&:hover": { bgcolor: "#1B2447", color: "#fff" },
            }}
            onClick={() => setIsModalOpen(true)}
          >
            Cancellation Policy
          </Button>
        </Box>

        {/* Property Rules */}
        <Box
          sx={{
            mt: 3,
            p: { xs: 2, sm: 3 },
            backgroundColor: "#FFFAF0",
            border: "1px solid #D9CFB8",
            borderRadius: "14px",
            boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)",
            maxWidth: { md: "65%" },
          }}
        >
          <Typography
            sx={{
              fontFamily: "'Fraunces', serif",
              fontSize: { xs: 20, sm: 22 },
              fontWeight: 400,
              letterSpacing: "-0.015em",
              color: "#1B2447",
              mb: "12px",
            }}
          >
            Property Rules
          </Typography>

          {rules.length ? (
            <Box sx={{ display: "flex", flexDirection: "column", gap: 1 }}>
              {rules.map((rule, index) => (
                <Typography
                  key={index}
                  sx={{ fontSize: { xs: 14, sm: 16 }, color: "#6B7390" }}
                >
                  • {rule}
                </Typography>
              ))}
            </Box>
          ) : (
            <Typography
              sx={{ fontSize: 14, color: "#777", fontStyle: "italic" }}
            >
              No rules
            </Typography>
          )}
        </Box>

        {/* Owner + Map */}
        <Box
          sx={{
            mt: 4,
            display: "flex",
            flexDirection: "column",
            gap: 3,
            maxWidth: { md: "65%" },
          }}
        >
          <Box
            sx={{
              p: { xs: 2, sm: 3 },
              backgroundColor: "#fff",
              borderRadius: 2,
              boxShadow: "0px 4px 15px rgba(0,0,0,0.1)",
            }}
          >
            <Typography
              sx={{
                fontFamily: "'Fraunces', serif",
                fontWeight: 400,
                fontSize: 22,
                letterSpacing: "-0.015em",
                color: "#1B2447",
                mb: "16px",
              }}
            >
              Meet your host
            </Typography>

            {/* Host card — POC: avatar 56, meta fs 13 */}
            <Box sx={{ display: "flex", gap: "14px", alignItems: "center", mb: 2 }}>
              <Avatar
                sx={{
                  width: 56,
                  height: 56,
                  bgcolor: "#1B2447",
                  fontSize: 22,
                  fontFamily: "'Fraunces', serif",
                }}
              >
                J
              </Avatar>
              <Box>
                <Typography sx={{ fontWeight: 600, fontSize: 16, color: "#1B2447", lineHeight: 1.2 }}>
                  Mr Joe Doe
                </Typography>
                <Typography sx={{ fontSize: 13, color: "#6B7390", mt: "2px" }}>
                  Host · 5 properties · Member since 2023
                </Typography>
              </Box>
            </Box>

            <Typography sx={{ fontSize: 14, color: "#6B7390", mb: "16px", lineHeight: 1.6 }}>
              Experienced host committed to providing comfortable, clean, and
              memorable stays for every guest.
            </Typography>

            <Box
              sx={{
                display: "inline-flex",
                alignItems: "center",
                gap: "8px",
                padding: "8px 16px",
                border: "1px solid #D9CFB8",
                borderRadius: "10px",
                color: "#1B2447",
                fontWeight: 600,
                fontSize: 13,
                cursor: "pointer",
                bgcolor: "#FFFAF0",
                transition: "0.2s",
                "&:hover": { bgcolor: "#1B2447", color: "#FFFAF0", borderColor: "#1B2447" },
              }}
              onClick={() => setOpen(true)}
            >
              <PermIdentityIcon sx={{ fontSize: 16 }} />
              View Host Profile
            </Box>
          </Box>

          <Box
            sx={{
              minHeight: { xs: 250, sm: 300, md: 350 },
              borderRadius: 2,
              overflow: "hidden",
              boxShadow: "0px 4px 15px rgba(0,0,0,0.1)",
            }}
          >
            <PropDetailMap
              // coordinates={[30.7333, 76.7794]}
              coordinates={[31.1048, 77.1734]}
              // popupText="Property located in Chandigarh"
            />
          </Box>
        </Box>

        {/* <PropertyGallery /> */}
        <PropertyGallery Images={Roomimages || []} />
        <Box
          sx={{
            mt: 5,
            p: { xs: 2, sm: 3 },
            backgroundColor: "#FFFAF0",
            border: "1px solid #D9CFB8",
            borderRadius: "14px",
            boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)",
            maxWidth: { md: "65%" },
          }}
        >
          <Typography
            sx={{
              fontFamily: "'Fraunces', serif",
              fontSize: { xs: 20, sm: 22 },
              fontWeight: 400,
              letterSpacing: "-0.015em",
              color: "#1B2447",
              mb: "16px",
            }}
          >
            Guest Reviews
          </Typography>

          <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
            {reviews.map((review, idx) => (
              <Box
                key={idx}
                sx={{
                  display: "flex",
                  flexDirection: { xs: "column", sm: "row" },
                  alignItems: { xs: "flex-start", sm: "center" },
                  gap: 2,
                  p: 2,
                  borderRadius: 2,
                  backgroundColor: "#FFFAF0",
                  border: "1px solid #D9CFB8",
                }}
              >
                <Avatar sx={{ bgcolor: "#1B2447" }}>
                  {review.name.charAt(0)}
                </Avatar>
                <Box>
                  <Typography sx={{ fontWeight: 600 }}>
                    {review.name}
                  </Typography>
                  <Rating
                    value={review.rating}
                    precision={0.5}
                    readOnly
                    size="small"
                    sx={{ color: "#1B2447", mb: 0.5 }}
                  />
                  <Typography sx={{ fontSize: 14, color: "#6B7390" }}>
                    {review.comment}
                  </Typography>
                </Box>
              </Box>
            ))}
          </Box>
        </Box>

        <ExploreMore />

        <CancellationPolicyModal
          isOpen={isModalOpen}
          onClose={() => setIsModalOpen(false)}
        />
      </Box>
      <HostDetailsModal
        open={open}
        onClose={() => setOpen(false)}
        user={user}
      />
    </>
  );
};

export default PropertyDetail;
