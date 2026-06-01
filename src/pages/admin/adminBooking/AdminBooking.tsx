// AdminBooking.tsx

import { useEffect, useMemo, useState } from "react";
import { Box, Paper, Pagination } from "@mui/material";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import { fetchBookingList } from "../../../features/admin/Bookings/fetchBooking.slice";
import { fetchBookingDetail } from "../../../features/admin/Bookings/bookingDetail.slice";
import { fetchBookingStatus } from "../../../features/admin/Bookings/bookingStatus.slice";
import { TableLoader } from "../../../components/admin/common/TableLoader";

import AdminBookingHeader from "./AdminBookingHeader";
import BookingListTable from "./BookingListTable";
import BookingDetailModal from "./BookingDetailModal";
import { BookingRow } from "./types";

const AdminBooking = () => {
  const dispatch = useAppDispatch();

  const [filters, setFilters] = useState({
    keyword: "",
    bookingStatus: "",
    paymentStatus: "",
    fromDate: null as Date | null,
    toDate: null as Date | null,
    limit: 10,
  });

  const { data, loading, totalPages, currentPage } = useAppSelector(
    (state) => state.bookingList
  );

  /* 🔁 Load status list once */
  useEffect(() => {
    dispatch(fetchBookingStatus());
    dispatch(fetchBookingList({ page: 1, limit: 10 }));
  }, [dispatch]);

  const { data: statusList, loading: statusLoading } = useAppSelector(
    (state) => state.bookingStatus
  );

  /* 🧠 SINGLE SOURCE OF TRUTH */
  const buildPayload = (page = 1) => ({
    page,
    limit: filters.limit,
    ...(filters.keyword && { search: filters.keyword }),
    ...(filters.bookingStatus && {
      status: Number(filters.bookingStatus),
    }),
    ...(filters.paymentStatus && {
      paymentStatus: filters.paymentStatus === "paid" ? 1 : 0,
    }),
    ...(filters.fromDate && { fromDate: filters.fromDate }),
    ...(filters.toDate && { toDate: filters.toDate }),
  });

  const handleFilterUpdate = (key: string, value: any) => {
    setFilters((prev) => ({ ...prev, [key]: value }));
  };

  const handleSearch = () => {
    dispatch(fetchBookingList(buildPayload(1)));
  };

  const handleClear = () => {
    setFilters({
      keyword: "",
      bookingStatus: "",
      paymentStatus: "",
      fromDate: null,
      toDate: null,
      limit: 10,
    });
    dispatch(fetchBookingList({ page: 1, limit: 10 }));
  };

  const rows: BookingRow[] = useMemo(
    () =>
      data.map((b) => ({
        id: b.book_id,
        userName: b.userDetails.user_fullName,
        propertyName: b.bookingProperty.property_name,
        checkIn: b.bookDetails.bt_book_checkIn ?? "-",
        checkOut: b.bookDetails.bt_book_checkout ?? "-",
        amount: Number(b.book_total_amt),
        bookingStatus: b.bookingStatus.bs_title,
        statusColor: b.bookingStatus.bs_code,
        paymentStatus: b.book_is_paid === 1 ? "paid" : "unpaid",
        createdAt: new Date(b.book_added_at).toLocaleDateString("en-IN"),
      })),
    [data]
  );

  const [detailOpen, setDetailOpen] = useState(false);
  const [isEdit, setIsEdit] = useState(false);
  const [selectedBookingId, setSelectedBookingId] = useState<string | null>(null);

  const { data: bookingDetail, loading: detailLoading } = useAppSelector(
    (state) => state.bookingDetail
  );

  useEffect(() => {
    if (detailOpen && selectedBookingId) {
      dispatch(fetchBookingDetail(selectedBookingId));
    }
  }, [detailOpen, selectedBookingId, dispatch]);

  return (
    <Box>
      <AdminBookingHeader
        ThemeColors={{ primary: "#1B2447" }}
        filterData={filters}
        handleFilterUpdate={handleFilterUpdate}
        handleFilter={handleSearch}
        handleClear={handleClear}
        handleFormShow={() => {}}
        statusList={statusList}
        statusLoading={statusLoading}
      />

      <Paper sx={{ p: 3, borderRadius: "1rem" }}>
        {loading ? (
          <TableLoader text="Loading bookings..." minHeight={260} />
        ) : (
          <BookingListTable
            rows={rows}
            onView={(row) => {
              setSelectedBookingId(row.id);
              setIsEdit(false);
              setDetailOpen(true);
            }}
            onEdit={(row) => {
              setSelectedBookingId(row.id);
              setIsEdit(true);
              setDetailOpen(true);
            }}
            onCancel={(row) => console.log("Cancel", row)}
          />
        )}

        {totalPages > 1 && (
          <Box display="flex" justifyContent="center" pt={3}>
            <Pagination
              count={totalPages}
              page={currentPage}
              onChange={(_, page) =>
                dispatch(fetchBookingList(buildPayload(page)))
              }
            />
          </Box>
        )}
      </Paper>

      <BookingDetailModal
        open={detailOpen}
        booking={bookingDetail}
        loading={detailLoading}
        isEdit={isEdit}
        onClose={() => setDetailOpen(false)}
        onSubmit={() => setDetailOpen(false)}
      />
    </Box>
  );
};

export default AdminBooking;
