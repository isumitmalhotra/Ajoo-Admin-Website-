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
} from "@mui/material";

import { Edit as EditIcon, Delete as DeleteIcon } from "@mui/icons-material";
import { Pagination } from "../../../components";
import { Brand } from "../../../theme/themeColor";
import AppSnackbarContainer from "../../../components/admin/common/AppSnackbarContainer";

import type { CategoryRecord, ListingProps } from './types';
import { TableLoader } from "../../../components/admin/common/TableLoader";

export default function Listing({
  ThemeColors,
  categories,
  loading,
  totalRecords,
  handleFormShow,
  handlePaginate,
  page,
  rowsPerPage,
  handleToggleActive,
  handleDeleteClick,
}: ListingProps) {

  return (
    <>
      {/* Snackbar for success/error */}
      <AppSnackbarContainer />

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
                {["SR. NO.", "NAME", "STATUS", "ACTIONS"].map((header) => (
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
                  <TableCell colSpan={4} align="center">
                    <TableLoader text="Fetching categories..." />
                  </TableCell>
                </TableRow>
              ) : categories.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={4} align="center">
                    <Typography
                      variant="body2"
                      sx={{ color: ThemeColors.text.secondary }}
                    >
                      No records found.
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                categories.map((cat:CategoryRecord, index:number) => (
                  <TableRow
                    key={cat.cat_id}
                    hover
                    sx={{
                      transition: "all 0.3s ease",
                      "&:hover": { backgroundColor: "#f5f3ff" },
                      fontSize: "0.8rem",
                    }}
                  >
                    <TableCell>{(page - 1) * rowsPerPage + index + 1}</TableCell>
                    <TableCell sx={{ fontSize: "0.85rem" }}>{cat.cat_title}</TableCell>
                    <TableCell>
                      <Switch
                        size="small"
                        checked={cat.cat_isActive === "1"}
                        onChange={() => handleToggleActive(Number(cat.cat_id))}
                        sx={{
                          "& .MuiSwitch-switchBase.Mui-checked": {
                            color: Brand.indigo,
                          },
                          "& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track": {
                            backgroundColor: Brand.indigo,
                          },
                          transition: "all 0.3s ease",
                        }}
                      />
                    </TableCell>
                    <TableCell>
                      <Tooltip title="Edit Category">
                        <IconButton
                          size="small"
                          sx={{
                            color: ThemeColors.secondary,
                            mr: 1,
                            transition: "all 0.3s ease",
                            "&:hover": { transform: "scale(1.1)" },
                          }}
                          onClick={() => handleFormShow(cat.cat_id.toString())}
                        >
                          <EditIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>

                      <Tooltip title="Delete Category">
                        <IconButton
                          size="small"
                          sx={{
                            color: "error.main",
                            transition: "all 0.3s ease",
                            "&:hover": { transform: "scale(1.1)" },
                          }}
                          onClick={() => handleDeleteClick(cat.cat_id.toString())}
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
        {categories.length > 0 && (
          <Box display="flex" justifyContent="center" alignItems="center" p={2}>
            <Pagination
              count={Math.ceil(totalRecords / rowsPerPage)}
              page={page}
              onChange={handlePaginate}
            />
          </Box>
        )}
      </Paper>
    </>
  );
}
