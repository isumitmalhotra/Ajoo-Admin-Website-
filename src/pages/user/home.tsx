import "../../styles/user/Home.css";
import "slick-carousel/slick/slick.css";
import "slick-carousel/slick/slick-theme.css";
import { useEffect, useState } from "react";
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
import Reveal from "../../components/frontend/Reveal";
import JoinusNow from "../../assets/UI/joinusNow.jpg";
import { faqs } from "../../styles/utils/reusableData";
import { searchProperties } from "../../services/customerApi";

const GOA = { lat: 15.4909, lng: 73.8278 };

const Home = () => {
  // Featured properties — real data from POST /properties/search (geo-based).
  const [hotels, setHotels] = useState<any[]>([]);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const coords = await new Promise<{ lat: number; lng: number }>((resolve) => {
          if (!("geolocation" in navigator)) return resolve(GOA);
          navigator.geolocation.getCurrentPosition(
            (p) => resolve({ lat: p.coords.latitude, lng: p.coords.longitude }),
            () => resolve(GOA),
            { timeout: 5000 }
          );
        });
        // Wider radius so "near me" surfaces stays across the user's region,
        // not just within the backend's tight 5km default.
        const rows = await searchProperties({ latitude: coords.lat, longitude: coords.lng, radius: 100 });
        if (cancelled) return;
        setHotels(
          rows.map((p) => ({
            id: p.property_id,
            image:
              p.coverImage ||
              (p.images && p.images.length > 0 ? p.images[0] : "") ||
              `https://picsum.photos/seed/aajoo${p.property_id}/600/400`,
            name: p.property_name,
            location: p.property_address || p.property_city || "India",
            price: `₹${(Number(p.property_price) || 0).toLocaleString("en-IN")}`,
            tag: (p.category_titles && p.category_titles[0]) || "Featured",
            rating: 4.5,
          }))
        );
      } catch {
        // leave empty → FeaturedProperties shows its empty state
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <Box sx={{ bgcolor: "#EFE7D6" }}>
      {/* 1. Hero */}
      <HeroSection />

      {/* 2. Search bar + category chips */}
      <MapandFilter />

      {/* 3. Featured properties */}
      <FeaturedProperties hotels={hotels} />

      {/* 4. Trust strip */}
      <Reveal>
        <WhyChooseUs />
      </Reveal>

      {/* 5. Destinations / Explore */}
      <Reveal>
        <ExploreMore />
      </Reveal>

      {/* 6. Become a Host CTA */}
      <Reveal>
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
      </Reveal>

      {/* 7. FAQ */}
      <Reveal>
        <FAQSection
          image="/faq_vector.jpg"
          faqs={faqs}
          description="Got questions? We've got answers for you!"
        />
      </Reveal>

      {/* 8. Reviews */}
      <Reveal>
        <ReviewSlider />
      </Reveal>

      {/* Floating ongoing booking */}
      <OngoingFloat />
    </Box>
  );
};

export default Home;
