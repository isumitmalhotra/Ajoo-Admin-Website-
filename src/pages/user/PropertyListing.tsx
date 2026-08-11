import { useMemo, useState, useCallback, useEffect } from "react";
import { Box, Drawer, IconButton, Button, Typography, CircularProgress } from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import TuneIcon from "@mui/icons-material/Tune";
import MapIcon from "@mui/icons-material/Map";
import ViewListIcon from "@mui/icons-material/ViewList";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { LatLngBounds } from "leaflet";

import {
  PageHeaderWithCategories,
  SidebarFilters,
  HomePropCard,
} from "../../components";
import ListingMap, { MapProperty } from "../../components/frontend/ListingMap";
import { searchProperties, getCategories, type ApiProperty } from "../../services/customerApi";
import { geocodePlace } from "../../styles/utils/locationUtils";

// ── Dummy properties with coordinates clustered around Goa ───────────────
// Approx Goa bbox: lat 14.9-15.8, lng 73.7-74.3
const GOA_CENTER = { lat: 15.4909, lng: 73.8278 };

type Property = {
  id: number;
  image: string;
  name: string;
  location: string;
  price: number; // numeric for map; formatted for card display
  priceLabel: string;
  category: string;
  tag?: string;
  rating?: number;
  lat: number;
  lng: number;
  featured?: boolean;
};

// Map a backend property (POST /properties/search) → the card/map Property shape.
const mapApiProperty = (p: ApiProperty): Property => {
  const price = Number(p.property_price) || 0;
  const catTitle = p.category_titles && p.category_titles.length > 0 ? p.category_titles[0] : "";
  return {
    id: p.property_id,
    image:
      p.coverImage ||
      (p.images && p.images.length > 0 ? p.images[0] : "") ||
      `https://picsum.photos/seed/aajoo${p.property_id}/600/400`,
    name: p.property_name,
    location: p.property_address || p.property_city || "India",
    price,
    priceLabel: `₹${price.toLocaleString("en-IN")}`,
    tag: catTitle || "Verified",
    rating: undefined,
    lat: Number(p.property_latitude) || GOA_CENTER.lat,
    lng: Number(p.property_longitude) || GOA_CENTER.lng,
    featured: false,
    category: catTitle,
  };
};

const PropertyListing = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  // Seed filters from the home search bar (?category=, ?location=).
  const [selectedCategory, setSelectedCategory] = useState<string | null>(
    searchParams.get("category")
  );
  const [filterDrawerOpen, setFilterDrawerOpen] = useState(false);

  // Mobile view-mode toggle: "list" or "map"
  const [mobileView, setMobileView] = useState<"list" | "map">("list");

  // Filter state — preserved from prior implementation
  const [locationName, setLocationName] = useState(searchParams.get("location") || "");
  const [distance, setDistance] = useState(5);
  const [selectedPrices, setSelectedPrices] = useState<string[]>([]);
  const [selectedAmenities, setSelectedAmenities] = useState<string[]>([]);

  const togglePrice = (p: string) =>
    setSelectedPrices((prev) =>
      prev.includes(p) ? prev.filter((x) => x !== p) : [...prev, p]
    );

  const toggleAmenity = (a: string) =>
    setSelectedAmenities((prev) =>
      prev.includes(a) ? prev.filter((x) => x !== a) : [...prev, a]
    );

  // Listing data — fetched from the real backend (POST /properties/search).
  const [allProperties, setAllProperties] = useState<Property[]>([]);
  const [loading, setLoading] = useState(true);
  const [fetchError, setFetchError] = useState<string | null>(null);
  // The visitor's location — used to centre the map on "near me".
  const [userCoords, setUserCoords] = useState(GOA_CENTER);

  // Real property categories for the filter chips (Villa, Apartment, …).
  const [categories, setCategories] = useState<{ label: string }[]>([]);
  useEffect(() => {
    getCategories()
      .then((rows) => setCategories(rows.map((c) => ({ label: c.cat_title }))))
      .catch(() => setCategories([]));
  }, []);

  useEffect(() => {
    let cancelled = false;
    const run = async () => {
      setLoading(true);
      setFetchError(null);
      try {
        let coords: { lat: number; lng: number };
        if (locationName.trim()) {
          // A place was chosen (e.g. clicked "Shimla" / typed a city) — search there.
          const geo = await geocodePlace(locationName.trim());
          coords = geo || GOA_CENTER;
        } else {
          // No place chosen → use the visitor's location, fall back to Goa.
          coords = await new Promise<{ lat: number; lng: number }>((resolve) => {
            if (!("geolocation" in navigator)) return resolve(GOA_CENTER);
            navigator.geolocation.getCurrentPosition(
              (pos) => resolve({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
              () => resolve(GOA_CENTER),
              { timeout: 5000 }
            );
          });
        }
        if (!cancelled) setUserCoords(coords);
        // Wider radius so a city search surfaces stays across the region.
        const rows = await searchProperties({ latitude: coords.lat, longitude: coords.lng, radius: 100 });
        if (cancelled) return;
        setAllProperties(rows.map(mapApiProperty));
      } catch {
        if (!cancelled) setFetchError("Couldn't load properties. Please try again.");
      } finally {
        if (!cancelled) setLoading(false);
      }
    };
    run();
    return () => {
      cancelled = true;
    };
  }, [locationName]);

  // Map ↔ Card sync state
  const [hoveredId, setHoveredId] = useState<number | string | null>(null);
  const [searchOnMove, setSearchOnMove] = useState(true);
  const [mapBounds, setMapBounds] = useState<LatLngBounds | null>(null);

  // Properties filtered by current map bounds (when searchOnMove is ON)
  const visibleProperties = useMemo(() => {
    if (!searchOnMove || !mapBounds) return allProperties;
    return allProperties.filter((p) =>
      mapBounds.contains([p.lat, p.lng])
    );
  }, [allProperties, mapBounds, searchOnMove]);

  // Apply the category filter (home search bar "Type" dropdown, category chips,
  // or ?category= URL param) on top of the map-bounds filter.
  const filteredProperties = useMemo(() => {
    if (!selectedCategory) return visibleProperties;
    return visibleProperties.filter((p) => p.category === selectedCategory);
  }, [visibleProperties, selectedCategory]);

  // Map-shape (lat/lng/price) for the ListingMap component
  const mapProperties: MapProperty[] = useMemo(
    () =>
      allProperties.map((p) => ({
        id: p.id,
        name: p.name,
        price: p.price,
        lat: p.lat,
        lng: p.lng,
        featured: p.featured,
      })),
    [allProperties]
  );

  const handleMoveEnd = useCallback((bounds: LatLngBounds) => {
    setMapBounds(bounds);
  }, []);

  const handleToggleSearchOnMove = useCallback(() => {
    setSearchOnMove((prev) => {
      // When turning ON, snapshot current bounds isn't needed —
      // the next moveend will populate. When turning OFF, clear bounds
      // so all properties become visible again.
      if (prev) setMapBounds(null);
      return !prev;
    });
  }, []);

  return (
    <Box sx={{ bgcolor: "#EFE7D6", minHeight: "100vh" }}>
      {/* ── Filter drawer (works on all viewports) ── */}
      <Drawer
        anchor="left"
        open={filterDrawerOpen}
        onClose={() => setFilterDrawerOpen(false)}
        sx={{ "& .MuiDrawer-paper": { width: 320, p: 2, bgcolor: "#FFFAF0" } }}
      >
        <Box
          sx={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            mb: 2,
          }}
        >
          <Typography
            sx={{
              fontFamily: "'Fraunces', serif",
              fontSize: 20,
              fontWeight: 500,
              color: "#1B2447",
            }}
          >
            Filters
          </Typography>
          <IconButton onClick={() => setFilterDrawerOpen(false)}>
            <CloseIcon sx={{ color: "#1B2447" }} />
          </IconButton>
        </Box>
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

      {/* ── Top action row: All filters + view toggle ── */}
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          padding: { xs: "16px 20px 8px", md: "20px 48px 8px" },
          flexWrap: "wrap",
          gap: "12px",
        }}
      >
        <Button
          onClick={() => setFilterDrawerOpen(true)}
          startIcon={<TuneIcon sx={{ fontSize: 16 }} />}
          sx={{
            textTransform: "none",
            bgcolor: "#FFFAF0",
            color: "#1B2447",
            border: "1px solid #D9CFB8",
            borderRadius: "999px",
            padding: "8px 16px",
            fontSize: 13,
            fontWeight: 600,
            boxShadow:
              "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)",
            "&:hover": { bgcolor: "#EFE7D6", borderColor: "#1B2447" },
          }}
        >
          All filters
        </Button>

        {/* Mobile-only view toggle */}
        <Box
          sx={{
            display: { xs: "inline-flex", md: "none" },
            border: "1px solid #D9CFB8",
            borderRadius: "999px",
            overflow: "hidden",
            bgcolor: "#FFFAF0",
          }}
        >
          <Button
            onClick={() => setMobileView("list")}
            startIcon={<ViewListIcon sx={{ fontSize: 16 }} />}
            sx={{
              textTransform: "none",
              fontSize: 12,
              fontWeight: 600,
              padding: "6px 14px",
              borderRadius: 0,
              minWidth: "unset",
              color: mobileView === "list" ? "#FFFAF0" : "#1B2447",
              bgcolor: mobileView === "list" ? "#1B2447" : "transparent",
              "&:hover": {
                bgcolor: mobileView === "list" ? "#2A356B" : "rgba(27,36,71,.05)",
              },
            }}
          >
            List
          </Button>
          <Button
            onClick={() => setMobileView("map")}
            startIcon={<MapIcon sx={{ fontSize: 16 }} />}
            sx={{
              textTransform: "none",
              fontSize: 12,
              fontWeight: 600,
              padding: "6px 14px",
              borderRadius: 0,
              minWidth: "unset",
              color: mobileView === "map" ? "#FFFAF0" : "#1B2447",
              bgcolor: mobileView === "map" ? "#1B2447" : "transparent",
              "&:hover": {
                bgcolor: mobileView === "map" ? "#2A356B" : "rgba(27,36,71,.05)",
              },
            }}
          >
            Map
          </Button>
        </Box>
      </Box>

      {/* ── Main split layout ── */}
      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: { xs: "1fr", md: "1.15fr 1fr" },
          gap: { xs: 0, md: "32px" },
          padding: { xs: "0", md: "8px 48px 48px" },
          alignItems: "start",
        }}
      >
        {/* ── LEFT: category chips + property cards ── */}
        <Box
          sx={{
            display: {
              xs: mobileView === "list" ? "block" : "none",
              md: "block",
            },
            padding: { xs: "8px 20px 32px", md: 0 },
          }}
        >
          <PageHeaderWithCategories
            title={`${filteredProperties.length} verified homes${
              selectedCategory ? ` · ${selectedCategory}` : ""
            }${
              searchOnMove && mapBounds
                ? " in this area"
                : locationName.trim()
                ? ` in ${locationName.trim()}`
                : " near you"
            }`}
            categories={categories}
            selectedCategory={selectedCategory}
            onSelect={(c) => setSelectedCategory((prev) => (prev === c ? null : c))}
            resultCount={undefined}
          />

          {loading ? (
            <Box sx={{ display: "flex", justifyContent: "center", alignItems: "center", py: "64px" }}>
              <CircularProgress sx={{ color: "#1B2447" }} />
            </Box>
          ) : fetchError ? (
            <Box sx={{ padding: "48px 24px", textAlign: "center", bgcolor: "#FFFAF0", borderRadius: "16px", border: "1px solid #D9CFB8" }}>
              <Typography sx={{ fontFamily: "'Fraunces', serif", fontSize: 20, color: "#1B2447", mb: 1 }}>
                {fetchError}
              </Typography>
              <Button onClick={() => window.location.reload()} sx={{ mt: 1, textTransform: "none", color: "#C16345", fontWeight: 600 }}>
                Retry
              </Button>
            </Box>
          ) : filteredProperties.length === 0 ? (
            <Box
              sx={{
                padding: "48px 24px",
                textAlign: "center",
                bgcolor: "#FFFAF0",
                borderRadius: "16px",
                border: "1px solid #D9CFB8",
              }}
            >
              <Typography
                sx={{
                  fontFamily: "'Fraunces', serif",
                  fontSize: 20,
                  color: "#1B2447",
                  mb: 1,
                }}
              >
                No homes found
              </Typography>
              <Typography sx={{ fontSize: 14, color: "#6B7390" }}>
                {selectedCategory ? `No "${selectedCategory}" stays nearby — try a different category.` : "Try a different location or zoom out on the map."}
              </Typography>
            </Box>
          ) : (
            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: {
                  xs: "1fr",
                  sm: "repeat(2, 1fr)",
                },
                gap: "24px",
              }}
            >
              {filteredProperties.map((p) => (
                <Link
                  key={p.id}
                  to={`/property/detail/${p.id}`}
                  style={{ textDecoration: "none" }}
                  onMouseEnter={() => setHoveredId(p.id)}
                  onMouseLeave={() => setHoveredId(null)}
                >
                  <Box
                    sx={{
                      "& .card-img-wrapper": { aspectRatio: "4/3 !important" },
                      transform:
                        hoveredId === p.id ? "translateY(-3px)" : "none",
                      transition: "transform .2s ease",
                    }}
                  >
                    <HomePropCard
                      id={p.id}
                      image={p.image}
                      name={p.name}
                      location={p.location}
                      price={p.priceLabel}
                      tag={p.tag}
                      rating={p.rating}
                    />
                  </Box>
                </Link>
              ))}
            </Box>
          )}
        </Box>

        {/* ── RIGHT: sticky interactive map ── */}
        <Box
          sx={{
            display: {
              xs: mobileView === "map" ? "block" : "none",
              md: "block",
            },
            position: { xs: "static", md: "sticky" },
            top: { md: 88 }, // below sticky AppBar
            alignSelf: { md: "flex-start" }, // collapse to map height instead of matching left column
            height: {
              xs: "calc(100vh - 180px)",
              md: "calc(100vh - 120px)",
            },
            minHeight: { xs: "60vh", md: 600 },
            bgcolor: "#EFE7D6",
            borderRadius: { md: "18px" },
            overflow: "hidden",
          }}
        >
          <ListingMap
            properties={mapProperties}
            hoveredId={hoveredId}
            onHoverPin={setHoveredId}
            onClickPin={(id) => navigate(`/property/detail/${id}`)}
            searchOnMove={searchOnMove}
            onToggleSearchOnMove={handleToggleSearchOnMove}
            onMoveEnd={handleMoveEnd}
            initialCenter={userCoords}
            initialZoom={12}
          />
        </Box>
      </Box>
    </Box>
  );
};

export default PropertyListing;
