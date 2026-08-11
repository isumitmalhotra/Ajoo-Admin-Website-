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
  Tabs,
  Tab,
} from "@mui/material";
import { useEffect, useMemo, useState, type SyntheticEvent } from "react";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import {
  approveHostKyc,
  clearHostKycActionState,
  fetchHostDetail,
  rejectHostKyc,
  resetHostDetail,
} from "../../../features/admin/userManagement/hostDetail.slice";
import {
  fetchAdminHostPerformance,
  resetAdminHostPerformance,
  type PerfWindow,
} from "../../../features/admin/hostManagement/adminHostPerformance.slice";
import {
  fetchAdminHostPayouts,
  setAdminHostPayoutHold,
  resetAdminHostPayout,
} from "../../../features/admin/hostManagement/adminHostPayout.slice";
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
  if (normalized.includes("approve") || normalized.includes("verified") || normalized.includes("accept")) {
    return "success";
  }
  if (normalized.includes("reject") || normalized.includes("decline") || normalized.includes("failed")) {
    return "error";
  }
  if (normalized.includes("pending") || normalized.includes("review") || normalized.includes("submitted")) {
    return "warning";
  }
  if (normalized.includes("update") || normalized.includes("edit")) {
    return "info";
  }
  return "default";
};

const toActionLabel = (action: string) =>
  action.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());

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
      action: String(entry?.action || entry?.event || entry?.status || entry?.ud_status || "KYC updated"),
      timestamp:
        entry?.createdAt || entry?.created_at || entry?.timestamp || entry?.time || entry?.actionAt || entry?.updated_at || null,
      actor: String(entry?.adminName || entry?.actor || entry?.by || entry?.updated_by || entry?.created_by || "System"),
      note: String(entry?.note || entry?.reason || entry?.remark || entry?.comments || ""),
    }))
    .sort((a, b) => {
      const aTime = a.timestamp ? new Date(a.timestamp).getTime() : 0;
      const bTime = b.timestamp ? new Date(b.timestamp).getTime() : 0;
      return bTime - aTime;
    });
};

const labelSx = { color: "text.secondary" } as const;

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
  const performance = useAppSelector((state) => state.adminHostPerformance);
  const payout = useAppSelector((state) => state.adminHostPayout);

  const [tab, setTab] = useState(0);
  const [rejectReason, setRejectReason] = useState("");
  const [performanceWindow, setPerformanceWindow] = useState<PerfWindow>("30D");

  // Load detail + performance + payouts when the dialog opens for a host.
  useEffect(() => {
    if (open && host?.id) {
      dispatch(fetchHostDetail(host.id));
      dispatch(fetchAdminHostPerformance({ hostId: host.id, window: "30D" }));
      dispatch(fetchAdminHostPayouts({ hostId: host.id }));
    }
    return () => {
      dispatch(clearHostKycActionState());
    };
  }, [dispatch, host?.id, open]);

  // Refetch performance when the window changes.
  useEffect(() => {
    if (open && host?.id) {
      dispatch(fetchAdminHostPerformance({ hostId: host.id, window: performanceWindow }));
    }
  }, [dispatch, host?.id, open, performanceWindow]);

  // Reset everything on close.
  useEffect(() => {
    if (!open) {
      setTab(0);
      setRejectReason("");
      setPerformanceWindow("30D");
      dispatch(resetHostDetail());
      dispatch(resetAdminHostPerformance());
      dispatch(resetAdminHostPayout());
    }
  }, [dispatch, open]);

  const detail = data || host;
  const isVerified = Number(detail?.user_isVerified ?? (host?.isVerified ? 1 : 0)) === 1;

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
      onActionComplete?.();
    }
  };

  const handleReject = async () => {
    if (!host?.id || !rejectReason.trim()) return;
    const res = await dispatch(rejectHostKyc({ hostId: host.id, reason: rejectReason.trim() }));
    if (rejectHostKyc.fulfilled.match(res)) {
      await dispatch(fetchHostDetail(host.id));
      setRejectReason("");
      onActionComplete?.();
    }
  };

  const handlePayoutToggle = (payoutId: string, currentStatus: string) => {
    dispatch(setAdminHostPayoutHold({ payoutId, hold: currentStatus !== "ON_HOLD" }));
  };

  const isActive = Number(detail?.user_isActive ?? (host.isActive ? 1 : 0)) === 1;

  const renderDetailTab = () => (
    <Stack spacing={2}>
      {error && <Alert severity="error">{error}</Alert>}
      <Box>
        <Typography variant="overline" sx={labelSx}>Name</Typography>
        <Typography variant="body1" fontWeight={600}>{detail?.user_fullName || host.name}</Typography>
      </Box>
      <Divider />
      <Box>
        <Typography variant="overline" sx={labelSx}>Email</Typography>
        <Typography variant="body2">{detail?.userCred?.cred_user_email || host.email || "-"}</Typography>
      </Box>
      <Box>
        <Typography variant="overline" sx={labelSx}>Phone</Typography>
        <Typography variant="body2">{detail?.user_pnumber || "-"}</Typography>
      </Box>
      <Box>
        <Typography variant="overline" sx={labelSx}>City</Typography>
        <Typography variant="body2">{detail?.user_city || "-"}</Typography>
      </Box>
      <Box>
        <Typography variant="overline" sx={labelSx}>Properties Listed</Typography>
        <Typography variant="body2">{detail?.propertyCount ?? host.propertyCount ?? 0}</Typography>
      </Box>
      <Box>
        <Typography variant="overline" sx={labelSx}>Account Created</Typography>
        <Typography variant="body2">{createdAt}</Typography>
      </Box>
      {detail?.profileImage?.url && (
        <Box>
          <Typography variant="overline" sx={labelSx}>Profile Image</Typography>
          <Box
            component="img"
            src={detail.profileImage.url}
            alt="Host profile"
            sx={{ mt: 1, width: 96, height: 96, objectFit: "cover", borderRadius: "50%", border: "1px solid #e5e7eb" }}
          />
        </Box>
      )}
      <Stack direction="row" spacing={1}>
        <Chip
          size="small"
          label={isActive ? "Active" : "Inactive"}
          color={isActive ? "success" : "default"}
          variant={isActive ? "filled" : "outlined"}
        />
        <Chip
          size="small"
          label={isVerified ? "Verified" : "Unverified"}
          color={isVerified ? "success" : "warning"}
          variant={isVerified ? "filled" : "outlined"}
        />
      </Stack>
    </Stack>
  );

  const renderKycTab = () => (
    <Stack spacing={2}>
      {actionError && <Alert severity="error">{actionError}</Alert>}
      {actionSuccess && <Alert severity="success">{actionSuccess}</Alert>}

      <Box>
        <Typography variant="overline" sx={labelSx}>KYC Document Number</Typography>
        <Typography variant="body2">{detail?.userKycDocs?.ud_number || "-"}</Typography>
      </Box>

      <Box>
        <Typography variant="overline" sx={labelSx}>KYC Document Preview</Typography>
        {detail?.kycDocumentImage?.url ? (
          <Box
            component="img"
            src={detail.kycDocumentImage.url}
            alt="Host KYC document"
            sx={{ mt: 1, width: "100%", maxHeight: 220, objectFit: "contain", borderRadius: 1, border: "1px solid #e5e7eb", p: 1 }}
          />
        ) : (
          <Typography variant="body2">No KYC document image available</Typography>
        )}
      </Box>

      <Divider />

      <Typography variant="subtitle2" sx={labelSx}>KYC Review Actions</Typography>
      <Stack direction={{ xs: "column", sm: "row" }} spacing={1.5}>
        <Button variant="contained" color="success" disabled={actionLoading || isVerified} onClick={handleApprove}>
          {actionLoading ? "Working…" : "Approve KYC"}
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
        <Button variant="outlined" color="error" disabled={actionLoading || !rejectReason.trim()} onClick={handleReject}>
          Reject KYC
        </Button>
      </Stack>

      <Divider />

      <Box>
        <Typography variant="subtitle2" sx={labelSx} mb={1}>Action Audit Trail</Typography>
        {auditTrail.length === 0 ? (
          <Typography variant="body2">No backend audit entries found for this host KYC yet.</Typography>
        ) : (
          <Stack spacing={1}>
            {auditTrail.map((entry, index) => (
              <Stack
                key={`${entry.action}-${entry.timestamp || index}-${index}`}
                direction={{ xs: "column", sm: "row" }}
                spacing={1}
                alignItems={{ xs: "flex-start", sm: "center" }}
              >
                <Chip size="small" variant="outlined" label={toActionLabel(entry.action)} color={getAuditActionChipColor(entry.action)} />
                <Typography variant="caption" sx={labelSx}>
                  {entry.timestamp ? new Date(entry.timestamp).toLocaleString() : "Time unavailable"}
                </Typography>
                <Typography variant="caption" sx={labelSx}>By {entry.actor}</Typography>
                {entry.note ? <Typography variant="caption" sx={labelSx}>Note: {entry.note}</Typography> : null}
              </Stack>
            ))}
          </Stack>
        )}
      </Box>
    </Stack>
  );

  const renderPerformanceTab = () => {
    const p = performance.data;
    const cards = p
      ? [
          { label: "Occupancy", value: `${p.occupancy}%` },
          { label: "Earnings", value: `INR ${p.earnings.toLocaleString("en-IN")}` },
          { label: "Total Bookings", value: String(p.totalBookings) },
          { label: "Cancellations", value: String(p.cancellations) },
          { label: "Avg Response", value: `${p.responseTimeHours} hrs` },
          { label: "Rating", value: `${p.rating.toFixed(1)}/5` },
        ]
      : [];

    return (
      <Stack spacing={2}>
        <Stack
          direction={{ xs: "column", sm: "row" }}
          spacing={1}
          alignItems={{ xs: "flex-start", sm: "center" }}
          justifyContent="space-between"
        >
          <Typography variant="subtitle2" sx={labelSx}>Performance Summary</Typography>
          <TextField
            select
            size="small"
            label="Window"
            value={performanceWindow}
            onChange={(e) => setPerformanceWindow(e.target.value as PerfWindow)}
            sx={{ minWidth: 130 }}
          >
            <MenuItem value="30D">30 Days</MenuItem>
            <MenuItem value="90D">90 Days</MenuItem>
          </TextField>
        </Stack>

        {performance.error && <Alert severity="error">{performance.error}</Alert>}

        {performance.loading ? (
          <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}>
            <CircularProgress size={26} />
          </Box>
        ) : cards.length === 0 ? (
          <Typography variant="body2" sx={labelSx}>No performance data available for this host.</Typography>
        ) : (
          <Box sx={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(150px, 1fr))", gap: 1 }}>
            {cards.map((c) => (
              <Paper key={c.label} variant="outlined" sx={{ p: 1.1 }}>
                <Typography variant="caption" sx={labelSx}>{c.label}</Typography>
                <Typography variant="subtitle1" fontWeight={700}>{c.value}</Typography>
              </Paper>
            ))}
          </Box>
        )}
      </Stack>
    );
  };

  const renderPayoutTab = () => (
    <Stack spacing={2}>
      <Typography variant="subtitle2" sx={labelSx}>Payout History</Typography>
      {payout.error && <Alert severity="error">{payout.error}</Alert>}

      {payout.loading ? (
        <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}>
          <CircularProgress size={26} />
        </Box>
      ) : payout.rows.length === 0 ? (
        <Typography variant="body2" sx={labelSx}>No payouts recorded for this host yet.</Typography>
      ) : (
        <Stack spacing={0.8}>
          {payout.rows.map((row) => (
            <Stack
              key={row.payoutId}
              direction={{ xs: "column", sm: "row" }}
              spacing={1}
              alignItems={{ xs: "flex-start", sm: "center" }}
              justifyContent="space-between"
              sx={{ p: 1, border: "1px solid #e5e7eb", borderRadius: "0.7rem" }}
            >
              <Box>
                <Typography variant="body2" fontWeight={700}>{row.payoutId}</Typography>
                <Typography variant="caption" sx={labelSx}>{new Date(row.date).toLocaleDateString("en-IN")}</Typography>
              </Box>
              <Stack direction="row" spacing={0.8} alignItems="center">
                <Typography variant="body2" fontWeight={700}>INR {row.amount.toLocaleString("en-IN")}</Typography>
                <Chip
                  size="small"
                  label={row.status.replace("_", " ")}
                  color={row.status === "READY" || row.status === "PAID" ? "success" : row.status === "ON_HOLD" ? "warning" : "info"}
                  variant="outlined"
                />
                <Button
                  size="small"
                  variant="outlined"
                  disabled={row.status === "PROCESSING" || row.status === "PAID" || payout.actioningId === row.payoutId}
                  onClick={() => handlePayoutToggle(row.payoutId, row.status)}
                >
                  {payout.actioningId === row.payoutId ? "…" : row.status === "ON_HOLD" ? "Release" : "Hold"}
                </Button>
              </Stack>
            </Stack>
          ))}
        </Stack>
      )}
    </Stack>
  );

  const TAB_LABELS = ["Detail", "KYC", "Performance", "Payout"];

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="md">
      <DialogTitle>Host Details</DialogTitle>

      <Tabs
        value={tab}
        onChange={(_e: SyntheticEvent, v: number) => setTab(v)}
        variant="scrollable"
        scrollButtons="auto"
        sx={{
          px: 2,
          borderBottom: "1px solid #e5e7eb",
          "& .MuiTab-root": { textTransform: "none", fontWeight: 600, minHeight: 46 },
          "& .Mui-selected": { color: "#1B2447 !important" },
          "& .MuiTabs-indicator": { backgroundColor: "#1B2447" },
        }}
      >
        {TAB_LABELS.map((l) => (
          <Tab key={l} label={l} />
        ))}
      </Tabs>

      <DialogContent dividers>
        {loading && tab < 2 ? (
          <Box sx={{ minHeight: 160, display: "flex", alignItems: "center", justifyContent: "center" }}>
            <CircularProgress size={28} />
          </Box>
        ) : (
          <Box sx={{ minHeight: 240 }}>
            {tab === 0 && renderDetailTab()}
            {tab === 1 && renderKycTab()}
            {tab === 2 && renderPerformanceTab()}
            {tab === 3 && renderPayoutTab()}
          </Box>
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
