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
  MenuItem,
  Paper,
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

interface HostPayoutPreview {
  payoutId: string;
  amount: number;
  status: "READY" | "ON_HOLD" | "PROCESSING";
  date: string;
}

const defaultPayoutPreview: HostPayoutPreview[] = [
  { payoutId: "PAY-4821", amount: 28600, status: "READY", date: "2026-05-11" },
  { payoutId: "PAY-4752", amount: 19300, status: "PROCESSING", date: "2026-05-06" },
  { payoutId: "PAY-4668", amount: 15850, status: "ON_HOLD", date: "2026-04-28" },
];

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
  const [performanceWindow, setPerformanceWindow] = useState<"30D" | "90D">("30D");
  const [payoutPreview, setPayoutPreview] = useState<HostPayoutPreview[]>(
    defaultPayoutPreview
  );

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
      setPerformanceWindow("30D");
      setPayoutPreview(defaultPayoutPreview);
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

  const performanceData = useMemo(() => {
    const isThirtyDay = performanceWindow === "30D";

    const fallback = {
      occupancy: isThirtyDay ? 74 : 69,
      earnings: isThirtyDay ? 168500 : 472000,
      cancellations: isThirtyDay ? 4 : 11,
      rating: isThirtyDay ? 4.6 : 4.5,
    };

    return {
      occupancy: Number(detail?.occupancyRate ?? detail?.occupancy ?? fallback.occupancy),
      earnings: Number(
        detail?.performanceSummary?.earnings ??
          detail?.hostEarnings ??
          detail?.monthEarnings ??
          fallback.earnings
      ),
      cancellations: Number(
        detail?.performanceSummary?.cancellations ??
          detail?.cancelledBookings ??
          fallback.cancellations
      ),
      rating: Number(detail?.rating ?? detail?.averageRating ?? fallback.rating),
    };
  }, [detail, performanceWindow]);

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

  const handlePayoutStatusToggle = (payoutId: string) => {
    setPayoutPreview((prev) =>
      prev.map((row) => {
        if (row.payoutId !== payoutId) return row;
        if (row.status === "ON_HOLD") return { ...row, status: "READY" };
        if (row.status === "READY") return { ...row, status: "ON_HOLD" };
        return row;
      })
    );
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="md">
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

          <Box>
            <Stack
              direction={{ xs: "column", sm: "row" }}
              spacing={1}
              alignItems={{ xs: "flex-start", sm: "center" }}
              justifyContent="space-between"
              mb={1}
            >
              <Typography variant="subtitle2" color="text.secondary">
                Performance Snapshot
              </Typography>
              <TextField
                select
                size="small"
                label="Window"
                value={performanceWindow}
                onChange={(event) =>
                  setPerformanceWindow(event.target.value as "30D" | "90D")
                }
                sx={{ minWidth: 130 }}
              >
                <MenuItem value="30D">30 Days</MenuItem>
                <MenuItem value="90D">90 Days</MenuItem>
              </TextField>
            </Stack>

            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: "repeat(auto-fit, minmax(150px, 1fr))",
                gap: 1,
              }}
            >
              <Paper variant="outlined" sx={{ p: 1.1 }}>
                <Typography variant="caption" color="text.secondary">
                  Occupancy
                </Typography>
                <Typography variant="subtitle1" fontWeight={700}>
                  {performanceData.occupancy}%
                </Typography>
              </Paper>
              <Paper variant="outlined" sx={{ p: 1.1 }}>
                <Typography variant="caption" color="text.secondary">
                  Earnings
                </Typography>
                <Typography variant="subtitle1" fontWeight={700}>
                  INR {performanceData.earnings.toLocaleString("en-IN")}
                </Typography>
              </Paper>
              <Paper variant="outlined" sx={{ p: 1.1 }}>
                <Typography variant="caption" color="text.secondary">
                  Cancellations
                </Typography>
                <Typography variant="subtitle1" fontWeight={700}>
                  {performanceData.cancellations}
                </Typography>
              </Paper>
              <Paper variant="outlined" sx={{ p: 1.1 }}>
                <Typography variant="caption" color="text.secondary">
                  Rating
                </Typography>
                <Typography variant="subtitle1" fontWeight={700}>
                  {performanceData.rating.toFixed(1)}/5
                </Typography>
              </Paper>
            </Box>
          </Box>

          <Divider />

          <Box>
            <Typography variant="subtitle2" color="text.secondary" mb={1}>
              Recent Payouts
            </Typography>
            <Stack spacing={0.8}>
              {payoutPreview.map((row) => (
                <Stack
                  key={row.payoutId}
                  direction={{ xs: "column", sm: "row" }}
                  spacing={1}
                  alignItems={{ xs: "flex-start", sm: "center" }}
                  justifyContent="space-between"
                  sx={{ p: 1, border: "1px solid #e5e7eb", borderRadius: "0.7rem" }}
                >
                  <Box>
                    <Typography variant="body2" fontWeight={700}>
                      {row.payoutId}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {new Date(row.date).toLocaleDateString("en-IN")}
                    </Typography>
                  </Box>
                  <Stack direction="row" spacing={0.8} alignItems="center">
                    <Typography variant="body2" fontWeight={700}>
                      INR {row.amount.toLocaleString("en-IN")}
                    </Typography>
                    <Chip
                      size="small"
                      label={row.status.replace("_", " ")}
                      color={
                        row.status === "READY"
                          ? "success"
                          : row.status === "ON_HOLD"
                          ? "warning"
                          : "info"
                      }
                      variant="outlined"
                    />
                    <Button
                      size="small"
                      variant="outlined"
                      disabled={row.status === "PROCESSING"}
                      onClick={() => handlePayoutStatusToggle(row.payoutId)}
                    >
                      {row.status === "ON_HOLD" ? "Release" : "Hold"}
                    </Button>
                  </Stack>
                </Stack>
              ))}
            </Stack>
          </Box>

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
        <Button onClick={onClose} variant="contained" sx={{ bgcolor: "#1B2447" }}>
          Close
        </Button>
      </DialogActions>
    </Dialog>
  );
}
