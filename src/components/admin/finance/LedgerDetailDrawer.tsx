import {
  Drawer,
  Box,
  Typography,
  Stack,
  IconButton,
  Divider,
  Chip,
} from "@mui/material";
import { X, ExternalLink } from "lucide-react";
import type { LedgerEntry } from "../../../pages/admin/finance/types";
import TransactionTypeChip from "./TransactionTypeChip";
import FinanceStatusChip from "./FinanceStatusChip";
import { useNavigate } from "react-router-dom";

interface LedgerDetailDrawerProps {
  open: boolean;
  entry: LedgerEntry | null;
  onClose: () => void;
}

const DetailRow = ({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) => (
  <Stack
    direction="row"
    justifyContent="space-between"
    alignItems="center"
    sx={{ py: 1.5, borderBottom: "1px solid #f3f4f6" }}
  >
    <Typography variant="body2" color="text.secondary" fontWeight={500}>
      {label}
    </Typography>
    <Box sx={{ textAlign: "right" }}>{children}</Box>
  </Stack>
);

const LedgerDetailDrawer = ({
  open,
  entry,
  onClose,
}: LedgerDetailDrawerProps) => {
  const navigate = useNavigate();

  if (!entry) return null;

  return (
    <Drawer
      anchor="right"
      open={open}
      onClose={onClose}
      PaperProps={{
        sx: { width: { xs: "100%", sm: 420 }, p: 3 },
      }}
    >
      {/* Header */}
      <Stack
        direction="row"
        justifyContent="space-between"
        alignItems="center"
        mb={2}
      >
        <Typography variant="h6" fontWeight={600} color="#374151">
          Ledger Entry #{entry.ledger_id}
        </Typography>
        <IconButton onClick={onClose} size="small">
          <X size={20} />
        </IconButton>
      </Stack>

      <Divider sx={{ mb: 2 }} />

      {/* Amount highlight */}
      <Box
        sx={{
          bgcolor:
            entry.entry_type === "CREDIT" ? "#f0fdf4" : "#fef2f2",
          borderRadius: "0.75rem",
          p: 3,
          textAlign: "center",
          mb: 3,
        }}
      >
        <Typography variant="caption" color="text.secondary">
          {entry.entry_type === "CREDIT" ? "Credit" : "Debit"}
        </Typography>
        <Typography
          variant="h3"
          fontWeight={700}
          color={entry.entry_type === "CREDIT" ? "#16a34a" : "#dc2626"}
        >
          {entry.entry_type === "CREDIT" ? "+" : "-"}₹
          {entry.amount.toLocaleString("en-IN")}
        </Typography>
        <Typography variant="body2" color="text.secondary" mt={0.5}>
          Balance after: ₹{entry.balance_after.toLocaleString("en-IN")}
        </Typography>
      </Box>

      {/* Detail rows */}
      <DetailRow label="Type">
        <TransactionTypeChip type={entry.transaction_type} />
      </DetailRow>

      <DetailRow label="Status">
        <FinanceStatusChip status={entry.status} />
      </DetailRow>

      <DetailRow label="Description">
        <Typography variant="body2" sx={{ maxWidth: 220 }}>
          {entry.description}
        </Typography>
      </DetailRow>

      <DetailRow label="Reference">
        <Chip
          label={entry.reference_id || "—"}
          size="small"
          sx={{
            fontFamily: "monospace",
            fontSize: "0.75rem",
            bgcolor: "#f3f4f6",
          }}
        />
      </DetailRow>

      <DetailRow label="Date">
        <Typography variant="body2">
          {new Date(entry.created_at).toLocaleString("en-IN", {
            day: "2-digit",
            month: "short",
            year: "numeric",
            hour: "2-digit",
            minute: "2-digit",
          })}
        </Typography>
      </DetailRow>

      {entry.host_name && (
        <DetailRow label="Host">
          <Stack direction="row" alignItems="center" spacing={1}>
            <Typography variant="body2" fontWeight={500}>
              {entry.host_name}
            </Typography>
            {entry.host_id && (
              <IconButton
                size="small"
                onClick={() => {
                  onClose();
                  navigate(
                    `/admin/finance/ledgers/host/${entry.host_id}`
                  );
                }}
              >
                <ExternalLink size={14} color="#881f9b" />
              </IconButton>
            )}
          </Stack>
        </DetailRow>
      )}

      {entry.user_name && (
        <DetailRow label="Guest">
          <Stack direction="row" alignItems="center" spacing={1}>
            <Typography variant="body2" fontWeight={500}>
              {entry.user_name}
            </Typography>
            {entry.user_id && (
              <IconButton
                size="small"
                onClick={() => {
                  onClose();
                  navigate(
                    `/admin/finance/ledgers/guest/${entry.user_id}`
                  );
                }}
              >
                <ExternalLink size={14} color="#881f9b" />
              </IconButton>
            )}
          </Stack>
        </DetailRow>
      )}

      {entry.property_name && (
        <DetailRow label="Property">
          <Typography variant="body2">{entry.property_name}</Typography>
        </DetailRow>
      )}

      {entry.booking_id && (
        <DetailRow label="Booking">
          <Chip
            label={`#${entry.booking_id}`}
            size="small"
            onClick={() => {
              onClose();
              navigate(`/admin/bookings`);
            }}
            sx={{
              cursor: "pointer",
              color: "#881f9b",
              borderColor: "#881f9b",
            }}
            variant="outlined"
          />
        </DetailRow>
      )}
    </Drawer>
  );
};

export default LedgerDetailDrawer;
