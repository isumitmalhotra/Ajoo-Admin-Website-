import React from "react";
import {
  Box,
  Chip,
  IconButton,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Tooltip,
  Typography,
} from "@mui/material";
import { Edit } from "@mui/icons-material";
import { BookingRow } from "./types";

interface BookingListTableProps {
  rows: BookingRow[];
  onView: (row: BookingRow) => void;
  onEdit?: (row: BookingRow) => void;
  onCancel?: (row: BookingRow) => void;
  onDelete?: (row: BookingRow) => void;
}

const THEME_COLOR = "#1B2447";
const paymentChipColor = (status: BookingRow["paymentStatus"]) =>
  status === "paid" ? "success" : "error";

const BookingListTable: React.FC<BookingListTableProps> = ({
  rows,
  onEdit
}) => {
  console.log(rows, "rows in table");
  return (
    <TableContainer
      component={Paper}
      sx={{
        borderRadius: "1rem",
        boxShadow: "0 12px 30px rgba(0,0,0,0.08)",
        overflow: "hidden",
      }}
    >
      <Table>
        {/* HEADER */}
        <TableHead>
          <TableRow sx={{ backgroundColor: "#f9f0fb" }}>
            {[
              "Booking ID",
              "User",
              "Property",
              "Check In",
              "Check Out",
              "Amount",
              "Booking Status",
              "Payment",
              "Created",
              "Actions",
            ].map((head) => (
              <TableCell
                key={head}
                align={head === "Actions" ? "center" : "left"}
                sx={{
                  fontWeight: 700,
                  color: THEME_COLOR,
                  whiteSpace: "nowrap",
                }}
              >
                {head}
              </TableCell>
            ))}
          </TableRow>
        </TableHead>

        {/* BODY */}
        <TableBody>
          {rows.length === 0 ? (
            <TableRow>
              <TableCell colSpan={10} align="center">
                <Typography color="text.secondary" py={3}>
                  No bookings found
                </Typography>
              </TableCell>
            </TableRow>
          ) : (
            rows.map((row) => (
              <TableRow key={row.id} hover>
                <TableCell>{row.id}</TableCell>
                <TableCell>{row.userName}</TableCell>

                <TableCell
                  sx={{
                    minWidth: 160,
                    maxWidth: 200,
                    fontWeight: 500,
                    whiteSpace: "nowrap",
                    overflow: "hidden",
                    textOverflow: "ellipsis",
                  }}
                >
                  {row.propertyName}
                </TableCell>

                <TableCell>{row.checkIn}</TableCell>
                <TableCell>{row.checkOut}</TableCell>

                <TableCell sx={{ fontWeight: 600 }}>₹{row.amount}</TableCell>

                {/* BOOKING STATUS */}
                <TableCell>
                  <Chip
                    label={row.bookingStatus}
                    size="small"
                    sx={{
                      backgroundColor: row.statusColor,
                      color: "#fff",
                      fontWeight: 600,
                      textTransform: "capitalize",
                    }}
                  />
                </TableCell>

                {/* PAYMENT STATUS */}
                <TableCell>
                  <Chip
                    label={row.paymentStatus}
                    size="small"
                    variant="outlined"
                    color={paymentChipColor(row.paymentStatus)}
                    sx={{ textTransform: "uppercase", fontWeight: 600 }}
                  />
                </TableCell>

                <TableCell>{row.createdAt}</TableCell>

                {/* ACTIONS */}
                <TableCell align="center">
                  <Box display="flex" justifyContent="center" gap={0.5}>
                    {onEdit && (
                      <Tooltip title="Edit">
                        <IconButton onClick={() => onEdit(row)}>
                          <Edit fontSize="small" />
                        </IconButton>
                      </Tooltip>
                    )}
                  </Box>
                </TableCell>
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>
    </TableContainer>
  );
};

export default BookingListTable;
