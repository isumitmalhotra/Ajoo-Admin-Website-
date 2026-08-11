import React, { useEffect, useState } from "react";
import {
  Box,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  CircularProgress,
  useTheme,
  useMediaQuery,
} from "@mui/material";
import { getMyBookings } from "../../services/customerApi";

const themeColor = "#1B2447";

interface TxnRow {
  id: string;
  invoice: string;
  property: string;
  amount: number;
  date: string;
  status: string;
}

const statusColor = (status: string) => {
  const s = status.toLowerCase();
  if (s.includes("confirm") || s.includes("paid") || s.includes("checkout"))
    return "success";
  if (s.includes("pending")) return "warning";
  if (s.includes("cancel")) return "error";
  return "default";
};

const UserTransactions: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const [rows, setRows] = useState<TxnRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      setError(null);
      try {
        const bookings = await getMyBookings();
        if (cancelled) return;
        setRows(
          bookings.map((b: any) => ({
            id: String(b.book_id ?? b.book_pri_id ?? ""),
            invoice: b.book_invoice || "—",
            property:
              b["bookingProperty.property_name"] ||
              b.bookingProperty?.property_name ||
              "Property",
            amount: Number(b.book_price) || 0,
            date: b.book_added_at
              ? new Date(b.book_added_at).toLocaleDateString("en-IN")
              : "",
            status:
              b["bookingStatus.bs_title"] ||
              b.bookingStatus?.bs_title ||
              "—",
          }))
        );
      } catch {
        if (!cancelled)
          setError("Couldn't load your transactions. Please try again.");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const total = rows.reduce((sum, r) => sum + r.amount, 0);

  return (
    <Box sx={{ p: { xs: 1, sm: 2 } }}>
      <Typography
        variant="h5"
        sx={{
          fontWeight: 700,
          mb: 1,
          color: themeColor,
          fontFamily: "'Inter', sans-serif",
        }}
      >
        Transactions
      </Typography>
      <Typography sx={{ color: "#6B7390", fontSize: 14, mb: 3 }}>
        A record of your bookings and the amounts billed.
      </Typography>

      {loading && (
        <Box sx={{ display: "flex", justifyContent: "center", py: 6 }}>
          <CircularProgress sx={{ color: themeColor }} />
        </Box>
      )}

      {!loading && error && (
        <Typography sx={{ textAlign: "center", color: "#b00020", py: 4 }}>
          {error}
        </Typography>
      )}

      {!loading && !error && rows.length === 0 && (
        <Typography sx={{ textAlign: "center", color: "#6B7390", py: 6 }}>
          You have no transactions yet.
        </Typography>
      )}

      {!loading && !error && rows.length > 0 && (
        <>
          <TableContainer
            component={Paper}
            sx={{ borderRadius: 3, boxShadow: "0 4px 16px rgba(0,0,0,0.06)" }}
          >
            <Table size={isMobile ? "small" : "medium"}>
              <TableHead>
                <TableRow sx={{ bgcolor: "#FFFAF0" }}>
                  <TableCell sx={{ fontWeight: 700, color: themeColor }}>
                    Invoice
                  </TableCell>
                  <TableCell sx={{ fontWeight: 700, color: themeColor }}>
                    Property
                  </TableCell>
                  {!isMobile && (
                    <TableCell sx={{ fontWeight: 700, color: themeColor }}>
                      Date
                    </TableCell>
                  )}
                  <TableCell sx={{ fontWeight: 700, color: themeColor }}>
                    Amount
                  </TableCell>
                  <TableCell sx={{ fontWeight: 700, color: themeColor }}>
                    Status
                  </TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {rows.map((r) => (
                  <TableRow key={r.id} hover>
                    <TableCell sx={{ fontFamily: "monospace" }}>
                      {r.invoice}
                    </TableCell>
                    <TableCell>{r.property}</TableCell>
                    {!isMobile && <TableCell>{r.date}</TableCell>}
                    <TableCell sx={{ fontWeight: 600 }}>
                      ₹ {r.amount.toLocaleString("en-IN")}
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={r.status}
                        size="small"
                        color={statusColor(r.status) as any}
                        sx={{ fontWeight: 600 }}
                      />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>

          <Box
            sx={{
              mt: 2,
              display: "flex",
              justifyContent: "flex-end",
              gap: 1,
              pr: 1,
            }}
          >
            <Typography sx={{ color: "#6B7390", fontWeight: 500 }}>
              Total billed:
            </Typography>
            <Typography sx={{ color: themeColor, fontWeight: 700 }}>
              ₹ {total.toLocaleString("en-IN")}
            </Typography>
          </Box>
        </>
      )}
    </Box>
  );
};

export default UserTransactions;
