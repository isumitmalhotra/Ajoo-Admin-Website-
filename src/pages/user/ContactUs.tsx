import React from "react";
import {
  Box,
  Typography,
  TextField,
  Button,
  FormControlLabel,
  Checkbox,
} from "@mui/material";
import { Formik, Form, Field } from "formik";
import * as Yup from "yup";
import toast from "react-hot-toast";
import EmailIcon from "@mui/icons-material/Email";
import PhoneInTalkIcon from "@mui/icons-material/PhoneInTalk";
import LanguageIcon from "@mui/icons-material/Language";
import PhoneAndroidIcon from "@mui/icons-material/PhoneAndroid";
import SendIcon from "@mui/icons-material/Send";
import contactUs from "../../assets/UI/contactUs.jpg";
import Reveal from "../../components/frontend/Reveal";

const INDIGO = "#1B2447";
const CREAM = "#FFFAF0";
const BG = "#EFE7D6";
const BORDER = "#D9CFB8";
const MUTED = "#6B7390";

const heading = {
  fontFamily: "'Fraunces', serif",
  fontWeight: 400,
  letterSpacing: "-0.02em",
  color: INDIGO,
};

const ContactSchema = Yup.object().shape({
  name: Yup.string().min(3, "At least 3 characters").required("Required"),
  email: Yup.string().email("Invalid email").required("Required"),
  message: Yup.string().min(10, "At least 10 characters").required("Required"),
  terms: Yup.boolean().oneOf([true], "You must accept the terms"),
});

const infoCards = [
  {
    icon: <PhoneAndroidIcon />,
    title: "Use the app",
    sub: "Open aajoo Homes on Play Store",
    action: () =>
      window.open(
        "https://play.google.com/store/apps/details?id=com.aajoohomes",
        "_blank"
      ),
  },
  {
    icon: <EmailIcon />,
    title: "Email us",
    sub: "contactus@aajoohomes.com",
    action: () => (window.location.href = "mailto:contactus@aajoohomes.com"),
  },
  {
    icon: <PhoneInTalkIcon />,
    title: "Call support",
    sub: "Mon–Sat, 9am–7pm",
    action: () => (window.location.href = "tel:+919999999999"),
  },
  {
    icon: <LanguageIcon />,
    title: "Visit website",
    sub: "aajoohomes.com",
    action: () => window.open("https://aajoohomes.com", "_blank"),
  },
];

const ContactUs: React.FC = () => {
  return (
    <Box sx={{ bgcolor: BG }}>
      {/* ---------- Hero ---------- */}
      <Box sx={{ position: "relative", width: "100%", height: { xs: 200, sm: 260, md: 320 }, overflow: "hidden" }}>
        <Box component="img" src={contactUs} alt="Contact aajoo" sx={{ width: "100%", height: "100%", objectFit: "cover" }} />
        <Box
          sx={{
            position: "absolute",
            inset: 0,
            background: "linear-gradient(180deg, rgba(27,36,71,.35) 0%, rgba(27,36,71,.75) 100%)",
            color: "#FFFAF0",
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
            alignItems: "center",
            textAlign: "center",
            px: 2,
          }}
        >
          <Typography sx={{ fontFamily: "'Fraunces', serif", fontWeight: 400, letterSpacing: "-0.02em", fontSize: { xs: "1.8rem", md: "2.8rem" }, mb: 1 }}>
            Contact <Box component="span" sx={{ fontStyle: "italic", color: "#E9B79E" }}>aajoo</Box>
          </Typography>
          <Typography sx={{ fontSize: { xs: "0.9rem", md: "1.05rem" }, maxWidth: 620, opacity: 0.95 }}>
            Questions, feedback or booking help — our team is here for you.
          </Typography>
        </Box>
      </Box>

      {/* ---------- Form + image ---------- */}
      <Box sx={{ maxWidth: 1200, mx: "auto", px: { xs: 2, md: 4 }, py: { xs: 5, md: 8 }, display: "flex", flexWrap: "wrap", gap: { xs: 3, md: 5 }, alignItems: "stretch" }}>
        <Reveal>
          <Box sx={{ flex: "1 1 380px", maxWidth: 560 }}>
            <Typography sx={{ ...heading, fontSize: { xs: 24, md: 30 }, mb: 0.5 }}>Get in touch</Typography>
            <Typography sx={{ color: MUTED, mb: 3 }}>We usually reply within a business day.</Typography>

            <Formik
              initialValues={{ name: "", email: "", message: "", terms: false }}
              validationSchema={ContactSchema}
              onSubmit={(_values, { resetForm }) => {
                toast.success("Thanks! Your message has been sent.");
                resetForm();
              }}
            >
              {({ errors, touched, handleChange, values }) => (
                <Form>
                  <Box sx={{ bgcolor: CREAM, p: { xs: 2.5, md: 3 }, borderRadius: "18px", border: `1px solid ${BORDER}`, boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)", display: "flex", flexDirection: "column", gap: 2 }}>
                    <Field as={TextField} name="name" label="Your name" fullWidth error={touched.name && Boolean(errors.name)} helperText={touched.name && errors.name} />
                    <Field as={TextField} name="email" label="Your email" fullWidth error={touched.email && Boolean(errors.email)} helperText={touched.email && errors.email} />
                    <Field as={TextField} name="message" label="Message" fullWidth multiline rows={4} error={touched.message && Boolean(errors.message)} helperText={touched.message && errors.message} />
                    <FormControlLabel
                      control={<Checkbox name="terms" checked={values.terms} onChange={handleChange} sx={{ color: INDIGO, "&.Mui-checked": { color: INDIGO } }} />}
                      label="I agree to the Terms & Conditions"
                    />
                    {touched.terms && errors.terms && (
                      <Typography sx={{ color: "#b00020", fontSize: "0.8rem", ml: 1, mt: -1 }}>{errors.terms}</Typography>
                    )}
                    <Button type="submit" variant="contained" endIcon={<SendIcon />} sx={{ bgcolor: INDIGO, py: 1.2, borderRadius: "12px", fontWeight: 600, textTransform: "none", alignSelf: "flex-start", px: 3, "&:hover": { bgcolor: "#2A356B" } }}>
                      Send message
                    </Button>
                  </Box>
                </Form>
              )}
            </Formik>
          </Box>
        </Reveal>

        <Reveal delay={0.08}>
          <Box sx={{ flex: "1 1 380px", maxWidth: 560, display: "flex" }}>
            <Box component="img" src={contactUs} alt="Get in touch" sx={{ width: "100%", borderRadius: "18px", objectFit: "cover", border: `1px solid ${BORDER}`, boxShadow: "0 10px 30px rgba(27,36,71,.10)", minHeight: 320 }} />
          </Box>
        </Reveal>
      </Box>

      {/* ---------- Contact cards ---------- */}
      <Reveal>
        <Box sx={{ maxWidth: 1200, mx: "auto", px: { xs: 2, md: 4 }, pb: { xs: 6, md: 9 } }}>
          <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr 1fr", md: "repeat(4, 1fr)" }, gap: 2 }}>
            {infoCards.map((c) => (
              <Box
                key={c.title}
                onClick={c.action}
                sx={{
                  bgcolor: CREAM,
                  border: `1px solid ${BORDER}`,
                  borderRadius: "16px",
                  p: { xs: 2, md: 3 },
                  textAlign: "center",
                  cursor: "pointer",
                  transition: "0.25s",
                  "&:hover": { transform: "translateY(-4px)", boxShadow: "0 12px 30px rgba(27,36,71,.12)", borderColor: INDIGO },
                }}
              >
                <Box sx={{ width: 50, height: 50, mx: "auto", mb: 1.5, borderRadius: "14px", bgcolor: "rgba(27,36,71,.06)", color: INDIGO, display: "grid", placeItems: "center", "& svg": { fontSize: 26 } }}>
                  {c.icon}
                </Box>
                <Typography sx={{ fontWeight: 700, color: INDIGO, fontSize: "0.98rem" }}>{c.title}</Typography>
                <Typography sx={{ color: MUTED, fontSize: "0.82rem", mt: 0.5 }}>{c.sub}</Typography>
              </Box>
            ))}
          </Box>
        </Box>
      </Reveal>
    </Box>
  );
};

export default ContactUs;
