import { useFormik, FormikErrors } from "formik";
import {
  Box,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Button,
  CircularProgress,
} from "@mui/material";
import { Brand } from "../../../theme/themeColor";
import { Pagination } from "../../../components";
import type { ListingProps, BookingStatusRow } from "./types";
import { bookingStatusRowSchema } from "../../../validations/admin-validations";

const indigoFieldSx = {
  "& .MuiOutlinedInput-root": {
    "& fieldset": {
      borderColor: Brand.indigo,
    },
    "&:hover fieldset": {
      borderColor: Brand.indigo,
    },
    "&.Mui-focused fieldset": {
      borderColor: Brand.indigo,
    },
    "&.Mui-error fieldset": {
      borderColor: Brand.indigo,
    },
  },
  "& .MuiFormHelperText-root": {
    color: Brand.indigo,
  },
};

export default function Listing({
  statusListing,
  totalRecords,
  loading,
  handlePaginate,
  page,
  rowsPerPage,
  onSave,
}: ListingProps) {
  const formik = useFormik({
    enableReinitialize: true,
    initialValues: { rows: statusListing },
    validationSchema: bookingStatusRowSchema,
    onSubmit: () => {},
  });

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" mt={4}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <form onSubmit={formik.handleSubmit}>
      <Paper sx={{ borderRadius: 3, overflow: "hidden" }}>
        <TableContainer>
          <Table>
            <TableHead sx={{ backgroundColor: "#f9fafb" }}>
              <TableRow>
                {["SR. NO.", "TITLE", "CODE", "ACTIONS"].map((header) => (
                  <TableCell key={header} sx={{ fontWeight: 600 }}>
                    {header}
                  </TableCell>
                ))}
              </TableRow>
            </TableHead>

            <TableBody>
              {formik.values.rows.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={4} align="center">
                    No records found
                  </TableCell>
                </TableRow>
              ) : (
                formik.values.rows.map((row, index) => (
                  <TableRow key={row.bs_id} hover>
                    <TableCell>
                      {(page - 1) * rowsPerPage + index + 1}
                    </TableCell>

                    <TableCell>
                      <TextField
                        size="small"
                        name={`rows.${index}.bs_title`}
                        value={row.bs_title}
                        onChange={formik.handleChange}
                        error={Boolean(
                          (formik.errors.rows?.[index] as any)?.bs_title
                        )}
                        helperText={
                          (formik.errors.rows?.[index] as any)?.bs_title
                        }
                        sx={indigoFieldSx}
                      />
                    </TableCell>

                    <TableCell>
                      <TextField
                        size="small"
                        name={`rows.${index}.bs_code`}
                        value={row.bs_code ?? ""}
                        onChange={formik.handleChange}
                        error={Boolean(
                          (formik.errors.rows?.[index] as any)?.bs_code
                        )}
                        helperText={
                          (formik.errors.rows?.[index] as any)?.bs_code
                        }
                        sx={indigoFieldSx}
                      />
                    </TableCell>

                    <TableCell>
                      <Button
                        size="small"
                        sx={{
                          backgroundColor: Brand.indigo,
                          "&:hover": {
                            backgroundColor: Brand.indigo,
                          },
                        }}
                        variant="contained"
                        onClick={async () => {
                          try {
                            await bookingStatusRowSchema.validate(row, {
                              abortEarly: false,
                            });
                            onSave(row); // API call
                          } catch (err: any) {
                            if (!err.inner) return;

                            const rowErrors: Record<string, string> = {};

                            err.inner.forEach((e: any) => {
                              if (e.path) {
                                rowErrors[e.path] = e.message;
                              }
                            });

                            const errorsArray: FormikErrors<BookingStatusRow>[] =
                              Array.isArray(formik.errors.rows)
                                ? formik.errors.rows.map((error) =>
                                    typeof error === "object" ? error : {}
                                  )
                                : [];
                            errorsArray[index] = rowErrors;

                            formik.setErrors({
                              rows: errorsArray,
                            });
                          }
                        }}
                      >
                        Save
                      </Button>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>

        {formik.values.rows.length > 0 && (
          <Box display="flex" justifyContent="center" p={2}>
            <Pagination
              count={Math.ceil(totalRecords / rowsPerPage)}
              page={page}
              onChange={handlePaginate}
            />
          </Box>
        )}
      </Paper>
    </form>
  );
}
