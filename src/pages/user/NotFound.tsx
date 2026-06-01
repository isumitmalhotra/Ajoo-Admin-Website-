import React from "react";
import { Box, Typography, Button } from "@mui/material";
import { useNavigate } from "react-router-dom";

interface NotFoundProps {
  image?: string; // optional prop for custom 404 image
}

const NotFound: React.FC<NotFoundProps> = ({ image }) => {
  const navigate = useNavigate();

  return (
    <Box
      sx={{
        minHeight: "100vh",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        textAlign: "center",
        bgcolor: "#f5f5f5",
        px: 2,
      }}
    >
      {image && (
        <Box
          component="img"
          src={image}
          alt="404 Not Found"
          sx={{
            width: "100%", // spans full width
            height: { xs: "250px", sm: "350px", md: "500px" }, // responsive height
            objectFit: "cover",
            mb: 4,
          }}
        />
      )}

      <Typography
        variant="h3"
        sx={{
          fontWeight: 700,
          color: "#1B2447",
          mb: 2,
          fontSize: { xs: "2rem", sm: "2.5rem", md: "3rem" },
        }}
      >
        404
      </Typography>

      <Typography
        variant="h6"
        sx={{
          color: "#555",
          mb: 4,
          fontSize: { xs: "1rem", sm: "1.2rem", md: "1.5rem" },
        }}
      >
        Oops! The page you are looking for does not exist.
      </Typography>

      <Button
        variant="contained"
        sx={{
          bgcolor: "#1B2447",
          "&:hover": { bgcolor: "#2A356B" },
          textTransform: "none",
          px: 4,
          py: 1.5,
          fontSize: { xs: "0.9rem", sm: "1rem", md: "1.1rem" },
        }}
        onClick={() => navigate("/")}
      >
        Go Back Home
      </Button>
    </Box>
  );
};

export default NotFound;
