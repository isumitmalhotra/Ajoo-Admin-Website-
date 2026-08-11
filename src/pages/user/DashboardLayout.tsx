import { useLocation } from "react-router-dom";
import React, { useState, useEffect } from "react";
import {
  Box,
  Button,
  Typography,
  Paper,
  IconButton,
  Drawer,
  Divider,
} from "@mui/material";
import ArrowForwardIosIcon from "@mui/icons-material/ArrowForwardIos";
import CloseIcon from "@mui/icons-material/Close";

// Account-area sections
import UserDashboard from "./dashboard.tsx";
import UserProfile from "./UserProfile.tsx";
import Bookings from "./UserBookings.tsx";
import UserOngoingBooking from "./userOngoingBooking.tsx";
import UserTransactions from "./UserTransactions.tsx";
import UserSaved from "./UserSaved.tsx";

const MENU: { key: string; label: string }[] = [
  { key: "dashboard", label: "Dashboard" },
  { key: "profile", label: "Profile" },
  { key: "bookings", label: "Bookings" },
  { key: "ongoing", label: "Ongoing" },
  { key: "transactions", label: "Transactions" },
  { key: "saved", label: "Saved" },
];

const DashboardLayout: React.FC = () => {
  const location = useLocation();

  const [activeSection, setActiveSection] = useState("dashboard");
  const [mobileOpen, setMobileOpen] = useState(false);

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  useEffect(() => {
    if (location.state?.section) {
      setActiveSection(location.state.section);
    }
  }, [location.state]);

  const renderSection = () => {
    switch (activeSection) {
      case "dashboard":
        return <UserDashboard />;
      case "profile":
        return <UserProfile />;
      case "bookings":
        return <Bookings />;
      case "ongoing":
        return <UserOngoingBooking />;
      case "transactions":
        return <UserTransactions />;
      case "saved":
        return <UserSaved />;
      default:
        return <Typography>Select a section</Typography>;
    }
  };

  const sidebarContent = (
    <Box
      sx={{
        width: 250,
        p: 2,
        backgroundColor: "#fff",
        height: "100%",
      }}
    >
      {/* Header with Close button for mobile */}
      <Box display="flex" justifyContent="space-between" alignItems="center">
        <Typography variant="h6" sx={{ color: "#1B2447" }}>
          Dashboard
        </Typography>
        <IconButton
          onClick={handleDrawerToggle}
          sx={{ display: { md: "none" } }}
        >
          <CloseIcon sx={{ color: "#1B2447" }} />
        </IconButton>
      </Box>
      <Divider sx={{ my: 2 }} />

      {/* Menu Buttons */}
      {MENU.map((item) => (
        <Button
          key={item.key}
          fullWidth
          variant={activeSection === item.key ? "contained" : "outlined"}
          sx={{
            mb: 1,
            borderColor: "#1B2447",
            color: activeSection === item.key ? "#fff" : "#1B2447",
            backgroundColor:
              activeSection === item.key ? "#1B2447" : "transparent",
            "&:hover": {
              backgroundColor:
                activeSection === item.key ? "#a0324f" : "#fbe6ec",
            },
          }}
          onClick={() => {
            setActiveSection(item.key);
            setMobileOpen(false);
          }}
        >
          {item.label}
        </Button>
      ))}
    </Box>
  );

  return (
    <Box
      sx={{ display: "flex", minHeight: "100vh", backgroundColor: "#f9f9f9" }}
    >
      {/* Sidebar for desktop */}
      <Box
        sx={{
          width: 250,
          height: "100vh",
          position: "sticky",
          top: 0,
          backgroundColor: "#fff",
          borderRight: "1px solid #ddd",
          p: 2,
          display: { xs: "none", md: "block" },
        }}
      >
        {sidebarContent}
      </Box>

      {/* Drawer for mobile */}
      <Drawer
        variant="temporary"
        open={mobileOpen}
        onClose={handleDrawerToggle}
        ModalProps={{ keepMounted: true }}
        sx={{
          display: { xs: "block", md: "none" },
          "& .MuiDrawer-paper": {
            width: 250,
          },
        }}
      >
        {sidebarContent}
      </Drawer>

      {/* Right Section */}
      <Box sx={{ flex: 1, p: { xs: 2, md: 3 } }}>
        {/* Arrow button on mobile only */}
        <IconButton
          onClick={handleDrawerToggle}
          sx={{
            display: { xs: "inline-flex", md: "none" },
            mb: 2,
            color: "#1B2447",
          }}
        >
          <ArrowForwardIosIcon />
        </IconButton>

        <Paper elevation={3} sx={{ p: 3, minHeight: "80vh" }}>
          {renderSection()}
        </Paper>
      </Box>
    </Box>
  );
};

export default DashboardLayout;
