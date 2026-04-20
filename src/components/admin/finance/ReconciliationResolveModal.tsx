import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Stack,
  TextField,
  MenuItem,
  Divider,
  Box,
} from "@mui/material";
import type {
  ReconciliationRecord,
  ReconciliationAction,
} from "../../../pages/admin/finance/types";
import { useState, useEffect } from "react";

interface Props {
  open: boolean;
  record: ReconciliationRecord | null;
  loading: boolean;
  onResolve: (action: ReconciliationAction, notes: string) => void;
  onClose: () => void;
}

const ACTION_OPTIONS: { value: ReconciliationAction; label: string; desc: string }[] = [
  { value: "ADJUST", label: "Adjust", desc: "Manually adjust the variance amount in the ledger" },
  { value: "WRITE_OFF", label: "Write Off", desc: "Write off the variance as a loss" },
  { value: "REFUND", label: "Refund", desc: "Issue a refund to the guest for the variance" },
];

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

const ReconciliationResolveModal = ({
  open,
  record,
  loading,
  onResolve,
  onClose,
}: Props) => {
  const [action, setAction] = useState<ReconciliationAction>("ADJUST");
  const [notes, setNotes] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    if (open) {
      setAction("ADJUST");
      setNotes("");
      setError("");
    }
  }, [open]);

  if (!record) return null;

  const handleSubmit = () => {
    if (!notes.trim()) {
      setError("Resolution notes are required");
      return;
    }
    setError("");
    onResolve(action, notes.trim());
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ fontWeight: 600, color: "#374151" }}>
        Resolve Variance
      </DialogTitle>
      <DialogContent>
        {/* Variance highlight */}
        <Box
          sx={{
            bgcolor: "#fff7ed",
            borderRadius: "0.75rem",
            p: 2,
            mb: 2,
            textAlign: "center",
          }}
        >
          <Typography variant="body2" color="text.secondary">
            Variance Amount
          </Typography>
          <Typography variant="h4" fontWeight={700} color="#ea580c">
            ₹{Math.abs(record.variance).toLocaleString("en-IN")}
          </Typography>
        </Box>

        <DetailRow label="Booking ID" value={`#${record.booking_id}`} />
        <DetailRow
          label="Property"
          value={record.property_name || "—"}
        />
        <DetailRow label="Host" value={record.host_name || "—"} />
        <DetailRow
          label="Expected"
          value={`₹${record.expected_amount.toLocaleString("en-IN")}`}
        />
        <DetailRow
          label="Payment Received"
          value={`₹${record.payment_amount.toLocaleString("en-IN")}`}
        />
        {record.notes && (
          <DetailRow label="Existing Notes" value={record.notes} />
        )}

        <Divider sx={{ my: 2 }} />

        {/* Resolution action */}
        <TextField
          select
          fullWidth
          size="small"
          label="Resolution Action"
          value={action}
          onChange={(e) => setAction(e.target.value as ReconciliationAction)}
          sx={{ mb: 2 }}
        >
          {ACTION_OPTIONS.map((opt) => (
            <MenuItem key={opt.value} value={opt.value}>
              <Box>
                <Typography variant="body2" fontWeight={500}>
                  {opt.label}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {opt.desc}
                </Typography>
              </Box>
            </MenuItem>
          ))}
        </TextField>

        {/* Notes */}
        <TextField
          fullWidth
          multiline
          rows={3}
          size="small"
          label="Resolution Notes"
          placeholder="Explain how this variance is being resolved..."
          value={notes}
          onChange={(e) => {
            setNotes(e.target.value);
            if (error) setError("");
          }}
          error={!!error}
          helperText={error || `${notes.length}/500`}
          inputProps={{ maxLength: 500 }}
        />
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2 }}>
        <Button onClick={onClose} disabled={loading}>
          Cancel
        </Button>
        <Button
          variant="contained"
          onClick={handleSubmit}
          disabled={loading}
          sx={{
            bgcolor: "#881f9b",
            "&:hover": { bgcolor: "#7115bd" },
          }}
        >
          {loading ? "Resolving..." : "Resolve Variance"}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ReconciliationResolveModal;
