import { useState} from "react";
import {
  Box,
  Drawer,
  IconButton,
  // Dialog,
  // DialogActions,
  // DialogContent,
  // DialogTitle,
  // Button,
} from "@mui/material";
import MenuIcon from "@mui/icons-material/Menu";
import CloseIcon from "@mui/icons-material/Close";
import {
  PageHeaderWithCategories,
  SidebarFilters,
  PropertyGrid,
} from "../../components";
// import PageHeaderWithCategories from "./PageHeaderWithCategories";
// import SidebarFilters from "./SidebarFilters";
// import PropertyGrid from "./PropertyGrid";

import single from "../../assets/provided asset/single.png";
import couple3 from "../../assets/provided asset/couple.png";
import family from "../../assets/provided asset/family.png";
import sharing from "../../assets/provided asset/sharing.png";
import party from "../../assets/provided asset/party.png";

const categories = [
  { img: single, label: "Single" },
  { img: couple3, label: "Couple" },
  { img: family, label: "Family" },
  { img: sharing, label: "Sharing" },
  { img: party, label: "Party" },
];

const PropertyListing = () => {
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  const [mobileOpen, setMobileOpen] = useState(false);

  // Filters States
  const [locationName, setLocationName] = useState("");
  const [distance, setDistance] = useState(5);
  const [selectedPrices, setSelectedPrices] = useState<string[]>([]);
  const [selectedAmenities, setSelectedAmenities] = useState<string[]>([]);
  // const [openDialog, setOpenDialog] = useState(false);

  const togglePrice = (p: string) =>
    setSelectedPrices((prev) =>
      prev.includes(p) ? prev.filter((x) => x !== p) : [...prev, p]
    );

  const toggleAmenity = (a: string) =>
    setSelectedAmenities((prev) =>
      prev.includes(a) ? prev.filter((x) => x !== a) : [...prev, a]
    );

  // Dummy properties
  const properties = Array.from({ length: 20 }, (_, i) => ({
    image: `https://picsum.photos/400/250?random=${i + 1}`,
    name: `Property ${i + 1}`,
    description: "Beautiful stay with modern amenities.",
    price: `₹${4000 + i * 200}`,
  }));

  return (
    <>
      {/* Sidebar Drawer Mobile */}
      <IconButton
        sx={{
          position: "fixed",
          top: 18,
          left: 18,
          zIndex: 20,
          display: { xs: "block", md: "none" },
          background: "#fff",
        }}
        onClick={() => setMobileOpen(true)}
      >
        <MenuIcon />
      </IconButton>

      <Drawer
        open={mobileOpen}
        onClose={() => setMobileOpen(false)}
        sx={{ "& .MuiDrawer-paper": { width: 280, p: 2 } }}
      >
        <IconButton onClick={() => setMobileOpen(false)}>
          <CloseIcon />
        </IconButton>
        <SidebarFilters
          {...{
            locationName,
            setLocationName,
            distance,
            setDistance,
            selectedPrices,
            togglePrice,
            selectedAmenities,
            toggleAmenity,
          }}
        />
      </Drawer>

      {/* MAIN LAYOUT */}
      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: { xs: "1fr", md: "280px 1fr" },
          gap: "24px",
          p: { xs: "16px 20px", md: "24px 48px 64px" },
          bgcolor: "#EFE7D6",
          minHeight: "100vh",
        }}
      >
        {/* Desktop Sidebar */}
        <Box
          sx={{
            display: { xs: "none", md: "block" },
            borderRight: "1px solid #D9CFB8",
            pr: 2,
          }}
        >
          <SidebarFilters
            {...{
              locationName,
              setLocationName,
              distance,
              setDistance,
              selectedPrices,
              togglePrice,
              selectedAmenities,
              toggleAmenity,
            }}
          />
        </Box>

        {/* Right Side Content */}
        <Box>
          <PageHeaderWithCategories
            categories={categories}
            selectedCategory={selectedCategory}
            onSelect={(c) => setSelectedCategory(c)}
            resultCount={properties.length}
          />

          <PropertyGrid properties={properties} />
        </Box>
      </Box>
    </>
  );
};

export default PropertyListing;
