import { Box, Stack, Typography, TextField, MenuItem, Switch, FormControlLabel } from "@mui/material";
import { Globe } from "lucide-react";
import SettingsSection from "./SettingsSection";

// TODO(BE): wire these fields to GET/PUT /admin/settings/platform once the
// backend settings endpoints land (not in B-01 scope — placeholder UI only).
const PlatformTab = () => {
  return (
    <Stack spacing={2.5}>
      <SettingsSection
        icon={Globe}
        title="Platform"
        subtitle="Branding, locale and availability of the AajooHomes platform."
      >
        <Box
          sx={{
            display: "grid",
            gridTemplateColumns: { xs: "1fr", sm: "1fr 1fr" },
            gap: 2,
          }}
        >
          <TextField
            label="Platform name"
            defaultValue="AajooHomes"
            size="small"
            fullWidth
          />
          <TextField
            label="Support email"
            defaultValue="support@aajoohomes.com"
            size="small"
            fullWidth
          />
          <TextField
            label="Default currency"
            defaultValue="INR"
            size="small"
            select
            fullWidth
          >
            <MenuItem value="INR">INR — Indian Rupee</MenuItem>
            <MenuItem value="USD">USD — US Dollar</MenuItem>
          </TextField>
          <TextField
            label="Timezone"
            defaultValue="Asia/Kolkata"
            size="small"
            select
            fullWidth
          >
            <MenuItem value="Asia/Kolkata">Asia/Kolkata (IST)</MenuItem>
            <MenuItem value="UTC">UTC</MenuItem>
          </TextField>
        </Box>

        <FormControlLabel
          sx={{ mt: 1 }}
          control={<Switch defaultChecked={false} />}
          label={
            <Box>
              <Typography variant="body2" fontWeight={600} color="#374151">
                Maintenance mode
              </Typography>
              <Typography variant="caption" color="text.secondary">
                Temporarily take the customer site offline for deploys.
              </Typography>
            </Box>
          }
        />
      </SettingsSection>
    </Stack>
  );
};

export default PlatformTab;
