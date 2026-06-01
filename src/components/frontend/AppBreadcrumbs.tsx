import React from "react";
import { Breadcrumbs, Link, Typography, Box } from "@mui/material";
import NavigateNextIcon from "@mui/icons-material/NavigateNext";

interface Props {
  items: { label: string; link?: string }[];
}

export const AppBreadcrumbs: React.FC<Props> = ({ items }) => {
  return (
    <Box sx={{ py: 2 }}>
      <Breadcrumbs
        separator={<NavigateNextIcon fontSize="small" sx={{ color: "#1B2447" }} />}
        aria-label="breadcrumb"
        sx={{
          "& a": {
            textDecoration: "none",
            color: "#1B2447",
            fontWeight: 500,
            fontSize: "0.95rem",
            fontFamily: "'Poppins', sans-serif",
            transition: "0.2s",
            "&:hover": { color: "#8A2C4A" },
          },
          "& p": {
            color: "#444",
            fontWeight: 600,
            fontSize: "0.95rem",
            fontFamily: "'Poppins', sans-serif",
          },
        }}
      >
        {items.map((item, index) =>
          item.link ? (
            <Link key={index} href={item.link}>
              {item.label}
            </Link>
          ) : (
            <Typography key={index}>{item.label}</Typography>
          )
        )}
      </Breadcrumbs>
    </Box>
  );
};
