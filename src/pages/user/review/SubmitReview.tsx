import { useMemo, useState } from "react";
import { useNavigate, useParams, useSearchParams, useLocation } from "react-router-dom";
import {
  Box,
  Paper,
  Stack,
  Typography,
  Rating,
  TextField,
  Button,
  Alert,
} from "@mui/material";
import { Star, ArrowLeft } from "lucide-react";
import { axios } from "../../../axios/axios";
import { useNotificationStore } from "../../../components/toast";

const RATING_LABELS: Record<number, string> = {
  1: "Poor",
  2: "Fair",
  3: "Good",
  4: "Very good",
  5: "Excellent",
};

/**
 * B-03 — User Review Submit page.
 * Route: /user/review/:bookingId  (?propertyId=123, or location.state.propertyId)
 * Posts to the live POST /user/review-add endpoint (mobile already uses it).
 * NOTE: the backend resolves the review by propertyId + user, so propertyId is
 * required — the "Write Review" CTA in booking history passes it through.
 */
const SubmitReview = () => {
  const { bookingId } = useParams<{ bookingId: string }>();
  const [searchParams] = useSearchParams();
  const location = useLocation();
  const navigate = useNavigate();
  const { addNotification } = useNotificationStore();

  // propertyId can arrive via query string or router state
  const propertyId = useMemo(() => {
    const fromQuery = searchParams.get("propertyId");
    const fromState = (location.state as { propertyId?: number | string } | null)?.propertyId;
    const raw = fromQuery ?? fromState;
    const num = raw != null ? Number(raw) : NaN;
    return Number.isFinite(num) && num > 0 ? num : null;
  }, [searchParams, location.state]);

  const [rating, setRating] = useState<number | null>(0);
  const [hover, setHover] = useState(-1);
  const [description, setDescription] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const ratingValue = rating ?? 0;
  const canSubmit = !!propertyId && ratingValue > 0 && description.trim().length > 0 && !submitting;

  const handleSubmit = async () => {
    if (!propertyId) {
      addNotification({
        type: "error",
        title: "Missing property",
        message: "We couldn't determine which property to review. Please reopen from your bookings.",
      });
      return;
    }
    if (ratingValue < 1) {
      addNotification({ type: "warning", title: "Rating required", message: "Please pick a star rating." });
      return;
    }
    if (description.trim().length === 0) {
      addNotification({ type: "warning", title: "Review required", message: "Please write a short review." });
      return;
    }

    try {
      setSubmitting(true);
      await axios.post("/user/review-add", {
        bookingId: bookingId ? Number(bookingId) : undefined,
        propertyId,
        rating: ratingValue,
        description: description.trim(),
      });
      addNotification({
        type: "success",
        title: "Review submitted",
        message: "Thanks for sharing your experience!",
      });
      navigate("/user-dashboard");
    } catch (error: unknown) {
      const message =
        (error as { response?: { data?: { message?: string } } })?.response?.data?.message ||
        "Something went wrong while submitting your review. Please try again.";
      addNotification({ type: "error", title: "Submission failed", message });
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Box sx={{ maxWidth: 640, mx: "auto", px: { xs: 2, sm: 3 }, py: { xs: 3, md: 5 } }}>
      <Button
        startIcon={<ArrowLeft size={16} />}
        onClick={() => navigate(-1)}
        sx={{ textTransform: "none", color: "#6b7280", mb: 2, "&:hover": { bgcolor: "#f3f4f6" } }}
      >
        Back
      </Button>

      <Paper
        sx={{
          borderRadius: "1.1rem",
          border: "1px solid #ede9fe",
          boxShadow: "0 14px 32px rgba(17,24,39,0.08)",
          overflow: "hidden",
        }}
      >
        {/* Header */}
        <Box
          sx={{
            background: "linear-gradient(135deg, #6d28d9 0%, #3D4670 55%, #C16345 100%)",
            color: "#fff",
            px: { xs: 2.5, md: 3.2 },
            py: { xs: 2.5, md: 3 },
          }}
        >
          <Stack direction="row" spacing={1.5} alignItems="center">
            <Box
              sx={{
                width: 44,
                height: 44,
                borderRadius: "0.8rem",
                bgcolor: "rgba(255,255,255,0.15)",
                display: "grid",
                placeItems: "center",
                flexShrink: 0,
              }}
            >
              <Star size={22} color="#fff" />
            </Box>
            <Box>
              <Typography variant="h5" fontWeight={800} sx={{ lineHeight: 1.15 }}>
                Write a review
              </Typography>
              <Typography variant="body2" sx={{ opacity: 0.85, mt: 0.4 }}>
                Tell other travellers about your stay.
              </Typography>
            </Box>
          </Stack>
        </Box>

        {/* Body */}
        <Box sx={{ px: { xs: 2.5, md: 3.2 }, py: { xs: 3, md: 3.5 } }}>
          {!propertyId && (
            <Alert severity="warning" sx={{ mb: 2.5 }}>
              Property reference is missing. Please open this page from the "Write Review" button in
              your bookings so we know which stay to review.
            </Alert>
          )}

          <Stack spacing={3}>
            <Box>
              <Typography variant="subtitle2" fontWeight={700} color="#374151" mb={1}>
                Your rating
              </Typography>
              <Stack direction="row" spacing={1.5} alignItems="center">
                <Rating
                  name="property-rating"
                  value={rating}
                  size="large"
                  onChange={(_e, value) => setRating(value)}
                  onChangeActive={(_e, value) => setHover(value)}
                  sx={{ "& .MuiRating-iconFilled": { color: "#C16345" } }}
                />
                <Typography variant="body2" color="text.secondary" sx={{ minWidth: 80 }}>
                  {RATING_LABELS[hover !== -1 ? hover : ratingValue] ?? ""}
                </Typography>
              </Stack>
            </Box>

            <Box>
              <Typography variant="subtitle2" fontWeight={700} color="#374151" mb={1}>
                Your review
              </Typography>
              <TextField
                multiline
                minRows={4}
                fullWidth
                placeholder="Share details of your experience — the location, cleanliness, host, and value."
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                inputProps={{ maxLength: 1000 }}
                helperText={`${description.length}/1000`}
              />
            </Box>

            <Button
              variant="contained"
              size="large"
              onClick={handleSubmit}
              disabled={!canSubmit}
              sx={{
                textTransform: "none",
                fontWeight: 700,
                borderRadius: "0.7rem",
                py: 1.2,
                background: "linear-gradient(135deg, #6d28d9 0%, #C16345 100%)",
                "&:hover": { background: "linear-gradient(135deg, #5b21b6 0%, #a84f37 100%)" },
                "&.Mui-disabled": { background: "#e5e7eb", color: "#9ca3af" },
              }}
            >
              {submitting ? "Submitting…" : "Submit review"}
            </Button>
          </Stack>
        </Box>
      </Paper>
    </Box>
  );
};

export default SubmitReview;
