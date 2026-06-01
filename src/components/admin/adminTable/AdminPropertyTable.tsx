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
  export interface PropertyRow {
    property_name: string;
    property_price: string;
    is_verify: boolean;
    is_active: boolean;
  }
  
  /* ===== COLUMN TYPE ===== */
  type Column<T> = {
    key: keyof T;
    header: string;
    render?: (value: T[keyof T], row: T) => React.ReactNode;
  };
  
  /* ===== COLUMNS ===== */
  const columns: Column<PropertyRow>[] = [
    {
      key: "property_name",
      header: "Property Name",
    },
    {
      key: "property_price",
      header: "Price",
      render: (value) => (
        <Typography fontWeight={600}>
          ₹{Number(value).toLocaleString()}
        </Typography>
      ),
    },
    {
      key: "is_verify",
      header: "Verified",
      render: (value) => (
        <Chip
          label={value ? "Yes" : "No"}
          color={value ? "success" : "default"}
          size="small"
          sx={{ fontWeight: 500 }}
        />
      ),
    },
    {
      key: "is_active",
      header: "Status",
      render: (value) => (
        <Chip
          label={value ? "Active" : "Inactive"}
          color={value ? "success" : "error"}
          size="small"
          sx={{ fontWeight: 500 }}
        />
      ),
    },
  ];
  
  /* ===== PROPS ===== */
  type AdminPropertyTableProps = {
    rows: PropertyRow[];
  };
  
  export default function AdminPropertyTable({
    rows,
  }: AdminPropertyTableProps) {
    return (
      <Box sx={{ width: "100%" }}>
        <TableContainer>
          <Table
            stickyHeader
            sx={{
              width: "100%",
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