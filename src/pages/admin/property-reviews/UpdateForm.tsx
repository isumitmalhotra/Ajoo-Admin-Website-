import {
  Modal,
  Box,
  Typography,
  IconButton,
  Button,
  FormControl,
  MenuItem,
  Select,
  OutlinedInput,
  InputLabel,
  Rating,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import { useFormik } from "formik";
import { Brand } from "../../../theme/themeColor";
import { reviewSchema } from "../../../validations/admin-validations";
import type { FormValues, UpdateFormProps } from "./types";
import { themeCss } from "../../../theme/themeCss";

export default function UpdateForm({
  formData,
  formshow,
  handleFormClose,
  handleUpdateReview,
}: UpdateFormProps) {
  const formik = useFormik<FormValues>({
    initialValues: {
      id: formData?.id ?? "",
      property: formData?.property ?? "",
      user_name: formData?.user_name ?? "",
      title: formData?.title ?? "",
      description: formData?.description ?? "",
      rating: formData?.rating ?? "1",
      status: formData?.status ?? "0",
    },
    validationSchema: reviewSchema,
    onSubmit: (values) => {
      handleUpdateReview(values);
      handleFormClose();
    },
  });

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
            Property Review
          </Typography>

          <IconButton onClick={handleFormClose} sx={{ color: "#fff" }}>
            <CloseIcon />
          </IconButton>
        </Box>
        <Box sx={{ p: 3 }}>
          <form onSubmit={formik.handleSubmit}>
            <Box display="flex" flexDirection="column" gap={2}>
              <Box>
                <Typography
                  variant="caption"
                  sx={{ color: "text.secondary", fontWeight: 500 }}
                >
                  Property
                </Typography>
                <Typography variant="body1">
                  {formik.values.property}
                </Typography>
              </Box>

              <Box>
                <Typography
                  variant="caption"
                  sx={{ color: "text.secondary", fontWeight: 500 }}
                >
                  User Name
                </Typography>
                <Typography variant="body1">
                  {formik.values.user_name}
                </Typography>
              </Box>

              <Box>
                <Typography
                  variant="caption"
                  sx={{ color: "text.secondary", fontWeight: 500 }}
                >
                  Title
                </Typography>
                <Typography variant="body1">{formik.values.title}</Typography>
              </Box>

              <Box>
                <Typography
                  variant="caption"
                  sx={{ color: "text.secondary", fontWeight: 500 }}
                >
                  Description
                </Typography>
                <Typography variant="body1">
                  {formik.values.description}
                </Typography>
              </Box>

              <Box>
                <Typography
                  variant="caption"
                  sx={{ color: "text.secondary", fontWeight: 500, display: "block" }}
                >
                  Rating
                </Typography>

                <Rating
                  value={Number(formik.values.rating)}
                  readOnly
                  size="large"
                />
              </Box>

              <FormControl fullWidth>
                <InputLabel
                  id="status-label"
                  sx={{
                    color:
                      formik.touched.status && formik.errors.status
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
                  id="status"
                  name="status"
                  value={formik.values.status}
                  onChange={formik.handleChange}
                  onBlur={formik.handleBlur}
                  input={<OutlinedInput label="Status" />}
                  sx={{
                    "&.Mui-focused .MuiOutlinedInput-notchedOutline": {
                      borderColor: Brand.indigo,
                    },
                    transition: "all 0.3s ease",
                  }}
                  error={formik.touched.status && !!formik.errors.status}
                >
                  <MenuItem value="">Select Status</MenuItem>
                  <MenuItem value="0">Pending</MenuItem>
                  <MenuItem value="1">Approved</MenuItem>
                  <MenuItem value="2">Rejected</MenuItem>
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
          </form>
        </Box>
      </Box>
    </Modal>
  );
}
