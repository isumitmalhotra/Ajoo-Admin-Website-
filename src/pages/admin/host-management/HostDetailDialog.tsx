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

  if (!host) return null;

  const handleApprove = async () => {
    if (!host?.id) return;

    const res = await dispatch(approveHostKyc({ hostId: host.id }));
    if (approveHostKyc.fulfilled.match(res) && onActionComplete) {
      onActionComplete();
    }
  };

  const handleReject = async () => {
    if (!host?.id || !rejectReason.trim()) return;

    const res = await dispatch(
      rejectHostKyc({ hostId: host.id, reason: rejectReason.trim() })
    );
    if (rejectHostKyc.fulfilled.match(res)) {
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
              placeholder="Rejection reason"
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
              disabled={actionLoading}
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
