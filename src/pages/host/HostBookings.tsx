import { useEffect } from "react";
import {
  Alert,
  Box,
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  MenuItem,
  Paper,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import { useAppDispatch, useAppSelector } from "../../app/hooks";
import {
  fetchHostBookings,
  type HostBooking,
  resetHostBookingsFilters,
  setHostBookingsFilters,
} from "../../features/host/hostBookings.slice";
import { Pagination } from "../../components";
import { useState } from "react";
import api from "../../services/api";
import { ADMINENDPOINTS } from "../../services/endpoints";

const statusChipColor = (
  status: string
): "success" | "warning" | "error" | "info" | "default" => {
  const normalized = status.toLowerCase();
  if (normalized === "completed") return "success";
  if (normalized === "confirmed") return "info";
  if (normalized === "pending") return "warning";
  if (normalized === "cancelled") return "error";
  return "default";
};

const statusLabel = (status?: string) => {
  if (!status) return "Unknown";
  return status
    .toLowerCase()
    .replace(/_/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());
};

const csvEscape = (value: unknown) => {
  const text = String(value ?? "");
  const needsQuote = text.includes(",") || text.includes("\"") || text.includes("\n");
  const escaped = text.replace(/\"/g, "\"\"");
  return needsQuote ? `"${escaped}"` : escaped;
};

const buildBookingsCsv = (rows: HostBooking[]) => {
  const headers = [
    "booking_id",
    "property_name",
    "guest_name",
    "check_in",
    "check_out",
    "amount",
    "status",
    "created_at",
  ];

  const csvRows = rows.map((booking) => [
    booking.booking_id,
    booking.property_name || "",
    booking.guest_name || "",
    booking.check_in || "",
    booking.check_out || "",
    booking.amount ?? 0,
    booking.status || "",
    booking.created_at || "",
  ]);

  return [headers, ...csvRows]
    .map((row) => row.map((cell) => csvEscape(cell)).join(","))
    .join("\n");
};

const triggerDownload = (blob: Blob, filename: string) => {
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
};

export default function HostBookings() {
  const dispatch = useAppDispatch();
  const { data, loading, error, totalPages, currentPage, filters } = useAppSelector(
    (state) => state.hostBookings
  );
  const [selectedBooking, setSelectedBooking] = useState<HostBooking | null>(null);
  const [exporting, setExporting] = useState(false);

  const loadPage = (page: number) => {
    dispatch(
      fetchHostBookings({
        page,
        limit: 10,
        search: filters.search,
        status: filters.status,
        dateFrom: filters.dateFrom,
        dateTo: filters.dateTo,
      })
    );
  };

  useEffect(() => {
    loadPage(1);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dispatch]);

  const handleFilter = () => {
    loadPage(1);
  };

  const handleReset = () => {
    dispatch(resetHostBookingsFilters());
    setTimeout(() => loadPage(1), 0);
  };

  const handleExportCsv = async () => {
    if (data.length === 0 && !filters.search && !filters.status && !filters.dateFrom && !filters.dateTo) {
      return;
    }

    setExporting(true);

    const defaultName = `host-bookings-${new Date().toISOString().slice(0, 10)}.csv`;

    try {
      const res = await api.post(
        ADMINENDPOINTS.HOST_PORTAL_BOOKINGS_EXPORT,
        {
          search: filters.search,
          status: filters.status,
          dateFrom: filters.dateFrom,
          dateTo: filters.dateTo,
          exportAll: true,
        },
        {
          responseType: "blob",
        }
      );

      const contentType = String(res.headers?.["content-type"] || "").toLowerCase();
      const contentDisposition = String(res.headers?.["content-disposition"] || "");
      const filenameMatch = contentDisposition.match(/filename\*?=(?:UTF-8''|\")?([^\";]+)/i);
      const serverFileName = filenameMatch?.[1]?.replace(/['\"]/g, "");

      if (contentType.includes("application/json")) {
        const jsonText = await res.data.text();
        const parsed = JSON.parse(jsonText || "{}");

        const fileUrl =
          parsed?.data?.fileUrl ||
          parsed?.data?.url ||
          parsed?.fileUrl ||
          parsed?.url ||
          "";

        const serverRows: HostBooking[] =
          parsed?.data?.rows || parsed?.data?.data || parsed?.rows || parsed?.data || [];

        if (typeof fileUrl === "string" && fileUrl) {
          window.open(fileUrl, "_blank", "noopener,noreferrer");
          return;
        }

        if (Array.isArray(serverRows) && serverRows.length > 0) {
          const csv = buildBookingsCsv(serverRows);
          triggerDownload(new Blob([csv], { type: "text/csv;charset=utf-8;" }), defaultName);
          return;
        }

        throw new Error("Server export response did not contain file or rows.");
      }

      triggerDownload(res.data, serverFileName || defaultName);
      return;
    } catch {
      // Fallback: export currently loaded rows when server export is unavailable.
      if (data.length > 0) {
        const csv = buildBookingsCsv(data);
        triggerDownload(
          new Blob([csv], { type: "text/csv;charset=utf-8;" }),
          `host-bookings-page-${currentPage}-${new Date().toISOString().slice(0, 10)}.csv`
        );
      }
    } finally {
      setExporting(false);
    }
  };

  return (
    <Paper sx={{ p: 3, borderRadius: 2 }} elevation={0}>
      <Stack
        direction={{ xs: "column", sm: "row" }}
        spacing={1}
        alignItems={{ xs: "flex-start", sm: "center" }}
        justifyContent="space-between"
      >
        <Box>
          <Typography variant="h6" fontWeight={700}>
            Host Bookings
          </Typography>
          <Typography variant="caption" color="text.secondary">
            Showing page {currentPage} of {Math.max(totalPages, 1)}
          </Typography>
        </Box>
        <Button
          variant="outlined"
          onClick={handleExportCsv}
          disabled={exporting || (data.length === 0 && !filters.search && !filters.status && !filters.dateFrom && !filters.dateTo)}
        >
          {exporting ? "Exporting..." : "Export CSV"}
        </Button>
      </Stack>

      <Stack direction={{ xs: "column", md: "row" }} spacing={1.5} mt={2}>
        <TextField
          size="small"
          label="Search"
          value={filters.search}
          onChange={(e) =>
            dispatch(setHostBookingsFilters({ search: e.target.value }))
          }
          sx={{ minWidth: 220 }}
        />

        <TextField
          size="small"
          select
          label="Status"
          value={filters.status}
          onChange={(e) =>
            dispatch(setHostBookingsFilters({ status: e.target.value }))
          }
          sx={{ minWidth: 160 }}
        >
          <MenuItem value="">All</MenuItem>
          <MenuItem value="PENDING">Pending</MenuItem>
          <MenuItem value="CONFIRMED">Confirmed</MenuItem>
          <MenuItem value="COMPLETED">Completed</MenuItem>
          <MenuItem value="CANCELLED">Cancelled</MenuItem>
        </TextField>

        <TextField
          size="small"
          type="date"
          label="From"
          value={filters.dateFrom}
          onChange={(e) =>
            dispatch(setHostBookingsFilters({ dateFrom: e.target.value }))
          }
          slotProps={{ inputLabel: { shrink: true } }}
        />

        <TextField
          size="small"
          type="date"
          label="To"
          value={filters.dateTo}
          onChange={(e) =>
            dispatch(setHostBookingsFilters({ dateTo: e.target.value }))
          }
          slotProps={{ inputLabel: { shrink: true } }}
        />

        <Button variant="contained" onClick={handleFilter} sx={{ bgcolor: "#881f9b" }}>
          Apply
        </Button>
        <Button variant="outlined" onClick={handleReset}>
          Reset
        </Button>
      </Stack>

      {error && (
        <Alert sx={{ mt: 2 }} severity="warning">
          {error}
        </Alert>
      )}

      {loading ? (
        <Typography variant="body2" color="text.secondary" mt={1}>
          Loading host bookings...
        </Typography>
      ) : data.length === 0 ? (
        <Typography variant="body2" color="text.secondary" mt={1}>
          No bookings found for this host account.
        </Typography>
      ) : (
        <Box sx={{ mt: 2, overflowX: "auto" }}>
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr>
                {["Booking", "Property", "Guest", "Check-in", "Check-out", "Amount", "Status", ""].map(
                  (head) => (
                    <th
                      key={head}
                      style={{
                        textAlign: "left",
                        padding: "10px",
                        borderBottom: "1px solid #e5e7eb",
                        color: "#6b7280",
                        fontSize: "0.8rem",
                      }}
                    >
                      {head}
                    </th>
                  )
                )}
              </tr>
            </thead>
            <tbody>
              {data.map((booking) => (
                <tr key={booking.booking_id}>
                  <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                    #{booking.booking_id}
                  </td>
                  <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                    {booking.property_name || "-"}
                  </td>
                  <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                    {booking.guest_name || "-"}
                  </td>
                  <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                    {booking.check_in ? new Date(booking.check_in).toLocaleDateString() : "-"}
                  </td>
                  <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                    {booking.check_out ? new Date(booking.check_out).toLocaleDateString() : "-"}
                  </td>
                  <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                    INR {booking.amount ?? 0}
                  </td>
                  <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                    <Chip
                      size="small"
                      label={statusLabel(booking.status)}
                      color={statusChipColor(booking.status || "")}
                      variant="outlined"
                    />
                  </td>
                  <td style={{ padding: "10px", borderBottom: "1px solid #f3f4f6" }}>
                    <Button
                      size="small"
                      variant="outlined"
                      onClick={() => setSelectedBooking(booking)}
                    >
                      View
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Box>
      )}

      <Box sx={{ mt: 2, display: "flex", justifyContent: "center" }}>
        <Pagination
          count={Math.max(totalPages, 1)}
          page={Math.max(currentPage, 1)}
          onChange={(_, page) => loadPage(page)}
        />
      </Box>

      <Dialog
        open={Boolean(selectedBooking)}
        onClose={() => setSelectedBooking(null)}
        fullWidth
        maxWidth="sm"
      >
        <DialogTitle>Booking Detail</DialogTitle>
        <DialogContent dividers>
          {selectedBooking && (
            <Stack spacing={1.2}>
              <Typography><strong>ID:</strong> #{selectedBooking.booking_id}</Typography>
              <Typography><strong>Property:</strong> {selectedBooking.property_name || "-"}</Typography>
              <Typography><strong>Guest:</strong> {selectedBooking.guest_name || "-"}</Typography>
              <Stack direction="row" alignItems="center" spacing={1}>
                <Typography><strong>Status:</strong></Typography>
                <Chip
                  size="small"
                  label={statusLabel(selectedBooking.status)}
                  color={statusChipColor(selectedBooking.status || "")}
                  variant="outlined"
                />
              </Stack>
              <Typography>
                <strong>Check-in:</strong> {selectedBooking.check_in ? new Date(selectedBooking.check_in).toLocaleDateString() : "-"}
              </Typography>
              <Typography>
                <strong>Check-out:</strong> {selectedBooking.check_out ? new Date(selectedBooking.check_out).toLocaleDateString() : "-"}
              </Typography>
              <Typography><strong>Amount:</strong> INR {selectedBooking.amount ?? 0}</Typography>
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSelectedBooking(null)}>Close</Button>
        </DialogActions>
      </Dialog>
    </Paper>
  );
}
