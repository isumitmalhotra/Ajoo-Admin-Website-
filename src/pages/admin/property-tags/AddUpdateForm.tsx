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
import { setupTagSchema } from "../../../validations/admin-validations";
import type { AddUpdateFormProps } from "./types";
import { themeCss } from "../../../theme/themeCss";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import React, { useEffect, useMemo } from "react";
import { getPropertyTagById } from "../../../features/admin/propertyTag/propertyTagDetails.slice";
import { addOrUpdatePropertyTag } from "../../../features/admin/propertyTag/propertyTagAddUpdate.slice";
import { fetchPropertyTags } from "../../../features/admin/propertyTag/propertyTag.thunk";
import { TableLoader } from "../../../components/admin/common/TableLoader";
import { CustomSnackbar } from "../../../components";

export default function AddUpdateForm({
  tagId,
  formshow,
  handleFormClose,
  filterData,
}: AddUpdateFormProps) {
  const dispatch = useAppDispatch();
  const initialValues = {
    tag_name: "",
    tag_isActive: "",
  };
  const { data, loading } = useAppSelector((state) => state.propertyTagDetails);
  const mapApiToFormValues = (data: any) => ({
    tag_name: data?.tag_name ?? "",
    tag_isActive: data?.tag_isActive ?? "",
  });
  useEffect(() => {
    if (tagId && formshow) {
      dispatch(getPropertyTagById(Number(tagId)));
    }
  }, [tagId, formshow, dispatch]);
  const formInitialValues = useMemo(() => {
    if (tagId === null) return initialValues;
    return data ? mapApiToFormValues(data) : initialValues;
  }, [tagId, data]);

  const [snackbar, setSnackbar] = React.useState<{
    open: boolean;
    message: string;
    severity: "success" | "error";
  }>({ open: false, message: "", severity: "success" });

  const handleSubmit = (values: any) => {
    if (tagId) {
      values.tagId = tagId;
    }
    dispatch(addOrUpdatePropertyTag(values))
      .unwrap()
      .then(() => {
        setSnackbar({
          open: true,
          message: "Tag updated successfully!",
          severity: "success",
        });
        handleFormClose();
        dispatch(fetchPropertyTags(filterData));
      })
      .catch((err: any) => {
        setSnackbar({
          open: true,
          message: err?.message || "Failed to update tag",
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
            {tagId ? "Update Tag" : "Add Tag"}
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
            validationSchema={setupTagSchema}
            enableReinitialize
            onSubmit={handleSubmit}
          >
            {({ values, errors, touched, handleChange, handleBlur }) => (
              <Form>
                <Box display="flex" flexDirection="column" gap={3}>
                  {/* Name Field */}
                  <FormControl fullWidth>
                    <InputLabel
                      htmlFor="tag_name"
                      sx={{
                        color:
                          touched.tag_name && errors.tag_name
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
                      id="tag_name"
                      name="tag_name"
                      label="Name"
                      value={values.tag_name}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      error={touched.tag_name && !!errors.tag_name}
                      sx={{
                        "&.Mui-focused .MuiOutlinedInput-notchedOutline": {
                          borderColor: Brand.indigo,
                        },
                        transition: "all 0.3s ease",
                      }}
                    />

                    {touched.tag_name && errors.tag_name && (
                      <FormHelperText error>
                        {errors.tag_name as string}
                      </FormHelperText>
                    )}
                  </FormControl>

                  {/* Status Field */}
                  <FormControl fullWidth>
                    <InputLabel
                      id="status-label"
                      sx={{
                        color:
                          touched.tag_isActive && errors.tag_isActive
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
                      id="tag_isActive"
                      name="tag_isActive"
                      value={values.tag_isActive}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      input={<OutlinedInput label="Status" />}
                      sx={{
                        "&.Mui-focused .MuiOutlinedInput-notchedOutline": {
                          borderColor: Brand.indigo,
                        },
                        transition: "all 0.3s ease",
                      }}
                      error={touched.tag_isActive && !!errors.tag_isActive}
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
