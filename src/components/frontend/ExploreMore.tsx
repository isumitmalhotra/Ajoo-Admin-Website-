import React from "react";
import { Box, Typography } from "@mui/material";
import Slider from "react-slick";

const ExploreMore: React.FC = () => {
  const properties = [
    { id: 1, img: "/room2.jpg", title: "Luxury Villa in Manali" },
    { id: 2, img: "/room3.jpg", title: "Cozy Cottage in Shimla" },
    { id: 3, img: "/room4.jpg", title: "Beach House in Goa" },
    { id: 4, img: "/room1.jpg", title: "Hill View Stay in Mussoorie" },
  ];

  const sliderSettings = {
    dots: true,
    infinite: true,
    autoplay: true,
    autoplaySpeed: 2500,
    speed: 500,
    slidesToShow: 3,
    slidesToScroll: 1,
    arrows: false,
    responsive: [
      { breakpoint: 1200, settings: { slidesToShow: 2.5 } },
      { breakpoint: 900, settings: { slidesToShow: 2 } },
      { breakpoint: 600, settings: { slidesToShow: 1.2 } },
    ],
  };

  return (
    <Box
      sx={{
        mt: 5,
        p: { xs: 2, sm: 3 },
        backgroundColor: "#fff",
        ml: { xs: 0, md: 0 },
        borderRadius: 2,
        boxShadow: "0px 4px 12px rgba(0,0,0,0.08)",
        maxWidth: { md: "65%" },
        mx: "auto",
        overflow: "hidden",
      }}
    >
      <Typography
        sx={{
          fontSize: { xs: 20, sm: 22 },
          fontWeight: 700,
          color: "#1B2447",
          mb: 3,
          textAlign: "left",
        }}
      >
        Explore Nearby Places
      </Typography>

      <Box
        sx={{
          overflow: "hidden",
          width: "100%",
          ".slick-slider": { width: "100%" },
          ".slick-slide": {
            px: { xs: 0.5, sm: 1 },
            boxSizing: "border-box",
          },
          ".slick-track": {
            display: "flex",
            alignItems: "center",
          },
          ".slick-dots li button:before": {
            color: "#1B2447",
            fontSize: "10px",
          },
          ".slick-dots li.slick-active button:before": {
            color: "#1B2447",
          },
        }}
      >
        <Slider {...sliderSettings}>
          {properties.map((item) => (
            <Box
              key={item.id}
              sx={{
                p: 1,
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                textAlign: "center",
              }}
            >
              <Box
                component="img"
                src={item.img}
                alt={item.title}
                sx={{
                  width: "100%",
                  height: { xs: 160, sm: 200, md: 220 },
                  objectFit: "cover",
                  borderRadius: 2,
                  mb: 1.5,
                  boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
                }}
              />
              <Typography
                sx={{
                  fontWeight: 600,
                  color: "#333",
                  fontSize: { xs: 14, sm: 16 },
                }}
              >
                {item.title}
              </Typography>
            </Box>
          ))}
        </Slider>
      </Box>
    </Box>
  );
};

export default ExploreMore;
