import { Box, Stack, Typography, Chip } from "@mui/material";
import { Plug, CreditCard, Mail, BadgeCheck, ImageIcon } from "lucide-react";
import type { LucideIcon } from "lucide-react";
import SettingsSection from "./SettingsSection";

// TODO(BE): drive `connected` from a live /admin/settings/integrations health
// probe. Razorpay (A-09), email (A-10) and Didit KYC (A-12) go live mid-sprint.
type Integration = {
  key: string;
  name: string;
  desc: string;
  icon: LucideIcon;
  connected: boolean;
};

const INTEGRATIONS: Integration[] = [
  {
    key: "razorpay",
    name: "Razorpay",
    desc: "Payment gateway for guest checkout and host payouts.",
    icon: CreditCard,
    connected: false,
  },
  {
    key: "email",
    name: "Email (Brevo)",
    desc: "Transactional email + OTP delivery via HTTP API.",
    icon: Mail,
    connected: false,
  },
  {
    key: "didit",
    name: "Didit KYC",
    desc: "Identity verification for hosts and guests.",
    icon: BadgeCheck,
    connected: false,
  },
  {
    key: "cloudinary",
    name: "Cloudinary",
    desc: "Image hosting and transformation for listings.",
    icon: ImageIcon,
    connected: true,
  },
];

const IntegrationsTab = () => {
  return (
    <SettingsSection
      icon={Plug}
      title="Integrations"
      subtitle="Third-party services powering payments, messaging and verification."
    >
      <Stack spacing={1.25}>
        {INTEGRATIONS.map((it) => {
          const Icon = it.icon;
          return (
            <Box
              key={it.key}
              sx={{
                display: "flex",
                alignItems: "center",
                gap: 1.5,
                p: 1.5,
                borderRadius: "0.85rem",
                border: "1px solid #e5e7eb",
                bgcolor: "#ffffff",
              }}
            >
              <Box
                sx={{
                  width: 36,
                  height: 36,
                  borderRadius: "0.65rem",
                  bgcolor: "#f5f3ff",
                  display: "grid",
                  placeItems: "center",
                  flexShrink: 0,
                }}
              >
                <Icon size={17} color="#1B2447" />
              </Box>
              <Box sx={{ flex: 1, minWidth: 0 }}>
                <Typography variant="body2" fontWeight={700} color="#111827">
                  {it.name}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {it.desc}
                </Typography>
              </Box>
              <Chip
                label={it.connected ? "Connected" : "Not configured"}
                size="small"
                sx={
                  it.connected
                    ? { bgcolor: "#dcfce7", color: "#166534", fontWeight: 700, border: "1px solid #bbf7d0" }
                    : { bgcolor: "#fff7ed", color: "#9a3412", fontWeight: 700, border: "1px solid #fed7aa" }
                }
              />
            </Box>
          );
        })}
      </Stack>
    </SettingsSection>
  );
};

export default IntegrationsTab;
