import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Stack,
  Typography,
  Chip,
  Divider,
  Box,
  Alert,
  TextField,
  CircularProgress,
} from "@mui/material";
import { useEffect, useMemo, useState } from "react";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import {
  approveHostKyc,
  clearHostKycActionState,
  fetchHostDetail,
  rejectHostKyc,
  resetHostDetail,
} from "../../../features/admin/userManagement/hostDetail.slice";
import type { HostTableRow } from "./HostTable";

interface KycAuditEntry {
  action: string;
  timestamp: string | null;
  actor: string;
  note: string;
}

const normalizeAction = (action: string) => action.trim().toLowerCase();

const getAuditActionChipColor = (
  action: string
): "success" | "error" | "warning" | "info" | "default" => {
  const normalized = normalizeAction(action);

  if (
    normalized.includes("approve") ||
    normalized.includes("verified") ||
    normalized.includes("accept")
  ) {
    return "success";
  }

  if (
    normalized.includes("reject") ||
    normalized.includes("decline") ||
    normalized.includes("failed")
  ) {
    return "error";
  }

  if (
    normalized.includes("pending") ||
    normalized.includes("review") ||
    normalized.includes("submitted")
  ) {
    return "warning";
  }

  if (normalized.includes("update") || normalized.includes("edit")) {
    return "info";
  }

  return "default";
};

const toActionLabel = (action: string) =>
  action
    .replace(/_/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());

const asArray = (value: unknown): any[] => {
  if (Array.isArray(value)) return value;
  if (typeof value === "string") {
    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }

  return [];
};

const extractKycAuditTrail = (detail: any): KycAuditEntry[] => {
  const candidates = [
    detail?.kycAuditTrail,
    detail?.kyc_audit_trail,
    detail?.kycTimeline,
    detail?.auditTrail,
    detail?.auditLogs,
    detail?.userKycDocs?.auditTrail,
    detail?.userKycDocs?.timeline,
    detail?.userKycDocs?.history,
  ];

  const source = candidates.map(asArray).find((rows) => rows.length > 0) || [];

  return source
    .map((entry: any) => ({
      action: String(
        entry?.action ||
          entry?.event ||
          entry?.status ||
          entry?.ud_status ||
          "KYC updated"
      ),
      timestamp:
        entry?.createdAt ||
        entry?.created_at ||
        entry?.timestamp ||
        entry?.time ||
        entry?.actionAt ||
        entry?.updated_at ||
        null,
      actor: String(
        entry?.adminName ||
          entry?.actor ||
          entry?.by ||
          entry?.updated_by ||
          entry?.created_by ||
          "System"
      ),
      note: String(entry?.note || entry?.reason || entry?.remark || entry?.comments || ""),
    }))
    .sort((a, b) => {
      const aTime = a.timestamp ? new Date(a.timestamp).getTime() : 0;
      const bTime = b.timestamp ? new Date(b.timestamp).getTime() : 0;
      return bTime - aTime;
    });
};

interface HostDetailDialogProps {
  open: boolean;
  host: HostTableRow | null;
  onClose: () => void;
  onActionComplete?: () => void;
}

export default function HostDetailDialog({
  open,
  host,
  onClose,
  onActionComplete,
}: HostDetailDialogProps) {
  const dispatch = useAppDispatch();
  const { data, loading, error, actionLoading, actionError, actionSuccess } =
    useAppSelector((state) => state.hostDetail);
  const [rejectReason, setRejectReason] = useState("");

  useEffect(() => {
    if (open && host?.id) {
      dispatch(fetchHostDetail(host.id));
    }

    return () => {
      dispatch(clearHostKycActionState());
    };
  }, [dispatch, host?.id, open]);

  useEffect(() => {
    if (!open) {
      setRejectReason("");
      dispatch(resetHostDetail());
    }
  }, [dispatch, open]);

  const detail = data || host;
  const isVerified =
    Number(detail?.user_isVerified ?? (host?.isVerified ? 1 : 0)) === 1;

  const createdAt = useMemo(() => {
    const raw = detail?.added_at || host?.addedAt;
    if (!raw) return "-";

    try {
      return new Date(raw).toLocaleDateString();
    } catch {
      return String(raw);
    }
  }, [detail?.added_at, host?.addedAt]);

  const auditTrail = useMemo(() => extractKycAuditTrail(detail), [detail]);

  if (!host) return null;

  const handleApprove = async () => {
    if (!host?.id) return;

    const res = await dispatch(approveHostKyc({ hostId: host.id }));
    if (approveHostKyc.fulfilled.match(res)) {
      await dispatch(fetchHostDetail(host.id));

      if (onActionComplete) {
        onActionComplete();
      }
    }
  };

  const handleReject = async () => {
    if (!host?.id || !rejectReason.trim()) return;

    const res = await dispatch(
      rejectHostKyc({ hostId: host.id, reason: rejectReason.trim() })
    );
    if (rejectHostKyc.fulfilled.match(res)) {
      await dispatch(fetchHostDetail(host.id));
      setRejectReason("");
      if (onActionComplete) {
        onActionComplete();
      }
    }
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle>Host Details</DialogTitle>

      <DialogContent dividers>
        {loading ? (
          <Box
            sx={{
              minHeight: 160,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <CircularProgress size={28} />
          </Box>
        ) : (
        <Stack spacing={2}>
          {error && <Alert severity="error">{error}</Alert>}
          {actionError && <Alert severity="error">{actionError}</Alert>}
          {actionSuccess && <Alert severity="success">{actionSuccess}</Alert>}

          <Box>
            <Typography variant="overline" color="text.secondary">
              Name
            </Typography>
            <Typography variant="body1" fontWeight={600}>
              {detail?.user_fullName || host.name}
            </Typography>
          </Box>

          <Divider />

          <Box>
            <Typography variant="overline" color="text.secondary">
              Email
            </Typography>
            <Typography variant="body2">
              {detail?.userCred?.cred_user_email || host.email || "-"}
            </Typography>
          </Box>

          <Box>
            <Typography variant="overline" color="text.secondary">
              Phone
            </Typography>
            <Typography variant="body2">{detail?.user_pnumber || "-"}</Typography>
          </Box>

          <Box>
            <Typography variant="overline" color="text.secondary">
              City
            </Typography>
            <Typography variant="body2">{detail?.user_city || "-"}</Typography>
          </Box>

          <Box>
            <Typography variant="overline" color="text.secondary">
              Properties Listed
            </Typography>
            <Typography variant="body2">
              {detail?.propertyCount ?? host.propertyCount ?? 0}
            </Typography>
          </Box>

          <Box>
            <Typography variant="overline" color="text.secondary">
              Account Created
            </Typography>
            <Typography variant="body2">{createdAt}</Typography>
          </Box>

          <Box>
            <Typography variant="overline" color="text.secondary">
              KYC Document Number
            </Typography>
            <Typography variant="body2">
              {detail?.userKycDocs?.ud_number || "-"}
            </Typography>
          </Box>

          <Box>
            <Typography variant="overline" color="text.secondary">
              KYC Document Preview
            </Typography>
            {detail?.kycDocumentImage?.url ? (
              <Box
                component="img"
                src={detail.kycDocumentImage.url}
                alt="Host KYC document"
                sx={{
                  mt: 1,
                  width: "100%",
                  maxHeight: 220,
                  objectFit: "contain",
                  borderRadius: 1,
                  border: "1px solid #e5e7eb",
                  p: 1,
                }}
              />
            ) : (
              <Typography variant="body2">No KYC document image available</Typography>
            )}
          </Box>

          {detail?.profileImage?.url && (
            <Box>
              <Typography variant="overline" color="text.secondary">
                Profile Image
              </Typography>
              <Box
                component="img"
                src={detail.profileImage.url}
                alt="Host profile"
                sx={{
                  mt: 1,
                  width: 96,
                  height: 96,
                  objectFit: "cover",
                  borderRadius: "50%",
                  border: "1px solid #e5e7eb",
                }}
              />
            </Box>
          )}

          <Stack direction="row" spacing={1}>
            <Chip
              size="small"
              label={Number(detail?.user_isActive ?? (host.isActive ? 1 : 0)) === 1 ? "Active" : "Inactive"}
              color={Number(detail?.user_isActive ?? (host.isActive ? 1 : 0)) === 1 ? "success" : "default"}
              variant={Number(detail?.user_isActive ?? (host.isActive ? 1 : 0)) === 1 ? "filled" : "outlined"}
            />
            <Chip
              size="small"
              label={isVerified ? "Verified" : "Unverified"}
              color={isVerified ? "success" : "warning"}
              variant={isVerified ? "filled" : "outlined"}
            />
          </Stack>

          <Divider />

          <Typography variant="subtitle2" color="text.secondary">
            KYC Review Actions
          </Typography>

          <Stack direction={{ xs: "column", sm: "row" }} spacing={1.5}>
            <Button
              variant="contained"
              color="success"
              disabled={actionLoading || isVerified}
              onClick={handleApprove}
            >
              Approve KYC
            </Button>
            <TextField
              size="small"
              fullWidth
              required
              label="Rejection reason"
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
              disabled={actionLoading}
              helperText="Reason is required for KYC rejection"
            />
            <Button
              variant="outlined"
              color="error"
              disabled={actionLoading || !rejectReason.trim()}
              onClick={handleReject}
            >
              Reject KYC
            </Button>
          </Stack>

          <Divider />

          <Box>
            <Typography variant="subtitle2" color="text.secondary" mb={1}>
              Action Audit Trail
            </Typography>
            {auditTrail.length === 0 ? (
              <Typography variant="body2">
                No backend audit entries found for this host KYC yet.
              </Typography>
            ) : (
              <Stack spacing={1}>
                {auditTrail.map((entry, index) => (
                  <Stack
                    key={`${entry.action}-${entry.timestamp || index}-${index}`}
                    direction={{ xs: "column", sm: "row" }}
                    spacing={1}
                    alignItems={{ xs: "flex-start", sm: "center" }}
                  >
                    <Chip
                      size="small"
                      variant="outlined"
                      label={toActionLabel(entry.action)}
                      color={getAuditActionChipColor(entry.action)}
                    />
                    <Typography variant="caption" color="text.secondary">
                      {entry.timestamp
                        ? new Date(entry.timestamp).toLocaleString()
                        : "Time unavailable"}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      By {entry.actor}
                    </Typography>
                    {entry.note ? (
                      <Typography variant="caption" color="text.secondary">
                        Note: {entry.note}
                      </Typography>
                    ) : null}
                  </Stack>
                ))}
              </Stack>
            )}
          </Box>
        </Stack>
        )}
      </DialogContent>

      <DialogActions>
        <Button onClick={onClose} variant="contained" sx={{ bgcolor: "#881f9b" }}>
          Close
        </Button>
      </DialogActions>
    </Dialog>
  );
}
