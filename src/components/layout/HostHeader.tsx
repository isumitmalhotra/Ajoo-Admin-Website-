import React, { useState } from 'react';
import { AppBar, Toolbar, IconButton, Menu, MenuItem, Typography, Box } from '@mui/material';
import AccountCircle from '@mui/icons-material/AccountCircle';
import storage from '../../styles/utils/storage';
import { useLocation, useNavigate } from 'react-router-dom';

export const HostHeader = () => {
    const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
    const location = useLocation();
    const navigate = useNavigate()
    const handleMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
        setAnchorEl(event.currentTarget);
    };

    const handleMenuClose = () => {
        setAnchorEl(null);
    };

    const handleProfileClick = () => {
        // Navigate to profile or do something
        handleMenuClose();
    };

   const handleLogoutClick = () => {
        handleMenuClose();
        storage.clearToken()
        localStorage.removeItem("adminToken");
        navigate("/")
        
    };

    const title = (() => {
      if (location.pathname.includes("/host/bookings")) return "Host Bookings";
      if (location.pathname.includes("/host/earnings")) return "Host Earnings";
      if (location.pathname.includes("/host/statements")) return "Host Statements";
      if (location.pathname.includes("/host/profile")) return "Host Profile";
      if (location.pathname.includes("/host/support")) return "Host Support";
      return "Host Dashboard";
    })();

    return (
        <AppBar position="static" sx={{ backgroundColor: '#C14365 !important' }}>
            <Toolbar sx={{ display: 'flex', justifyContent: 'space-between' }}>
                <Typography variant="h6" component="div">
                    {title}
                </Typography>
                <Box>
                    <IconButton
                        size="large"
                        edge="end"
                        color="inherit"
                        onClick={handleMenuOpen}
                    >
                        <AccountCircle />
                    </IconButton>
                    <Menu
                        anchorEl={anchorEl}
                        open={Boolean(anchorEl)}
                        onClose={handleMenuClose}
                        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
                        transformOrigin={{ vertical: 'top', horizontal: 'right' }}
                    >
                        <MenuItem onClick={handleProfileClick}>Profile</MenuItem>
                        <MenuItem onClick={handleLogoutClick}>Logout</MenuItem>
                    </Menu>
                </Box>
            </Toolbar>
        </AppBar>
    );
};
