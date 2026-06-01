import { useState, useEffect } from "react";
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  MenuItem,
  Stack,
  Switch,
  Typography,
  InputAdornment,
} from "@mui/material";
import type {
  PayoutFrequency,
  PayoutMethod,
  PayoutSchedule,
} from "../../../pages/admin/finance/types";
import { CalendarClock } from "lucide-react";

const FREQUENCY_OPTIONS: { value: PayoutFrequency; label: string }[] = [
  { value: "DAILY", label: "Daily" },
  { value: "WEEKLY", label: "Weekly" },
  { value: "BIWEEKLY", label: "Bi-Weekly" },
  { value: "MONTHLY", label: "Monthly" },
];

const METHOD_OPTIONS: { value: PayoutMethod; label: string }[] = [
  { value: "BANK_TRANSFER", label: "Bank Transfer" },
  { value: "UPI", label: "UPI" },
];

interface FormState {
  hostId: string;
  frequency: PayoutFrequency;
  minPayoutAmount: number;
  payoutMethod: PayoutMethod;
  isActive: boolean;
}

interface Props {
  open: boolean;
  schedule: PayoutSchedule | null; // null = create mode, filled = edit mode
  loading: boolean;
  onSave: (data: FormState) => void;
  onClose: () => void;
}

const INITIAL_FORM: FormState = {
  hostId: "",
  frequency: "WEEKLY",
  minPayoutAmount: 500,
  payoutMethod: "BANK_TRANSFER",
  isActive: true,
};

const PayoutScheduleModal = ({
  open,
  schedule,
  loading,
  onSave,
  onClose,
}: Props) => {
  const isEdit = !!schedule;
  const [form, setForm] = useState<FormState>(INITIAL_FORM);
  const [errors, setErrors] = useState<Partial<Record<keyof FormState, string>>>({});

  useEffect(() => {
    if (schedule) {
      setForm({
        hostId: String(schedule.host_id),
        frequency: schedule.frequency,
        minPayoutAmount: schedule.min_payout_amount,
        payoutMethod: schedule.payout_method,
        isActive: schedule.is_active,
      });
    } else {
      setForm(INITIAL_FORM);
    }
    setErrors({});
  }, [schedule, open]);

  const validate = (): boolean => {
    const errs: Partial<Record<keyof FormState, string>> = {};
    if (!isEdit && !form.hostId.trim()) {
      errs.hostId = "Host ID is required";
    }
    if (form.minPayoutAmount < 1) {
      errs.minPayoutAmount = "Minimum payout must be at least ₹1";
    }
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = () => {
    if (validate()) {
      onSave(form);
    }
  };

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="sm"
      fullWidth
      PaperProps={{
        sx: {
          borderRadius: "1rem",
          border: "1px solid #ede9fe",
          overflow: "hidden",
        },
      }}
    >
      <DialogTitle
        sx={{
          fontWeight: 700,
          color: "#6b21a8",
          display: "flex",
          alignItems: "center",
          gap: 1,
          bgcolor: "#faf5ff",
        }}
      >
        <CalendarClock size={18} />
        {isEdit
          ? `Edit Schedule — ${schedule?.host_name}`
          : "Create Payout Schedule"}
      </DialogTitle>
      <DialogContent>
        <Typography variant="body2" color="text.secondary" mt={1}>
          Configure when and how host payouts should be generated.
        </Typography>
        <Stack spacing={3} mt={1}>
          {!isEdit && (
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
          )}

          <TextField
            select
            label="Frequency"
            value={form.frequency}
            onChange={(e) =>
              setForm((p) => ({
                ...p,
                frequency: e.target.value as PayoutFrequency,
              }))
            }
            fullWidth
          >
            {FREQUENCY_OPTIONS.map((o) => (
              <MenuItem key={o.value} value={o.value}>
                {o.label}
              </MenuItem>
            ))}
          </TextField>

          <TextField
            label="Minimum Payout Amount (₹)"
            type="number"
            value={form.minPayoutAmount}
            onChange={(e) =>
              setForm((p) => ({
                ...p,
                minPayoutAmount: Number(e.target.value),
              }))
            }
            error={!!errors.minPayoutAmount}
            helperText={errors.minPayoutAmount}
            fullWidth
            slotProps={{
              input: {
                startAdornment: <InputAdornment position="start">₹</InputAdornment>,
              },
            }}
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

          <Stack direction="row" alignItems="center" spacing={2}>
            <Typography fontWeight={600}>Auto payout active</Typography>
            <Switch
              checked={form.isActive}
              onChange={(e) =>
                setForm((p) => ({ ...p, isActive: e.target.checked }))
              }
            />
          </Stack>
        </Stack>
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2 }}>
        <Button onClick={onClose} sx={{ color: "#6b7280" }}>
          Cancel
        </Button>
        <Button
          variant="contained"
          onClick={handleSubmit}
          disabled={loading}
          sx={{
            bgcolor: "#1B2447",
            textTransform: "none",
            fontWeight: 700,
            px: 2,
            "&:hover": { bgcolor: "#7115bd" },
          }}
        >
          {loading
            ? "Saving..."
            : isEdit
            ? "Save Changes"
            : "Create Schedule"}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default PayoutScheduleModal;
