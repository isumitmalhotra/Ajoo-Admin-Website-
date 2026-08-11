import React from "react";
import { Swiper, SwiperSlide } from "swiper/react";
import { Navigation, Autoplay } from "swiper/modules";
import "swiper/css";
import "swiper/css/navigation";
import { Box, Typography, Card, CardContent, Rating } from "@mui/material";

interface Review {
  name: string;
  review: string;
  location: string;
  rating: number;
}

const reviews: Review[] = [
  { name: "Amit Sharma", review: "The property was excellent, service was top-notch. Highly recommend!", location: "Delhi, India", rating: 5 },
  { name: "Priya Verma", review: "Amazing location and very clean rooms. Would stay again.", location: "Mumbai, India", rating: 4.5 },
  { name: "Rahul Kumar", review: "Loved the amenities. Everything was perfect for our vacation.", location: "Bangalore, India", rating: 5 },
  { name: "Sneha Gupta", review: "Peaceful environment, friendly staff, and great food.", location: "Jaipur, India", rating: 4.5 },
  { name: "Karan Singh", review: "Affordable and luxurious at the same time. Great experience!", location: "Chandigarh, India", rating: 5 },
  { name: "Neha Kapoor", review: "The pool and spa facilities were amazing. Highly recommend.", location: "Goa, India", rating: 4 },
  { name: "Ravi Patel", review: "Modern interiors and very comfortable rooms.", location: "Ahmedabad, India", rating: 4.5 },
  { name: "Meera Iyer", review: "Had the best holiday with my family. Will come back again!", location: "Chennai, India", rating: 5 },
  { name: "Vikas Yadav", review: "Best hospitality experience. Staff was very polite and helpful.", location: "Lucknow, India", rating: 4.5 },
  { name: "Ananya Das", review: "The resort is surrounded by nature. Very refreshing stay!", location: "Kolkata, India", rating: 5 },
];

const ReviewSlider: React.FC = () => {
  return (
    <Box
      sx={{
        width: "100%",
        maxWidth: "1200px",
        mx: "auto",
        my: { xs: 4, md: 8 },
        px: { xs: 2, sm: 3, md: 4 },
      }}
    >
      <Typography
        variant="h4"
        sx={{
          textAlign: "center",
          fontWeight: "bold",
          mb: { xs: 3, md: 5 },
          color: "#1B2447",
          fontFamily: "'Fraunces', serif",
          fontSize: { xs: "1.5rem", sm: "1.8rem", md: "2rem" },
        }}
      >
        What Our Guests Say
      </Typography>

      <Swiper
        modules={[Navigation, Autoplay]}
        autoplay={{ delay: 2500, disableOnInteraction: false }}
        spaceBetween={20}
        breakpoints={{
          0: { slidesPerView: 1, spaceBetween: 12 },
          600: { slidesPerView: 1.3, spaceBetween: 16 },
          900: { slidesPerView: 2, spaceBetween: 20 },
          1200: { slidesPerView: 3, spaceBetween: 24 },
        }}
        style={{ paddingBottom: "50px" }}
      >
        {reviews.map((rev, idx) => (
          <SwiperSlide key={idx}>
            <Card
              sx={{
                height: "100%",
                borderRadius: "16px",
                background: "#FFFAF0",
                border: "1px solid #D9CFB8",
                boxShadow: "0 6px 20px rgba(27,36,71, 0.15)",
                transition: "transform 0.3s ease, box-shadow 0.3s ease",
                p: { xs: 1.5, sm: 2 },
                "&:hover": {
                  transform: { md: "translateY(-6px)" },
                  boxShadow: "0 10px 25px rgba(27,36,71, 0.25)",
                },
              }}
            >
              <CardContent sx={{ textAlign: "left" }}>
                <Box sx={{ display: "flex", alignItems: "center", gap: 0.75, mb: 1.5 }}>
                  <Rating
                    value={rev.rating}
                    precision={0.5}
                    readOnly
                    size="small"
                    sx={{ color: "#C16345" }}
                  />
                  <Typography sx={{ fontSize: "0.85rem", fontWeight: 700, color: "#1B2447" }}>
                    {rev.rating.toFixed(1)}
                  </Typography>
                </Box>
                <Typography
                  variant="body1"
                  sx={{
                    fontStyle: "italic",
                    mb: 2,
                    color: "#333",
                    fontSize: { xs: "0.9rem", sm: "1rem" },
                    lineHeight: 1.6,
                  }}
                >
                  “{rev.review}”
                </Typography>
                <Typography
                  variant="subtitle1"
                  sx={{
                    fontWeight: 700,
                    color: "#1B2447",
                    mb: 0.5,
                    fontSize: { xs: "0.95rem", sm: "1rem" },
                  }}
                >
                  {rev.name}
                </Typography>
                <Typography
                  variant="body2"
                  sx={{
                    color: "#6B7390",
                    fontSize: { xs: "0.8rem", sm: "0.9rem" },
                  }}
                >
                  {rev.location}
                </Typography>
              </CardContent>
            </Card>
          </SwiperSlide>
        ))}
      </Swiper>

      <style>
        {`
          .swiper-button-next,
          .swiper-button-prev {
            color: #1B2447 !important;
            background: #fff;
            border: 2px solid #1B2447;
            width: 40px;
            height: 40px;
            border-radius: 50%;
            display: flex;
            justify-content: center;
            align-items: center;
            box-shadow: 0 4px 12px rgba(27,36,71, 0.2);
            top: 45%;
            transition: all 0.3s ease;
          }

          .swiper-button-next:hover,
          .swiper-button-prev:hover {
            background: #1B2447;
            color: #fff !important;
          }

          .swiper-button-prev {
            left: -50px;
          }

          .swiper-button-next {
            right: -50px;
          }

          @media (max-width: 900px) {
            .swiper-button-prev { left: -30px; }
            .swiper-button-next { right: -30px; }
          }

          @media (max-width: 600px) {
            .swiper-button-prev, .swiper-button-next {
              display: none !important;
            }
          }
        `}
      </style>
    </Box>
  );
};

export default ReviewSlider;
