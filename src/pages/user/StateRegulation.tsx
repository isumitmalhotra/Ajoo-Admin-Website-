import React, { useState } from "react";
import {
  Box,
  Typography,
  Container,
  useTheme,
  useMediaQuery,
  Button,
} from "@mui/material";
import { RegulationModal } from "../../components";
// import Img1 from "../../assets/UI/chandigarh.jpeg";
import shimlahimachal from "../../assets/provided asset/shimlahimachal.jpg";
import punjab from "../../assets/provided asset/punjab.jpg";
import chandigarh from "../../assets/provided asset/chandigarh.jpg";

const StateRegulation: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const [openModal, setOpenModal] = useState(false);
  const [modalData, setModalData] = useState({ title: "", content: "" });

  const handleOpenModal = (title: string, content: string) => {
    setModalData({ title, content });
    setOpenModal(true);
  };
  const handleCloseModal = () => setOpenModal(false);

  // 🏔️ Himachal Pradesh content
  const himachalContent = `
  🏔️ Hosting with Aajoo in Himachal Pradesh
If you’re thinking about opening your home to travelers in Himachal Pradesh, you’re in the right place. At Aajoo, we help everyday homeowners, families, and locals turn extra rooms or unused spaces into meaningful income, while giving travelers an authentic Himachali experience.
But before you start, it’s important to know the local regulations. Himachal Pradesh has a clear framework for homestays, designed to protect hosts, guests, and the community. Aajoo guides you through this process step by step.
✅ Registration Requirements
In Himachal Pradesh, all homestays must be registered under the Himachal Pradesh Homestay Scheme.
    • Who can apply?
 Any permanent resident of Himachal Pradesh who owns a residential house.
    • How many rooms?
 You can host up to 3 rooms for paying guests.
    • Why register?
        ◦ Legal recognition from the state.
        ◦ Eligible for tourism promotion programs.
        ◦ Builds guest trust and improves your bookings on Aajoo.

📝 How Registration Works
    1. Fill out the application – Available at the Department of Tourism & Civil Aviation, HP.
    2. Submit documents – Proof of residence, property ownership, and a No Objection Certificate (NOC) from your local authority.
    3. Inspection – A tourism officer will visit your property to ensure it meets basic standards.
    4. Certificate issued – Once approved, you’ll receive a registration certificate.

👉 Aajoo helps you prepare documents, connect with authorities, and list your property faster.

🛡️ Operating Standards
To stay compliant, every Himachal homestay must follow some essential rules:
    • Guest Records – Keep a simple register of all guests, including ID proofs. (Aajoo provides digital tools for this.)
    • Safety – Install fire extinguishers, follow electrical safety norms, and keep a first-aid kit.
    • Cleanliness – Maintain hygienic rooms, bathrooms, and common areas.
    • Noise Control – Ensure your homestay is a peaceful place for both guests and neighbors.

💰 Taxes & Legal
    • Property Tax – Keep municipal taxes updated; hosting may affect this.
    • Income Tax – Hosting income should be declared in your annual tax return.
    • GST – Only applicable if your income crosses the government threshold.

👉 Don’t worry — Aajoo gives you simple tax checklists so you never feel lost.

📞 Helpful Contacts
    • Department of Tourism & Civil Aviation, HP
 Block No. 28, SDA Complex, Kasumpti, Shimla – 171009
 📞 +91-177-2625924, 2625925 | ✉️ tourismmin-hp@nic.in
    • Urban Development, HP
 Nigam Vihar, Shimla – 171002
 📞 +91-177-2626518 | ✉️ ud-hp@nic.in

🌟 Why Host with Aajoo?
    • We simplify registration & compliance so you don’t have to chase government offices alone.
    • We boost your visibility — more travelers see your homestay on Aajoo.
    • We give you tools to manage bookings, guest records, and reviews.
    • We support you locally — real people in Himachal helping you succeed.

🚀 Conclusion
Hosting in Himachal Pradesh is more than just renting rooms — it’s about sharing your culture, your food, and your home with the world. By joining Aajoo and registering under the Himachal Homestay Scheme, you not only earn income but also contribute to sustainable tourism in the hills.
👉 Ready to start? Join Aajoo today and let us guide you from registration to your very first guest.
.
    `;

  const punjabContent = `
    🌾 Hosting with Aajoo in Punjab
Punjab is famous for its warmth, culture, and hospitality — and now you can share that spirit with travelers by opening your home as a homestay or Bed & Breakfast (BnB). At Aajoo, we help you turn spare rooms into income while making sure you meet all state rules and tourism standards.
Here’s what you need to know before you start hosting in Punjab.

✅ Who Can Become a Host?
    • You must own the property or have legal rights to it.
    • The host or family must live on the premises.
    • You can offer 1 to 6 rooms for tourists.
    • Your homestay must meet basic safety and hygiene standards.

📝 Registrations & Approvals
To operate legally in Punjab, here’s what hosts usually need:
    • Trade License – From your local municipal corporation.
    • Tourism Registration – Apply via the Punjab Tourism Development Corporation (PTDC) or through Punjab e-Services.
    • FSSAI Registration – If you’re serving food (mandatory for BnBs).
    • Fire Safety Certificate – From your local fire department.
    • GST Registration – If your income crosses the government threshold.
    • Local Approvals – Ensure your property follows building codes and municipal rules.

👉 Don’t worry — Aajoo helps you prepare documents, get NOCs, and complete applications hassle-free.

🔍 Registration Process (Step by Step)
    1. Apply Online/Offline – Fill out the PTDC form.
    2. Submit Documents – ID, property ownership proof, NOC from municipality, fire safety certificate, photos of property.
    3. Inspection – Officials will check your property for hygiene, safety, and facilities.
    4. Approval & License – Once verified, you get your license to host.
    5. Renewal – Licenses must be renewed annually.

🛡️ Operating Standards for Punjab Hosts
    • Guest Register – Record all guest details with ID proofs (Aajoo app helps digitize this).
    • Fire & Safety – Install extinguishers and maintain clear exits.
    • Cleanliness – Keep rooms, bathrooms, and common spaces hygienic.
    • Amenities – Provide clean linen, basic toiletries, safe drinking water, and (for BnBs) breakfast.
    • Noise & Respect – Ensure your homestay is guest-friendly and neighbor-friendly.

🌟 Benefits of Registering
By complying with Punjab’s homestay/BnB regulations, you get:
    • Official Recognition – Builds trust with travelers.
    • Marketing Support – Your homestay may be featured on Punjab Tourism websites.
    • Training & Workshops – Access to hospitality training by tourism boards.
    • Tourism Boost – Increased visibility with both domestic and international guests.

With Aajoo, you get all of this plus digital visibility, booking tools, and host support.

📞 Helpful Contacts
    • Punjab Tourism Development Corporation (PTDC)
 🌐 punjabtourism.punjab.gov.in
 📍 SCO 183-184, Sector 8-C, Chandigarh, Punjab
    • Punjab e-Services Portal
 🌐 eservices.punjab.gov.in

🚀 Why Host with Aajoo in Punjab?
    • We simplify compliance (licenses, approvals, renewals).
    • We increase your reach with travelers looking for real Punjabi hospitality.
    • We give you tools for bookings, payments, and guest records.
    • We are your local growth partner — not just a booking app.

✨ Conclusion
Hosting in Punjab isn’t just about extra income — it’s about sharing your culture, food, and traditions with the world. By registering your homestay under Punjab’s guidelines and partnering with Aajoo, you make your property guest-ready, legal, and profitable.
👉 Ready to host? Start with Aajoo today and let us walk with you from registration to your first guest.`;

  // 🏡 Chandigarh content
  const chandigarhContent = `
🏡 Host with Aajoo in Chandigarh
Chandigarh isn’t just a city — it’s a planned masterpiece with a blend of modernity and culture. More travelers now want to stay with locals instead of hotels, which is why homestays and BnBs are growing here.
With Aajoo, you can turn your extra space into income + cultural exchange, while we help you with registrations, guest bookings, and digital growth.
✅ Who Can Host in Chandigarh?
    • Property must be owned or leased by you/family.
    • Host must live on the property.
    • You can host 1 to 6 rooms for tourists.
    • Property must follow safety, hygiene, and municipal rules.

👉 If you meet these points, Aajoo helps you become tourism-compliant and guest-ready.
📝 Chandigarh Registration Made Easy
Here’s how the official process works — with Aajoo guiding you step by step:
1. Application
    • Apply on the Chandigarh Tourism website or visit their office.
    • Fill out the homestay/BnB application form.

2. Submit Documents
    • ID + Address Proof (Aadhaar, PAN, Passport).
    • Property ownership or lease documents.
    • NOC from local authority/Chandigarh Administration.
    • Fire Safety Certificate.
    • Layout plan + photos of rooms.

3. Inspection
    • Officials visit your property to check hygiene, safety, and facilities.

4. License & Renewal
    • If approved, you’ll get your homestay/BnB license.
    • Must be renewed every year with updated documents.

👉 Don’t stress. Aajoo helps you collect documents, prepare the layout plan, get fire NOC, and track renewals.

🛡️ Hosting Standards in Chandigarh
Once approved, here’s what’s expected from every host:
    • Fire Safety – Extinguishers & safety exits.
    • Guest Register – Record every guest with ID (Aajoo app digitizes this).
    • Cleanliness – Rooms, bathrooms, kitchens must stay hygienic.
    • Basic Amenities – Clean linen, toiletries, safe water.
    • BnB Requirement – Serve simple, hygienic breakfast.
    • Fair Pricing – Keep rates transparent and competitive.


📈 How Aajoo Helps You Grow
Most hosts get stuck after licensing. Aajoo takes you further:
    • Compliance Partner – We ensure you stay 100% legal.
    • Digital Visibility – Get listed on Aajoo + major travel platforms.
    • Smart Pricing Tools – Set competitive rates, maximize occupancy.
    • Guest Management – Digital register, bookings, and payments — all in one place.
    • Marketing Boost – Local + digital promotions to attract tourists.


📞 Chandigarh Tourism Contacts
    • 🌐 Chandigarh Tourism Website
    • 📧 info@chandigarhtourism.gov.in
    • ☎ +91-172-2740420


🚀 Why Choose Aajoo in Chandigarh?
    • We simplify paperwork and compliance.
    • We increase your bookings through visibility + smart tools.
    • We help you earn more from your extra space.
    • We position you as a part of Chandigarh’s tourism growth story.


✨ Final Word
Hosting in Chandigarh means more than income — it’s about sharing the city’s modern design, gardens, and Punjabi-Haryanvi culture with guests. With Aajoo by your side, you don’t just open your doors — you open opportunities.
👉 Start your Chandigarh hosting journey with Aajoo today.`;

  // ✅ Common Section component
  const Section = ({
    title,
    description,
    image,
    reverse,
    content,
  }: {
    title: string;
    description: string;
    image: string;
    reverse?: boolean;
    content: string;
  }) => (
    <Box
      sx={{
        width: "80%",
        backgroundColor: "#fff",
        boxShadow: "0 4px 20px rgba(0,0,0,0.1)",
        borderRadius: "16px",
        display: "flex",
        flexDirection: isMobile ? "column" : reverse ? "row-reverse" : "row",
        alignItems: "center",
        justifyContent: "space-between",
        p: { xs: 3, md: 5 },
        gap: 3,
        mb: 5,
      }}
    >
      {/* Text Side */}
      <Box sx={{ flex: 1 }}>
        <Typography
          variant="h5"
          sx={{
            fontWeight: 600,
            mb: 2,
            color: "#1B2447",
            fontFamily: "'Poppins', sans-serif",
          }}
        >
          {title}
        </Typography>

        <Typography
          variant="body1"
          sx={{
            fontSize: "1rem",
            color: "#555",
            lineHeight: 1.7,
            fontFamily: "'Poppins', sans-serif",
          }}
        >
          {description}
        </Typography>

        <Button
          variant="text"
          sx={{
            mt: 2,
            color: "#1B2447",
            textTransform: "none",
            fontWeight: 600,
            "&:hover": { backgroundColor: "#fce4ec" },
          }}
          onClick={() => handleOpenModal(title, content)}
        >
          Read More →
        </Button>
      </Box>

      {/* Image Side */}
      <Box
        sx={{
          flex: 1,
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
        }}
      >
        <Box
          component="img"
          src={image}
          alt={title}
          sx={{
            width: "100%",
            maxWidth: 400,
            borderRadius: "12px",
            boxShadow: "0 4px 10px rgba(0,0,0,0.15)",
          }}
        />
      </Box>
    </Box>
  );

  return (
    <Container
      maxWidth="lg"
      sx={{
        py: 6,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
      }}
    >
      <Typography
        variant="h4"
        sx={{
          fontWeight: 700,
          mb: 4,
          color: "#1B2447",
          fontFamily: "'Poppins', sans-serif",
          textAlign: "center",
        }}
      >
        State Regulation For Aajoo
      </Typography>

      {/* 🏔️ Himachal Section */}
      <Section
        title="🏔️ Hosting with Aajoo in Himachal Pradesh"
        description="If you’re thinking about opening your home to travelers in Himachal Pradesh, you’re in the right place. At Aajoo, we help everyday homeowners, families, and locals turn extra rooms or unused spaces into meaningful income, while giving travelers an authentic Himachali experience."
        image={shimlahimachal}
        content={himachalContent}
      />

      {/* 🌾 Punjab Section (Reversed) */}
      <Section
        title="🌾Hosting with Aajoo in Punjab"
        description="Punjab is famous for its warmth, culture, and hospitality — and now you can share that spirit with travelers by opening your home as a homestay or Bed & Breakfast (BnB). At Aajoo, we help you turn spare rooms into income while making sure you meet all state rules and tourism standards."
        image={punjab}
        reverse
        content={punjabContent}
      />

      {/* 🏡 Chandigarh Section */}
      <Section
        title="🏡 Host with Aajoo in Chandigarh"
        description="Chandigarh isn’t just a city — it’s a planned masterpiece with a blend of modernity and culture. More travelers now want to stay with locals instead of hotels, which is why homestays and BnBs are growing here.With Aajoo, you can turn your extra space into income + cultural exchange, while we help you with registrations, guest bookings, and digital growth."
        image={chandigarh}
        content={chandigarhContent}
      />

      {/* Shared Modal */}
      <RegulationModal
        open={openModal}
        onClose={handleCloseModal}
        title={modalData.title}
        content={modalData.content}
      />
    </Container>
  );
};

export default StateRegulation;
