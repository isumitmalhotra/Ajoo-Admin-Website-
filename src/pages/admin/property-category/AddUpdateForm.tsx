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
import { setupCategorySchema } from "../../../validations/admin-validations";
import type { AddUpdateFormProps } from "./types";
import { themeCss } from "../../../theme/themeCss";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import { getPropertyCategoryById } from "../../../features/admin/propertyCategory/propertyCategoryDetails.slice";
import React, { useEffect, useMemo } from "react";
import { CustomSnackbar } from "../../../components";
import { TableLoader } from "../../../components/admin/common/TableLoader";
import { addOrUpdatePropertyCategory } from "../../../features/admin/propertyCategory/propertyCategoryAddUpdate.slice";
import { fetchPropertyCategories } from "../../../features/admin/propertyCategory/propertyCategory.thunk";

export default function AddUpdateForm({
  categoryId,
  formshow,
  handleFormClose,
  filterData
}: AddUpdateFormProps) {
  const dispatch = useAppDispatch();
  const initialValues = {
    cat_title: "",
    cat_isActive: "",
  };
  const { data, loading } = useAppSelector(
    (state) => state.propertyCategoryDetails,
  );
  const mapApiToFormValues = (data: any) => ({
    cat_title: data?.cat_title ?? "",
    cat_isActive: data?.cat_isActive ?? "",
  });
  useEffect(() => {
    if (categoryId && formshow) {
      dispatch(getPropertyCategoryById(Number(categoryId)));
    }
  }, [categoryId, formshow, dispatch]);
  const formInitialValues = useMemo(() => {
    if (categoryId === null) return initialValues;
    return data ? mapApiToFormValues(data) : initialValues;
  }, [categoryId, data]);

  const [snackbar, setSnackbar] = React.useState<{
    open: boolean;
    message: string;
    severity: "success" | "error";
  }>({ open: false, message: "", severity: "success" });

  const handleSubmit = (values: any) => {
    if(categoryId){
      values.categoryId = categoryId;
    }
    dispatch(addOrUpdatePropertyCategory(values))
      .unwrap()
      .then(() => {
        setSnackbar({
          open: true,
          message: "Category updated successfully!",
          severity: "success",
        });
        handleFormClose();
        dispatch(fetchPropertyCategories(filterData));
      })
      .catch((err: any) => {
        setSnackbar({
          open: true,
          message: err?.message || "Failed to update category",
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
            {categoryId ? "Update Category" : "Add Category"}
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
            validationSchema={setupCategorySchema}
            enableReinitialize
            onSubmit={handleSubmit}
          >
            {({ values, errors, touched, handleChange, handleBlur }) => (
              <Form>
              <Box display="flex" flexDirection="column" gap={3}>
                {/* Name Field */}
                <FormControl fullWidth>
                  <InputLabel
                    htmlFor="cat_title"
                    sx={{
                      color:
                        touched.cat_title && errors.cat_title
                          ? "error.main"
                          : undefined,
                      "&.Mui-focused": {
                        color: Brand.indigo,
                      },
                      transition: "color 0.3s ease",
                    }}
                  >
                    Title
                  </InputLabel>

                  <OutlinedInput
                    id="cat_title"
                    name="cat_title"
                    label="Title"
                    value={values.cat_title}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    error={touched.cat_title && !!errors.cat_title}
                    sx={{
                      "&.Mui-focused .MuiOutlinedInput-notchedOutline": {
                        borderColor: Brand.indigo,
                      },
                      transition: "all 0.3s ease",
                    }}
                  />

                  {touched.cat_title && errors.cat_title && (
                    <FormHelperText error>{errors.cat_title as string}</FormHelperText>
                  )}
                </FormControl>

                {/* Status Field */}
                <FormControl fullWidth>
                  <InputLabel
                    id="status-label"
                    sx={{
                      color:
                        touched.cat_isActive &&
                        errors.cat_isActive
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
                    id="cat_isActive"
                    name="cat_isActive"
                    value={values.cat_isActive}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    input={<OutlinedInput label="Status" />}
                    sx={{
                      "&.Mui-focused .MuiOutlinedInput-notchedOutline": {
                        borderColor: Brand.indigo,
                      },
                      transition: "all 0.3s ease",
                    }}
                    error={touched.cat_isActive && !!errors.cat_isActive}
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
