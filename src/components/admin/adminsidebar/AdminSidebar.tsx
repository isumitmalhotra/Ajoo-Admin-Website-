import { NavLink } from "react-router-dom";
import { useSidebar } from "../../../context/AdminContext";
import {
  Box,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Collapse,
  Typography,
  IconButton,
} from "@mui/material";
import {
  LayoutDashboard,
  Users,
  ChevronDown,
  ChevronUp,
  AlignVerticalJustifyCenter,
  BookOpen,
  Octagon,
  TrafficCone,
  Activity,
  CircleDot,
  Bath,
  Tag,
  ShieldCheck,
  Star,
  Wallet,
  BookText,
  HandCoins,
  FileCheck,
  FileText,
  BarChart3,
} from "lucide-react";
import { useEffect, useState, MouseEvent } from "react";

interface NavItem {
  text: string;
  path: string;
  icon: React.ElementType;
}

const NAV_ITEMS: NavItem[] = [
  { text: "Dashboard", path: "/admin/dashboard", icon: LayoutDashboard },
  { text: "Users", path: "/admin/users", icon: Users },
  { text: "Host", path: "/admin/host", icon: Octagon },
  {
    text: "Properties",
    path: "/admin/properties",
    icon: AlignVerticalJustifyCenter,
  },
  { text: "Bookings", path: "/admin/bookings", icon: BookOpen },
  { text: "Finance", path: "/admin/finance", icon: Wallet },
  // { text: "Support", path: "/admin/support", icon: Octagon },
];

const SUB_ITEMS: Record<string, NavItem[]> = {
  Properties: [
    {
      text: "Property Categories",
      path: "/admin/categories",
      icon: CircleDot,
    },
    {
      text: "Property Tags",
      path: "/admin/tags",
      icon: Tag,
    },
    {
      text: "Amenities",
      path: "/admin/amenities",
      icon: Bath,
    },
    {
      text: "Property Verification",
      path: "/admin/property-verification",
      icon: ShieldCheck,
    },
    {
      text: "Property Reviews",
      path: "/admin/property-reviews",
      icon: Star,
    },
  ],
  Bookings: [
    {
      text: "Status",
      path: "/admin/status",
      icon: Activity,
    },
  ],
  Finance: [
    {
      text: "Ledgers",
      path: "/admin/finance/ledgers",
      icon: BookText,
    },
    {
      text: "Payouts",
      path: "/admin/finance/payouts",
      icon: HandCoins,
    },
    {
      text: "Reconciliation",
      path: "/admin/finance/reconciliation",
      icon: FileCheck,
    },
    {
      text: "Invoices",
      path: "/admin/finance/invoices",
      icon: FileText,
    },
    {
      text: "Reports",
      path: "/admin/finance/reports/revenue",
      icon: BarChart3,
    },
  ],
  Configuration: [
    {
      text: "Status",
      path: "/admin/status",
      icon: TrafficCone,
    },
  ],
};

const AdminSidebar = () => {
  const { isCollapsed } = useSidebar();
  const [open, setOpen] = useState<Record<string, boolean>>({});

  const toggleDropdown = (e: MouseEvent, key: string) => {
    e.preventDefault();
    e.stopPropagation(); // 🔑 prevents NavLink navigation
    setOpen((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  useEffect(() => {
    if (isCollapsed) setOpen({});
  }, [isCollapsed]);

  return (
    <Box
      sx={{
        height: "100vh",
        width: isCollapsed ? 64 : 240,
        borderRight: "1px solid #e5e7eb",
        bgcolor: "#fff",
        display: "flex",
        flexDirection: "column",
        transition: "width 0.3s ease",
      }}
    >
      {/* LOGO */}
      <Box
        sx={{
          display: "flex",
          alignItems: "center",
          justifyContent: isCollapsed ? "center" : "flex-start",
          gap: 1,
          px: 2,
          py: 2,
          borderBottom: "1px solid #e5e7eb",
        }}
      >
        <Octagon size={28} color="#7115bd" />
        {!isCollapsed && (
          <Typography fontWeight={600} color="#27548a">
            Your Logo
          </Typography>
        )}
      </Box>

      {/* NAV */}
      <Box sx={{ flex: 1, overflowY: "auto" }}>
        <List disablePadding>
          {NAV_ITEMS.map((item) => {
            const hasSub = !!SUB_ITEMS[item.text];
            const Icon = item.icon;

            return (
              <Box key={item.text}>
                <ListItemButton
                  component={NavLink}
                  to={item.path}
                  sx={{
                    mx: 1,
                    my: 0.5,
                    borderRadius: 1,
                    color: "#27548a",
                    "&.active": {
                      color: "#8e07d6",
                    },
                    "&:hover": {
                      color: "#8e07d6",
                    },
                  }}
                >
                  <ListItemIcon sx={{ minWidth: 36, color: "inherit" }}>
                    <Icon size={20} />
                  </ListItemIcon>

                  {!isCollapsed && (
                    <ListItemText
                      primary={item.text}
                      primaryTypographyProps={{
                        fontSize: "0.85rem",
                        fontWeight: 500,
                      }}
                    />
                  )}

                  {!isCollapsed && hasSub && (
                    <IconButton
                      size="small"
                      onClick={(e) => toggleDropdown(e, item.text)}
                      sx={{ color: "inherit" }}
                    >
                      {open[item.text] ? (
                        <ChevronUp size={16} />
                      ) : (
                        <ChevronDown size={16} />
                      )}
                    </IconButton>
                  )}
                </ListItemButton>

                {/* SUB MENU */}
                {!isCollapsed && hasSub && (
                  <Collapse in={open[item.text]} timeout="auto" unmountOnExit>
                    <List disablePadding sx={{ pl: 4 }}>
                      {SUB_ITEMS[item.text].map((sub) => {
                        const SubIcon = sub.icon;
                        return (
                          <ListItemButton
                            key={sub.path}
                            component={NavLink}
                            to={sub.path}
                            sx={{
                              my: 0.3,
                              borderRadius: 1,
                              color: "#27548a",
                              "&.active": {
                                color: "#8e07d6",
                              },
                            }}
                          >
                            <ListItemIcon
                              sx={{ minWidth: 30, color: "inherit" }}
                            >
                              <SubIcon size={16} />
                            </ListItemIcon>
                            <ListItemText
                              primary={sub.text}
                              primaryTypographyProps={{
                                fontSize: "0.8rem",
                              }}
                            />
                          </ListItemButton>
                        );
                      })}
                    </List>
                  </Collapse>
                )}
              </Box>
            );
          })}
        </List>
      </Box>
    </Box>
  );
};

export default AdminSidebar;
