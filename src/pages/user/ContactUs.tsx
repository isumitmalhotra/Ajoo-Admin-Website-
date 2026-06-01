import React from "react";
import {
  Box,
  Typography,
  TextField,
  Button,
  Card,
  CardContent,
  FormControlLabel,
  Checkbox,
} from "@mui/material";
import { Formik, Form, Field } from "formik";
import * as Yup from "yup";
import contactUs from "../../assets/UI/contactUs.jpg";
import EmailIcon from "@mui/icons-material/Email";

// -------------------- VALIDATION SCHEMA --------------------
const ContactSchema = Yup.object().shape({
  name: Yup.string().min(3, "At least 3 characters").required("Required"),
  email: Yup.string().email("Invalid email").required("Required"),
  message: Yup.string().min(10, "At least 10 characters").required("Required"),
  terms: Yup.boolean().oneOf([true], "You must accept the terms"),
});

const ContactUs: React.FC = () => {
  // -------------------- SNACKBAR STATE --------------------

  return (
    <Box
      sx={{
        fontFamily: "Poppins, sans-serif",
        background: "#fafafa",
        color: "#222",
        textAlign: "center",
        lineHeight: 1.6,
      }}
    >
      {/* ---------------------- HERO SECTION ---------------------- */}
      <Box
        sx={{
          position: "relative",
          width: "100%",
          height: { xs: 180, sm: 220, md: 280 },
          overflow: "hidden",
        }}
      >
        <Box
          component="img"
          src="/room2.jpg"
          alt="Contact Hero"
          sx={{ width: "100%", height: "100%", objectFit: "cover" }}
        />

        <Box
          sx={{
            position: "absolute",
            top: 0,
            left: 0,
            width: "100%",
            height: "100%",
            background: "rgba(0,0,0,0.55)",
            color: "#fff",
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
            alignItems: "center",
            px: 2,
          }}
        >
          <Typography
            variant="h3"
            sx={{
              fontSize: { xs: "1.4rem", sm: "1.8rem", md: "2.4rem" },
              fontWeight: 700,
              mb: 1,
            }}
          >
            Contact AAJOO Homes
          </Typography>

          <Typography
            variant="body1"
            sx={{ fontSize: { xs: "0.85rem", md: "1rem" }, maxWidth: 680 }}
          >
            We’d love to hear from you! Whether you have questions, feedback, or
            booking inquiries, our team is here to assist you anytime.
          </Typography>
        </Box>
      </Box>

      {/* ---------------------- MAIN SECTION ---------------------- */}
      <Box
        sx={{
          display: "flex",
          flexWrap: "wrap",
          gap: "28px",
          justifyContent: "center",
          maxWidth: "1200px",
          mx: "auto",
          my: 5,
          px: 2,
        }}
      >
        {/* ---------------------- LEFT FORM ---------------------- */}
        <Box sx={{ flex: "1 1 360px", maxWidth: "600px" }}>
          <Typography
            variant="h4"
            sx={{
              color: "#1B2447",
              fontWeight: 700,
              mb: 2,
              fontSize: { xs: "1.3rem", md: "1.9rem" },
              textAlign: "left",
            }}
          >
            Get in Touch
          </Typography>

          {/* ---------------------- FORM START ---------------------- */}
          <Formik
            initialValues={{ name: "", email: "", message: "", terms: false }}
            validationSchema={ContactSchema}
            onSubmit={(_values, { resetForm }) => {
              resetForm();
            }}
          >
            {({ errors, touched, handleChange }) => (
              <Form>
                <Box
                  sx={{
                    background: "#fff",
                    p: 3,
                    borderRadius: "12px",
                    boxShadow: "0 6px 20px rgba(0,0,0,0.06)",
                    display: "flex",
                    flexDirection: "column",
                    gap: 2,
                  }}
                >
                  {/* NAME */}
                  <Field
                    as={TextField}
                    name="name"
                    label="Your Name"
                    fullWidth
                    error={touched.name && Boolean(errors.name)}
                    helperText={touched.name && errors.name}
                  />

                  {/* EMAIL */}
                  <Field
                    as={TextField}
                    name="email"
                    label="Your Email"
                    fullWidth
                    error={touched.email && Boolean(errors.email)}
                    helperText={touched.email && errors.email}
                  />

                  {/* MESSAGE */}
                  <Field
                    as={TextField}
                    name="message"
                    label="Message"
                    fullWidth
                    multiline
                    rows={4}
                    error={touched.message && Boolean(errors.message)}
                    helperText={touched.message && errors.message}
                  />

                  {/* TERMS CHECKBOX */}
                  <FormControlLabel
                    control={
                      <Checkbox
                        name="terms"
                        onChange={handleChange}
                        sx={{
                          color: "#1B2447",
                          "&.Mui-checked": { color: "#1B2447" },
                        }}
                      />
                    }
                    label="I agree to the Terms & Conditions"
                  />

                  {touched.terms && errors.terms && (
                    <Typography
                      sx={{ color: "red", fontSize: "0.8rem", ml: 1 }}
                    >
                      {errors.terms}
                    </Typography>
                  )}

                  {/* SUBMIT BTN */}
                  <Button
                    type="submit"
                    variant="contained"
                    sx={{
                      backgroundColor: "#1B2447",
                      color: "#fff",
                      py: 1.2,
                      borderRadius: "26px",
                      fontWeight: 600,
                      textTransform: "none",
                      width: "100%",
                      maxWidth: { xs: "100%", sm: 220 },
                      alignSelf: "center",
                    }}
                    onClick={() => {
                      // show error when required fields missing
                      if (
                        touched.name ||
                        touched.email ||
                        touched.message ||
                        touched.terms
                      ) {
                        if (
                          errors.name ||
                          errors.email ||
                          errors.message ||
                          errors.terms
                        ) {
                          // handleSnack("Please fill all required fields", "error");
                        }
                      }
                    }}
                  >
                    Send Message
                  </Button>
                </Box>
              </Form>
            )}
          </Formik>
        </Box>

        {/* ---------------------- RIGHT IMAGE ---------------------- */}
        <Box
          sx={{
            flex: "1 1 360px",
            maxWidth: "600px",
            display: "flex",
            justifyContent: "center",
          }}
        >
          <Box
            component="img"
            src={contactUs}
            alt="Location"
            sx={{
              width: "100%",
              borderRadius: "12px",
              boxShadow: "0 6px 20px rgba(0,0,0,0.06)",
              objectFit: "cover",
            }}
          />
        </Box>
      </Box>
      {/* ---------------------- INFO CARDS ---------------------- */}
      <Box sx={{ my: 4, px: 2 }}>
        <Box
          sx={{
            display: "flex",
            gap: 2,
            justifyContent: "center",
            flexWrap: "wrap",
          }}
        >
          {/* ---------- USE APP CARD ---------- */}
          <Card
            onClick={() =>
              window.open(
                "https://play.google.com/store/apps/details?id=com.aajoohomes",
                "_blank"
              )
            }
            sx={{
              flex: "1 1 240px",
              maxWidth: 340,
              p: 2,
              borderRadius: "12px",
              boxShadow: "0 8px 22px rgba(0,0,0,0.08)",
              cursor: "pointer",
              transition: "0.25s",
              "&:hover": {
                transform: "translateY(-4px)",
                boxShadow: "0 10px 28px rgba(0,0,0,0.12)",
              },
            }}
          >
            <CardContent sx={{ textAlign: "center" }}>
              <Typography
                variant="h6"
                sx={{
                  color: "#1B2447",
                  fontWeight: 700,
                  display: "flex",
                  justifyContent: "center",
                  gap: 1,
                }}
              >
                <img
                  src="https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Google_Play_Arrow_logo.svg/512px-Google_Play_Arrow_logo.svg.png"
                  alt="Playstore"
                  width="26"
                  height="26"
                  style={{ marginRight: 4 }}
                />
                Use App
              </Typography>

              <Typography sx={{ mt: 1 }}>Open AAJOO Homes App</Typography>
            </CardContent>
          </Card>

          {/* ---------- CONTACT US CARD ---------- */}
          <Card
            onClick={() =>
              (window.location.href = "mailto:contactus@aajoohomes.com")
            }
            sx={{
              flex: "1 1 240px",
              maxWidth: 340,
              p: 2,
              borderRadius: "12px",
              boxShadow: "0 8px 22px rgba(0,0,0,0.08)",
              cursor: "pointer",
              transition: "0.25s",
              "&:hover": {
                transform: "translateY(-4px)",
                boxShadow: "0 10px 28px rgba(0,0,0,0.12)",
              },
            }}
          >
            <CardContent sx={{ textAlign: "center" }}>
              <Typography
                variant="h6"
                sx={{
                  color: "#1B2447",
                  fontWeight: 700,
                  display: "flex",
                  justifyContent: "center",
                  alignItems: "center",
                  gap: 1,
                }}
              >
                <EmailIcon sx={{ fontSize: 26, color: "#1B2447" }} />
                Contact Us
              </Typography>

              <Typography sx={{ mt: 1 }}>Tap to Email Now</Typography>
            </CardContent>
          </Card>

          {/* ---------- VISIT WEBSITE CARD ---------- */}
          <Card
            onClick={() => window.open("https://aajoohomes.com", "_blank")}
            sx={{
              flex: "1 1 240px",
              maxWidth: 340,
              p: 2,
              borderRadius: "12px",
              boxShadow: "0 8px 22px rgba(0,0,0,0.08)",
              cursor: "pointer",
              transition: "0.25s",
              "&:hover": {
                transform: "translateY(-4px)",
                boxShadow: "0 10px 28px rgba(0,0,0,0.12)",
              },
            }}
          >
            <CardContent sx={{ textAlign: "center" }}>
              <Typography
                variant="h6"
                sx={{ color: "#1B2447", fontWeight: 700 }}
              >
                🌐 Visit Website
              </Typography>

              <Typography sx={{ mt: 1 }}>Open Aajoo Homes Website</Typography>
            </CardContent>
          </Card>
        </Box>
      </Box>
    </Box>
  );
};

export default ContactUs;
