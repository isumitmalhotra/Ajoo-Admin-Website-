import type { ReactNode } from "react";
import { Paper, Stack, Box, Typography } from "@mui/material";
import type { LucideIcon } from "lucide-react";

type SettingsSectionProps = {
  icon: LucideIcon;
  title: string;
  subtitle?: string;
  children: ReactNode;
};

/**
 * Shared surface for a group of settings controls — keeps every tab visually
 * consistent with the Sand & Indigo admin theme.
 */
const SettingsSection = ({ icon: Icon, title, subtitle, children }: SettingsSectionProps) => {
  return (
    <Paper
      sx={{
        p: 2.5,
        borderRadius: "1rem",
        border: "1px solid #ede9fe",
        boxShadow: "0 12px 28px rgba(17,24,39,0.06)",
      }}
    >
      <Stack direction="row" spacing={1.5} alignItems="flex-start" mb={2}>
        <Box
          sx={{
            width: 38,
            height: 38,
            borderRadius: "0.7rem",
            bgcolor: "#f5f3ff",
            display: "grid",
            placeItems: "center",
            flexShrink: 0,
          }}
        >
          <Icon size={18} color="#1B2447" />
        </Box>
        <Box>
          <Typography variant="h6" fontWeight={700} color="#111827" sx={{ lineHeight: 1.2 }}>
            {title}
          </Typography>
          {subtitle && (
            <Typography variant="body2" color="text.secondary" sx={{ mt: 0.25 }}>
              {subtitle}
            </Typography>
          )}
        </Box>
      </Stack>

      <Box>{children}</Box>
    </Paper>
  );
};

export default SettingsSection;
