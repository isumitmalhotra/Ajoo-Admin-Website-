import React, { useState } from "react";
import {
  AppBar,
  Toolbar,
  IconButton,
  Button,
  Drawer,
  List,
  ListItem,
  ListItemText,
  Box,
  useMediaQuery,
  useTheme,
  Typography,
} from "@mui/material";
import NotificationDropdown from "../frontend/NotificationDropdown";
import MenuIcon from "@mui/icons-material/Menu";
import CloseIcon from "@mui/icons-material/Close";
import PersonIcon from "@mui/icons-material/Person";
import { Link, useNavigate } from "react-router-dom";

const Header: React.FC = () => {
  const [drawerOpen, setDrawerOpen] = useState(false);
  const navigate = useNavigate();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("md"));

  const toggleDrawer = (open: boolean) => () => {
    setDrawerOpen(open);
  };

  const navLinks = [
    { label: "Find Your Stay", to: "/" },
    { label: "Homes", to: "/property/list" },
    { label: "About Us", to: "/about" },
    { label: "Contact", to: "/contact" },
  ];

  const drawerLinks = [
    { label: "Find Your Stay", to: "/" },
    { label: "Homes", to: "/property/list" },
    { label: "About Us", to: "/about" },
    { label: "Contact", to: "/contact" },
    { label: "FAQ", to: "/faqs" },
    { label: "Privacy Policy", to: "/Privacy-Policy" },
    { label: "Terms & Conditions", to: "/terms-condition" },
    { label: "Why Host List With Aajoo", to: "/Why-Hosts-List-With-Aajoo" },
    { label: "State Regulation", to: "/state-regulation" },
    { label: "Become A Host", to: "/auth/signup" },
    { label: "Help Center", to: "/help-center" },
  ];

  return (
    <>
      <AppBar
        position="sticky"
        elevation={0}
        sx={{
          bgcolor: "#FFFAF0",
          borderBottom: "1px solid #D9CFB8",
          color: "#1B2447",
        }}
      >
        <Toolbar
          sx={{
            px: { xs: "20px", md: "48px" },
            py: "18px",
            minHeight: "unset !important",
            justifyContent: "space-between",
          }}
        >
          {/* Logo */}
          <Link to="/" style={{ display: "flex", alignItems: "center", gap: 10, textDecoration: "none" }}>
            <Box
              sx={{
                width: 34,
                height: 34,
                borderRadius: "10px",
                background: "linear-gradient(135deg, #1B2447 0%, #2A356B 100%)",
                display: "grid",
                placeItems: "center",
                color: "#FFFAF0",
                fontFamily: "'Fraunces', serif",
                fontWeight: 700,
                fontSize: "18px",
                letterSpacing: "-0.04em",
                boxShadow: "inset 0 -2px 0 rgba(0,0,0,.15)",
              }}
            >
              A
            </Box>
            <Typography
              sx={{
                fontFamily: "'Fraunces', serif",
                fontWeight: 600,
                fontSize: "20px",
                letterSpacing: "-0.02em",
                color: "#1B2447",
                "& em": { fontStyle: "italic", fontWeight: 400, color: "#C16345" },
              }}
            >
              aajoo<em>Homes</em>
            </Typography>
          </Link>

          {/* Desktop nav */}
          {!isMobile && (
            <>
              {/* Nav links */}
              <Box sx={{ display: "flex", gap: "32px" }}>
                {navLinks.map((item) => (
                  <Link
                    key={item.to}
                    to={item.to}
                    style={{ textDecoration: "none" }}
                  >
                    <Typography
                      sx={{
                        fontSize: 14,
                        fontWeight: 500,
                        color: "#3D4670",
                        padding: "6px 0",
                        cursor: "pointer",
                        transition: "color 0.2s",
                        "&:hover": { color: "#1B2447" },
                      }}
                    >
                      {item.label}
                    </Typography>
                  </Link>
                ))}
              </Box>

              {/* Right controls */}
              <Box sx={{ display: "flex", alignItems: "center", gap: "18px" }}>
                <Typography
                  onClick={() => navigate("/become-a-host")}
                  sx={{
                    fontSize: 14,
                    fontWeight: 500,
                    color: "#3D4670",
                    cursor: "pointer",
                    "&:hover": { color: "#1B2447" },
                  }}
                >
                  Become a Host
                </Typography>

                {/* Language pill */}
                <Box
                  sx={{
                    display: "flex",
                    alignItems: "center",
                    gap: "6px",
                    fontSize: 12,
                    color: "#6B7390",
                    border: "1px solid #D9CFB8",
                    padding: "6px 10px",
                    borderRadius: "999px",
                    cursor: "pointer",
                  }}
                >
                  🌐 EN
                </Box>

                <NotificationDropdown />

                <IconButton
                  onClick={() => navigate("/user-dashboard")}
                  sx={{ p: 0.5 }}
                >
                  <PersonIcon sx={{ color: "#3D4670", fontSize: 22 }} />
                </IconButton>

                {/* CTA */}
                <Button
                  onClick={() => navigate("/auth/login")}
                  sx={{
                    textTransform: "none",
                    bgcolor: "#1B2447",
                    color: "#FFFAF0",
                    padding: "10px 18px",
                    borderRadius: "999px",
                    fontSize: 13,
                    fontWeight: 500,
                    letterSpacing: "0.01em",
                    "&:hover": { bgcolor: "#2A356B" },
                    minWidth: "unset",
                    lineHeight: 1,
                  }}
                >
                  Sign In
                </Button>

                <IconButton onClick={toggleDrawer(true)} sx={{ p: 0.5 }}>
                  <MenuIcon sx={{ color: "#1B2447" }} />
                </IconButton>
              </Box>
            </>
          )}

          {/* Mobile */}
          {isMobile && (
            <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
              <NotificationDropdown />
              <IconButton edge="end" onClick={toggleDrawer(true)}>
                <MenuIcon sx={{ color: "#1B2447" }} />
              </IconButton>
            </Box>
          )}
        </Toolbar>
      </AppBar>

      {/* Drawer */}
      <Drawer anchor="right" open={drawerOpen} onClose={toggleDrawer(false)}>
        <Box
          sx={{
            width: 270,
            p: 3,
            bgcolor: "#FFFAF0",
            height: "100%",
            display: "flex",
            flexDirection: "column",
          }}
        >
          <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
            <Typography
              sx={{
                fontFamily: "'Fraunces', serif",
                fontWeight: 600,
                fontSize: 18,
                color: "#1B2447",
              }}
            >
              Menu
            </Typography>
            <IconButton onClick={toggleDrawer(false)}>
              <CloseIcon sx={{ color: "#1B2447" }} />
            </IconButton>
          </Box>

          <List sx={{ mb: 1 }}>
            {drawerLinks.map((item) => (
              <ListItem
                key={item.to}
                component={Link}
                to={item.to}
                onClick={toggleDrawer(false)}
                sx={{
                  py: 0.8,
                  borderRadius: "8px",
                  "&:hover": { bgcolor: "rgba(27,36,71,0.05)" },
                }}
              >
                <ListItemText
                  primary={item.label}
                  sx={{
                    "& .MuiTypography-root": {
                      fontSize: "0.875rem",
                      color: "#3D4670",
                      fontWeight: 500,
                    },
                  }}
                />
              </ListItem>
            ))}
          </List>

          <Box sx={{ mt: "auto", pt: 2, borderTop: "1px solid #D9CFB8", display: "flex", flexDirection: "column", gap: 1.5 }}>
            <Button
              fullWidth
              onClick={() => { navigate("/auth/login"); setDrawerOpen(false); }}
              variant="outlined"
              sx={{
                color: "#1B2447",
                borderColor: "#D9CFB8",
                textTransform: "none",
                borderRadius: "10px",
                fontWeight: 500,
                "&:hover": { bgcolor: "rgba(27,36,71,0.05)", borderColor: "#1B2447" },
              }}
            >
              Login
            </Button>
            <Button
              fullWidth
              onClick={() => { navigate("/auth/signup"); setDrawerOpen(false); }}
              variant="contained"
              sx={{
                textTransform: "none",
                bgcolor: "#1B2447",
                color: "#FFFAF0",
                borderRadius: "10px",
                fontWeight: 500,
                "&:hover": { bgcolor: "#2A356B" },
              }}
            >
              Register
            </Button>
          </Box>
        </Box>
      </Drawer>
    </>
  );
};

export default Header;
