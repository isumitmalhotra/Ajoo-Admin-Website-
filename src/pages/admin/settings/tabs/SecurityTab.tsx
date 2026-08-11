import { Box, Stack, Typography, TextField, MenuItem, Switch, FormControlLabel } from "@mui/material";
import { ShieldCheck } from "lucide-react";
import SettingsSection from "./SettingsSection";

// TODO(BE): wire to /admin/settings/security. RBAC roles arrive with A-13 (JWT
// role claim) and FE guards with B-12 — this tab only previews the controls.
const SecurityTab = () => {
  return (
    <Stack spacing={2.5}>
      <SettingsSection
        icon={ShieldCheck}
        title="Authentication"
        subtitle="Session lifetime and sign-in protections for admin users."
      >
        <Box
          sx={{
            display: "grid",
            gridTemplateColumns: { xs: "1fr", sm: "1fr 1fr" },
            gap: 2,
          }}
        >
          <TextField
            label="Session timeout"
            defaultValue="60"
            size="small"
            select
            fullWidth
          >
            <MenuItem value="30">30 minutes</MenuItem>
            <MenuItem value="60">1 hour</MenuItem>
            <MenuItem value="240">4 hours</MenuItem>
            <MenuItem value="1440">24 hours</MenuItem>
          </TextField>
          <TextField
            label="Minimum password length"
            defaultValue="8"
            type="number"
            size="small"
            fullWidth
          />
        </Box>

        <Stack spacing={0.5} mt={1.5}>
          <FormControlLabel
            control={<Switch defaultChecked={false} />}
            label={
              <Box>
                <Typography variant="body2" fontWeight={600} color="#374151">
                  Require two-factor authentication
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Admins must verify a second factor on every new device.
                </Typography>
              </Box>
            }
          />
          <FormControlLabel
            control={<Switch defaultChecked />}
            label={
              <Box>
                <Typography variant="body2" fontWeight={600} color="#374151">
                  Enforce strong passwords
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Require a mix of upper, lower, number and symbol.
                </Typography>
              </Box>
            }
          />
        </Stack>
      </SettingsSection>
    </Stack>
  );
};

export default SecurityTab;
