import { motion } from "framer-motion";
import { Link } from "react-router-dom";
import HomePropCard from "./HomePropCard";
import { useState } from "react";
import { Button, useMediaQuery, Box, Typography } from "@mui/material";

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.15, delayChildren: 0.2 },
  },
};

// const cardVariants = {
//   hidden: { opacity: 0, y: 30 },
//   visible: {
//     opacity: 1,
//     y: 0,
//     transition: { duration: 0.3, ease: [0.42, 0, 0.58, 1] },
//   },
// };

export default function FeaturedProperties({ hotels }: { hotels: any[] }) {
  const [visibleCount, setVisibleCount] = useState(12);

  // Responsive media queries
  const isLgDesktop = useMediaQuery("(min-width: 1600px)");
  const isDesktop = useMediaQuery("(min-width: 1200px)");
  const isLaptop = useMediaQuery("(min-width: 992px)");
  const isTablet = useMediaQuery("(min-width: 768px)");
  const isMobile = useMediaQuery("(min-width: 480px)");

  const loadMore = () => setVisibleCount((p) => p + 12);

  // Responsive column count
  const columns = isLgDesktop
    ? 6
    : isDesktop
    ? 5
    : isLaptop
    ? 4
    : isTablet
    ? 3
    : isMobile
    ? 2
    : 2; // mobile (incl. small phones) shows two columns

  return (
    <section className="featured-properties" style={{ marginTop: "3rem" }}>
      {/* ⭐ TITLE + DESCRIPTION */}
      <Box
        sx={{
          width: "100%",
          padding: "0 1rem",
          marginBottom: "1.5rem",
        }}
      >
        <Typography
          variant="h4"
          sx={{
            fontFamily: "'Fraunces', serif",
            fontWeight: 400,
            fontSize: "36px",
            letterSpacing: "-0.025em",
            // color: "#222",
            color: "#1B2447",
            marginBottom: "0.5rem",

          }}
        >
          Featured Properties
        </Typography>

        <Typography
          sx={{
            color: "#6B7390",
            fontSize: "14px",
            maxWidth: "600px",
            lineHeight: 1.6,
          }}
        >
          Explore our top-rated stays, selected to provide comfort, convenience,
          and unforgettable experiences.
        </Typography>
      </Box>

      {/* Empty state */}
      {(!hotels || hotels.length === 0) && (
        <Box
          sx={{
            mx: "1rem",
            my: "1rem",
            p: { xs: "32px 24px", md: "48px 32px" },
            borderRadius: "16px",
            border: "1px solid #D9CFB8",
            bgcolor: "#FFFAF0",
            textAlign: "center",
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: "12px",
          }}
        >
          <Box
            sx={{
              width: 56,
              height: 56,
              borderRadius: "14px",
              bgcolor: "rgba(27,36,71,0.06)",
              display: "grid",
              placeItems: "center",
              fontSize: 26,
            }}
          >
            🏡
          </Box>
          <Typography
            sx={{
              fontFamily: "'Fraunces', serif",
              fontSize: 22,
              fontWeight: 500,
              letterSpacing: "-0.02em",
              color: "#1B2447",
            }}
          >
            No featured stays just yet
          </Typography>
          <Typography
            sx={{
              fontSize: 14,
              color: "#6B7390",
              maxWidth: 420,
              lineHeight: 1.6,
            }}
          >
            We're curating the next round of handpicked stays. Check back soon, or browse all properties to find your perfect getaway.
          </Typography>
          <Link to="/property/list" style={{ textDecoration: "none" }}>
            <Button
              variant="contained"
              sx={{
                mt: 1,
                bgcolor: "#1B2447",
                color: "#FFFAF0",
                px: 3,
                py: 1,
                borderRadius: "10px",
                textTransform: "none",
                fontWeight: 600,
                "&:hover": { bgcolor: "#2A356B" },
              }}
            >
              Browse all properties
            </Button>
          </Link>
        </Box>
      )}

      {/* 🔥 PROPERTIES GRID */}
      <motion.div
        className="properties-grid"
        variants={containerVariants}
        initial="hidden"
        whileInView="visible"
        viewport={{ once: false, amount: 0.01 }}
        style={{
          display: "grid",
          gridTemplateColumns: `repeat(${columns}, 1fr)`,
          gap: "1rem",
          padding: "1rem",
        }}
      >
        {hotels?.slice(0, visibleCount).map((hotel, idx) => (
          <motion.div
            key={idx}
            // variants={cardVariants}
            initial="hidden"
            animate="visible"
          >
            <Link
              to={`/property/detail/${hotel.id}`}
              style={{ textDecoration: "none", color: "inherit" }}
            >
              <HomePropCard {...hotel} />
            </Link>
          </motion.div>
        ))}
      </motion.div>

      {/* Load More Button */}
      {visibleCount < hotels.length && (
        <div style={{ textAlign: "center", marginTop: "2rem" }}>
          <Button
            variant="contained"
            onClick={loadMore}
            sx={{
              bgcolor: "#1B2447",
              px: 4,
              py: 1.2,
              borderRadius: "10px",
              textTransform: "none",
              fontWeight: 600,
              "&:hover": { bgcolor: "#2A356B" },
            }}
          >
            Load More Properties
          </Button>
        </div>
      )}
    </section>
  );
}
