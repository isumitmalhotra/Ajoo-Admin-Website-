import {
  Modal,
  Box,
  Typography,
  IconButton,
  Button,
  FormControl,
  FormHelperText,
  MenuItem,
  Select,
  OutlinedInput,
  InputLabel,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import { Form, Formik } from "formik";
import { Brand } from "../../../theme/themeColor";
import { setupAmenitySchema } from "../../../validations/admin-validations";
import type { AddUpdateFormProps } from "./types";
import { themeCss } from "../../../theme/themeCss";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import React, { useEffect, useMemo } from "react";
import { TableLoader } from "../../../components/admin/common/TableLoader";
import { CustomSnackbar } from "../../../components";
import { getPropertyAmenityById } from "../../../features/admin/propertyAmenity/propertyAmenityDetails.slice";
import { addOrUpdatePropertyAmenity } from "../../../features/admin/propertyAmenity/propertyAmenityAddUpdate.slice";
import { fetchPropertyAmenities } from "../../../features/admin/propertyAmenity/propertyAmenity.thunk";

export default function AddUpdateForm({
  amenetiesId,
  formshow,
  handleFormClose,
  filterData,
}: AddUpdateFormProps) {
  const dispatch = useAppDispatch();
  const initialValues = {
    amn_title: "",
    amn_isActive: "",
  };
  const { data, loading } = useAppSelector((state) => state.propertyAmenityDetails);
  const mapApiToFormValues = (data: any) => ({
    amn_title: data?.amn_title ?? "",
    amn_isActive: data?.amn_isActive ?? "",
  });
  useEffect(() => {
    if (amenetiesId && formshow) {
      dispatch(getPropertyAmenityById(Number(amenetiesId)));
    }
  }, [amenetiesId, formshow, dispatch]);
  const formInitialValues = useMemo(() => {
    if (amenetiesId === null) return initialValues;
    return data ? mapApiToFormValues(data) : initialValues;
  }, [amenetiesId, data]);

  const [snackbar, setSnackbar] = React.useState<{
    open: boolean;
    message: string;
    severity: "success" | "error";
  }>({ open: false, message: "", severity: "success" });

  const handleSubmit = (values: any) => {
    if (amenetiesId) {
      values.amenetiesId = amenetiesId;
    }
    dispatch(addOrUpdatePropertyAmenity(values))
      .unwrap()
      .then(() => {
        setSnackbar({
          open: true,
          message: "Amenity updated successfully!",
          severity: "success",
        });
        handleFormClose();
        dispatch(fetchPropertyAmenities(filterData));
      })
      .catch((err: any) => {
        setSnackbar({
          open: true,
          message: err?.message || "Failed to update amenity",
          severity: "error",
        });
      });
  };

  return (
    <Modal open={formshow} onClose={handleFormClose}>
      <Box sx={themeCss.modalFormContainer}>
        <Box sx={themeCss.modalHeader}>
          <Typography
            variant="h6"
            sx={{
              color: "#fff",
              fontWeight: 600,
            }}
          >
            {amenetiesId ? "Update Amenity" : "Add Amenity"}
          </Typography>

          <IconButton onClick={handleFormClose} sx={{ color: "#fff" }}>
            <CloseIcon />
          </IconButton>
        </Box>
        <Box sx={{ p: 3 }}>
          {loading && (
            <Box
              sx={{
                position: "absolute",
                inset: 0,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                backgroundColor: "rgba(255,255,255,0.7)",
                zIndex: 10,
              }}
            >
              <TableLoader />
            </Box>
          )}
          <Formik
            initialValues={formInitialValues}
            validationSchema={setupAmenitySchema}
            enableReinitialize
            onSubmit={handleSubmit}
          >
            {({ values, errors, touched, handleChange, handleBlur }) => (
              <Form>
                <Box display="flex" flexDirection="column" gap={3}>
                  {/* Name Field */}
                  <FormControl fullWidth>
                    <InputLabel
                      htmlFor="amn_title"
                      sx={{
                        color:
                          touched.amn_title && errors.amn_title
                            ? "error.main"
                            : undefined,
                        "&.Mui-focused": {
                          color: Brand.indigo,
                        },
                        transition: "color 0.3s ease",
                      }}
                    >
                      Name
                    </InputLabel>

                    <OutlinedInput
                      id="amn_title"
                      name="amn_title"
                      label="Name"
                      value={values.amn_title}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      error={touched.amn_title && !!errors.amn_title}
                      sx={{
                        "&.Mui-focused .MuiOutlinedInput-notchedOutline": {
                          borderColor: Brand.indigo,
                        },
                        transition: "all 0.3s ease",
                      }}
                    />

                    {touched.amn_title && errors.amn_title && (
                      <FormHelperText error>
                        {errors.amn_title as string}
                      </FormHelperText>
                    )}
                  </FormControl>

                  {/* Status Field */}
                  <FormControl fullWidth>
                    <InputLabel
                      id="status-label"
                      sx={{
                        color:
                          touched.amn_isActive && errors.amn_isActive
                            ? "error.main"
                            : undefined,
                        "&.Mui-focused": {
                          color: Brand.indigo,
                        },
                        transition: "color 0.3s ease",
                      }}
                    >
                      Status
                    </InputLabel>

                    <Select
                      labelId="status-label"
                      id="amn_isActive"
                      name="amn_isActive"
                      value={values.amn_isActive}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      input={<OutlinedInput label="Status" />}
                      sx={{
                        "&.Mui-focused .MuiOutlinedInput-notchedOutline": {
                          borderColor: Brand.indigo,
                        },
                        transition: "all 0.3s ease",
                      }}
                      error={touched.amn_isActive && !!errors.amn_isActive}
                    >
                      <MenuItem value="">Select Status</MenuItem>
                      <MenuItem value="1">Active</MenuItem>
                      <MenuItem value="0">Inactive</MenuItem>
                    </Select>
                  </FormControl>
                </Box>

                {/* Actions */}
                <Box display="flex" justifyContent="flex-end" gap={2} mt={4}>
                  <Button
                    variant="outlined"
                    onClick={handleFormClose}
                    sx={{
                      color: "#cf1f1f",
                      borderColor: "#cf1f1f",
                      transition: "all 0.3s ease",
                      "&:hover": {
                        backgroundColor: "#fcecec",
                        borderColor: "#cf1f1f",
                        transform: "scale(1.05)",
                      },
                    }}
                  >
                    Cancel
                  </Button>
                  <Button
                    type="submit"
                    variant="contained"
                    sx={{
                      bgcolor: Brand.indigo,
                      transition: "all 0.3s ease",
                      "&:hover": {
                        bgcolor: "#6f137f",
                        transform: "scale(1.05)",
                      },
                    }}
                  >
                    Submit
                  </Button>
                </Box>
              </Form>
            )}
          </Formik>
        </Box>
        <CustomSnackbar
          open={snackbar.open}
          message={snackbar.message}
          severity={snackbar.severity}
          onClose={() => setSnackbar((prev) => ({ ...prev, open: false }))}
        />
      </Box>
    </Modal>
  );
}
