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
  CircularProgress,
} from "@mui/material";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
// import PhoneIcon from "@mui/icons-material/Phone";
import PermIdentityIcon from "@mui/icons-material/PermIdentity";
import VerifiedIcon from "@mui/icons-material/Verified";
import LocalCafeIcon from "@mui/icons-material/LocalCafe";
import RestaurantIcon from "@mui/icons-material/Restaurant";
import HikingIcon from "@mui/icons-material/Hiking";
import LocalMallIcon from "@mui/icons-material/LocalMall";
import CameraAltIcon from "@mui/icons-material/CameraAlt";
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
  AmenitiesGrid,
} from "../../components";
import { sliderSettings } from "../../styles/utils/reusableData";
import { useParams } from "react-router-dom";
import {
  getProperty,
  getPropertyReviews,
  getHostProfile,
  type ApiProperty,
} from "../../services/customerApi";
import storage from "../../styles/utils/storage";

interface ReviewItem {
  name: string;
  rating: number;
  comment: string;
}

interface HostProfile {
  name: string;
  image: string | null;
  city: string | null;
  propertyCount: number;
  memberSince: number | null;
}

export const PropertyDetail: React.FC = () => {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [open, setOpen] = useState(false);

  // Real property — GET /properties/:propId
  const { id } = useParams();
  const [property, setProperty] = useState<ApiProperty | null>(null);
  const [loadingProperty, setLoadingProperty] = useState(true);
  const [notFound, setNotFound] = useState(false);

  // Real guest reviews — POST /properties/reviews/list (auth required).
  const [reviewsList, setReviewsList] = useState<ReviewItem[]>([]);
  // Real host profile — GET /properties/host/:hostId (auth required).
  const [host, setHost] = useState<HostProfile | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoadingProperty(true);
      setNotFound(false);
      try {
        const p = await getProperty(id || "");
        if (cancelled) return;
        if (!p) setNotFound(true);
        else setProperty(p);
      } catch {
        if (!cancelled) setNotFound(true);
      } finally {
        if (!cancelled) setLoadingProperty(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [id]);

  // Reviews require authentication; only fetch when a token exists so anonymous
  // visitors don't trip the global 401 → redirect interceptor.
  useEffect(() => {
    if (!id || !storage.getToken()) return;
    let cancelled = false;
    (async () => {
      try {
        const rows = await getPropertyReviews(id);
        if (cancelled) return;
        setReviewsList(
          rows.map((r: any) => ({
            name:
              r["userReview.user_fullName"] ||
              r.userReview?.user_fullName ||
              "Guest",
            rating: Number(r.br_rating) || 0,
            comment: r.br_desc || "",
          }))
        );
      } catch {
        // leave reviews empty on failure
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [id]);

  // Host profile — fetched once the property (and its host id) is known.
  const hostId = property?.property_host_id;
  useEffect(() => {
    if (!hostId || !storage.getToken()) return;
    let cancelled = false;
    (async () => {
      try {
        const h = await getHostProfile(hostId);
        if (cancelled || !h) return;
        setHost({
          name: h.name || "Host",
          image: h.image ?? null,
          city: h.city ?? null,
          propertyCount: Number(h.propertyCount) || 0,
          memberSince: h.memberSince ?? null,
        });
      } catch {
        // leave host null → falls back to neutral display
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [hostId]);

  // Derived view values (real data with safe fallbacks)
  const title = property?.property_name || "Property";
  const heroImage =
    property?.coverImage ||
    (property?.images && property.images.length > 0 ? property.images[0] : "") ||
    "/room1.jpg";
  const galleryImages =
    property?.images && property.images.length > 0 ? property.images : Roomimages;
  const description =
    property?.property_desc || "No description provided for this property.";
  const amenitiesList = (property?.amenities as string[] | undefined) || [];
  const detailPrice = Number(property?.property_price) || 0;
  const detailLat = Number(property?.property_latitude) || 31.1048;
  const detailLng = Number(property?.property_longitude) || 77.1734;
  const [rules] = useState<string[]>([
    "No smoking inside the property.",
    "Pets are not allowed.",
    "Please respect quiet hours after 10 PM.",
  ]);
  // Host identity now comes from GET /properties/host/:hostId. Phone/contact
  // stays from the property record (the public host profile omits it by design).
  const hostContact =
    (property?.property_contact as string) ||
    (property?.property_phone as string) ||
    "";
  const hostName = host?.name || "Your Host";
  const hostImage = host?.image || "";
  const hostPropertyCount = host?.propertyCount ?? 0;
  const hostMemberSince = host?.memberSince ?? null;
  const hostSubtitle = [
    "Verified Aajoo Host",
    hostPropertyCount > 0
      ? `${hostPropertyCount} ${hostPropertyCount === 1 ? "property" : "properties"}`
      : null,
    hostMemberSince ? `Member since ${hostMemberSince}` : null,
  ]
    .filter(Boolean)
    .join(" · ");
  const user = {
    name: hostName,
    image: hostImage,
    contact: hostContact,
    address: host?.city || (property?.property_address as string) || "",
    propertyCount: hostPropertyCount,
    // Host profile API doesn't expose a rating yet — use the property's rating
    // as a stand-in so the host card can show one.
    rating: Number(property?.property_rating) || 4.8,
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

  if (loadingProperty) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", alignItems: "center", minHeight: "60vh", bgcolor: "#EFE7D6" }}>
        <CircularProgress sx={{ color: "#1B2447" }} />
      </Box>
    );
  }

  if (notFound) {
    return (
      <Box sx={{ textAlign: "center", py: "120px", bgcolor: "#EFE7D6", minHeight: "60vh" }}>
        <Typography sx={{ fontFamily: "'Fraunces', serif", fontSize: 28, color: "#1B2447", mb: 1 }}>
          Property not found
        </Typography>
        <Typography sx={{ fontSize: 14, color: "#6B7390" }}>
          This stay may have been removed. Browse other properties from the listings.
        </Typography>
      </Box>
    );
  }

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
            {title}
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
            {/* Mobile: single swipeable image slider */}
            <Box
              sx={{
                display: { xs: "block", sm: "none" },
                width: "100%",
                "& .slick-dots": { bottom: 8 },
                "& .slick-dots li button:before": { color: "#FFFAF0", opacity: 0.6, fontSize: 9 },
                "& .slick-dots li.slick-active button:before": { color: "#C16345", opacity: 1 },
              }}
            >
              <Slider dots arrows={false} infinite speed={400} slidesToShow={1} slidesToScroll={1}>
                {galleryImages.map((img, i) => (
                  <Box
                    key={i}
                    component="img"
                    src={img}
                    alt={`${title} ${i + 1}`}
                    sx={{ width: "100%", height: 260, objectFit: "cover", borderRadius: 2 }}
                  />
                ))}
              </Slider>
            </Box>

            {/* Desktop: hero image + thumbnail strip */}
            <Box sx={{ display: { xs: "none", sm: "block" } }}>
              <Box
                component="img"
                src={heroImage}
                alt={title}
                sx={{
                  width: "100%",
                  height: { sm: 300, md: 400 },
                  objectFit: "cover",
                  borderRadius: 2,
                  mb: 2,
                }}
              />
              <Box
                sx={{
                  width: "100%",
                  overflow: "hidden",
                  ".slick-slider": { width: "100%" },
                  ".slick-slide": { px: 0.5 },
                  ".slick-track": { display: "flex", alignItems: "center" },
                  mb: 1,
                }}
              >
                <Slider {...sliderSettings}>
                  {galleryImages.map((img, i) => (
                    <Box
                      key={i}
                      component="img"
                      src={img}
                      alt={`room${i}`}
                      sx={{
                        width: "100%",
                        height: { sm: 120, md: 140 },
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
            </Box>

            <PropertyBookingBox
              price={detailPrice}
              title={title}
              location={
                (property?.property_address as string) ||
                (property?.property_city as string) ||
                ""
              }
              categories={(property?.category_titles as string[]) || []}
              rating={Number(property?.property_rating) || 0}
            />
          </Box>

          {/* RIGHT SECTION (Sticky) */}
          <Box ref={bookingBoxRef} className="sticky-booking-box">
            <BookingSection
              price={detailPrice}
              propertyId={property?.property_id}
              propertyName={title}
              propertyAddress={
                (property?.property_address as string) ||
                (property?.property_city as string) ||
                ""
              }
              propertyImage={heroImage}
              propertyImages={galleryImages}
            />
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
            {description}
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

        {/* What this place offers (Amenities) */}
        <Box sx={{ mt: 3 }}>
          <AmenitiesGrid amenities={amenitiesList} />
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
                src={hostImage || undefined}
                sx={{
                  width: 56,
                  height: 56,
                  bgcolor: "#1B2447",
                  fontSize: 22,
                  fontFamily: "'Fraunces', serif",
                }}
              >
                {hostName.charAt(0).toUpperCase()}
              </Avatar>
              <Box>
                <Typography sx={{ fontWeight: 600, fontSize: 16, color: "#1B2447", lineHeight: 1.2 }}>
                  {hostName}
                </Typography>
                <Typography sx={{ fontSize: 13, color: "#6B7390", mt: "2px" }}>
                  {hostSubtitle}
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
            <PropDetailMap coordinates={[detailLat, detailLng]} />
          </Box>
        </Box>

        {/* Explore places near this property — recommended by host */}
        <Box
          sx={{
            mt: 4,
            p: { xs: 2, sm: 3 },
            backgroundColor: "#FFFAF0",
            border: "1px solid #D9CFB8",
            borderRadius: "14px",
            boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)",
            maxWidth: { md: "65%" },
          }}
        >
          <Box sx={{ display: "flex", alignItems: "center", flexWrap: "wrap", gap: 1, mb: "6px" }}>
            <Typography
              sx={{
                fontFamily: "'Fraunces', serif",
                fontSize: { xs: 20, sm: 22 },
                fontWeight: 400,
                letterSpacing: "-0.015em",
                color: "#1B2447",
              }}
            >
              Explore places nearby
            </Typography>
            <Box
              sx={{
                display: "inline-flex",
                alignItems: "center",
                gap: "4px",
                bgcolor: "rgba(63,107,78,.1)",
                color: "#3F6B4E",
                padding: "3px 10px",
                borderRadius: "999px",
                fontSize: 11,
                fontWeight: 600,
              }}
            >
              <VerifiedIcon sx={{ fontSize: 14 }} />
              Recommended by host
            </Box>
          </Box>
          <Typography sx={{ fontSize: 14, color: "#6B7390", mb: "18px" }}>
            Cafés, food, shopping and treks the host loves around this stay
          </Typography>

          <Box
            sx={{
              display: "flex",
              gap: { xs: "12px", md: "16px" },
              overflowX: "auto",
              pb: "6px",
              scrollbarWidth: "none",
              "&::-webkit-scrollbar": { display: "none" },
            }}
          >
            {[
              { label: "Cafés", icon: <LocalCafeIcon /> },
              { label: "Restaurants", icon: <RestaurantIcon /> },
              { label: "Treks", icon: <HikingIcon /> },
              { label: "Shopping", icon: <LocalMallIcon /> },
              { label: "Sightseeing", icon: <CameraAltIcon /> },
            ].map((p) => (
              <Box
                key={p.label}
                sx={{
                  flexShrink: 0,
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: "10px",
                  minWidth: { xs: "92px", md: "110px" },
                  padding: { xs: "14px 12px", md: "18px 16px" },
                  borderRadius: "16px",
                  bgcolor: "#fff",
                  border: "1px solid #D9CFB8",
                  transition: "0.2s",
                  "&:hover": { transform: "translateY(-3px)", borderColor: "#1B2447" },
                }}
              >
                <Box
                  sx={{
                    width: 46,
                    height: 46,
                    borderRadius: "14px",
                    display: "grid",
                    placeItems: "center",
                    bgcolor: "rgba(27,36,71,.06)",
                    color: "#1B2447",
                    "& svg": { fontSize: 24 },
                  }}
                >
                  {p.icon}
                </Box>
                <Typography sx={{ fontSize: 13, fontWeight: 600, color: "#3D4670", whiteSpace: "nowrap" }}>
                  {p.label}
                </Typography>
              </Box>
            ))}
          </Box>
        </Box>

        {/* <PropertyGallery /> */}
        <PropertyGallery Images={galleryImages} />
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
            {reviewsList.length === 0 ? (
              <Typography sx={{ fontSize: 14, color: "#6B7390", fontStyle: "italic" }}>
                No reviews yet. Be the first to share your experience after your stay.
              </Typography>
            ) : (
              reviewsList.map((review, idx) => (
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
              ))
            )}
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
