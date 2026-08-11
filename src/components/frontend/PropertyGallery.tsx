import React, { useState } from "react";
import { Box, Typography, Button, Modal, IconButton } from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import GridViewIcon from "@mui/icons-material/GridView";
import Slider from "react-slick";

interface PropertyGalleryProps {
  Images?: string[];
}

const PropertyGallery: React.FC<PropertyGalleryProps> = ({ Images = [] }) => {
  // null = closed; otherwise the index the lightbox slider opens on.
  const [lightboxIndex, setLightboxIndex] = useState<number | null>(null);
  const [showAll, setShowAll] = useState(false);

  if (!Array.isArray(Images) || Images.length === 0) return null;

  const displayed = showAll ? Images : Images.slice(0, 3);

  return (
    <Box sx={{ mt: 5, maxWidth: { md: "65%" } }}>
      {/* Section heading */}
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          mb: "16px",
        }}
      >
        <Typography
          sx={{
            fontFamily: "'Fraunces', serif",
            fontSize: { xs: 20, sm: 24 },
            fontWeight: 400,
            letterSpacing: "-0.02em",
            color: "#1B2447",
          }}
        >
          Property Gallery
        </Typography>

        {/* Show-all CTA — POC: padding 8 14, fs 12, radius 8 */}
        {Images.length > 3 && !showAll && (
          <Button
            onClick={() => setShowAll(true)}
            startIcon={<GridViewIcon sx={{ fontSize: 14 }} />}
            sx={{
              padding: "8px 14px",
              fontSize: 12,
              fontWeight: 600,
              borderRadius: "8px",
              border: "1px solid #D9CFB8",
              bgcolor: "#FFFAF0",
              color: "#1B2447",
              textTransform: "none",
              "&:hover": { bgcolor: "#EFE7D6", borderColor: "#1B2447" },
            }}
          >
            Show all {Images.length} photos
          </Button>
        )}
      </Box>

      {/* Mobile: swipeable gallery slider */}
      <Box
        sx={{
          display: { xs: "block", sm: "none" },
          "& .slick-dots": { bottom: 8 },
          "& .slick-dots li button:before": { color: "#FFFAF0", opacity: 0.6, fontSize: 9 },
          "& .slick-dots li.slick-active button:before": { color: "#C16345", opacity: 1 },
        }}
      >
        <Slider dots arrows={false} infinite={Images.length > 1} speed={350} slidesToShow={1} slidesToScroll={1}>
          {Images.map((img, i) => (
            <Box
              key={i}
              component="img"
              src={img}
              alt={`gallery-${i}`}
              onClick={() => setLightboxIndex(i)}
              sx={{ width: "100%", height: 240, objectFit: "cover", borderRadius: 2, cursor: "pointer" }}
            />
          ))}
        </Slider>
      </Box>

      {/* Desktop: gallery grid — POC: 2fr 1fr 1fr, height 480, gap 8, radius 18 */}
      <Box
        sx={{
          display: { xs: "none", sm: "grid" },
          gridTemplateColumns: showAll
            ? { xs: "repeat(2, 1fr)", sm: "repeat(3, 1fr)" }
            : { xs: "repeat(2, 1fr)", md: "2fr 1fr 1fr" },
          gridTemplateRows: showAll ? "auto" : { md: "1fr 1fr" },
          height: showAll ? "auto" : { xs: "auto", md: "480px" },
          gap: "8px",
          borderRadius: "18px",
          overflow: "hidden",
        }}
      >
        {displayed.map((img, i) => (
          <Box
            key={i}
            onClick={() => setLightboxIndex(i)}
            sx={{
              position: "relative",
              overflow: "hidden",
              gridRow: (!showAll && i === 0) ? { md: "1 / 3" } : undefined,
              cursor: "pointer",
              bgcolor: "#D9CFB8",
              minHeight: { xs: 120, md: "auto" },
              "&:hover img": { transform: "scale(1.04)" },
            }}
          >
            <Box
              component="img"
              src={img}
              alt={`gallery-${i}`}
              sx={{
                width: "100%",
                height: "100%",
                objectFit: "cover",
                display: "block",
                transition: "transform 0.4s ease",
              }}
            />
            {/* Show-all overlay on last visible image */}
            {!showAll && i === 2 && Images.length > 3 && (
              <Box
                sx={{
                  position: "absolute",
                  inset: 0,
                  bgcolor: "rgba(27,36,71,0.55)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                }}
              >
                <Typography sx={{ color: "#fff", fontWeight: 600, fontSize: 14 }}>
                  +{Images.length - 3} more
                </Typography>
              </Box>
            )}
          </Box>
        ))}
      </Box>

      {/* Lightbox — ALL images in a swipeable slider, opening on the clicked one */}
      <Modal
        open={lightboxIndex !== null}
        onClose={() => setLightboxIndex(null)}
        sx={{
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
          bgcolor: "rgba(0,0,0,0.92)",
        }}
      >
        <Box
          sx={{
            position: "relative",
            width: "94vw",
            maxWidth: 920,
            outline: "none",
            "& .slick-prev, & .slick-next": { zIndex: 2, width: 40, height: 40 },
            "& .slick-prev": { left: 8 },
            "& .slick-next": { right: 8 },
            "& .slick-prev:before, & .slick-next:before": { fontSize: 34, opacity: 0.9 },
            "& .slick-dots li button:before": { color: "#fff", opacity: 0.5 },
            "& .slick-dots li.slick-active button:before": { color: "#C16345", opacity: 1 },
          }}
        >
          <IconButton
            onClick={() => setLightboxIndex(null)}
            sx={{
              position: "absolute",
              top: -48,
              right: 0,
              zIndex: 3,
              bgcolor: "rgba(255,255,255,0.15)",
              color: "#fff",
              "&:hover": { bgcolor: "rgba(255,255,255,0.3)" },
            }}
          >
            <CloseIcon />
          </IconButton>

          {lightboxIndex !== null && (
            <Slider
              initialSlide={lightboxIndex}
              dots
              infinite={Images.length > 1}
              arrows={Images.length > 1}
              speed={350}
              slidesToShow={1}
              slidesToScroll={1}
            >
              {Images.map((img, i) => (
                <Box key={i} sx={{ outline: "none" }}>
                  <Box
                    component="img"
                    src={img}
                    alt={`gallery-${i}`}
                    sx={{
                      width: "100%",
                      maxHeight: "82vh",
                      objectFit: "contain",
                      borderRadius: "12px",
                    }}
                  />
                </Box>
              ))}
            </Slider>
          )}
        </Box>
      </Modal>
    </Box>
  );
};

export default PropertyGallery;
