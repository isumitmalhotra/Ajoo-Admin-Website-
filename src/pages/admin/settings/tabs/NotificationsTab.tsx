import { Box, Typography, Switch, Divider } from "@mui/material";
import { Bell } from "lucide-react";
import SettingsSection from "./SettingsSection";

// TODO(BE): persist these channel preferences via /admin/settings/notifications.
// B-09 / A-14 deliver the real notification backend; this tab only sets defaults.
const NOTIFY_ROWS = [
  { key: "newBooking", label: "New booking", desc: "Notify admins when a guest confirms a booking." },
  { key: "payoutRequest", label: "Payout request", desc: "Alert finance when a host requests a payout." },
  { key: "kycReview", label: "KYC in review", desc: "Flag when a host or guest enters manual KYC review." },
  { key: "newHost", label: "New host signup", desc: "Notify when a host registers and awaits approval." },
  { key: "reviewFlag", label: "Flagged review", desc: "Surface reviews flagged for moderation." },
];

const NotificationsTab = () => {
  return (
    <SettingsSection
      icon={Bell}
      title="Notifications"
      subtitle="Choose which platform events generate admin notifications."
    >
      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: "1fr auto auto",
          alignItems: "center",
          rowGap: 0.5,
          columnGap: 2,
        }}
      >
        <Box />
        <Typography variant="caption" fontWeight={700} color="#64748b" textAlign="center">
          In-app
        </Typography>
        <Typography variant="caption" fontWeight={700} color="#64748b" textAlign="center">
          Email
        </Typography>

        {NOTIFY_ROWS.map((row, i) => (
          <Box key={row.key} sx={{ display: "contents" }}>
            {i > 0 && (
              <Box sx={{ gridColumn: "1 / -1" }}>
                <Divider />
              </Box>
            )}
            <Box sx={{ py: 1 }}>
              <Typography variant="body2" fontWeight={600} color="#374151">
                {row.label}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                {row.desc}
              </Typography>
            </Box>
            <Switch defaultChecked />
            <Switch defaultChecked={row.key !== "reviewFlag"} />
          </Box>
        ))}
      </Box>
    </SettingsSection>
  );
};

export default NotificationsTab;
