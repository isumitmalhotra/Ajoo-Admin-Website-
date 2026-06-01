// import React, { useState } from "react";
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

// Import your other components here
import UserProfile from "./UserProfile.tsx";
import Bookings from "./UserBookings.tsx";
import UserOngoingBooking from "./userOngoingBooking.tsx";

const DashboardLayout: React.FC = () => {
  const location = useLocation();
  
  const [activeSection, setActiveSection] = useState("profile");
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
      case "profile":
        return <UserProfile />;
      case "bookings":
        return <Bookings />;
      case "ongoing":
        return <UserOngoingBooking />;
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
      <Button
        fullWidth
        variant={activeSection === "profile" ? "contained" : "outlined"}
        sx={{
          mb: 1,
          borderColor: "#1B2447",
          color: activeSection === "profile" ? "#fff" : "#1B2447",
          backgroundColor:
            activeSection === "profile" ? "#1B2447" : "transparent",
          "&:hover": {
            backgroundColor:
              activeSection === "profile" ? "#a0324f" : "#fbe6ec",
          },
        }}
        onClick={() => {
          setActiveSection("profile");
          setMobileOpen(false);
        }}
      >
        Profile
      </Button>

      <Button
        fullWidth
        variant={activeSection === "bookings" ? "contained" : "outlined"}
        sx={{
          mb: 1,
          borderColor: "#1B2447",
          color: activeSection === "bookings" ? "#fff" : "#1B2447",
          backgroundColor:
            activeSection === "bookings" ? "#1B2447" : "transparent",
          "&:hover": {
            backgroundColor:
              activeSection === "bookings" ? "#a0324f" : "#fbe6ec",
          },
        }}
        onClick={() => {
          setActiveSection("bookings");
          setMobileOpen(false);
        }}
      >
        Bookings
      </Button>

      <Button
        fullWidth
        variant={activeSection === "ongoing" ? "contained" : "outlined"}
        sx={{
          mb: 1,
          borderColor: "#1B2447",
          color: activeSection === "ongoing" ? "#fff" : "#1B2447",
          backgroundColor:
            activeSection === "ongoing" ? "#1B2447" : "transparent",
          "&:hover": {
            backgroundColor:
              activeSection === "ongoing" ? "#a0324f" : "#fbe6ec",
          },
        }}
        onClick={() => {
          setActiveSection("ongoing");
          setMobileOpen(false);
        }}
      >
        ongoing
      </Button>
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
