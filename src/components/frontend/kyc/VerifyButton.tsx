import { useState } from "react";
import { Button, CircularProgress } from "@mui/material";
import { ShieldCheck } from "lucide-react";
import { axios } from "../../../axios/axios";
import { useNotificationStore } from "../../toast";
import type { CreateSessionResponse, KycContext } from "./kyc.types";

// Where VerifyComplete reads the pending session id from after Didit redirects back.
export const KYC_SESSION_STORAGE_KEY = "aajao_kyc_session";

interface VerifyButtonProps {
  context: KycContext;
  bookingId?: number | string;
  /** Path to return to after verification completes (carried through /verify/complete). */
  returnPath?: string;
  label?: string;
  fullWidth?: boolean;
  /** Called when the user is already verified (90-day skip) — proceed without redirect. */
  onVerified?: () => void;
}

const VerifyButton = ({
  context,
  bookingId,
  returnPath,
  label = "Verify your identity",
  fullWidth,
  onVerified,
}: VerifyButtonProps) => {
  const { addNotification } = useNotificationStore();
  const [loading, setLoading] = useState(false);

  const startVerification = async () => {
    try {
      setLoading(true);
      const body = (await axios.post("/verify/create-session", {
        context,
        ...(bookingId != null ? { bookingId } : {}),
      })) as unknown as { data: CreateSessionResponse };

      const session = body?.data ?? ({} as CreateSessionResponse);

      // Already verified within validity window → proceed, no redirect.
      if (session.status === "verified" || (!session.sessionUrl && session.skipReason)) {
        addNotification({
          type: "success",
          title: "Already verified",
          message: "Your identity is already verified.",
        });
        onVerified?.();
        return;
      }

      if (session.sessionUrl) {
        if (session.sessionId) {
          window.localStorage.setItem(KYC_SESSION_STORAGE_KEY, session.sessionId);
        }
        // Hand off to Didit's hosted verification flow.
        window.location.href = session.sessionUrl;
        return;
      }

      // No URL and no skip — backend stubbed (creds not configured). Send the
      // user to the completion screen to poll the stored session.
      if (session.sessionId) {
        window.localStorage.setItem(KYC_SESSION_STORAGE_KEY, session.sessionId);
        const q = new URLSearchParams({ session_id: session.sessionId });
        if (returnPath) q.set("returnPath", returnPath);
        window.location.href = `/verify/complete?${q.toString()}`;
        return;
      }

      addNotification({
        type: "warning",
        title: "Verification unavailable",
        message: "Could not start verification right now. Please try again.",
      });
    } catch (error: unknown) {
      const message =
        (error as { response?: { data?: { message?: string } } })?.response?.data?.message ||
        "Could not start identity verification. Please try again.";
      addNotification({ type: "error", title: "Verification failed", message });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Button
      variant="contained"
      fullWidth={fullWidth}
      onClick={startVerification}
      disabled={loading}
      startIcon={loading ? <CircularProgress size={16} color="inherit" /> : <ShieldCheck size={18} />}
      sx={{
        textTransform: "none",
        fontWeight: 700,
        borderRadius: "0.7rem",
        py: 1.1,
        background: "linear-gradient(135deg, #6d28d9 0%, #C16345 100%)",
        "&:hover": { background: "linear-gradient(135deg, #5b21b6 0%, #a84f37 100%)" },
        "&.Mui-disabled": { background: "#e5e7eb", color: "#9ca3af" },
      }}
    >
      {loading ? "Starting…" : label}
    </Button>
  );
};

export default VerifyButton;
