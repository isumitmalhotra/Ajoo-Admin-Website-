import { useEffect, useState } from "react";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import {
  fetchPayoutSchedules,
  createPayoutSchedule,
  updatePayoutSchedule,
  resetPayoutScheduleAction,
} from "../../../features/admin/finance/payoutScheduleList.slice";
import {
  Box,
  Paper,
  Typography,
  Stack,
  Chip,
  IconButton,
  Tooltip,
  Button,
} from "@mui/material";
import { Pagination } from "../../../components";
import { TableLoader } from "../../../components/admin/common/TableLoader";
import PayoutScheduleModal from "../../../components/admin/finance/PayoutScheduleModal";
import { useNotificationStore } from "../../../components/toast";
import type { PayoutSchedule } from "./types";
import { formatINR } from "./utils";
import { Settings, Plus } from "lucide-react";
import ExportButton from "../../../components/admin/finance/ExportButton";
import FinanceEmptyState from "../../../components/admin/finance/FinanceEmptyState";
import FinanceErrorAlert from "../../../components/admin/finance/FinanceErrorAlert";
import { MOCK_SCHEDULES } from "./mockData";

const USE_DEV_FINANCE_MOCKS =
  import.meta.env.DEV &&
  import.meta.env.VITE_USE_FINANCE_MOCKS === "true";

const PayoutSchedules = () => {
  const dispatch = useAppDispatch();
  const { addNotification } = useNotificationStore();
  const {
    data,
    loading,
    error,
    totalPages,
    currentPage,
    actionSuccess,
    actionLoading,
    actionError,
  } = useAppSelector((state) => state.payoutScheduleList);

  const [modalState, setModalState] = useState<{
    open: boolean;
    schedule: PayoutSchedule | null;
  }>({ open: false, schedule: null });

  useEffect(() => {
    dispatch(fetchPayoutSchedules({ page: 1, limit: 10 }));
  }, [dispatch]);

  useEffect(() => {
    if (actionSuccess) {
      addNotification({
        type: "success",
        title: modalState.schedule
          ? "Schedule updated successfully"
          : "Schedule created successfully",
      });
      dispatch(fetchPayoutSchedules({ page: 1, limit: 10 }));
      dispatch(resetPayoutScheduleAction());
      setModalState({ open: false, schedule: null });
    }
    if (actionError) {
      addNotification({ type: "error", title: actionError });
      dispatch(resetPayoutScheduleAction());
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [actionSuccess, actionError]);

  const handleSave = (formData: {
    hostId: string;
    frequency: string;
    minPayoutAmount: number;
    payoutMethod: string;
    isActive: boolean;
  }) => {
    if (modalState.schedule) {
      dispatch(
        updatePayoutSchedule({
          scheduleId: modalState.schedule.schedule_id,
          payload: {
            frequency: formData.frequency as PayoutSchedule["frequency"],
            minPayoutAmount: formData.minPayoutAmount,
            payoutMethod: formData.payoutMethod as PayoutSchedule["payout_method"],
            isActive: formData.isActive,
          },
        })
      );
    } else {
      dispatch(
        createPayoutSchedule({
          hostId: Number(formData.hostId),
          frequency: formData.frequency as PayoutSchedule["frequency"],
          minPayoutAmount: formData.minPayoutAmount,
          payoutMethod: formData.payoutMethod as PayoutSchedule["payout_method"],
        })
      );
    }
  };

  const rows =
    data && data.length > 0
      ? data
      : USE_DEV_FINANCE_MOCKS
      ? MOCK_SCHEDULES
      : [];

  return (
    <>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h5" fontWeight={600} color="#374151">
          Payout Schedules
        </Typography>
        <Button
          variant="contained"
          startIcon={<Plus size={16} />}
          onClick={() => setModalState({ open: true, schedule: null })}
          sx={{
            bgcolor: "#881f9b",
            textTransform: "none",
            "&:hover": { bgcolor: "#7115bd" },
          }}
        >
          Create Schedule
        </Button>
        <ExportButton
          headers={["Host", "Frequency", "Min Amount", "Method", "Next Payout", "Last Payout", "Active"]}
          rows={rows.map((s) => [
            s.host_name,
            s.frequency,
            s.min_payout_amount,
            s.payout_method,
            s.next_payout_date,
            s.last_payout_date || "—",
            s.is_active ? "Yes" : "No",
          ])}
          filename="payout-schedules"
        />
      </Stack>

      <Paper sx={{ p: 3, borderRadius: "0.75rem" }}>
        {loading ? (
          <TableLoader text="Loading schedules..." minHeight={300} />
        ) : error && !USE_DEV_FINANCE_MOCKS ? (
          <FinanceErrorAlert message={error} onRetry={() => dispatch(fetchPayoutSchedules({ page: 1, limit: 10 }))} />
        ) : rows.length === 0 ? (
          <FinanceEmptyState variant="payouts" message="No payout schedules configured yet." />
        ) : (
          <Box sx={{ overflowX: "auto" }}>
            <table style={{ width: "100%", borderCollapse: "collapse" }}>
              <thead>
                <tr>
                  {[
                    "Host",
                    "Frequency",
                    "Min Amount",
                    "Method",
                    "Next Payout",
                    "Last Payout",
                    "Active",
                    "",
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
                {rows.map((schedule) => (
                  <tr key={schedule.schedule_id}>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        fontWeight: 500,
                      }}
                    >
                      {schedule.host_name}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                      }}
                    >
                      <Chip
                        label={schedule.frequency}
                        size="small"
                        sx={{
                          bgcolor: "#f3e8ff",
                          color: "#7c3aed",
                          fontWeight: 500,
                          fontSize: "0.75rem",
                        }}
                      />
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                      }}
                    >
                      {formatINR(schedule.min_payout_amount)}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                      }}
                    >
                      {schedule.payout_method === "BANK_TRANSFER"
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
                      {new Date(schedule.next_payout_date).toLocaleDateString(
                        "en-IN",
                        { day: "2-digit", month: "short", year: "2-digit" }
                      )}
                    </td>
                    <td
                      style={{
                        padding: "10px 12px",
                        borderBottom: "1px solid #f3f4f6",
                        fontSize: "0.85rem",
                        whiteSpace: "nowrap",
                      }}
                    >
                      {schedule.last_payout_date
                        ? new Date(
                            schedule.last_payout_date
                          ).toLocaleDateString("en-IN", {
                            day: "2-digit",
                            month: "short",
                            year: "2-digit",
                          })
                        : "—"}
                    </td>
                    <td style={{ padding: "10px 12px", borderBottom: "1px solid #f3f4f6" }}>
                      <Chip
                        label={schedule.is_active ? "Active" : "Inactive"}
                        size="small"
                        color={schedule.is_active ? "success" : "default"}
                      />
                    </td>
                    <td style={{ padding: "10px 12px", borderBottom: "1px solid #f3f4f6" }}>
                      <Tooltip title="Edit Schedule">
                        <IconButton
                          size="small"
                          onClick={() =>
                            setModalState({ open: true, schedule })
                          }
                        >
                          <Settings size={16} />
                        </IconButton>
                      </Tooltip>
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
              dispatch(fetchPayoutSchedules({ page, limit: 10 }))
            }
          />
        )}
      </Paper>

      {/* ================= SCHEDULE MODAL ================= */}
      <PayoutScheduleModal
        open={modalState.open}
        schedule={modalState.schedule}
        loading={actionLoading}
        onSave={handleSave}
        onClose={() => setModalState({ open: false, schedule: null })}
      />
    </>
  );
};

export default PayoutSchedules;
