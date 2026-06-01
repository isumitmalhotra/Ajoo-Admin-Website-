import {
  Drawer,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Typography,
  Box,
  Divider,
} from "@mui/material";

import PersonIcon from "@mui/icons-material/Person";
import HistoryIcon from "@mui/icons-material/History";
import BookmarkIcon from "@mui/icons-material/Bookmark";
import SecurityIcon from "@mui/icons-material/Security";
import SettingsIcon from "@mui/icons-material/Settings";
import HelpIcon from "@mui/icons-material/Help";
import InfoIcon from "@mui/icons-material/Info";
import LogoutIcon from "@mui/icons-material/Logout";
import { UserType } from "../../types/type";
import { useSelector } from "react-redux";

const drawerWidth = 240;

const menuItems = [
  { text: "Profile", icon: <PersonIcon /> },
  { text: "History", icon: <HistoryIcon /> },
  { text: "Bookmarks", icon: <BookmarkIcon /> },
  { text: "Safety", icon: <SecurityIcon /> },
  { text: "Settings", icon: <SettingsIcon /> },
  { text: "Help & Support", icon: <HelpIcon /> },
  { text: "About", icon: <InfoIcon /> },
  { text: "Logout", icon: <LogoutIcon /> },
];

export const UserSidebar = () => {
  const { data } = useSelector(
    ({ auth }: { auth: { data: UserType } }) => auth
  );
  return (
    <Drawer
      variant="permanent"
      sx={{
        width: drawerWidth,
        flexShrink: 0,
        "& .MuiDrawer-paper": {
          width: drawerWidth,
          boxSizing: "border-box",
          backgroundColor: "#1B2447 !important",
          color: "#FFFAF0",
        },
      }}
    >
      <Box sx={{ p: 2 }}>
        <Typography variant="h6" sx={{ fontWeight: "bold" }}>
          Welcome, {data?.user_fullName}
        </Typography>
      </Box>
      <Divider sx={{ borderColor: "rgba(255,255,255,0.3)" }} />
      <List>
        {menuItems.map((item) => (
          <ListItem
            component="div"
            key={item.text}
            sx={{
              "&:hover": {
                backgroundColor: "rgba(255, 255, 255, 0.1)",
                cursor: "pointer",
              },
            }}
          >
            <ListItemIcon sx={{ color: "white" }}>{item.icon}</ListItemIcon>
            <ListItemText primary={item.text} />
          </ListItem>
        ))}
      </List>
    </Drawer>
  );
};
