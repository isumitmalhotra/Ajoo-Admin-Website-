import {
    Box,
    Chip,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Typography,
  } from "@mui/material";
  
  /* ===== API ROW TYPE ===== */
  export interface BookingRow {
    book_id: string;
    book_total_amt: number;
    book_is_paid: 0 | 1;
    book_status: number;
    "bookingStatus.bs_title": string;
    "bookingStatus.bs_code": string;
  }
  
  /* ===== COLUMN TYPE (same pattern as User table) ===== */
  type Column<T> = {
    key: keyof T;
    header: string;
    render?: (value: T[keyof T], row: T) => React.ReactNode;
  };
  
  /* ===== COLUMNS ===== */
  const columns: Column<BookingRow>[] = [
    {
      key: "book_id",
      header: "Booking ID",
    },
    {
      key: "book_total_amt",
      header: "Amount",
      render: (value) => (
        <Typography fontWeight={600}>
          ₹{Number(value).toLocaleString()}
        </Typography>
      ),
    },
    {
      key: "book_is_paid",
      header: "Payment",
      render: (value) => (
        <Chip
          label={value === 1 ? "Paid" : "Unpaid"}
          color={value === 1 ? "success" : "warning"}
          size="small"
          sx={{ fontWeight: 500 }}
        />
      ),
    },
    {
      key: "bookingStatus.bs_title",
      header: "Status",
      render: (_, row) => (
        <Chip
          label={row["bookingStatus.bs_title"]}
          size="small"
          sx={{
            fontWeight: 500,
            backgroundColor: row["bookingStatus.bs_code"],
            color: "#fff",
          }}
        />
      ),
    },
  ];
  
  /* ===== PROPS ===== */
  type AdminBookingTableProps = {
    rows: BookingRow[];
  };
  
  export default function AdminBookingTable({ rows }: AdminBookingTableProps) {
    return (
      <Box sx={{ width: "100%" }}>
        <TableContainer>
          <Table
            stickyHeader
            sx={{
              borderCollapse: "separate",
              borderSpacing: "0 8px",
              fontFamily: "'Inter', system-ui, sans-serif",
            }}
          >
            {/* ===== HEADER ===== */}
            <TableHead>
              <TableRow>
                {columns.map((col) => (
                  <TableCell
                    key={String(col.key)}
                    sx={{
                      fontWeight: 600,
                      color: "#374151",
                      backgroundColor: "#f9fafb",
                      borderBottom: "none",
                    }}
                  >
                    {col.header}
                  </TableCell>
                ))}
              </TableRow>
            </TableHead>
  
            {/* ===== BODY ===== */}
            <TableBody>
              {rows.map((row, rowIndex) => (
                <TableRow
                  key={rowIndex}
                  sx={{
                    backgroundColor: "#ffffff",
                    boxShadow: "0 4px 12px rgba(0,0,0,0.06)",
                    transition: "all 0.2s ease",
                    "&:hover": {
                      backgroundColor: "#f9fafb",
                      transform: "translateY(-2px)",
                    },
                  }}
                >
                  {columns.map((col) => {
                    const value = row[col.key];
  
                    return (
                      <TableCell key={String(col.key)}>
                        {col.render ? (
                          col.render(value, row)
                        ) : (
                          <Typography fontWeight={500}>
                            {String(value)}
                          </Typography>
                        )}
                      </TableCell>
                    );
                  })}
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </Box>
    );
  }