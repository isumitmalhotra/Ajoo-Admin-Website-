import React from "react";
import { Box, Typography } from "@mui/material";

interface Props {
  title?: string;
  categories: { img?: string; label: string }[];
  selectedCategory: string | null;
  onSelect: (label: string) => void;
  resultCount?: number;
}

const PageHeaderWithCategories: React.FC<Props> = ({
  title = "Available Homes",
  categories,
  selectedCategory,
  onSelect,
  resultCount,
}) => {
  return (
    <Box sx={{ width: "100%", mb: "24px" }}>
      {/* Results header — POC spec: h2 28, sub fs 13, sort fs 13 */}
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "flex-end",
          mb: "20px",
          flexWrap: "wrap",
          gap: "8px",
        }}
      >
        <Box>
          <Typography
            component="h2"
            sx={{
              fontFamily: "'Fraunces', serif",
              fontWeight: 400,
              fontSize: 28,
              letterSpacing: "-0.02em",
              color: "#1B2447",
              lineHeight: 1.1,
            }}
          >
            {title}
          </Typography>
          {resultCount !== undefined && (
            <Typography sx={{ fontSize: 13, color: "#6B7390", mt: "4px" }}>
              {resultCount} properties found
            </Typography>
          )}
        </Box>
        <Typography
          sx={{
            fontSize: 13,
            color: "#6B7390",
            cursor: "pointer",
            "&:hover": { color: "#1B2447" },
          }}
        >
          Sort: Recommended ▾
        </Typography>
      </Box>

      {/* Filter chips row — POC spec: padding 16 0 24, chip padding 8 14, fs 13 */}
      <Box
        sx={{
          display: "flex",
          gap: "8px",
          overflowX: "auto",
          alignItems: "center",
          padding: "16px 0 24px",
          borderBottom: "1px solid #D9CFB8",
          scrollbarWidth: "none",
          "&::-webkit-scrollbar": { display: "none" },
        }}
      >
        {categories.map((cat) => {
          const isActive = selectedCategory === cat.label;
          return (
            <Box
              key={cat.label}
              onClick={() => onSelect(cat.label)}
              sx={{
                display: "inline-flex",
                alignItems: "center",
                gap: "6px",
                padding: "8px 14px",
                border: "1px solid",
                borderColor: isActive ? "#1B2447" : "#D9CFB8",
                borderRadius: "999px",
                fontSize: 13,
                fontWeight: isActive ? 600 : 500,
                color: isActive ? "#1B2447" : "#3D4670",
                bgcolor: isActive ? "rgba(27,36,71,.06)" : "#FFFAF0",
                cursor: "pointer",
                flexShrink: 0,
                transition: "0.2s",
                textTransform: "capitalize",
                boxShadow: isActive
                  ? "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)"
                  : "none",
                "&:hover": {
                  borderColor: "#1B2447",
                  bgcolor: "rgba(27,36,71,.04)",
                },
              }}
            >
              {cat.img && (
                <Box
                  component="img"
                  src={cat.img}
                  alt={cat.label}
                  sx={{ width: 18, height: 18, objectFit: "contain" }}
                />
              )}
              {cat.label}
            </Box>
          );
        })}
      </Box>
    </Box>
  );
};

export default PageHeaderWithCategories;
