// PageHeaderWithCategories.tsx
import React from "react";
import { Box, Typography } from "@mui/material";

interface Props {
  title?: string;
  categories: { img: string; label: string }[];
  selectedCategory: string | null;
  onSelect: (label: string) => void;
}

const PageHeaderWithCategories: React.FC<Props> = ({
  title = "Homes for you",
  categories,
  selectedCategory,
  onSelect,
}) => {
  return (
    <Box sx={{ width: "100%", mb: 2 }}>
      {/* Page Title */}
      <Typography
        sx={{
          fontSize: { xs: "1.3rem", md: "1.8rem" },
          fontWeight: 700,
          color: "#1B2447",
          mb: 1,
        }}
      >
        {title}
      </Typography>

      {/* Horizontal Categories */}
      <Box
        sx={{
          display: "flex",
          gap: { xs: 2, sm: 3 },
          overflowX: "auto",
          alignItems: "center",
          py: 1,
          scrollbarWidth: "none",
          "&::-webkit-scrollbar": { display: "none" },
        }}
      >
        {categories.map((cat) => (
          <Box
            key={cat.label}
            onClick={() => onSelect(cat.label)}
            sx={{
              minWidth: 80,
              textAlign: "center",
              cursor: "pointer",
              opacity: selectedCategory === cat.label ? 1 : 0.6,
              transform:
                selectedCategory === cat.label ? "scale(1.05)" : "scale(1)",
              transition: "0.2s",
            }}
          >
            <Box
              component="img"
              src={cat.img}
              alt={cat.label}
              sx={{ width: 40, height: 40 }}
            />
            <Typography
              sx={{
                fontSize: "0.78rem",
                mt: 0.5,
                fontWeight: 600,
                color: "#1B2447",
              }}
            >
              {cat.label}
            </Typography>
          </Box>
        ))}
      </Box>
    </Box>
  );
};

export default PageHeaderWithCategories;
