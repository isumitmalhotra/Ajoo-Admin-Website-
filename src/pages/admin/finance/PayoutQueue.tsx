import { useEffect, useState } from "react";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import { fetchPayoutList } from "../../../features/admin/finance/payoutList.slice";
import {
  approvePayout,
  rejectPayout,
  initiatePayout,
  resetPayoutAction,
} from "../../../features/admin/finance/payoutAction.slice";
import {
  Box,
  Paper,
  Typography,
  TextField,
  Stack,
  Tabs,
  Tab,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
} from "@mui/material";
import { Pagination } from "../../../components";
import { TableLoader } from "../../../components/admin/common/TableLoader";
import FinanceStatusChip from "../../../components/admin/finance/FinanceStatusChip";
import PayoutApprovalModal from "../../../components/admin/finance/PayoutApprovalModal";
import ManualPayoutModal from "../../../components/admin/finance/ManualPayoutModal";
import ExportButton from "../../../components/admin/finance/ExportButton";
import FinanceEmptyState from "../../../components/admin/finance/FinanceEmptyState";
import FinanceErrorAlert from "../../../components/admin/finance/FinanceErrorAlert";
import { useNotificationStore } from "../../../components/toast";
import type { PayoutStatus, Payout } from "./types";
import { formatINR } from "./utils";
import { Check, X, History, Plus } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { MOCK_PAYOUTS } from "./mockData";

const USE_DEV_FINANCE_MOCKS =
  import.meta.env.DEV &&
  import.meta.env.VITE_USE_FINANCE_MOCKS === "true";

const TAB_STATUS: (PayoutStatus | "")[] = [
  "",
  "QUEUED",
  "PROCESSING",
  "COMPLETED",
  "FAILED",
];
const TAB_LABELS = ["All", "Pending", "Processing", "Completed", "Failed"];

const PayoutQueue = () => {
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const { addNotification } = useNotificationStore();
  const { data, loading, error, totalPages, currentPage } = useAppSelector(
    (state) => state.payoutList
  );
  const payoutAction = useAppSelector((state) => state.payoutAction);

  const [activeTab, setActiveTab] = useState(0);
  const [approveDialog, setApproveDialog] = useState<{
    open: boolean;
    payout: Payout | null;
  }>({ open: false, payout: null });
  const [rejectDialog, setRejectDialog] = useState<{
    open: boolean;
    payoutId: number | null;
  }>({ open: false, payoutId: null });
  const [rejectReason, setRejectReason] = useState("");
  const [manualPayoutOpen, setManualPayoutOpen] = useState(false);

  const buildPayload = (page = 1) => ({
    page,
    limit: 10,
    ...(TAB_STATUS[activeTab] && { status: TAB_STATUS[activeTab] as PayoutStatus }),
  });

  useEffect(() => {
    dispatch(fetchPayoutList(buildPayload(1)));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dispatch, activeTab]);

  useEffect(() => {
    if (payoutAction.success) {
      addNotification({
        type: "success",
        title: approveDialog.payout
          ? "Payout approved successfully"
          : rejectDialog.payoutId
          ? "Payout rejected successfully"
          : "Manual payout initiated successfully",
      });
      dispatch(fetchPayoutList(buildPayload(1)));
      dispatch(resetPayoutAction());
      setApproveDialog({ open: false, payout: null });
      setRejectDialog({ open: false, payoutId: null });
      setRejectReason("");
      setManualPayoutOpen(false);
    }
    if (payoutAction.error) {
      addNotification({
        type: "error",
        title: payoutAction.error,
      });
      dispatch(resetPayoutAction());
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [payoutAction.success, payoutAction.error]);

  const handleApproveConfirm = () => {
    if (approveDialog.payout) {
      dispatch(approvePayout(approveDialog.payout.payout_id));
    }
  };

  const handleManualPayout = (data: {
    hostId: number;
    amount: number;
    note: string;
  }) => {
    dispatch(initiatePayout(data));
  };

  const handleRejectSubmit = () => {
    if (rejectDialog.payoutId && rejectReason.trim()) {
      dispatch(
        rejectPayout({
          payoutId: rejectDialog.payoutId,
          payload: { reason: rejectReason },
        })
      );
    }
  };

  const rows =
    data && data.length > 0
      ? data
      : USE_DEV_FINANCE_MOCKS
      ? MOCK_PAYOUTS
      : [];

  return (
    <>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h5" fontWeight={600} color="#374151">
          Payout Management
        </Typography>
        <Stack direction="row" spacing={1.5}>
          <Button
            variant="outlined"
            startIcon={<History size={16} />}
            onClick={() => navigate("/admin/finance/payouts/history")}
            sx={{
              borderColor: "#881f9b",
              color: "#881f9b",
              textTransform: "none",
              "&:hover": { borderColor: "#7115bd", bgcolor: "#faf5ff" },
            }}
          >
            Payout History
          </Button>
          <Button
            variant="contained"
            startIcon={<Plus size={16} />}
            onClick={() => setManualPayoutOpen(true)}
            sx={{
              bgcolor: "#881f9b",
              textTransform: "none",
              "&:hover": { bgcolor: "#7115bd" },
            }}
          >
            Manual Payout
          </Button>
          <ExportButton
            headers={["Host", "Period", "Amount", "Method", "Status", "Initiated", "Reference"]}
            rows={rows.map((p) => [
              p.host_name,
              `${new Date(p.period_start).toLocaleDateString("en-IN")} - ${new Date(p.period_end).toLocaleDateString("en-IN")}`,
              p.amount,
              p.payout_method,
              p.status,
              new Date(p.initiated_at).toLocaleDateString("en-IN"),
              p.reference_id,
            ])}
            filename="payout-queue"
          />
        </Stack>
      </Stack>

      {/* ================= TABS ================= */}
      <Paper sx={{ borderRadius: "0.75rem", mb: 3 }}>
        <Tabs
          value={activeTab}
          onChange={(_, v) => setActiveTab(v)}
          sx={{
            px: 2,
            "& .MuiTab-root": { textTransform: "none", fontWeight: 500 },
            "& .Mui-selected": { color: "#881f9b" },
            "& .MuiTabs-indicator": { backgroundColor: "#881f9b" },
          }}
        >
          {TAB_LABELS.map((label) => (
            <Tab key={label} label={label} />
          ))}
        </Tabs>
      </Paper>

      {/* ================= TABLE ================= */}
      <Paper sx={{ p: 3, borderRadius: "0.75rem" }}>
        {loading ? (
          <TableLoader text="Loading payouts..." minHeight={300} />
        ) : error && !USE_DEV_FINANCE_MOCKS ? (
          <FinanceErrorAlert message={error} onRetry={() => dispatch(fetchPayoutList({ page: 1, limit: 10 }))} />
        ) : rows.length === 0 ? (
          <FinanceEmptyState variant="payouts" message="No payouts found for this filter." />
        ) : (
          <Box sx={{ overflowX: "auto" }}>
            <table style={{ width: "100%", borderCollapse: "collapse" }}>
              <thead>
                <tr>
                  {[
                    "Host",
                    "Period",
                    "Amount",
                    "Method",
                    "Initiated",
                    "Status",
                    "Actions",
                  ].map((h) => (
                    <th
                      key={h}
                      style={{
                        textAlign: "left",
                        padding: "10px 12px",
                        borderBottom: "2px solid #e5e7eb",
                        fontSize: "0.8rem",
                        fontWeight: 600,
                        color: "#6b7280",
                        whiteSpace: "nowrap",
                      }}
                    >
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {rows.map((payout) => (
                  <tr key={payout.payout_id}>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        fontWeight: 500,
                      }}
                    >
                      {payout.host_name}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        whiteSpace: "nowrap",
                      }}
                    >
                      {new Date(payout.period_start).toLocaleDateString(
                        "en-IN",
                        { day: "2-digit", month: "short" }
                      )}{" "}
                      –{" "}
                      {new Date(payout.period_end).toLocaleDateString("en-IN", {
                        day: "2-digit",
                        month: "short",
                      })}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        fontWeight: 600,
                        color: "#374151",
                      }}
                    >
                      {formatINR(payout.amount)}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                      }}
                    >
                      {payout.payout_method === "BANK_TRANSFER"
                        ? "Bank"
                        : "UPI"}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        whiteSpace: "nowrap",
                      }}
                    >
                      {payout.initiated_by === "SYSTEM" ? "Auto" : "Manual"}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                      }}
                    >
                      <FinanceStatusChip status={payout.status} />
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                      }}
                    >
                      <Stack direction="row" spacing={0.5}>
                        {payout.status === "QUEUED" && (
                          <>
                            <Tooltip title="Approve">
                              <IconButton
                                size="small"
                                sx={{ color: "#16a34a" }}
                                onClick={() =>
                                  setApproveDialog({
                                    open: true,
                                    payout,
                                  })
                                }
                                disabled={payoutAction.loading}
                              >
                                <Check size={16} />
                              </IconButton>
                            </Tooltip>
                            <Tooltip title="Reject">
                              <IconButton
                                size="small"
                                sx={{ color: "#dc2626" }}
                                onClick={() =>
                                  setRejectDialog({
                                    open: true,
                                    payoutId: payout.payout_id,
                                  })
                                }
                                disabled={payoutAction.loading}
                              >
                                <X size={16} />
                              </IconButton>
                            </Tooltip>
                          </>
                        )}
                      </Stack>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Box>
        )}

        {totalPages > 1 && (
          <Pagination
            count={totalPages}
            page={currentPage}
            onChange={(_, page) =>
              dispatch(fetchPayoutList(buildPayload(page)))
            }
          />
        )}
      </Paper>

      {/* ================= REJECT DIALOG ================= */}
      <Dialog
        open={rejectDialog.open}
        onClose={() => setRejectDialog({ open: false, payoutId: null })}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle sx={{ fontWeight: 600, color: "#374151" }}>
          Reject Payout
        </DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" mb={2}>
            Please provide a reason for rejecting this payout.
          </Typography>
          <TextField
            fullWidth
            multiline
            rows={3}
            placeholder="Enter rejection reason..."
            value={rejectReason}
            onChange={(e) => setRejectReason(e.target.value)}
          />
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button
            onClick={() => setRejectDialog({ open: false, payoutId: null })}
            sx={{ color: "#6b7280" }}
          >
            Cancel
          </Button>
          <Button
            variant="contained"
            onClick={handleRejectSubmit}
            disabled={!rejectReason.trim() || payoutAction.loading}
            sx={{
              bgcolor: "#dc2626",
              "&:hover": { bgcolor: "#b91c1c" },
            }}
          >
            Reject
          </Button>
        </DialogActions>
      </Dialog>

      {/* ================= APPROVAL MODAL ================= */}
      <PayoutApprovalModal
        open={approveDialog.open}
        payout={approveDialog.payout}
        loading={payoutAction.loading}
        onConfirm={handleApproveConfirm}
        onClose={() => setApproveDialog({ open: false, payout: null })}
      />

      {/* ================= MANUAL PAYOUT MODAL ================= */}
      <ManualPayoutModal
        open={manualPayoutOpen}
        loading={payoutAction.loading}
        onSubmit={handleManualPayout}
        onClose={() => setManualPayoutOpen(false)}
      />
    </>
  );
};

export default PayoutQueue;
