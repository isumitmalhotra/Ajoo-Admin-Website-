import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import {
  fetchInvoiceDetail,
  voidInvoice,
  resetInvoiceDetail,
} from "../../../features/admin/finance/invoiceDetail.slice";
import {
  Box,
  Paper,
  Typography,
  Stack,
  Chip,
  Divider,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
} from "@mui/material";
import { TableLoader } from "../../../components/admin/common/TableLoader";
import FinanceStatusChip from "../../../components/admin/finance/FinanceStatusChip";
import { formatINR } from "./utils";
import { ArrowLeft, Download, Ban } from "lucide-react";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import { useNotificationStore } from "../../../components/toast";
import FinanceEmptyState from "../../../components/admin/finance/FinanceEmptyState";
import FinanceErrorAlert from "../../../components/admin/finance/FinanceErrorAlert";
import { MOCK_INVOICES } from "./mockData";

const USE_DEV_FINANCE_MOCKS =
  import.meta.env.DEV &&
  import.meta.env.VITE_USE_FINANCE_MOCKS === "true";

const typeColors: Record<string, { bg: string; color: string; label: string }> = {
  BOOKING_RECEIPT: { bg: "#dbeafe", color: "#1d4ed8", label: "Booking Receipt" },
  HOST_COMMISSION: { bg: "#f3e8ff", color: "#7c3aed", label: "Host Commission" },
  PAYOUT_STATEMENT: { bg: "#dcfce7", color: "#16a34a", label: "Payout Statement" },
};

const DetailRow = ({ label, value, mono }: { label: string; value: string; mono?: boolean }) => (
  <Stack direction="row" justifyContent="space-between" py={1}>
    <Typography variant="body2" color="text.secondary">
      {label}
    </Typography>
    <Typography
      variant="body2"
      fontWeight={500}
      sx={mono ? { fontFamily: "monospace" } : undefined}
    >
      {value}
    </Typography>
  </Stack>
);

const InvoiceDetail = () => {
  const { invoiceId } = useParams<{ invoiceId: string }>();
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const { addNotification } = useNotificationStore();

  const { data: apiInvoice, loading, error } = useAppSelector(
    (state) => state.invoiceDetail
  );

  const [voidDialog, setVoidDialog] = useState(false);
  const [voidReason, setVoidReason] = useState("");
  const [voidError, setVoidError] = useState("");
  const [voidLoading, setVoidLoading] = useState(false);
  const [downloading, setDownloading] = useState(false);

  const numericId = Number(invoiceId);

  useEffect(() => {
    if (numericId) {
      dispatch(fetchInvoiceDetail(numericId));
    }
    return () => {
      dispatch(resetInvoiceDetail());
    };
  }, [dispatch, numericId]);

  const invoice =
    apiInvoice ??
    (USE_DEV_FINANCE_MOCKS
      ? MOCK_INVOICES.find((x) => x.invoice_id === numericId) || MOCK_INVOICES[0]
      : null);

  // ────────── PDF DOWNLOAD ──────────
  const handleDownload = async () => {
    if (!invoice) return;
    setDownloading(true);
    try {
      const res = await api.get(
        `${ADMINENDPOINTS.FINANCE_INVOICE_DOWNLOAD}/${invoice.invoice_id}`,
        { responseType: "blob" }
      );
      const url = window.URL.createObjectURL(new Blob([res.data]));
      const link = document.createElement("a");
      link.href = url;
      link.setAttribute("download", `${invoice.invoice_number}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);
      addNotification({ type: "success", title: "Invoice PDF downloaded" });
    } catch {
      addNotification({
        type: "error",
        title: "PDF download failed — backend may not be available yet",
      });
    } finally {
      setDownloading(false);
    }
  };

  // ────────── VOID INVOICE ──────────
  const handleVoid = async () => {
    if (!voidReason.trim()) {
      setVoidError("Please provide a reason for voiding this invoice");
      return;
    }
    if (!invoice) return;
    setVoidLoading(true);
    try {
      await dispatch(
        voidInvoice({ invoiceId: invoice.invoice_id, reason: voidReason.trim() })
      ).unwrap();
      addNotification({ type: "success", title: "Invoice voided successfully" });
      setVoidDialog(false);
      setVoidReason("");
    } catch {
      addNotification({ type: "error", title: "Failed to void invoice" });
    } finally {
      setVoidLoading(false);
    }
  };

  if (loading) {
    return <TableLoader text="Loading invoice..." minHeight={400} />;
  }

  if (error && !USE_DEV_FINANCE_MOCKS) {
    return <FinanceErrorAlert message={error} onRetry={() => { if (invoiceId) dispatch(fetchInvoiceDetail(Number(invoiceId))); }} />;
  }

  if (!invoice) {
    return <FinanceEmptyState variant="invoices" message="Invoice not found." minHeight={200} />;
  }

  const tc = typeColors[invoice.invoice_type] ?? {
    bg: "#f3f4f6",
    color: "#374151",
    label: invoice.invoice_type,
  };
  const isVoidable = invoice.status !== "VOID";

  return (
    <>
      {/* ================= HEADER ================= */}
      <Stack direction="row" alignItems="center" spacing={2} mb={3}>
        <IconButton
          onClick={() => navigate("/admin/finance/invoices")}
          size="small"
        >
          <ArrowLeft size={20} />
        </IconButton>
        <Box sx={{ flex: 1 }}>
          <Typography variant="h5" fontWeight={600} color="#374151">
            {invoice.invoice_number}
          </Typography>
          <Stack direction="row" spacing={1} mt={0.5}>
            <Chip
              label={tc.label}
              size="small"
              sx={{ bgcolor: tc.bg, color: tc.color, fontWeight: 500, fontSize: "0.7rem" }}
            />
            <FinanceStatusChip status={invoice.status} />
          </Stack>
        </Box>

        {/* Action buttons */}
        <Stack direction="row" spacing={1}>
          <Button
            variant="outlined"
            startIcon={<Download size={16} />}
            onClick={handleDownload}
            disabled={downloading}
            sx={{
              borderColor: "#881f9b",
              color: "#881f9b",
              "&:hover": { borderColor: "#7115bd", bgcolor: "#faf0fc" },
            }}
          >
            {downloading ? "Downloading..." : "Download PDF"}
          </Button>
          {isVoidable && (
            <Button
              variant="outlined"
              color="error"
              startIcon={<Ban size={16} />}
              onClick={() => setVoidDialog(true)}
            >
              Void Invoice
            </Button>
          )}
        </Stack>
      </Stack>

      {/* ================= INVOICE CARD ================= */}
      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: { xs: "1fr", md: "1fr 1fr" },
          gap: 3,
        }}
      >
        {/* Left — Amount summary */}
        <Paper sx={{ p: 3, borderRadius: "0.75rem" }}>
          <Typography variant="subtitle2" color="text.secondary" mb={2}>
            Amount Summary
          </Typography>

          <Box
            sx={{
              bgcolor: "#f0fdf4",
              borderRadius: "0.75rem",
              p: 2.5,
              mb: 2,
              textAlign: "center",
            }}
          >
            <Typography variant="body2" color="text.secondary">
              Total Amount
            </Typography>
            <Typography variant="h3" fontWeight={700} color="#15803d">
              {formatINR(invoice.total)}
            </Typography>
          </Box>

          <DetailRow
            label="Subtotal"
            value={formatINR(invoice.subtotal)}
          />
          <DetailRow
            label={`Tax (${invoice.tax_rate}%)`}
            value={formatINR(invoice.tax_amount)}
          />
          <Divider sx={{ my: 1 }} />
          <DetailRow
            label="Grand Total"
            value={formatINR(invoice.total)}
          />
        </Paper>

        {/* Right — Invoice details */}
        <Paper sx={{ p: 3, borderRadius: "0.75rem" }}>
          <Typography variant="subtitle2" color="text.secondary" mb={2}>
            Invoice Details
          </Typography>

          <DetailRow label="Invoice Number" value={invoice.invoice_number} mono />
          {invoice.booking_id > 0 && (
            <DetailRow label="Booking ID" value={`#${invoice.booking_id}`} />
          )}
          <DetailRow
            label="Date"
            value={new Date(invoice.created_at).toLocaleDateString("en-IN", {
              day: "2-digit",
              month: "long",
              year: "numeric",
            })}
          />
          <Divider sx={{ my: 1 }} />
          {invoice.host_name && (
            <DetailRow label="Host" value={invoice.host_name} />
          )}
          {invoice.user_name && (
            <DetailRow label="Guest" value={invoice.user_name} />
          )}
          {invoice.property_name && (
            <DetailRow label="Property" value={invoice.property_name} />
          )}
          <Divider sx={{ my: 1 }} />
          {invoice.hsn_sac_code && (
            <DetailRow label="HSN/SAC Code" value={invoice.hsn_sac_code} mono />
          )}
          {invoice.gstin && (
            <DetailRow label="GSTIN" value={invoice.gstin} mono />
          )}
        </Paper>
      </Box>

      {/* ================= VOID DIALOG ================= */}
      <Dialog
        open={voidDialog}
        onClose={() => setVoidDialog(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle sx={{ fontWeight: 600, color: "#374151" }}>
          Void Invoice
        </DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" mb={2}>
            Voiding invoice <strong>{invoice.invoice_number}</strong> ({formatINR(invoice.total)}). This action cannot be
            undone.
          </Typography>
          <TextField
            fullWidth
            multiline
            rows={3}
            size="small"
            label="Reason for Voiding"
            placeholder="e.g., Duplicate invoice, booking cancelled..."
            value={voidReason}
            onChange={(e) => {
              setVoidReason(e.target.value);
              if (voidError) setVoidError("");
            }}
            error={!!voidError}
            helperText={voidError || `${voidReason.length}/300`}
            inputProps={{ maxLength: 300 }}
          />
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setVoidDialog(false)} disabled={voidLoading}>
            Cancel
          </Button>
          <Button
            variant="contained"
            color="error"
            onClick={handleVoid}
            disabled={voidLoading}
          >
            {voidLoading ? "Voiding..." : "Void Invoice"}
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
};

export default InvoiceDetail;
