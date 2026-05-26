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
import { formatDateTimeIN, formatINR } from "../../../pages/admin/finance/utils";

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
        sx: {
          width: { xs: "100%", sm: 430 },
          p: 0,
          bgcolor: "#fcfcff",
        },
      }}
    >
      <Box
        sx={{
          px: 3,
          py: 2.5,
          borderBottom: "1px solid #ede9fe",
          background:
            "linear-gradient(165deg, rgba(139,92,246,0.14), rgba(168,85,247,0.05) 55%, rgba(255,255,255,1) 100%)",
        }}
      >
        <Stack direction="row" justifyContent="space-between" alignItems="center">
          <Box>
            <Typography variant="overline" sx={{ color: "#6b21a8", letterSpacing: 0.7 }}>
              Ledger entry
            </Typography>
            <Typography variant="h6" fontWeight={700} color="#111827">
              #{entry.ledger_id}
            </Typography>
          </Box>
          <IconButton onClick={onClose} size="small">
            <X size={20} />
          </IconButton>
        </Stack>

        <Box
          sx={{
            mt: 2,
            borderRadius: "0.85rem",
            p: 2.2,
            border: entry.entry_type === "CREDIT" ? "1px solid #bbf7d0" : "1px solid #fecaca",
            bgcolor: entry.entry_type === "CREDIT" ? "#f0fdf4" : "#fef2f2",
          }}
        >
          <Typography variant="caption" color="text.secondary">
            {entry.entry_type === "CREDIT" ? "Credit transaction" : "Debit transaction"}
          </Typography>
          <Typography
            variant="h4"
            fontWeight={800}
            color={entry.entry_type === "CREDIT" ? "#166534" : "#991b1b"}
            sx={{ lineHeight: 1.1 }}
          >
            {entry.entry_type === "CREDIT" ? "+" : "-"}
            {formatINR(entry.amount)}
          </Typography>
          <Typography variant="body2" color="text.secondary" mt={0.5}>
            Balance after: {formatINR(entry.balance_after)}
          </Typography>
        </Box>
      </Box>

      <Box sx={{ px: 3, py: 2.4 }}>
        <Divider sx={{ mb: 1 }} />

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
          <Typography variant="body2">{formatDateTimeIN(entry.created_at)}</Typography>
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
                    navigate(`/admin/finance/ledgers/host/${entry.host_id}`);
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
                    navigate(`/admin/finance/ledgers/guest/${entry.user_id}`);
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
      </Box>
    </Drawer>
  );
};

export default LedgerDetailDrawer;
