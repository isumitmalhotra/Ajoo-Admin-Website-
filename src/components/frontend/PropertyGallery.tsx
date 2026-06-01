import React, { useState } from "react";
import {
  Box,
  Typography,
  Modal,
  IconButton,
  useMediaQuery,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import { motion, AnimatePresence } from "framer-motion";

interface PropertyGalleryProps {
  Images?: string[];
}

const PropertyGallery: React.FC<PropertyGalleryProps> = ({ Images = [] }) => {
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const isMobile = useMediaQuery("(max-width:600px)");

  if (!Array.isArray(Images) || Images.length === 0) return null;

  return (
    <Box
      sx={{
        mt: 5,
        p: { xs: 2, sm: 3 },
        backgroundColor: "#fff",
        borderRadius: 2,
        boxShadow: "0px 4px 12px rgba(0,0,0,0.08)",
        maxWidth: { md: "65%" },
        ml: 0, // 👈 left aligned, no margin
      }}
    >
      <Typography
        sx={{
          fontSize: { xs: 20, sm: 22 },
          fontWeight: 700,
          color: "#1B2447",
          mb: 3,
        }}
      >
        Property Gallery
      </Typography>

      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: {
            xs: "repeat(2, 1fr)",
            sm: "repeat(3, 1fr)",
          },
          gap: 1.5,
        }}
      >
        {Images.map((img, i) => (
          <Box
            key={i}
            component="img"
            src={img}
            alt={`property-${i}`}
            onClick={() => setSelectedImage(img)}
            sx={{
              width: "100%",
              height: isMobile ? 120 : 150,
              borderRadius: 2,
              objectFit: "cover",
              cursor: "pointer",
              transition: "transform 0.3s",
              "&:hover": { transform: "scale(1.05)" },
            }}
          />
        ))}
      </Box>

      <AnimatePresence>
        {selectedImage && (
          <Modal
            open={true}
            onClose={() => setSelectedImage(null)}
            aria-labelledby="property-image-modal"
            sx={{
              display: "flex",
              justifyContent: "center",
              alignItems: "center",
              backgroundColor: "rgba(0,0,0,0.85)",
            }}
          >
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.8 }}
              style={{
                position: "relative",
                outline: "none",
                maxWidth: "90vw",
                maxHeight: "90vh",
              }}
            >
              <IconButton
                onClick={() => setSelectedImage(null)}
                sx={{
                  position: "absolute",
                  top: 8,
                  right: 8,
                  backgroundColor: "rgba(0,0,0,0.6)",
                  color: "#fff",
                  "&:hover": { backgroundColor: "rgba(0,0,0,0.8)" },
                }}
              >
                <CloseIcon />
              </IconButton>

              <img
                src={selectedImage}
                alt="enlarged"
                style={{
                  width: "100%",
                  height: "auto",
                  borderRadius: "12px",
                  objectFit: "contain",
                  maxHeight: "90vh",
                }}
              />
            </motion.div>
          </Modal>
        )}
      </AnimatePresence>
    </Box>
  );
};

export default PropertyGallery;
