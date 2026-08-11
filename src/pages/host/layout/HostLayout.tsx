import { Box } from "@mui/material";
import { Outlet } from "react-router-dom";
import { HostHeader } from "../../../components/layout/HostHeader";
import { HostSidebar } from "../../../components/layout/HostSidebar";

export default function HostLayout() {
  return (
    <Box
      sx={{
        display: "flex",
        minHeight: "100vh",
        bgcolor: "#EFE7D6",
        background:
          "radial-gradient(circle at top right, rgba(27,36,71,0.06), rgba(239,231,214,1) 38%)",
      }}
    >
      <HostSidebar />

      <Box sx={{ flex: 1, minWidth: 0, maxWidth: "calc(100vw - 260px)" }}>
        <HostHeader />
        <Box sx={{ p: { xs: 2, md: 3 }, pb: 4 }}>
          <Outlet />
        </Box>
      </Box>
    </Box>
  );
}
