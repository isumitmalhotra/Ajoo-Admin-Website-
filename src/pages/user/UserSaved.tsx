import React, { useEffect, useState } from "react";
import { Box, Typography, CircularProgress, useMediaQuery } from "@mui/material";
import { Link } from "react-router-dom";
import HomePropCard from "../../components/frontend/HomePropCard";
import { getSavedProperties } from "../../services/customerApi";

const themeColor = "#1B2447";

interface SavedCard {
  id: number | string;
  image: string;
  name: string;
  location: string;
  price: string;
}

const UserSaved: React.FC = () => {
  const [items, setItems] = useState<SavedCard[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const isLgDesktop = useMediaQuery("(min-width: 1600px)");
  const isDesktop = useMediaQuery("(min-width: 1200px)");
  const isLaptop = useMediaQuery("(min-width: 992px)");
  const isTablet = useMediaQuery("(min-width: 768px)");
  const isMobile = useMediaQuery("(min-width: 480px)");

  const columns = isLgDesktop
    ? 5
    : isDesktop
    ? 4
    : isLaptop
    ? 3
    : isTablet
    ? 3
    : isMobile
    ? 2
    : 1;

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const rows = await getSavedProperties();
      setItems(
        rows.map((p: any) => ({
          id: p.property_id,
          image:
            p.coverImage ||
            (p.images && p.images.length > 0 ? p.images[0] : "") ||
            `https://picsum.photos/seed/aajoo${p.property_id}/600/400`,
          name: p.property_name || "Property",
          location: p.property_address || p.property_city || "India",
          price: `₹${(Number(p.property_price) || 0).toLocaleString("en-IN")}`,
        }))
      );
    } catch {
      setError("Couldn't load your saved properties. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  return (
    <Box sx={{ p: { xs: 1, sm: 2 } }}>
      <Typography
        variant="h5"
        sx={{
          fontWeight: 700,
          mb: 1,
          color: themeColor,
          fontFamily: "'Inter', sans-serif",
        }}
      >
        Saved Properties
      </Typography>
      <Typography sx={{ color: "#6B7390", fontSize: 14, mb: 3 }}>
        Stays you've hearted for later.
      </Typography>

      {loading && (
        <Box sx={{ display: "flex", justifyContent: "center", py: 6 }}>
          <CircularProgress sx={{ color: themeColor }} />
        </Box>
      )}

      {!loading && error && (
        <Typography sx={{ textAlign: "center", color: "#b00020", py: 4 }}>
          {error}
        </Typography>
      )}

      {!loading && !error && items.length === 0 && (
        <Typography sx={{ textAlign: "center", color: "#6B7390", py: 6 }}>
          You haven't saved any properties yet. Tap the heart on a stay to save it.
        </Typography>
      )}

      {!loading && !error && items.length > 0 && (
        <Box
          sx={{
            display: "grid",
            gridTemplateColumns: `repeat(${columns}, 1fr)`,
            gap: 2,
          }}
        >
          {items.map((it) => (
            <Link
              key={it.id}
              to={`/property/detail/${it.id}`}
              style={{ textDecoration: "none", color: "inherit" }}
            >
              <HomePropCard
                id={it.id}
                image={it.image}
                name={it.name}
                location={it.location}
                price={it.price}
                tag="Saved"
                initialSaved
                onToggleSaved={(_, saved) => {
                  // When unsaved from this page, drop it from the list.
                  if (!saved) setItems((prev) => prev.filter((p) => p.id !== it.id));
                }}
              />
            </Link>
          ))}
        </Box>
      )}
    </Box>
  );
};

export default UserSaved;
