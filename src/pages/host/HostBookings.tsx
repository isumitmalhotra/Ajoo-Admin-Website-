import { useEffect, useMemo } from "react";
import {
  Alert,
  AlertTitle,
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
  type HostBookingsFilters,
  resetHostBookingsFilters,
  setHostBookingsFilters,
} from "../../features/host/hostBookings.slice";
import { Pagination } from "../../components";
import { useState } from "react";
import api from "../../services/api";
import { ADMINENDPOINTS } from "../../services/endpoints";
import { useSearchParams } from "react-router-dom";
import { API_BASE_URL } from "../../configs/apiConfigs";

type SortBy = "created_at" | "check_in" | "amount" | "status";
type SortOrder = "asc" | "desc";

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
  const [searchParams, setSearchParams] = useSearchParams();
  const [selectedBooking, setSelectedBooking] = useState<HostBooking | null>(null);
  const [exporting, setExporting] = useState(false);
  const [pageSize, setPageSize] = useState(10);
  const [sortBy, setSortBy] = useState<SortBy>("created_at");
  const [sortOrder, setSortOrder] = useState<SortOrder>("desc");

  const isConnectivityIssue =
    Boolean(error) && /unable to reach|network|failed to fetch|connect/i.test(error || "");

  const updateUrlState = (
    page: number,
    currentFilters: HostBookingsFilters,
    currentPageSize: number,
    currentSortBy: SortBy,
    currentSortOrder: SortOrder
  ) => {
    const nextParams = new URLSearchParams();
    nextParams.set("page", String(page));
    nextParams.set("limit", String(currentPageSize));
    nextParams.set("sortBy", currentSortBy);
    nextParams.set("sortOrder", currentSortOrder);

    if (currentFilters.search) nextParams.set("search", currentFilters.search);
    if (currentFilters.status) nextParams.set("status", currentFilters.status);
    if (currentFilters.dateFrom) nextParams.set("dateFrom", currentFilters.dateFrom);
    if (currentFilters.dateTo) nextParams.set("dateTo", currentFilters.dateTo);

    setSearchParams(nextParams, { replace: true });
  };

  const loadPage = (
    page: number,
    options?: {
      nextFilters?: HostBookingsFilters;
      nextPageSize?: number;
      nextSortBy?: SortBy;
      nextSortOrder?: SortOrder;
    }
  ) => {
    const resolvedFilters = options?.nextFilters || filters;
    const resolvedPageSize = options?.nextPageSize || pageSize;
    const resolvedSortBy = options?.nextSortBy || sortBy;
    const resolvedSortOrder = options?.nextSortOrder || sortOrder;

    dispatch(
      fetchHostBookings({
        page,
        limit: resolvedPageSize,
        search: resolvedFilters.search,
        status: resolvedFilters.status,
        dateFrom: resolvedFilters.dateFrom,
        dateTo: resolvedFilters.dateTo,
        sortBy: resolvedSortBy,
        sortOrder: resolvedSortOrder,
      })
    );

    updateUrlState(
      page,
      resolvedFilters,
      resolvedPageSize,
      resolvedSortBy,
      resolvedSortOrder
    );
  };

  useEffect(() => {
    const initialPage = Math.max(Number(searchParams.get("page") || 1), 1);
    const initialPageSize = Math.max(Number(searchParams.get("limit") || 10), 1);
    const initialSortBy = (searchParams.get("sortBy") || "created_at") as SortBy;
    const initialSortOrder = (searchParams.get("sortOrder") || "desc") as SortOrder;

    const initialFilters: HostBookingsFilters = {
      search: searchParams.get("search") || "",
      status: searchParams.get("status") || "",
      dateFrom: searchParams.get("dateFrom") || "",
      dateTo: searchParams.get("dateTo") || "",
    };

    setPageSize(initialPageSize);
    setSortBy(initialSortBy);
    setSortOrder(initialSortOrder);
    dispatch(setHostBookingsFilters(initialFilters));

    dispatch(
      fetchHostBookings({
        page: initialPage,
        limit: initialPageSize,
        search: initialFilters.search,
        status: initialFilters.status,
        dateFrom: initialFilters.dateFrom,
        dateTo: initialFilters.dateTo,
        sortBy: initialSortBy,
        sortOrder: initialSortOrder,
      })
    );

    updateUrlState(
      initialPage,
      initialFilters,
      initialPageSize,
      initialSortBy,
      initialSortOrder
    );
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dispatch]);

  const sortedData = useMemo(() => {
    const rows = [...data];
    rows.sort((a, b) => {
      let left: string | number = "";
      let right: string | number = "";

      if (sortBy === "amount") {
        left = Number(a.amount || 0);
        right = Number(b.amount || 0);
      } else if (sortBy === "status") {
        left = (a.status || "").toLowerCase();
        right = (b.status || "").toLowerCase();
      } else {
        const leftDate = a[sortBy] ? new Date(String(a[sortBy])).getTime() : 0;
        const rightDate = b[sortBy] ? new Date(String(b[sortBy])).getTime() : 0;
        left = leftDate;
        right = rightDate;
      }

      if (left < right) return sortOrder === "asc" ? -1 : 1;
      if (left > right) return sortOrder === "asc" ? 1 : -1;
      return 0;
    });

    return rows;
  }, [data, sortBy, sortOrder]);

  const handleFilter = () => {
    loadPage(1);
  };

  const handleReset = () => {
    const clearedFilters: HostBookingsFilters = {
      search: "",
      status: "",
      dateFrom: "",
      dateTo: "",
    };
    dispatch(resetHostBookingsFilters());
    loadPage(1, { nextFilters: clearedFilters });
  };

  const handleRetry = () => {
    loadPage(Math.max(currentPage, 1));
  };

  const handlePageSizeChange = (value: number) => {
    setPageSize(value);
    loadPage(1, { nextPageSize: value });
  };

  const handleSortByChange = (value: SortBy) => {
    setSortBy(value);
    loadPage(1, { nextSortBy: value });
  };

  const handleSortOrderChange = (value: SortOrder) => {
    setSortOrder(value);
    loadPage(1, { nextSortOrder: value });
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
          select
          label="Sort By"
          value={sortBy}
          onChange={(e) => handleSortByChange(e.target.value as SortBy)}
          sx={{ minWidth: 150 }}
        >
          <MenuItem value="created_at">Created At</MenuItem>
          <MenuItem value="check_in">Check-in</MenuItem>
          <MenuItem value="amount">Amount</MenuItem>
          <MenuItem value="status">Status</MenuItem>
        </TextField>

        <TextField
          size="small"
          select
          label="Order"
          value={sortOrder}
          onChange={(e) => handleSortOrderChange(e.target.value as SortOrder)}
          sx={{ minWidth: 120 }}
        >
          <MenuItem value="desc">Desc</MenuItem>
          <MenuItem value="asc">Asc</MenuItem>
        </TextField>

        <TextField
          size="small"
          select
          label="Page Size"
          value={String(pageSize)}
          onChange={(e) => handlePageSizeChange(Number(e.target.value))}
          sx={{ minWidth: 130 }}
        >
          <MenuItem value="10">10</MenuItem>
          <MenuItem value="25">25</MenuItem>
          <MenuItem value="50">50</MenuItem>
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
        <Alert
          sx={{ mt: 2 }}
          severity="warning"
          action={
            <Button color="inherit" size="small" onClick={handleRetry}>
              Retry
            </Button>
          }
        >
          <AlertTitle>Host bookings data unavailable</AlertTitle>
          <Typography variant="body2">{error}</Typography>
          {isConnectivityIssue && (
            <Typography variant="caption" sx={{ display: "block", mt: 0.5 }}>
              Check backend availability and API base URL: {API_BASE_URL}
            </Typography>
          )}
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
              {sortedData.map((booking) => (
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
