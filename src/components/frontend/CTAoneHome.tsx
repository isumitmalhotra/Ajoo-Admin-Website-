import { Box, Typography, Button } from "@mui/material";

interface CTAoneHomeProps {
  backgroundImage: string;   // Background image URL
  title: string;             // Title text
  buttonText?: string;       // Button text (optional, default "View Rooms")
  onButtonClick: () => void; // Function (API call or any handler)
}

const CTAoneHome: React.FC<CTAoneHomeProps> = ({
  backgroundImage,
  title,
  buttonText = "View Rooms",
  onButtonClick,
}) => {
  return (
    <Box
      sx={{
        backgroundImage: `url(${backgroundImage})`,
        backgroundSize: "cover",
        backgroundPosition: "center",
        backgroundRepeat: "no-repeat",
        py: 15,
        textAlign: "center",
        color: "#fff",
        position: "relative",
      }}
    >
      {/* Overlay */}
      <Box
        sx={{
          position: "absolute",
          inset: 0,
          bgcolor: "rgba(0,0,0,0.5)",
        }}
      />

      {/* Content */}
      <Box sx={{ position: "relative", zIndex: 1 }}>
        <Typography
          variant="h4"
          fontWeight="bold"
          mb={2}
          sx={{
            fontFamily: "'Fraunces', serif",
            fontSize: { xs: "1.8rem", md: "2.5rem" },
            letterSpacing: 1,
          }}
        >
          {title}
        </Typography>

        <Button
          variant="contained"
          onClick={onButtonClick} // ✅ dynamic function
          sx={{
            bgcolor: "#fff",
            color: "#1B2447",
            fontWeight: "bold",
            fontFamily: "'Inter', system-ui, sans-serif",
            px: 4,
            py: 1.5,
            borderRadius: "30px",
            boxShadow: 3,
            "&:hover": {
              bgcolor: "#EFE7D6",
            },
          }}
        >
          {buttonText}
        </Button>
      </Box>
    </Box>
  );
};

export default CTAoneHome;
