import { useEffect, useMemo, useState } from "react";
import {
  Alert,
  AlertTitle,
  Box,
  Button,
  Paper,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import { useAppDispatch, useAppSelector } from "../../app/hooks";
import {
  clearHostProfileUpdateState,
  fetchHostProfile,
  setLocalHostProfile,
  updateHostProfile,
} from "../../features/host/hostProfile.slice";
import { API_BASE_URL } from "../../configs/apiConfigs";

const USE_DEV_HOST_MOCKS =
  import.meta.env.DEV && import.meta.env.VITE_USE_HOST_MOCKS === "true";

const MOCK_PROFILE = {
  fullName: "Aajoo Host",
  email: "host@aajoo.test",
  phone: "9876543210",
  city: "Chandigarh",
  bankName: "HDFC Bank",
  accountNumber: "123456789012",
  ifscCode: "HDFC0001234",
  upiId: "host@upi",
};

type ProfileFormState = {
  fullName: string;
  email: string;
  phone: string;
  city: string;
  bankName: string;
  accountNumber: string;
  ifscCode: string;
  upiId: string;
};

type FormErrors = Partial<Record<keyof ProfileFormState, string>>;

const sanitizeDigits = (value: string) => value.replace(/\D/g, "");

const validateForm = (form: ProfileFormState): FormErrors => {
  const errors: FormErrors = {};

  if (!form.fullName.trim()) {
    errors.fullName = "Full name is required.";
  }

  if (!form.email.trim()) {
    errors.email = "Email is required.";
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
    errors.email = "Enter a valid email address.";
  }

  if (!form.phone.trim()) {
    errors.phone = "Phone number is required.";
  } else if (!/^\d{10}$/.test(form.phone)) {
    errors.phone = "Phone must be 10 digits.";
  }

  if (!form.city.trim()) {
    errors.city = "City is required.";
  }

  if (!form.bankName.trim()) {
    errors.bankName = "Bank name is required.";
  }

  if (!form.accountNumber.trim()) {
    errors.accountNumber = "Account number is required.";
  } else if (!/^\d{9,18}$/.test(form.accountNumber)) {
    errors.accountNumber = "Account number must be 9 to 18 digits.";
  }

  if (!form.ifscCode.trim()) {
    errors.ifscCode = "IFSC code is required.";
  } else if (!/^[A-Z]{4}0[A-Z0-9]{6}$/.test(form.ifscCode.toUpperCase())) {
    errors.ifscCode = "Enter a valid IFSC code.";
  }

  if (form.upiId.trim() && !/^[\w.-]{2,}@[a-zA-Z]{2,}$/.test(form.upiId.trim())) {
    errors.upiId = "Enter a valid UPI ID (example: name@bank).";
  }

  return errors;
};

export default function HostProfile() {
  const dispatch = useAppDispatch();
  const { data, loading, error, updateLoading, updateError, updateSuccess } = useAppSelector(
    (state) => state.hostProfile
  );
  const [form, setForm] = useState<ProfileFormState>({
    fullName: "",
    email: "",
    phone: "",
    city: "",
    bankName: "",
    accountNumber: "",
    ifscCode: "",
    upiId: "",
  });
  const [errors, setErrors] = useState<FormErrors>({});
  const [isDirty, setIsDirty] = useState(false);

  const showMockData = Boolean(error) && USE_DEV_HOST_MOCKS;

  const displayData = useMemo(() => {
    if (showMockData) return MOCK_PROFILE;
    return {
      fullName: data?.fullName || "",
      email: data?.email || "",
      phone: data?.phone || "",
      city: data?.city || "",
      bankName: data?.bankName || "",
      accountNumber: data?.accountNumber || "",
      ifscCode: data?.ifscCode || "",
      upiId: data?.upiId || "",
    };
  }, [data, showMockData]);

  const isConnectivityIssue =
    Boolean(error) && /unable to reach|network|failed to fetch|connect/i.test(error || "");

  useEffect(() => {
    dispatch(fetchHostProfile());
  }, [dispatch]);

  useEffect(() => {
    setForm(displayData);
  }, [displayData]);

  useEffect(() => {
    return () => {
      dispatch(clearHostProfileUpdateState());
    };
  }, [dispatch]);

  const handleRetry = () => {
    dispatch(fetchHostProfile());
  };

  const updateField = (key: keyof ProfileFormState, value: string) => {
    const nextValue =
      key === "phone" || key === "accountNumber"
        ? sanitizeDigits(value)
        : key === "ifscCode"
        ? value.toUpperCase()
        : value;

    setForm((prev) => ({
      ...prev,
      [key]: nextValue,
    }));

    setErrors((prev) => ({
      ...prev,
      [key]: undefined,
    }));

    setIsDirty(true);
  };

  const handleReset = () => {
    setForm(displayData);
    setErrors({});
    setIsDirty(false);
    dispatch(clearHostProfileUpdateState());
  };

  const handleSave = async () => {
    const validationErrors = validateForm(form);
    setErrors(validationErrors);

    if (Object.keys(validationErrors).length > 0) return;

    dispatch(clearHostProfileUpdateState());

    const result = await dispatch(
      updateHostProfile({
        fullName: form.fullName.trim(),
        email: form.email.trim(),
        phone: form.phone.trim(),
        city: form.city.trim(),
        bankName: form.bankName.trim(),
        accountNumber: form.accountNumber.trim(),
        ifscCode: form.ifscCode.trim().toUpperCase(),
        upiId: form.upiId.trim(),
      })
    );

    if (updateHostProfile.fulfilled.match(result)) {
      setIsDirty(false);
      return;
    }

    if (USE_DEV_HOST_MOCKS) {
      dispatch(setLocalHostProfile(form));
      setIsDirty(false);
    }
  };

  return (
    <Stack spacing={2.5}>
      <Paper sx={{ p: 3, borderRadius: 2 }} elevation={0}>
        <Typography variant="h6" fontWeight={700}>
          Host Profile and Banking
        </Typography>
        <Typography variant="body2" color="text.secondary" mt={0.5}>
          Update host profile and payout account details.
        </Typography>

        {error && !showMockData && (
          <Alert
            sx={{ mt: 2 }}
            severity="warning"
            action={
              <Button color="inherit" size="small" onClick={handleRetry}>
                Retry
              </Button>
            }
          >
            <AlertTitle>Host profile data unavailable</AlertTitle>
            <Typography variant="body2">{error}</Typography>
            {isConnectivityIssue && (
              <Typography variant="caption" sx={{ display: "block", mt: 0.5 }}>
                Check backend availability and API base URL: {API_BASE_URL}
              </Typography>
            )}
          </Alert>
        )}

        {error && showMockData && (
          <Alert sx={{ mt: 2 }} severity="info">
            Backend host profile API is unavailable. Showing local mock profile data.
          </Alert>
        )}

        {updateError && !USE_DEV_HOST_MOCKS && (
          <Alert sx={{ mt: 2 }} severity="error">
            {updateError}
          </Alert>
        )}

        {updateSuccess && (
          <Alert sx={{ mt: 2 }} severity="success">
            {updateSuccess}
          </Alert>
        )}

        {loading && !showMockData ? (
          <Typography variant="body2" color="text.secondary" mt={1.5}>
            Loading profile...
          </Typography>
        ) : (
          <Stack spacing={2} mt={2.5}>
            <Box>
              <Typography variant="subtitle2" fontWeight={700} mb={1.25}>
                Profile Information
              </Typography>
              <Box
                sx={{
                  display: "grid",
                  gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
                  gap: 1.5,
                }}
              >
                <TextField
                  label="Full Name"
                  size="small"
                  value={form.fullName}
                  onChange={(e) => updateField("fullName", e.target.value)}
                  error={Boolean(errors.fullName)}
                  helperText={errors.fullName || " "}
                />
                <TextField
                  label="Email"
                  size="small"
                  value={form.email}
                  onChange={(e) => updateField("email", e.target.value)}
                  error={Boolean(errors.email)}
                  helperText={errors.email || " "}
                />
                <TextField
                  label="Phone"
                  size="small"
                  value={form.phone}
                  onChange={(e) => updateField("phone", e.target.value)}
                  error={Boolean(errors.phone)}
                  helperText={errors.phone || " "}
                  inputProps={{ maxLength: 10 }}
                />
                <TextField
                  label="City"
                  size="small"
                  value={form.city}
                  onChange={(e) => updateField("city", e.target.value)}
                  error={Boolean(errors.city)}
                  helperText={errors.city || " "}
                />
              </Box>
            </Box>

            <Box>
              <Typography variant="subtitle2" fontWeight={700} mb={1.25}>
                Banking Details
              </Typography>
              <Box
                sx={{
                  display: "grid",
                  gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
                  gap: 1.5,
                }}
              >
                <TextField
                  label="Bank Name"
                  size="small"
                  value={form.bankName}
                  onChange={(e) => updateField("bankName", e.target.value)}
                  error={Boolean(errors.bankName)}
                  helperText={errors.bankName || " "}
                />
                <TextField
                  label="Account Number"
                  size="small"
                  value={form.accountNumber}
                  onChange={(e) => updateField("accountNumber", e.target.value)}
                  error={Boolean(errors.accountNumber)}
                  helperText={errors.accountNumber || " "}
                  inputProps={{ maxLength: 18 }}
                />
                <TextField
                  label="IFSC Code"
                  size="small"
                  value={form.ifscCode}
                  onChange={(e) => updateField("ifscCode", e.target.value)}
                  error={Boolean(errors.ifscCode)}
                  helperText={errors.ifscCode || " "}
                  inputProps={{ maxLength: 11 }}
                />
                <TextField
                  label="UPI ID (optional)"
                  size="small"
                  value={form.upiId}
                  onChange={(e) => updateField("upiId", e.target.value)}
                  error={Boolean(errors.upiId)}
                  helperText={errors.upiId || " "}
                />
              </Box>
            </Box>

            <Stack direction="row" spacing={1.25} justifyContent="flex-end">
              <Button variant="outlined" onClick={handleReset} disabled={updateLoading || !isDirty}>
                Reset
              </Button>
              <Button
                variant="contained"
                onClick={handleSave}
                disabled={updateLoading || !isDirty}
                sx={{ bgcolor: "#881f9b" }}
              >
                {updateLoading ? "Saving..." : "Save Changes"}
              </Button>
            </Stack>
          </Stack>
        )}
      </Paper>
    </Stack>
  );
}
