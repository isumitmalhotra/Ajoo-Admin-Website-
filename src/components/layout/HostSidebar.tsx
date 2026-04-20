import {
    Drawer,
    List,
    ListItemButton,
    ListItemText,
    ListItemIcon,
    Typography,
    Box,
    Divider,
} from '@mui/material';
import HomeIcon from '@mui/icons-material/Home';
import PersonIcon from '@mui/icons-material/Person';
import AddHomeIcon from '@mui/icons-material/AddHome';
import HistoryIcon from '@mui/icons-material/History';
import ReceiptIcon from '@mui/icons-material/Receipt';
import PaymentIcon from '@mui/icons-material/Payment';
import PrivacyTipIcon from '@mui/icons-material/PrivacyTip';
import SettingsIcon from '@mui/icons-material/Settings';
import { NavLink } from 'react-router-dom';

const menuItems = [
    { text: 'Dashboard', icon: <HomeIcon />, path: '/host/dashboard' },
    { text: 'Bookings', icon: <HistoryIcon />, path: '/host/bookings' },
    { text: 'Earnings', icon: <PaymentIcon />, path: '/host/earnings' },
    { text: 'Statements', icon: <ReceiptIcon />, path: '/host/statements' },
    { text: 'Profile', icon: <PersonIcon />, path: '/host/profile' },
    { text: 'Support', icon: <SettingsIcon />, path: '/host/support' },
    { text: 'Privacy Policy', icon: <PrivacyTipIcon />, path: '/Privacy-Policy' },
    { text: 'Add Property', icon: <AddHomeIcon />, path: '/admin/properties/form' },
];

const drawerWidth = 240;

export const HostSidebar = () => {
    return (
        <Drawer
            variant="permanent"
            sx={{
                width: drawerWidth,
                flexShrink: 0,
                '& .MuiDrawer-paper': {
                    width: drawerWidth,
                    boxSizing: 'border-box',
                    backgroundColor: '#C14365 !important',
                    color: '#fff',
                },
            }}
        >
            <Box sx={{ p: 2 }}>
                <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                    Host Portal
                </Typography>
            </Box>
            <Divider sx={{ borderColor: 'rgba(255,255,255,0.3)' }} />
            <List>
                {menuItems.map((item) => (
                    <ListItemButton
                        key={item.text}
                        component={item.path ? NavLink : 'div'}
                        {...(item.path ? { to: item.path } : {})}
                        sx={{
                            borderRadius: 1,
                            mx: 1,
                            '&:hover': {
                                backgroundColor: 'rgba(255, 255, 255, 0.1)',
                            },
                            '&.active': {
                                backgroundColor: 'rgba(255, 255, 255, 0.2)',
                            },
                        }}
                    >
                        <ListItemIcon sx={{ color: 'white' }}>{item.icon}</ListItemIcon>
                        <ListItemText primary={item.text} />
                    </ListItemButton>
                ))}
            </List>
        </Drawer>
    );
};
