import { useState } from "react";
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  MenuItem,
  Stack,
} from "@mui/material";
import type { PayoutMethod } from "../../../pages/admin/finance/types";

const METHOD_OPTIONS: { value: PayoutMethod; label: string }[] = [
  { value: "BANK_TRANSFER", label: "Bank Transfer" },
  { value: "UPI", label: "UPI" },
];

interface FormState {
  hostId: string;
  amount: string;
  payoutMethod: PayoutMethod;
  notes: string;
}

interface Props {
  open: boolean;
  loading: boolean;
  onSubmit: (data: {
    hostId: number;
    amount: number;
    payoutMethod: PayoutMethod;
    note: string;
  }) => void;
  onClose: () => void;
}

const INITIAL: FormState = {
  hostId: "",
  amount: "",
  payoutMethod: "BANK_TRANSFER",
  notes: "",
};

const ManualPayoutModal = ({ open, loading, onSubmit, onClose }: Props) => {
  const [form, setForm] = useState<FormState>(INITIAL);
  const [errors, setErrors] = useState<Partial<Record<keyof FormState, string>>>({});

  const handleClose = () => {
    setForm(INITIAL);
    setErrors({});
    onClose();
  };

  const validate = (): boolean => {
    const errs: Partial<Record<keyof FormState, string>> = {};
    if (!form.hostId.trim()) errs.hostId = "Host ID is required";
    const amt = Number(form.amount);
    if (!form.amount || isNaN(amt) || amt < 1) {
      errs.amount = "Amount must be at least ₹1";
    }
    if (form.notes.length > 500) {
      errs.notes = "Notes cannot exceed 500 characters";
    }
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = () => {
    if (validate()) {
      onSubmit({
        hostId: Number(form.hostId),
        amount: Number(form.amount),
        payoutMethod: form.payoutMethod,
        note: form.notes,
      });
      setForm(INITIAL);
      setErrors({});
    }
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ fontWeight: 600, color: "#374151" }}>
        Initiate Manual Payout
      </DialogTitle>
      <DialogContent>
        <Stack spacing={3} mt={1}>
          <TextField
            label="Host ID"
            value={form.hostId}
            onChange={(e) =>
              setForm((p) => ({ ...p, hostId: e.target.value }))
            }
            error={!!errors.hostId}
            helperText={errors.hostId}
            fullWidth
            placeholder="Enter host ID"
          />

          <TextField
            label="Payout Amount (₹)"
            type="number"
            value={form.amount}
            onChange={(e) =>
              setForm((p) => ({ ...p, amount: e.target.value }))
            }
            error={!!errors.amount}
            helperText={errors.amount}
            fullWidth
            placeholder="Enter amount"
          />

          <TextField
            select
            label="Payout Method"
            value={form.payoutMethod}
            onChange={(e) =>
              setForm((p) => ({
                ...p,
                payoutMethod: e.target.value as PayoutMethod,
              }))
            }
            fullWidth
          >
            {METHOD_OPTIONS.map((o) => (
              <MenuItem key={o.value} value={o.value}>
                {o.label}
              </MenuItem>
            ))}
          </TextField>

          <TextField
            label="Notes (optional)"
            value={form.notes}
            onChange={(e) =>
              setForm((p) => ({ ...p, notes: e.target.value }))
            }
            error={!!errors.notes}
            helperText={errors.notes || `${form.notes.length}/500`}
            fullWidth
            multiline
            rows={3}
            placeholder="Reason for manual payout..."
          />
        </Stack>
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2 }}>
        <Button onClick={handleClose} sx={{ color: "#6b7280" }}>
          Cancel
        </Button>
        <Button
          variant="contained"
          onClick={handleSubmit}
          disabled={loading}
          sx={{ bgcolor: "#881f9b", "&:hover": { bgcolor: "#7115bd" } }}
        >
          {loading ? "Processing..." : "Initiate Payout"}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ManualPayoutModal;
