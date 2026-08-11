// HostInfo.tsx
import React from "react";
import {
  Box,
  Typography,
  Avatar,
  Button,
  useMediaQuery,
  useTheme,
} from "@mui/material";
// import PersonIcon from "@mui/icons-material/Person";
import PhoneIcon from "@mui/icons-material/Phone";
import EmailIcon from "@mui/icons-material/Email";
import HomeIcon from "@mui/icons-material/Home";
import WhatsAppIcon from "@mui/icons-material/WhatsApp";

interface HostInfoProps {
  host?: {
    name?: string;
    phone?: string;
    email?: string;
    address?: string;
    image?: string;
  };
}

const HostInfo: React.FC<HostInfoProps> = ({ host = {} }) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  // Real host data only — no fabricated fallbacks.
  const {
    name = "Your Host",
    phone = "",
    email = "",
    address = "",
    image = "",
  } = host;

  // wa.me needs digits only (with country code).
  const waNumber = phone.replace(/[^\d]/g, "");

  return (
    <Box
      sx={{
        flex: 1,
        minWidth: 280,
        p: 2.5,
        borderRadius: 3,
        background: "#FFFAF0",
        boxShadow: "0 6px 18px rgba(27,36,71, 0.06)",
      }}
    >
      <Typography
        variant="h6"
        sx={{
          fontWeight: 700,
          color: "#1B2447",
          mb: 2,
          fontFamily: "'Inter', sans-serif",
        }}
      >
        Meet your host
      </Typography>

      <Box sx={{ display: "flex", gap: 2, alignItems: "center", mb: 2 }}>
        <Avatar
          src={image}
          sx={{
            width: 72,
            height: 72,
            border: "3px solid #1B2447",
            boxShadow: "0 6px 18px rgba(0,0,0,0.12)",
          }}
        />
        <Box>
          <Typography sx={{ fontWeight: 700 }}>{name}</Typography>
          <Typography sx={{ color: "text.secondary", fontSize: "0.85rem" }}>
            Verified Aajoo Host
          </Typography>
        </Box>
      </Box>

      <Box sx={{ display: "flex", flexDirection: "column", gap: 1.25 }}>
        {phone && (
          <Box sx={{ display: "flex", gap: 1, alignItems: "center" }}>
            <PhoneIcon sx={{ color: "#4caf50", fontSize: 20 }} />
            <Typography sx={{ fontWeight: 600 }}>{phone}</Typography>
          </Box>
        )}

        {email && (
          <Box sx={{ display: "flex", gap: 1, alignItems: "center" }}>
            <EmailIcon sx={{ color: "#1976d2", fontSize: 20 }} />
            <Typography sx={{ fontWeight: 600 }}>{email}</Typography>
          </Box>
        )}

        {address && (
          <Box sx={{ display: "flex", gap: 1, alignItems: "center" }}>
            <HomeIcon sx={{ color: "#ff9800", fontSize: 20 }} />
            <Typography sx={{ fontWeight: 600 }}>{address}</Typography>
          </Box>
        )}
      </Box>

      <Box
        sx={{
          display: "flex",
          gap: 1.25,
          mt: 2.25,
          flexDirection: isMobile ? "column" : "row",
        }}
      >
        <Button
          variant="contained"
          href={phone ? `tel:${phone}` : undefined}
          disabled={!phone}
          sx={{
            bgcolor: "#4caf50",
            "&:hover": { bgcolor: "#3b9c43" },
            textTransform: "none",
            px: 2.5,
            py: 0.7,
            fontWeight: 700,
            borderRadius: 2,
            minWidth: 130,
          }}
          startIcon={<PhoneIcon />}
        >
          Call
        </Button>

        {/* Chat directly with the host on WhatsApp */}
        <Button
          variant="contained"
          disabled={!waNumber}
          sx={{
            bgcolor: "#25D366",
            "&:hover": { bgcolor: "#1ebe5d" },
            color: "#fff",
            textTransform: "none",
            px: 2.5,
            py: 0.7,
            fontWeight: 700,
            borderRadius: 2,
            minWidth: 130,
          }}
          startIcon={<WhatsAppIcon />}
          onClick={() =>
            window.open(
              `https://wa.me/${waNumber}?text=${encodeURIComponent(
                "Hi! I have a booking with you on Aajoo Homes."
              )}`,
              "_blank"
            )
          }
        >
          WhatsApp
        </Button>
      </Box>
    </Box>
  );
};

export default HostInfo;
