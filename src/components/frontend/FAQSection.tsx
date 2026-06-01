import { useState, useEffect, useRef } from "react";
import {
  Box,
  Typography,
  Accordion,
  AccordionSummary,
  AccordionDetails,
} from "@mui/material";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import HelpOutlineIcon from "@mui/icons-material/HelpOutline";
import { motion, useAnimate, stagger, useInView } from "motion/react";

interface FAQ {
  question: string;
  answer: string;
}

interface FAQSectionProps {
  image: string;
  faqs: FAQ[];
  title?: string;
  description?: string;
}

const FAQSection: React.FC<FAQSectionProps> = ({
  image,
  faqs,
  title = "Frequently Asked Questions",
  description = "Find answers to common questions about our services.",
}) => {
  const [expanded, setExpanded] = useState<number | false>(false);
  const [scope, animate] = useAnimate();
  const containerRef = useRef<HTMLDivElement>(null);
  const inView = useInView(containerRef, { amount: 0.4, once: false });

  const handleChange = async (panel: number) => {
    const isExpanding = expanded !== panel;
    setExpanded(isExpanding ? panel : false);

    // Animate expansion (bounce scale + opacity pulse)
    if (isExpanding) {
      await animate(
        `.faq-item-${panel}`,
        { scale: [1, 1.03, 1], opacity: [1, 0.9, 1] },
        { duration: 0.4, ease: "easeOut" }
      );
    }
  };

  // Animate when section enters/leaves the viewport
  useEffect(() => {
    if (inView) {
      // Animate image first, then stagger FAQ list
      animate([
        [
          ".faq-image",
          { opacity: [0, 1], x: [-40, 0] },
          { duration: 0.6, ease: "easeOut" },
        ],
        [
          "div.faq-item",
          { opacity: [0, 1], y: [30, 0] },
          { duration: 0.5, delay: stagger(0.15), ease: "easeOut" },
        ],
      ]);
    } else {
      // Reset on scroll out
      animate([
        [".faq-image", { opacity: 0, x: -40 }, { duration: 0.2 }],
        ["div.faq-item", { opacity: 0, y: 30 }, { duration: 0.2 }],
      ]);
    }
  }, [inView, animate]);

  return (
    <Box
      ref={containerRef}
      sx={{
        py: { xs: 6, md: 8 },
        px: { xs: 2, sm: 3, md: 6 },
        bgcolor: "#fdfdfd",
      }}
    >
      {/* Section Title */}
      <Typography
        variant="h4"
        textAlign="center"
        fontWeight="bold"
        mb={{ xs: 4, md: 5 }}
        sx={{
          color: "#1B2447",
          fontSize: { xs: "1.8rem", sm: "2rem", md: "2.4rem" },
        }}
      >
        {title}
      </Typography>

      {/* Content Wrapper */}
      <Box
        ref={scope}
        sx={{
          display: "flex",
          flexDirection: { xs: "column", md: "row" },
          alignItems: "stretch", // Make both sides align in height
          justifyContent: "space-between",
          gap: { xs: 4, sm: 5, md: 6 },
          maxWidth: "1200px",
          mx: "auto",
        }}
      >
        {/* Left: Image with motion */}
        <motion.div
          className="faq-image"
          initial={{ opacity: 0, x: -40 }}
          transition={{ duration: 0.6, ease: "easeOut" }}
          style={{
            flex: 1,
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
          }}
        >
           <Box
            component="img"
            src={image}
            alt="FAQ"
            sx={{
              width: "100%",
              height: { xs: 280, sm: 350, md: 420, lg: 480 }, // Taller and responsive
              borderRadius: 4,
              boxShadow: 4,
              objectFit: "cover",
              objectPosition: "center",
              maxWidth: { xs: "100%", md: "100%" },
              transition: "transform 0.4s ease",
              "&:hover": {
                transform: "scale(1.02)",
              },
            }}
          />
        </motion.div>

        {/* Right: FAQs */}
        <Box
          sx={{
            flex: 1,
            width: "100%",
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
          }}
        >
          {/* Description */}
          <Box
            sx={{
              display: "flex",
              alignItems: "center",
              gap: 1.5,
              mb: 3,
              flexWrap: "wrap",
              justifyContent: { xs: "center", md: "flex-start" },
              textAlign: { xs: "center", md: "left" },
            }}
          >
            <HelpOutlineIcon
              sx={{ color: "#1B2447", fontSize: { xs: 26, sm: 30 } }}
            />
            <Typography
              variant="h6"
              sx={{
                color: "#1B2447",
                fontWeight: 600,
                fontSize: { xs: "1rem", sm: "1.1rem", md: "1.2rem" },
              }}
            >
              {description}
            </Typography>
          </Box>

          {/* FAQ List with motion */}
          {faqs.map((faq, idx) => (
            <motion.div
              key={idx}
              className={`faq-item faq-item-${idx}`}
              initial={{ opacity: 0, y: 30 }}
              transition={{ duration: 0.4, delay: idx * 0.1 }}
            >
              <Accordion
                expanded={expanded === idx}
                onChange={() => handleChange(idx)}
                sx={{
                  mb: 2,
                  border: "1px solid #1B2447",
                  borderRadius: 2,
                  boxShadow: "none",
                  "&:before": { display: "none" },
                  overflow: "hidden",
                  width: "100%",
                }}
              >
                <AccordionSummary
                  expandIcon={
                    <ExpandMoreIcon
                      sx={{
                        color: expanded === idx ? "#fff" : "#1B2447",
                        fontSize: 28,
                      }}
                    />
                  }
                  sx={{
                    bgcolor: expanded === idx ? "#1B2447" : "#fff",
                    color: expanded === idx ? "#fff" : "#1B2447",
                    fontWeight: 700,
                    fontSize: { xs: "1rem", sm: "1.1rem" },
                    transition: "0.3s",
                    "&:hover": {
                      bgcolor: expanded === idx ? "#2A356B" : "#fce4ec",
                    },
                  }}
                >
                  {faq.question}
                </AccordionSummary>
                <AccordionDetails
                  sx={{
                    color: "#333",
                    bgcolor: "#fff",
                    fontSize: { xs: "0.95rem", sm: "1rem" },
                    lineHeight: 1.6,
                    px: { xs: 2, sm: 3 },
                    py: { xs: 1, sm: 1.5 },
                  }}
                >
                  <Typography>{faq.answer}</Typography>
                </AccordionDetails>
              </Accordion>
            </motion.div>
          ))}
        </Box>
      </Box>
    </Box>
  );
};

export default FAQSection;
