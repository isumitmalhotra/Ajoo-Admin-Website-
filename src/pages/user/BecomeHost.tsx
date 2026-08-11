import { useMemo, useState } from "react";
import {
  Alert,
  Box,
  Button,
  Container,
  FormControlLabel,
  LinearProgress,
  MenuItem,
  Paper,
  Step,
  StepLabel,
  Stepper,
  TextField,
  Typography,
  Checkbox,
  CircularProgress,
} from "@mui/material";
import MyLocationIcon from "@mui/icons-material/MyLocation";
import toast from "react-hot-toast";
import { FECustomSnackbar } from "../../components";
import { axios } from "../../axios/axios";
import { detectAddress, INDIAN_STATES } from "../../styles/utils/locationUtils";
import { citiesForState } from "../../styles/utils/indiaCities";

const PRIMARY = "#1B2447";
const steps = ["Host details", "Property details", "Verification"];

const PROPERTY_TYPES = [
  "Apartment",
  "Villa",
  "Cottage",
  "Homestay",
  "Resort",
  "Boutique stay",
];

const HOST_EXPERIENCE = [
  "First time hosting",
  "Hosted before (1-3 properties)",
  "Professional host (4+ properties)",
];

const DOCUMENT_TYPES = [
  { value: "AADHAAR", label: "Aadhaar" },
  { value: "VOTER_ID", label: "Voter ID" },
  { value: "DRIVING_LICENSE", label: "Driving License" },
];

const OWNERSHIP_PROOF = [
  "Property deed",
  "Rental agreement",
  "Host authorization letter",
];

type HostForm = {
  fullName: string;
  email: string;
  phone: string;
  city: string;
  hostingExperience: string;
  propertyName: string;
  propertyType: string;
  address: string;
  propertyCity: string;
  propertyState: string;
  pincode: string;
  rooms: string;
  nightlyRate: string;
  maxGuests: string;
  docType: string;
  docNumber: string;
  ownershipProof: string;
  agreeToTerms: boolean;
};

type HostErrors = Partial<Record<keyof HostForm, string>>;

const sanitizeDigits = (value: string) => value.replace(/\D/g, "");

const getDocPattern = (docType: string) => {
  switch (docType) {
    case "AADHAAR":
      return /^\d{12}$/;
    case "VOTER_ID":
      return /^[A-Z]{3}\d{7}$/;
    case "DRIVING_LICENSE":
      return /^[A-Z]{2}\d{13}$/;
    default:
      return null;
  }
};

const extractMessage = (error: unknown, fallback: string) => {
  if (typeof error === "string") return error;
  if (error && typeof error === "object") {
    const maybeMessage = (error as { message?: string }).message;
    if (typeof maybeMessage === "string") return maybeMessage;
  }
  return fallback;
};

const USE_DEV_HOST_MOCKS =
  import.meta.env.DEV && import.meta.env.VITE_USE_HOST_MOCKS === "true";

const mockSubmit = (payload: HostForm) =>
  new Promise<{ applicationId: string; message: string }>((resolve) => {
    setTimeout(() => {
      resolve({
        applicationId: `HOST-${payload.phone.slice(-4)}-${Date.now().toString().slice(-4)}`,
        message: "Host onboarding submitted in mock mode.",
      });
    }, 900);
  });

const BecomeHost = () => {
  const [activeStep, setActiveStep] = useState(0);
  const [form, setForm] = useState<HostForm>({
    fullName: "",
    email: "",
    phone: "",
    city: "",
    hostingExperience: "",
    propertyName: "",
    propertyType: "",
    address: "",
    propertyCity: "",
    propertyState: "",
    pincode: "",
    rooms: "",
    nightlyRate: "",
    maxGuests: "",
    docType: "",
    docNumber: "",
    ownershipProof: "",
    agreeToTerms: false,
  });
  const [errors, setErrors] = useState<HostErrors>({});
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState("");
  const [applicationId, setApplicationId] = useState<string | null>(null);
  const [snackbar, setSnackbar] = useState({
    open: false,
    message: "",
    type: "success" as "success" | "error" | "info" | "warning",
  });

  const progressValue = useMemo(
    () => ((activeStep + 1) / steps.length) * 100,
    [activeStep]
  );

  const updateField = (key: keyof HostForm, value: string | boolean) => {
    setForm((prev) => ({
      ...prev,
      [key]: value,
    }));
    setErrors((prev) => ({ ...prev, [key]: undefined }));
  };

  const validateStep = (step: number) => {
    const nextErrors: HostErrors = {};

    if (step === 0) {
      if (!form.fullName.trim()) nextErrors.fullName = "Full name is required.";
      if (!form.email.trim()) nextErrors.email = "Email is required.";
      if (
        form.email.trim() &&
        !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email.trim())
      ) {
        nextErrors.email = "Enter a valid email.";
      }
      if (!form.phone.trim()) nextErrors.phone = "Phone is required.";
      if (form.phone.trim() && !/^\d{10}$/.test(form.phone.trim())) {
        nextErrors.phone = "Phone must be 10 digits.";
      }
      if (!form.city.trim()) nextErrors.city = "City is required.";
      if (!form.hostingExperience)
        nextErrors.hostingExperience = "Select your hosting experience.";
    }

    if (step === 1) {
      if (!form.propertyName.trim())
        nextErrors.propertyName = "Property name is required.";
      if (!form.propertyType)
        nextErrors.propertyType = "Select a property type.";
      if (!form.address.trim())
        nextErrors.address = "Property address is required.";
      if (!form.propertyCity.trim())
        nextErrors.propertyCity = "Property city is required.";
      if (!form.propertyState.trim())
        nextErrors.propertyState = "Property state is required.";
      if (!form.pincode.trim()) nextErrors.pincode = "Pincode is required.";
      if (form.pincode.trim() && !/^\d{6}$/.test(form.pincode.trim())) {
        nextErrors.pincode = "Enter a valid 6-digit pincode.";
      }
      if (!form.rooms.trim()) nextErrors.rooms = "Total rooms is required.";
      if (form.rooms.trim() && Number(form.rooms) < 1) {
        nextErrors.rooms = "Rooms must be at least 1.";
      }
      if (!form.nightlyRate.trim())
        nextErrors.nightlyRate = "Nightly rate is required.";
      if (form.nightlyRate.trim() && Number(form.nightlyRate) < 1) {
        nextErrors.nightlyRate = "Nightly rate must be positive.";
      }
      if (!form.maxGuests.trim())
        nextErrors.maxGuests = "Guest capacity is required.";
      if (form.maxGuests.trim() && Number(form.maxGuests) < 1) {
        nextErrors.maxGuests = "Guest capacity must be at least 1.";
      }
    }

    if (step === 2) {
      if (!form.docType) nextErrors.docType = "Select a document type.";
      if (!form.docNumber.trim())
        nextErrors.docNumber = "Document number is required.";
      const docPattern = getDocPattern(form.docType);
      if (docPattern && !docPattern.test(form.docNumber.trim().toUpperCase())) {
        nextErrors.docNumber = "Enter a valid document number.";
      }
      if (!form.ownershipProof)
        nextErrors.ownershipProof = "Select an ownership proof.";
      if (!form.agreeToTerms)
        nextErrors.agreeToTerms = "You must accept the terms to proceed.";
    }

    setErrors(nextErrors);
    return Object.keys(nextErrors).length === 0;
  };

  const [locating, setLocating] = useState(false);
  const handleUseLocation = async () => {
    setLocating(true);
    try {
      const addr = await detectAddress();
      if (addr.address) updateField("address", addr.address);
      if (addr.city) updateField("propertyCity", addr.city);
      if (addr.state) updateField("propertyState", addr.state);
      if (addr.pincode) updateField("pincode", addr.pincode);
      toast.success("Address filled from your location");
    } catch {
      toast.error("Couldn't get your location. Please allow location access.");
    } finally {
      setLocating(false);
    }
  };

  const handleNext = () => {
    if (validateStep(activeStep)) {
      setActiveStep((prev) => prev + 1);
    }
  };

  const handleBack = () => {
    setActiveStep((prev) => Math.max(prev - 1, 0));
  };

  const handleSubmit = async () => {
    if (!validateStep(activeStep)) return;
    setSubmitting(true);
    setSubmitError("");

    try {
      if (USE_DEV_HOST_MOCKS) {
        const result = await mockSubmit(form);
        setApplicationId(result.applicationId);
        setSnackbar({
          open: true,
          message: result.message,
          type: "success",
        });
        setActiveStep(steps.length);
        return;
      }

      const payload = {
        host: {
          fullName: form.fullName.trim(),
          email: form.email.trim(),
          phone: form.phone.trim(),
          city: form.city.trim(),
          hostingExperience: form.hostingExperience,
        },
        property: {
          name: form.propertyName.trim(),
          type: form.propertyType,
          address: form.address.trim(),
          city: form.propertyCity.trim(),
          state: form.propertyState.trim(),
          pincode: form.pincode.trim(),
          rooms: Number(form.rooms),
          nightlyRate: Number(form.nightlyRate),
          maxGuests: Number(form.maxGuests),
        },
        verification: {
          docType: form.docType,
          docNumber: form.docNumber.trim().toUpperCase(),
          ownershipProof: form.ownershipProof,
        },
      };

      const response = await axios.post("/host/onboarding/submit", payload);
      const resolvedMessage =
        (response as { message?: string })?.message ||
        "Host onboarding submitted successfully.";
      const resolvedId =
        (response as { data?: { applicationId?: string } })?.data
          ?.applicationId || `HOST-${Date.now().toString().slice(-6)}`;

      setApplicationId(resolvedId);
      setSnackbar({
        open: true,
        message: resolvedMessage,
        type: "success",
      });
      setActiveStep(steps.length);
    } catch (error) {
      setSubmitError(
        extractMessage(
          error,
          "Unable to submit onboarding right now. Please try again."
        )
      );
      setSnackbar({
        open: true,
        message: "Submission failed. Check the form and try again.",
        type: "error",
      });
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Box sx={{ py: { xs: 4, md: 6 }, backgroundColor: "#EFE7D6" }}>
      <Container maxWidth="md">
        <Box sx={{ textAlign: "center", mb: 4 }}>
          <Typography
            sx={{
              fontFamily: "'Fraunces', serif",
              fontWeight: 400,
              letterSpacing: "-0.02em",
              color: PRIMARY,
              mb: 1,
              fontSize: { xs: "2rem", md: "2.8rem" },
            }}
          >
            Become a <Box component="span" sx={{ fontStyle: "italic", color: "#C16345" }}>host</Box>
          </Typography>
          <Typography sx={{ color: "#6B7390" }}>
            Tell us about your property and we'll onboard you within 48 hours.
          </Typography>
        </Box>

        <Paper sx={{ p: { xs: 2.5, md: 4 }, borderRadius: "20px", bgcolor: "#FFFAF0", border: "1px solid #D9CFB8", boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 12px 40px rgba(27,36,71,.08)" }}>
          <LinearProgress
            variant="determinate"
            value={progressValue}
            sx={{ mb: 3, height: 6, borderRadius: 3 }}
          />
          <Stepper
            activeStep={activeStep}
            alternativeLabel
            sx={{
              mb: 3,
              "& .MuiStepIcon-root.Mui-active": { color: PRIMARY },
              "& .MuiStepIcon-root.Mui-completed": { color: PRIMARY },
            }}
          >
            {steps.map((label) => (
              <Step key={label}>
                <StepLabel>{label}</StepLabel>
              </Step>
            ))}
          </Stepper>

          {activeStep === steps.length ? (
            <Box sx={{ textAlign: "center", py: 4 }}>
              <Typography variant="h5" sx={{ fontWeight: 700, mb: 1 }}>
                Application submitted!
              </Typography>
              <Typography sx={{ color: "#666", mb: 2 }}>
                Our team will verify the details and reach out within 1-2
                business days.
              </Typography>
              {applicationId && (
                <Typography sx={{ fontWeight: 600, color: PRIMARY }}>
                  Application ID: {applicationId}
                </Typography>
              )}
              <Button
                variant="contained"
                sx={{ mt: 3, bgcolor: PRIMARY }}
                onClick={() => {
                  setActiveStep(0);
                  setApplicationId(null);
                  setForm({
                    fullName: "",
                    email: "",
                    phone: "",
                    city: "",
                    hostingExperience: "",
                    propertyName: "",
                    propertyType: "",
                    address: "",
                    propertyCity: "",
                    propertyState: "",
                    pincode: "",
                    rooms: "",
                    nightlyRate: "",
                    maxGuests: "",
                    docType: "",
                    docNumber: "",
                    ownershipProof: "",
                    agreeToTerms: false,
                  });
                  setErrors({});
                }}
              >
                Submit another property
              </Button>
            </Box>
          ) : (
            <>
              {submitError && (
                <Alert severity="error" sx={{ mb: 2 }}>
                  {submitError}
                </Alert>
              )}

              {activeStep === 0 && (
                <Box
                  sx={{
                    display: "grid",
                    gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
                    gap: 2,
                  }}
                >
                  <TextField
                    label="Full name"
                    value={form.fullName}
                    onChange={(e) => updateField("fullName", e.target.value)}
                    error={Boolean(errors.fullName)}
                    helperText={errors.fullName || " "}
                  />
                  <TextField
                    label="Email address"
                    value={form.email}
                    onChange={(e) => updateField("email", e.target.value)}
                    error={Boolean(errors.email)}
                    helperText={errors.email || " "}
                  />
                  <TextField
                    label="Phone number"
                    value={form.phone}
                    onChange={(e) =>
                      updateField("phone", sanitizeDigits(e.target.value))
                    }
                    error={Boolean(errors.phone)}
                    helperText={errors.phone || " "}
                    inputProps={{ maxLength: 10 }}
                  />
                  <TextField
                    label="City"
                    value={form.city}
                    onChange={(e) => updateField("city", e.target.value)}
                    error={Boolean(errors.city)}
                    helperText={errors.city || " "}
                  />
                  <TextField
                    select
                    label="Hosting experience"
                    value={form.hostingExperience}
                    onChange={(e) =>
                      updateField("hostingExperience", e.target.value)
                    }
                    error={Boolean(errors.hostingExperience)}
                    helperText={errors.hostingExperience || " "}
                  >
                    {HOST_EXPERIENCE.map((option) => (
                      <MenuItem key={option} value={option}>
                        {option}
                      </MenuItem>
                    ))}
                  </TextField>
                </Box>
              )}

              {activeStep === 1 && (
                <Box
                  sx={{
                    display: "grid",
                    gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
                    gap: 2,
                  }}
                >
                  <Box sx={{ gridColumn: "1 / -1" }}>
                    <Button
                      onClick={handleUseLocation}
                      disabled={locating}
                      startIcon={locating ? <CircularProgress size={16} /> : <MyLocationIcon />}
                      variant="outlined"
                      sx={{ borderColor: PRIMARY, color: PRIMARY, textTransform: "none", fontWeight: 600, borderRadius: "10px", "&:hover": { borderColor: PRIMARY, bgcolor: "rgba(27,36,71,.05)" } }}
                    >
                      {locating ? "Detecting…" : "Use my current location"}
                    </Button>
                  </Box>
                  <TextField
                    label="Property name"
                    value={form.propertyName}
                    onChange={(e) =>
                      updateField("propertyName", e.target.value)
                    }
                    error={Boolean(errors.propertyName)}
                    helperText={errors.propertyName || " "}
                  />
                  <TextField
                    select
                    label="Property type"
                    value={form.propertyType}
                    onChange={(e) =>
                      updateField("propertyType", e.target.value)
                    }
                    error={Boolean(errors.propertyType)}
                    helperText={errors.propertyType || " "}
                  >
                    {PROPERTY_TYPES.map((option) => (
                      <MenuItem key={option} value={option}>
                        {option}
                      </MenuItem>
                    ))}
                  </TextField>
                  <TextField
                    label="Street address"
                    value={form.address}
                    onChange={(e) => updateField("address", e.target.value)}
                    error={Boolean(errors.address)}
                    helperText={errors.address || " "}
                  />
                  <TextField
                    select
                    label="State"
                    value={form.propertyState}
                    onChange={(e) => {
                      updateField("propertyState", e.target.value);
                      updateField("propertyCity", ""); // reset city on state change
                    }}
                    error={Boolean(errors.propertyState)}
                    helperText={errors.propertyState || " "}
                  >
                    {INDIAN_STATES.map((s) => (
                      <MenuItem key={s} value={s}>
                        {s}
                      </MenuItem>
                    ))}
                  </TextField>
                  <TextField
                    select
                    label="City"
                    value={form.propertyCity}
                    disabled={!form.propertyState}
                    onChange={(e) =>
                      updateField("propertyCity", e.target.value)
                    }
                    error={Boolean(errors.propertyCity)}
                    helperText={
                      errors.propertyCity ||
                      (!form.propertyState ? "Select a state first" : " ")
                    }
                  >
                    {Array.from(
                      new Set([
                        ...(form.propertyCity ? [form.propertyCity] : []),
                        ...citiesForState(form.propertyState),
                      ])
                    ).map((c) => (
                      <MenuItem key={c} value={c}>
                        {c}
                      </MenuItem>
                    ))}
                  </TextField>
                  <TextField
                    label="Pincode"
                    value={form.pincode}
                    onChange={(e) =>
                      updateField("pincode", sanitizeDigits(e.target.value))
                    }
                    error={Boolean(errors.pincode)}
                    helperText={errors.pincode || " "}
                    inputProps={{ maxLength: 6 }}
                  />
                  <TextField
                    label="Total rooms"
                    value={form.rooms}
                    onChange={(e) =>
                      updateField("rooms", sanitizeDigits(e.target.value))
                    }
                    error={Boolean(errors.rooms)}
                    helperText={errors.rooms || " "}
                  />
                  <TextField
                    label="Nightly rate (INR)"
                    value={form.nightlyRate}
                    onChange={(e) =>
                      updateField("nightlyRate", sanitizeDigits(e.target.value))
                    }
                    error={Boolean(errors.nightlyRate)}
                    helperText={errors.nightlyRate || " "}
                  />
                  <TextField
                    label="Max guests"
                    value={form.maxGuests}
                    onChange={(e) =>
                      updateField("maxGuests", sanitizeDigits(e.target.value))
                    }
                    error={Boolean(errors.maxGuests)}
                    helperText={errors.maxGuests || " "}
                  />
                </Box>
              )}

              {activeStep === 2 && (
                <Box
                  sx={{
                    display: "grid",
                    gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
                    gap: 2,
                  }}
                >
                  <TextField
                    select
                    label="Document type"
                    value={form.docType}
                    onChange={(e) => updateField("docType", e.target.value)}
                    error={Boolean(errors.docType)}
                    helperText={errors.docType || " "}
                  >
                    {DOCUMENT_TYPES.map((option) => (
                      <MenuItem key={option.value} value={option.value}>
                        {option.label}
                      </MenuItem>
                    ))}
                  </TextField>
                  <TextField
                    label="Document number"
                    value={form.docNumber}
                    onChange={(e) =>
                      updateField("docNumber", e.target.value.toUpperCase())
                    }
                    error={Boolean(errors.docNumber)}
                    helperText={errors.docNumber || " "}
                  />
                  <TextField
                    select
                    label="Ownership proof"
                    value={form.ownershipProof}
                    onChange={(e) =>
                      updateField("ownershipProof", e.target.value)
                    }
                    error={Boolean(errors.ownershipProof)}
                    helperText={errors.ownershipProof || " "}
                  >
                    {OWNERSHIP_PROOF.map((option) => (
                      <MenuItem key={option} value={option}>
                        {option}
                      </MenuItem>
                    ))}
                  </TextField>
                  <FormControlLabel
                    control={
                      <Checkbox
                        checked={form.agreeToTerms}
                        onChange={(e) =>
                          updateField("agreeToTerms", e.target.checked)
                        }
                      />
                    }
                    label="I confirm the information is accurate and agree to the hosting terms."
                    sx={{
                      gridColumn: "1 / -1",
                      color: errors.agreeToTerms ? "#d32f2f" : "inherit",
                    }}
                  />
                  {errors.agreeToTerms && (
                    <Typography
                      variant="caption"
                      sx={{ color: "#d32f2f", gridColumn: "1 / -1" }}
                    >
                      {errors.agreeToTerms}
                    </Typography>
                  )}
                </Box>
              )}

              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  mt: 3,
                  gap: 2,
                }}
              >
                <Button
                  variant="outlined"
                  disabled={activeStep === 0}
                  onClick={handleBack}
                >
                  Back
                </Button>
                <Button
                  variant="contained"
                  sx={{ bgcolor: PRIMARY }}
                  onClick={activeStep === steps.length - 1 ? handleSubmit : handleNext}
                  disabled={submitting}
                >
                  {activeStep === steps.length - 1
                    ? submitting
                      ? "Submitting..."
                      : "Submit application"
                    : "Next"}
                </Button>
              </Box>
            </>
          )}
        </Paper>
      </Container>

      <FECustomSnackbar
        open={snackbar.open}
        message={snackbar.message}
        type={snackbar.type}
        onClose={() => setSnackbar((prev) => ({ ...prev, open: false }))}
      />
    </Box>
  );
};

export default BecomeHost;
