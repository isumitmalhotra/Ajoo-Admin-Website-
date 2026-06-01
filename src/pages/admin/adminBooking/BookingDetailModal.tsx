import React, { useState, useEffect } from "react";
import Modal from "react-modal";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import { fetchBookingStatus } from "../../../features/admin/Bookings/bookingStatus.slice";
import { fetchBookingList } from "../../../features/admin/Bookings/fetchBooking.slice";
import { updateBookingStatus } from "../../../features/admin/Bookings/updateBookingStatus.slice";
import { setMessage } from "../../../features/ui/ui.slice";
import Grow from "@mui/material/Grow";
import { TableLoader } from "../../../components/admin/common/TableLoader";

import {
  Box,
  Typography,
  MenuItem,
  Button,
  IconButton,
  Divider,
  Select,
  Paper,
  Chip,
  FormControl,
  InputLabel,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import { BookingDetail } from "./types";

const BRAND = "#1B2447";

interface Props {
  open: boolean;
  onClose: () => void;
  onSubmit: (status: string) => void;
  booking: BookingDetail | null;
  loading?: boolean;
  isEdit?: boolean;
}

Modal.setAppElement("#root");

/* ---------------- UI HELPERS ---------------- */

const Section = ({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) => (
  <Paper
    elevation={0}
    sx={{
      p: 2.5,
      mb: 2.5,
      borderRadius: "14px",
      backgroundColor: "#fafafa",
    }}
  >
    <Typography
      fontWeight={700}
      fontSize={14}
      mb={1.5}
      color={BRAND}
      letterSpacing={0.3}
    >
      {title}
    </Typography>
    <Divider sx={{ mb: 1.5 }} />
    {children}
  </Paper>
);

const Row = ({ label, value }: { label: string; value?: React.ReactNode }) => (
  <Box display="flex" justifyContent="space-between" py={0.75}>
    <Typography fontSize={13} color="text.secondary">
      {label}
    </Typography>
    <Typography fontSize={14} fontWeight={600}>
      {value || "-"}
    </Typography>
  </Box>
);

/* ---------------- COMPONENT ---------------- */

const BookingDetailModal = ({
  open,
  onClose,
  booking,
  loading = false,
  isEdit = false,
}: Props) => {
  const [status, setStatus] = useState("");

  const dispatch = useAppDispatch();

  const { data: statusList } = useAppSelector(
    (state) => state.bookingStatus
  );

  const { loading: updateLoading } = useAppSelector(
    (state) => state.updateBookingStatus
  );
  const handleUpdate = async () => {
    if (!booking || !status) return;

    const res = await dispatch(
      updateBookingStatus({
        bookingId: booking.id,
        statusId: Number(status),
      })
    );

    if (updateBookingStatus.fulfilled.match(res)) {
      /* ✅ SUCCESS TOAST */
      dispatch(
        setMessage({
          message: "Booking status updated successfully",
          severity: "success",
        })
      );

      /* ✅ CLOSE MODAL */
      onClose();

      /* ✅ REFRESH BOOKING LIST */
      dispatch(fetchBookingList({ page: 1, limit: 10 }));
    }

    if (updateBookingStatus.rejected.match(res)) {
      /* ❌ ERROR TOAST */
      dispatch(
        setMessage({
          message: res.payload as string,
          severity: "error",
        })
      );
    }
  };
  useEffect(() => {
    if (open) {
      dispatch(fetchBookingStatus());
    }
  }, [open, dispatch]);

  console.log(statusList, ":statusList");
  return (
    <Modal
      isOpen={open}
      onRequestClose={onClose}
      overlayClassName="booking-modal-overlay"
      className="booking-modal-content"
    >
      {/* ================= HEADER ================= */}
      <Box
        sx={{
          p: 3,
          borderBottom: "1px solid #eee",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          background: `linear-gradient(135deg, ${BRAND}15, #fff)`,
        }}
      >
        <Box>
          <Typography fontSize={20} fontWeight={800}>
            Booking Details
          </Typography>
          {booking && !loading && (
            <Typography fontSize={13} color="text.secondary">
              ID: {booking.id}
            </Typography>
          )}
        </Box>

        <Box display="flex" gap={2} alignItems="center">
          {booking && !loading && (
            <Chip
              label={booking.status.title}
              sx={{
                backgroundColor: booking.status.color,
                color: "#fff",
                fontWeight: 700,
                px: 1.5,
              }}
            />
          )}
          <IconButton onClick={onClose}>
            <CloseIcon />
          </IconButton>
        </Box>
      </Box>

      {/* ================= BODY ================= */}
      <Box sx={{ p: 3, minHeight: 360 }}>
        {loading && (
          <TableLoader text="Loading booking details..." minHeight={300} />
        )}

        {!loading && booking && (
          <Box sx={{ maxHeight: "65vh", overflowY: "auto", pr: 1 }}>
            <Section title="Booking Info">
              <Row label="Created At" value={booking.createdAt} />
              <Row label="Check In" value={booking.dates.checkIn} />
              <Row label="Check Out" value={booking.dates.checkOut} />
            </Section>

            <Section title="User Details">
              <Row label="Name" value={booking.user.name} />
              <Row label="Phone" value={booking.user.phone} />
              <Row label="Email" value={booking.user.email} />
            </Section>

            <Section title="Property Details">
              <Row label="Property" value={booking.property.name} />
              <Row label="Contact" value={booking.property.contact} />
              <Row label="Email" value={booking.property.email} />
            </Section>

            <Section title="Host Details">
              <Row label="Name" value={booking.host.name} />
              <Row label="Phone" value={booking.host.phone} />
              <Row label="Email" value={booking.host.email} />
            </Section>

            <Section title="Payment Summary">
              <Row label="Base Price" value={`₹${booking.pricing.price}`} />
              <Row label="Tax" value={`₹${booking.pricing.tax}`} />
              <Row label="Total Amount" value={`₹${booking.pricing.total}`} />
              <Row
                label="Payment Status"
                value={booking.pricing.isPaid ? "Paid" : "Unpaid"}
              />
              <Row
                label="Payment Mode"
                value={booking.pricing.isCOD ? "Cash on Delivery" : "Online"}
              />
            </Section>

            <Section title="Booking History">
              {booking.history.length === 0 && (
                <Typography fontSize={13} color="text.secondary">
                  No history available
                </Typography>
              )}

              {booking.history.map((h, i) => (
                <Box key={i} mb={1.5}>
                  <Typography fontWeight={700}>{h.title}</Typography>
                  <Typography fontSize={13} color="text.secondary">
                    {h.description}
                  </Typography>
                </Box>
              ))}
            </Section>
          </Box>
        )}
      </Box>

      {/* ================= FOOTER ================= */}
      <Box
        sx={{
          p: 3,
          borderTop: "1px solid #eee",
          backgroundColor: "#fafafa",
        }}
      >
        {/* const BRAND = "#1B2447"; */}
        <FormControl
          fullWidth
          size="small"
          sx={{
            mb: 2,
            "& .MuiInputLabel-root": {
              color: BRAND,
            },
            "& .MuiInputLabel-root.Mui-focused": {
              color: BRAND,
            },
            "& .MuiOutlinedInput-root": {
              "& fieldset": { borderColor: BRAND },
              "&:hover fieldset": { borderColor: BRAND },
              "&.Mui-focused fieldset": { borderColor: BRAND },
            },
          }}
        >
          <InputLabel>Update Status</InputLabel>

          <Select
            label="Update Status"
            value={status}
            onChange={(e) => setStatus(e.target.value)}
            disabled={!isEdit || loading || !booking}
            MenuProps={{
              disablePortal: true,
              TransitionComponent: Grow,
              TransitionProps: { timeout: 200 },
              PaperProps: {
                sx: { borderRadius: 2 },
              },
            }}
          >
            {statusList.map((s) => (
              <MenuItem key={s.bs_id} value={s.bs_id}>
                <Box display="flex" alignItems="center" gap={1}>
                  {s.bs_code && (
                    <Box
                      sx={{
                        width: 10,
                        height: 10,
                        borderRadius: "50%",
                        bgcolor: s.bs_code,
                      }}
                    />
                  )}
                  {s.bs_title}
                </Box>
              </MenuItem>
            ))}
          </Select>
        </FormControl>

        <Box display="flex" justifyContent="flex-end" gap={2}>
          <Button
            variant="outlined"
            onClick={onClose}
            sx={{
              borderColor: BRAND,
              color: BRAND,
              "&:hover": { borderColor: BRAND, backgroundColor: `${BRAND}10` },
            }}
          >
            Close
          </Button>

          {isEdit && (
            <Button
              variant="contained"
              disabled={updateLoading}
              onClick={handleUpdate}
              sx={{
                backgroundColor: BRAND,
                "&:hover": { backgroundColor: BRAND },
              }}
            >
              {updateLoading ? "Updating..." : "Update Status"}
            </Button>
          )}
        </Box>
      </Box>
    </Modal>
  );
};

export default BookingDetailModal;
