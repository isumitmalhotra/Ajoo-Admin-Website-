import {
  Box,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Typography,
  Switch,
  Tooltip,
  IconButton,
  Chip,
} from "@mui/material";

import { Edit as EditIcon, Delete as DeleteIcon } from "@mui/icons-material";
import { Pagination } from "../../../components";
import { Brand } from "../../../theme/themeColor";
import type { ListingProps, PropertyRecord } from "../properties/types";
import { Link } from "react-router-dom";
import { TableLoader } from "../../../components/admin/common/TableLoader";

export default function VerificationListing({
  ThemeColors,
  properties,
  totalRecords,
  loading,
  handlePaginate,
  page,
  rowsPerPage,
  handleToggleActive,
  handleDeleteClick,
}: ListingProps) {
  const headers = [
    "SR. NO.",
    "NAME",
    "HOST NAME",
    "CATEGORIES",
    "STATUS",
    "VERIFICATION STATUS",
    "ACTIONS",
  ];

  return (
    <Paper
      elevation={0}
      sx={{
        borderRadius: 3,
        overflow: "hidden",
        boxShadow: "0 4px 12px rgba(0,0,0,0.05)",
      }}
    >
      <TableContainer>
        <Table>
          <TableHead sx={{ backgroundColor: "#f9fafb" }}>
            <TableRow>
              {headers.map((header) => (
                <TableCell
                  key={header}
                  sx={{
                    fontWeight: 600,
                    color: ThemeColors.text.secondary,
                    fontSize: "0.85rem",
                  }}
                >
                  {header}
                </TableCell>
              ))}
            </TableRow>
          </TableHead>

          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={6} align="center">
                  <TableLoader text="Fetching properties..." />
                </TableCell>
              </TableRow>
            ) : properties?.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} align="center">
                  <Typography
                    variant="body2"
                    sx={{ color: ThemeColors.text.secondary }}
                  >
                    No records found.
                  </Typography>
                </TableCell>
              </TableRow>
            ) : (
              properties &&
              properties.length > 0 &&
              properties.map((property: PropertyRecord, index: number) => (
                <TableRow
                  key={property.property_id}
                  hover
                  sx={{
                    transition: "all 0.3s ease",
                    "&:hover": { backgroundColor: "#f5f3ff" },
                    fontSize: "0.8rem",
                  }}
                >
                  <TableCell>{(page - 1) * rowsPerPage + index + 1}</TableCell>

                  <TableCell sx={{ fontSize: "0.85rem" }}>
                    {property.property_name}
                  </TableCell>
                  <TableCell sx={{ fontSize: "0.85rem" }}>
                    {property["HostDetails.user_fullName"]}
                  </TableCell>
                  <TableCell sx={{ fontSize: "0.85rem" }}>
                    {property.categories.join(", ")}
                  </TableCell>

                  <TableCell>
                    <Switch
                      size="small"
                      checked={property.is_active === true}
                      onChange={() =>
                        handleToggleActive(Number(property.property_id))
                      }
                      sx={{
                        "& .MuiSwitch-switchBase.Mui-checked": {
                          color: Brand.indigo,
                        },
                        "& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track":
                          {
                            backgroundColor: Brand.indigo,
                          },
                        transition: "all 0.3s ease",
                      }}
                    />
                  </TableCell>

                  <TableCell>
                    {property.is_verify === "Rejected" ? (
                      <Chip
                        label="Rejected"
                        size="small"
                        sx={{
                          backgroundColor: "#fee2e2", // light red
                          color: "#b91c1c",
                          fontWeight: 500,
                        }}
                      />
                    ) : (
                      <Chip
                        label="Pending"
                        size="small"
                        sx={{
                          backgroundColor: "#fef9c3", // light yellow
                          color: "#a16207",
                          fontWeight: 500,
                        }}
                      />
                    )}
                  </TableCell>

                  <TableCell>
                    <Tooltip title="Edit Property">
                      <IconButton
                        component={Link}
                        to={`/admin/properties/form/${property.property_id}`}
                        state={{ from: "/admin/property-verification" }}
                        size="small"
                        sx={{
                          color: ThemeColors.secondary,
                          mr: 1,
                          transition: "all 0.3s ease",
                          "&:hover": { transform: "scale(1.1)" },
                        }}
                      >
                        <EditIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>

                    <Tooltip title="Delete Property">
                      <IconButton
                        size="small"
                        sx={{
                          color: "error.main",
                          transition: "all 0.3s ease",
                          "&:hover": { transform: "scale(1.1)" },
                        }}
                        onClick={() => handleDeleteClick(property.property_id)}
                      >
                        <DeleteIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Pagination */}
      {properties?.length > 0 && (
        <Box display="flex" justifyContent="center" alignItems="center" p={2}>
          <Pagination
            count={Math.ceil(totalRecords / rowsPerPage)}
            page={page}
            onChange={handlePaginate}
          />
        </Box>
      )}
    </Paper>
  );
}
