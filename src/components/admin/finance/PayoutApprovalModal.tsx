import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Stack,
  Divider,
  Box,
} from "@mui/material";
import type { Payout } from "../../../pages/admin/finance/types";

interface Props {
  open: boolean;
  payout: Payout | null;
  loading: boolean;
  onConfirm: () => void;
  onClose: () => void;
}

const DetailRow = ({ label, value }: { label: string; value: string }) => (
  <Stack direction="row" justifyContent="space-between" py={0.75}>
    <Typography variant="body2" color="text.secondary">
      {label}
    </Typography>
    <Typography variant="body2" fontWeight={500}>
      {value}
    </Typography>
  </Stack>
);

const PayoutApprovalModal = ({
  open,
  payout,
  loading,
  onConfirm,
  onClose,
}: Props) => {
  if (!payout) return null;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ fontWeight: 600, color: "#374151" }}>
        Confirm Payout Approval
      </DialogTitle>
      <DialogContent>
        <Box
          sx={{
            bgcolor: "#f0fdf4",
            border: "1px solid #bbf7d0",
            borderRadius: "0.75rem",
            p: 2.5,
            mb: 2.5,
            textAlign: "center",
          }}
        >
          <Typography variant="h4" fontWeight={700} color="#16a34a">
            ₹{payout.amount.toLocaleString("en-IN")}
          </Typography>
          <Typography variant="body2" color="#15803d" mt={0.5}>
            Will be transferred to host
          </Typography>
        </Box>

        <Stack spacing={0}>
          <DetailRow label="Host" value={payout.host_name} />
          <Divider />
          <DetailRow
            label="Period"
            value={`${new Date(payout.period_start).toLocaleDateString(
              "en-IN",
              { day: "2-digit", month: "short" }
            )} – ${new Date(payout.period_end).toLocaleDateString("en-IN", {
              day: "2-digit",
              month: "short",
            })}`}
          />
          <Divider />
          <DetailRow
            label="Method"
            value={
              payout.payout_method === "BANK_TRANSFER"
                ? "Bank Transfer"
                : "UPI"
            }
          />
          <Divider />
          <DetailRow label="Reference" value={payout.reference_id} />
        </Stack>

        <Typography
          variant="body2"
          color="text.secondary"
          mt={2.5}
          sx={{ fontStyle: "italic" }}
        >
          This action will move the payout to "Processing" status and trigger
          the payment transfer. This cannot be undone.
        </Typography>
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2 }}>
        <Button onClick={onClose} sx={{ color: "#6b7280" }}>
          Cancel
        </Button>
        <Button
          variant="contained"
          onClick={onConfirm}
          disabled={loading}
          sx={{ bgcolor: "#16a34a", "&:hover": { bgcolor: "#15803d" } }}
        >
          {loading ? "Processing..." : "Approve Payout"}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default PayoutApprovalModal;
