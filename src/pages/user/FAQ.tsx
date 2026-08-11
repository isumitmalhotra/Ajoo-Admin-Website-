import { Box, Typography, Accordion, AccordionSummary, AccordionDetails, Button } from "@mui/material";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import HelpOutlineIcon from "@mui/icons-material/HelpOutline";
import { Link } from "react-router-dom";
import { CTAoneHome } from "../../components";
import Reveal from "../../components/frontend/Reveal";

const INDIGO = "#1B2447";
const TERRA = "#C16345";
const CREAM = "#FFFAF0";
const BG = "#EFE7D6";
const BORDER = "#D9CFB8";
const MUTED = "#6B7390";

const faqs = [
  { title: "How do I find a room near me on aajoo?", description: "Open the site, enable location, and you'll see available rooms within walking distance of your current location." },
  { title: "Can I negotiate the price before booking?", description: "Yes! aajoo allows real-time price negotiation with the host — propose a price and the host may accept, decline, or counter it." },
  { title: "Can I book for one night, a week, or a month?", description: "Absolutely. Choose a daily, weekly, or monthly stay as per your requirement using the filters while searching." },
  { title: "Is my booking and payment secure?", description: "Yes. We use secure payment gateways and you receive confirmation via the app and email after booking." },
  { title: "Do I have to pay a security deposit?", description: "For monthly stays, a minimal security deposit may apply. For daily or short stays, no deposit is required." },
  { title: "Is KYC mandatory to book?", description: "Yes — to keep both guests and hosts safe, basic KYC (ID verification with photo) is required before final booking." },
  { title: "What if I have an issue during the stay?", description: "Contact aajoo support via in-app chat, email, or WhatsApp for any help during your stay." },
  { title: "What is the cancellation policy?", description: "You can cancel your booking according to the cancellation terms shown on your booking." },
  { title: "Can I talk to the host before booking?", description: "Yes — once your negotiation or request is accepted, you can communicate with the host through the platform." },
];

const FAQ = () => {
  return (
    <Box sx={{ bgcolor: BG }}>
      {/* Hero */}
      <Box sx={{ py: { xs: 6, md: 9 }, px: 3, textAlign: "center", background: "linear-gradient(180deg, #FFFAF0 0%, #EFE7D6 100%)", borderBottom: `1px solid ${BORDER}` }}>
        <Reveal>
          <Typography sx={{ fontFamily: "'Fraunces', serif", fontWeight: 400, letterSpacing: "-0.02em", color: INDIGO, fontSize: { xs: "2rem", md: "3rem" }, mb: 1.5 }}>
            Frequently asked <Box component="span" sx={{ fontStyle: "italic", color: TERRA }}>questions</Box>
          </Typography>
          <Typography sx={{ maxWidth: 700, mx: "auto", color: MUTED, lineHeight: 1.7, fontSize: { xs: "0.98rem", md: "1.1rem" } }}>
            Answers to the most common questions about aajoo. Still stuck? Our support team is a tap away.
          </Typography>
        </Reveal>
      </Box>

      {/* Accordions */}
      <Box sx={{ maxWidth: 900, mx: "auto", px: { xs: 2, md: 3 }, py: { xs: 5, md: 7 }, display: "flex", flexDirection: "column", gap: 1.5 }}>
        {faqs.map((faq, index) => (
          <Reveal key={index} delay={Math.min(index * 0.04, 0.3)}>
            <Accordion
              disableGutters
              elevation={0}
              sx={{
                bgcolor: CREAM,
                border: `1px solid ${BORDER}`,
                borderRadius: "14px !important",
                "&:before": { display: "none" },
                overflow: "hidden",
                boxShadow: "0 1px 2px rgba(27,36,71,.04)",
              }}
            >
              <AccordionSummary expandIcon={<ExpandMoreIcon sx={{ color: INDIGO }} />} sx={{ px: { xs: 2, md: 2.5 } }}>
                <Box sx={{ display: "flex", alignItems: "center", gap: 1.25 }}>
                  <HelpOutlineIcon sx={{ color: TERRA, fontSize: 20 }} />
                  <Typography sx={{ fontWeight: 700, color: INDIGO, fontSize: { xs: "0.98rem", md: "1.05rem" } }}>
                    {faq.title}
                  </Typography>
                </Box>
              </AccordionSummary>
              <AccordionDetails sx={{ px: { xs: 2, md: 2.5 }, pt: 0 }}>
                <Typography sx={{ color: MUTED, lineHeight: 1.7, pl: { xs: "30px", md: "33px" } }}>
                  {faq.description}
                </Typography>
              </AccordionDetails>
            </Accordion>
          </Reveal>
        ))}
      </Box>

      {/* Still have questions */}
      <Reveal>
        <Box sx={{ maxWidth: 900, mx: "auto", px: { xs: 2, md: 3 }, pb: { xs: 5, md: 7 } }}>
          <Box sx={{ textAlign: "center", p: { xs: 3, md: 5 }, borderRadius: "20px", bgcolor: CREAM, border: `1px solid ${BORDER}`, boxShadow: "0 8px 24px rgba(27,36,71,.06)" }}>
            <Typography sx={{ fontFamily: "'Fraunces', serif", fontWeight: 400, fontSize: { xs: 22, md: 28 }, color: INDIGO, mb: 1 }}>
              Still have questions?
            </Typography>
            <Typography sx={{ color: MUTED, mb: 3, maxWidth: 520, mx: "auto" }}>
              If you can't find the answer you're looking for, our support team is here to help.
            </Typography>
            <Button component={Link} to="/contact" variant="contained" sx={{ bgcolor: INDIGO, textTransform: "none", fontWeight: 600, borderRadius: "10px", px: 3, py: 1, "&:hover": { bgcolor: "#2A356B" } }}>
              Contact us
            </Button>
          </Box>
        </Box>
      </Reveal>

      <CTAoneHome
        backgroundImage="/room3.jpg"
        title="Looking for a relaxing vacation?"
        buttonText="Book now"
        onButtonClick={() => { window.location.href = "/property/list"; }}
      />
    </Box>
  );
};

export default FAQ;
