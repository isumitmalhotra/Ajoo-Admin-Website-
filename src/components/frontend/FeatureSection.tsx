import { Box, Typography } from "@mui/material";
import AutorenewIcon from "@mui/icons-material/Autorenew";
import RoomServiceIcon from "@mui/icons-material/RoomService";
import RateReviewIcon from "@mui/icons-material/RateReview";
import "../../styles/user/FeatureSection.css";

const features = [
  {
    icon: <AutorenewIcon sx={{ fontSize: 40, color: "#1B2447" }} />,
    title: "Keep it flexible",
    description:
      "Choose from flexible booking options and hassle-free cancellations.",
  },
  {
    icon: <RoomServiceIcon sx={{ fontSize: 40, color: "#1B2447" }} />,
    title: "Get the amenities you want",
    description:
      "Pick properties that match your lifestyle with the right facilities.",
  },
  {
    icon: <RateReviewIcon sx={{ fontSize: 40, color: "#1B2447" }} />,
    title: "Read real reviews",
    description:
      "Make confident decisions with verified guest reviews you can trust.",
  },
];

const FeatureSection = () => {
  return (
    <Box className="main_box">
      <Box className="feature-section">
        {features.map((feature, idx) => (
          <Box className="feature-card" key={idx}>
            {feature.icon}
            <Typography variant="h6" className="feature-title">
              {feature.title}
            </Typography>
            <Typography variant="body2" className="feature-desc">
              {feature.description}
            </Typography>
          </Box>
        ))}
      </Box>
    </Box>
  );
};

export default FeatureSection;
