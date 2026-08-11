import { useEffect, useRef, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { Box, Paper, Stack, Typography, Button, CircularProgress } from "@mui/material";
import { axios } from "../../../axios/axios";
import KycStatusBadge from "../../../components/frontend/kyc/KycStatusBadge";
import { KYC_SESSION_STORAGE_KEY } from "../../../components/frontend/kyc/VerifyButton";
import { isApproved, isTerminal, type KycStatus, type VerifyStatusResponse } from "../../../components/frontend/kyc/kyc.types";

const POLL_INTERVAL_MS = 3000;
const MAX_POLLS = 60; // ~3 minutes before we stop auto-polling

/**
 * B-10 — /verify/complete
 * Didit redirects the user here after the hosted flow. We poll
 * GET /verify/status?sessionId= every 3s until the status is terminal.
 */
const VerifyComplete = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();

  const sessionId =
    searchParams.get("session_id") ||
    searchParams.get("sessionId") ||
    window.localStorage.getItem(KYC_SESSION_STORAGE_KEY) ||
    "";
  const returnPath = searchParams.get("returnPath") || "";

  const [status, setStatus] = useState<KycStatus>("pending");
  const [polling, setPolling] = useState(true);
  const pollCount = useRef(0);

  useEffect(() => {
    if (!sessionId) {
      setStatus("error");
      setPolling(false);
      return;
    }

    let active = true;
    let timer: ReturnType<typeof setTimeout>;

    const poll = async () => {
      try {
        const body = (await axios.get(
          `/verify/status?sessionId=${encodeURIComponent(sessionId)}`
        )) as unknown as { data: VerifyStatusResponse };
        const next = (body?.data?.status as KycStatus) ?? "pending";
        if (!active) return;
        setStatus(next);

        if (isTerminal(next)) {
          setPolling(false);
          window.localStorage.removeItem(KYC_SESSION_STORAGE_KEY);
          return;
        }
      } catch {
        // transient — keep polling until the cap
      }

      pollCount.current += 1;
      if (pollCount.current >= MAX_POLLS) {
        if (active) setPolling(false);
        return;
      }
      timer = setTimeout(poll, POLL_INTERVAL_MS);
    };

    poll();
    return () => {
      active = false;
      clearTimeout(timer);
    };
  }, [sessionId]);

  const approved = isApproved(status);

  const heading = approved
    ? "You're verified!"
    : status === "declined"
    ? "Verification declined"
    : status === "in_review"
    ? "Verification in review"
    : status === "error"
    ? "Something went wrong"
    : "Finishing verification…";

  const subtitle = approved
    ? "Your identity has been confirmed. You can continue where you left off."
    : status === "declined"
    ? "We couldn't verify your identity. Please retry or contact support."
    : status === "in_review"
    ? "Your documents are being reviewed. We'll notify you once a decision is made — this usually takes a few minutes."
    : status === "error"
    ? "We couldn't find your verification session. Please restart verification."
    : "Please keep this page open while we confirm your verification.";

  const handleContinue = () => navigate(returnPath || "/user-dashboard");

  return (
    <Box sx={{ maxWidth: 560, mx: "auto", px: { xs: 2, sm: 3 }, py: { xs: 4, md: 6 } }}>
      <Paper
        sx={{
          borderRadius: "1.1rem",
          border: "1px solid #ede9fe",
          boxShadow: "0 14px 32px rgba(17,24,39,0.08)",
          overflow: "hidden",
        }}
      >
        <Box
          sx={{
            background: "linear-gradient(135deg, #6d28d9 0%, #3D4670 55%, #C16345 100%)",
            color: "#fff",
            px: { xs: 2.5, md: 3.2 },
            py: { xs: 3, md: 3.5 },
            textAlign: "center",
          }}
        >
          <Typography variant="h5" fontWeight={800}>{heading}</Typography>
        </Box>

        <Stack spacing={2.5} sx={{ px: { xs: 2.5, md: 3.5 }, py: { xs: 3.5, md: 4 } }} alignItems="center">
          {polling ? (
            <CircularProgress sx={{ color: "#6d28d9" }} />
          ) : (
            <KycStatusBadge status={status} size="medium" />
          )}

          <Typography variant="body2" color="text.secondary" textAlign="center">
            {subtitle}
          </Typography>

          {!polling && (
            <Stack direction={{ xs: "column", sm: "row" }} spacing={1.5} sx={{ width: "100%" }} justifyContent="center">
              {approved ? (
                <Button
                  variant="contained"
                  onClick={handleContinue}
                  sx={{
                    textTransform: "none",
                    fontWeight: 700,
                    borderRadius: "0.7rem",
                    px: 3,
                    background: "linear-gradient(135deg, #6d28d9 0%, #C16345 100%)",
                  }}
                >
                  Continue
                </Button>
              ) : (
                <>
                  <Button
                    variant="outlined"
                    onClick={() => navigate(returnPath || "/user-dashboard")}
                    sx={{ textTransform: "none", fontWeight: 700, borderRadius: "0.7rem" }}
                  >
                    Back
                  </Button>
                  {(status === "declined" || status === "error") && (
                    <Button
                      variant="contained"
                      onClick={() => navigate(-1)}
                      sx={{
                        textTransform: "none",
                        fontWeight: 700,
                        borderRadius: "0.7rem",
                        background: "linear-gradient(135deg, #6d28d9 0%, #C16345 100%)",
                      }}
                    >
                      Retry verification
                    </Button>
                  )}
                </>
              )}
            </Stack>
          )}
        </Stack>
      </Paper>
    </Box>
  );
};

export default VerifyComplete;
