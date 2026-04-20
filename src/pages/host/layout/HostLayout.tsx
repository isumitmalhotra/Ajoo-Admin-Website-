import { Box } from "@mui/material";
import { Outlet } from "react-router-dom";
import { HostHeader } from "../../../components/layout/HostHeader";
import { HostSidebar } from "../../../components/layout/HostSidebar";

export default function HostLayout() {
  return (
    <Box sx={{ display: "flex", minHeight: "100vh", bgcolor: "#f8fafc" }}>
      <HostSidebar />

      <Box sx={{ flex: 1, minWidth: 0 }}>
        <HostHeader />
        <Box sx={{ p: { xs: 2, md: 3 } }}>
          <Outlet />
        </Box>
      </Box>
    </Box>
  );
}
