import React, { useState } from "react";
import { Box, Typography, Button, Modal, IconButton } from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import GridViewIcon from "@mui/icons-material/GridView";
import { motion, AnimatePresence } from "framer-motion";

interface PropertyGalleryProps {
  Images?: string[];
}

const PropertyGallery: React.FC<PropertyGalleryProps> = ({ Images = [] }) => {
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
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

      {/* Gallery grid — POC: 2fr 1fr 1fr, height 480, gap 8, radius 18 */}
      <Box
        sx={{
          display: "grid",
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
            onClick={() => setSelectedImage(img)}
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

      {/* Lightbox modal */}
      <AnimatePresence>
        {selectedImage && (
          <Modal
            open={true}
            onClose={() => setSelectedImage(null)}
            sx={{
              display: "flex",
              justifyContent: "center",
              alignItems: "center",
              bgcolor: "rgba(0,0,0,0.88)",
            }}
          >
            <motion.div
              initial={{ opacity: 0, scale: 0.85 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.85 }}
              style={{ position: "relative", outline: "none", maxWidth: "90vw", maxHeight: "90vh" }}
            >
              <IconButton
                onClick={() => setSelectedImage(null)}
                sx={{
                  position: "absolute",
                  top: 8,
                  right: 8,
                  bgcolor: "rgba(0,0,0,0.6)",
                  color: "#fff",
                  "&:hover": { bgcolor: "rgba(0,0,0,0.8)" },
                }}
              >
                <CloseIcon />
              </IconButton>
              <img
                src={selectedImage}
                alt="enlarged"
                style={{ width: "100%", height: "auto", borderRadius: "12px", objectFit: "contain", maxHeight: "90vh" }}
              />
            </motion.div>
          </Modal>
        )}
      </AnimatePresence>
    </Box>
  );
};

export default PropertyGallery;
