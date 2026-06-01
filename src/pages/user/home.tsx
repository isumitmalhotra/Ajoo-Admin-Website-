import "../../styles/user/Home.css";
import "slick-carousel/slick/slick.css";
import "slick-carousel/slick/slick-theme.css";
import { Box } from "@mui/material";
import { Link } from "react-router-dom";
import {
  MapandFilter,
  FAQSection,
  ReviewSlider,
  FeaturedProperties,
  OngoingFloat,
  WhyChooseUs,
  ExploreMore,
} from "../../components";
import HeroSection from "../../components/frontend/HeroSection";
import JoinusNow from "../../assets/UI/joinusNow.jpg";
import { hotels, faqs } from "../../styles/utils/reusableData";

const Home = () => {
  return (
    <Box sx={{ bgcolor: "#EFE7D6" }}>
      {/* 1. Hero */}
      <HeroSection />

      {/* 2. Search bar + category chips */}
      <MapandFilter />

      {/* 3. Featured properties */}
      <FeaturedProperties hotels={hotels} />

      {/* 4. Trust strip */}
      <WhyChooseUs />

      {/* 5. Destinations / Explore */}
      <ExploreMore />

      {/* 6. Become a Host CTA */}
      <div className="addHostSection">
        <div className="addHostSectionLeft">
          <img src={JoinusNow} alt="Become a Host" />
        </div>
        <div className="addHostSectionRight">
          <h2>Become a Host</h2>
          <p className="addHostDesc">
            Turn your extra space into an opportunity. Whether you have a cozy
            apartment, a charming villa, or a vacation home, Aajoo Homes makes
            it simple and secure to list your property. Connect with verified
            guests, earn extra income, and share your hospitality with travelers
            from around the world — all while maintaining complete control over
            your property.
          </p>
          <Link to="/become-a-host" className="addHostButton">
            Get Started
          </Link>
        </div>
      </div>

      {/* 7. FAQ */}
      <FAQSection
        image="/faq_vector.jpg"
        faqs={faqs}
        description="Got questions? We've got answers for you!"
      />

      {/* 8. Reviews */}
      <ReviewSlider />

      {/* Floating ongoing booking */}
      <OngoingFloat />
    </Box>
  );
};

export default Home;
