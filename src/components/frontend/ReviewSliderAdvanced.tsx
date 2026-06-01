// components/ReviewSliderAdvanced.tsx
import React from "react";
import Slider from "react-slick";
import {
  Box,
  Typography,
  Avatar,
  Rating,
  useTheme,
  useMediaQuery,
} from "@mui/material";

interface Review {
  userName: string;
  profilePic: string;
  rating: number;
  title: string;
  description: string;
}

interface ReviewSliderProps {
  propertyId: string;
}

const reviews: Review[] = [
  {
    userName: "Priya Sharma",
    profilePic: "/users/priya.jpg",
    rating: 5,
    title: "Amazing stay!",
    description:
      "The apartment was clean, spacious, and had a great view. Highly recommended!",
  },
  {
    userName: "Rahul Verma",
    profilePic: "/users/rahul.jpg",
    rating: 4,
    title: "Comfortable and cozy",
    description: "Perfect for a weekend getaway. The host was very helpful.",
  },
  {
    userName: "Sneha Kapoor",
    profilePic: "/users/sneha.jpg",
    rating: 5,
    title: "Loved the interiors",
    description:
      "Modern design and peaceful location. Will definitely come back!",
  },
  {
    userName: "Arjun Mehta",
    profilePic: "/users/arjun.jpg",
    rating: 3,
    title: "Good but noisy",
    description: "Nice place but a bit noisy at night due to traffic.",
  },
  {
    userName: "Meera Iyer",
    profilePic: "/users/meera.jpg",
    rating: 4,
    title: "Family friendly",
    description: "Spacious and safe for kids. Great amenities.",
  },
  {
    userName: "Karan Singh",
    profilePic: "/users/karan.jpg",
    rating: 5,
    title: "Exceptional service",
    description: "The host went above and beyond. Truly memorable experience.",
  },
];

const Arrow = ({
  onClick,
  direction,
}: {
  onClick?: () => void;
  direction: "left" | "right";
}) => (
  <Box
    onClick={onClick}
    sx={{
      position: "absolute",
      top: "45%",
      [direction === "left" ? "left" : "right"]: -30,
      zIndex: 10,
      width: 40,
      height: 40,
      backgroundColor: "#1B2447",
      borderRadius: "50%",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      color: "#fff",
      cursor: "pointer",
      fontSize: 22,
      "&:hover": {
        backgroundColor: "#2A356B",
      },
    }}
  >
    {direction === "left" ? "<" : ">"}
  </Box>
);

const ReviewSliderAdvanced: React.FC<ReviewSliderProps> = ({ propertyId }) => {
  console.log(propertyId)
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const settings = {
    dots: true,
    infinite: true,
    speed: 600,
    slidesToShow: isMobile ? 1 : 3,
    slidesToScroll: 1,
    arrows: true,
    autoplay: true,           // enable auto sliding
    autoplaySpeed: 3000,      // 3000ms = 3 seconds per slide
    nextArrow: <Arrow direction="right" />,
    prevArrow: <Arrow direction="left" />,
    responsive: [
      {
        breakpoint: 1024,
        settings: { slidesToShow: 1 },
      },
    ],
  };
  

  return (
    <Box sx={{ mt: 6, fontFamily: "Roboto, sans-serif", px: 1 }}>
      <Typography
        sx={{
          fontSize: { xs: 28, sm: 36 },
          fontWeight: 600,
          mb: 3,
          color: "#1B2447",
          textAlign: "center",
        }}
      >
        What People Say About This Property
      </Typography>

      {reviews.length === 0 ? (
        <Typography
          sx={{
            fontSize: 16,
            color: "#777",
            textAlign: "center",
            py: 5,
          }}
        >
          No reviews yet
        </Typography>
      ) : (
        <Slider {...settings}>
          {reviews.map((review, index) => (
            <Box
              key={index}
              sx={{
                p: 3,
                mx: 1,
                backgroundColor: "#fff",
                borderRadius: 3,
                boxShadow: "0px 4px 20px rgba(0,0,0,0.08)",
                minHeight: 200,
                display: "flex",
                flexDirection: "column",
                justifyContent: "space-between",
                transition: "transform 0.3s",
                "&:hover": { transform: "translateY(-5px)" },
              }}
            >
              <Box sx={{ display: "flex", alignItems: "center", gap: 2 }}>
                <Avatar
                  src={review.profilePic}
                  alt={review.userName}
                  sx={{ width: 50, height: 50 }}
                />
                <Box>
                  <Typography
                    sx={{ fontWeight: 600, fontSize: 15, color: "#333" }}
                  >
                    {review.userName}
                  </Typography>
                  <Rating value={review.rating} readOnly size="small" />
                </Box>
              </Box>
              <Box sx={{ mt: 2 }}>
                <Typography
                  sx={{
                    fontSize: 16,
                    fontWeight: 500,
                    mb: 1,
                    color: "#1B2447",
                  }}
                >
                  {review.title}
                </Typography>
                <Typography
                  sx={{
                    fontSize: 14,
                    color: "#555",
                    lineHeight: 1.5,
                    maxHeight: 70,
                    overflow: "hidden",
                    textOverflow: "ellipsis",
                  }}
                >
                  {review.description}
                </Typography>
              </Box>
            </Box>
          ))}
        </Slider>
      )}
    </Box>
  );
};

export default ReviewSliderAdvanced;
