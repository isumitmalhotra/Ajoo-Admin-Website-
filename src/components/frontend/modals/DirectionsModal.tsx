import React from "react";
import { Modal, Box, Typography, IconButton, Button } from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import OpenInNewIcon from "@mui/icons-material/OpenInNew";

interface DirectionsModalProps {
  open: boolean;
  onClose: () => void;
  destination: { lat?: number; lng?: number; label?: string };
  userLocation?: { lat: number; lng: number } | null;
}

/**
 * Shows directions to the property INSIDE the app (embedded Google map) rather
 * than bouncing the user out to an external maps tab.
 */
const DirectionsModal: React.FC<DirectionsModalProps> = ({
  open,
  onClose,
  destination,
  userLocation,
}) => {
  const dest =
    destination.lat != null && destination.lng != null
      ? `${destination.lat},${destination.lng}`
      : encodeURIComponent(destination.label || "Aajoo Property");

  // output=embed renders a map (and a route when saddr/daddr are set) with no API key.
  const embedSrc = userLocation
    ? `https://maps.google.com/maps?saddr=${userLocation.lat},${userLocation.lng}&daddr=${dest}&output=embed`
    : `https://maps.google.com/maps?q=${dest}&output=embed`;

  const externalHref = userLocation
    ? `https://www.google.com/maps/dir/${userLocation.lat},${userLocation.lng}/${dest}`
    : `https://www.google.com/maps/search/?api=1&query=${dest}`;

  return (
    <Modal
      open={open}
      onClose={onClose}
      sx={{
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        backdropFilter: "blur(6px)",
        zIndex: 1500,
        p: 2,
      }}
    >
      <Box
        sx={{
          width: { xs: "96vw", sm: "90vw" },
          maxWidth: 760,
          bgcolor: "#fff",
          borderRadius: 3,
          overflow: "hidden",
          boxShadow: "0 14px 50px rgba(0,0,0,0.25)",
          outline: "none",
        }}
      >
        <Box
          sx={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            px: 2.5,
            py: 1.5,
            borderBottom: "1px solid #EFE7D6",
          }}
        >
          <Typography sx={{ fontWeight: 700, color: "#1B2447" }}>
            Directions{destination.label ? ` · ${destination.label}` : ""}
          </Typography>
          <IconButton onClick={onClose} size="small" sx={{ color: "#1B2447" }}>
            <CloseIcon />
          </IconButton>
        </Box>

        <Box sx={{ width: "100%", height: { xs: "60vh", sm: 460 } }}>
          <iframe
            title="directions"
            src={embedSrc}
            width="100%"
            height="100%"
            style={{ border: 0 }}
            loading="lazy"
            referrerPolicy="no-referrer-when-downgrade"
          />
        </Box>

        <Box sx={{ p: 2, display: "flex", justifyContent: "flex-end" }}>
          <Button
            href={externalHref}
            target="_blank"
            rel="noreferrer"
            startIcon={<OpenInNewIcon />}
            sx={{
              textTransform: "none",
              color: "#1B2447",
              fontWeight: 600,
            }}
          >
            Open in Google Maps
          </Button>
        </Box>
      </Box>
    </Modal>
  );
};

export default DirectionsModal;
