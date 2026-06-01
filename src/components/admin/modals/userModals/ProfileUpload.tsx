import React, { useEffect, useState } from "react";
import { Box, Button, Typography, IconButton } from "@mui/material";
import { useFormikContext } from "formik";
import UploadFileIcon from "@mui/icons-material/UploadFile";
import CloseIcon from "@mui/icons-material/Close";
import { uploadBox, uploadPreview } from "./styles";
import { useAppDispatch } from "../../../../app/hooks";
import { deleteUserImage } from "../../../../features/admin/userManagement/UserImageDelete.slice";
import { getUserById } from "../../../../features/admin/userManagement/userDetails.slice";
import CustomSnackbar from "../../snackbar/CustomSnackbar";

const PURPLE = "#1B2447";

const ProfileUpload = ({
  disabled,
  userId,
}: {
  disabled: boolean;
  userId?: number;
}) => {
  const dispatch = useAppDispatch();
  const { setFieldValue, values } = useFormikContext<any>();
  const [preview, setPreview] = useState<string>("");
  const [snackbar, setSnackbar] = React.useState<{
    open: boolean;
    message: string;
    severity: "success" | "error";
  }>({ open: false, message: "", severity: "success" });
  /* ================= PREVIEW HANDLING ================= */
  useEffect(() => {
    if (!values.profileImage) {
      setPreview("");
      return;
    }
    if (typeof values.profileImage === "string") {
      setPreview(values.profileImage);
      return;
    }

    // Newly selected file
    if (values.profileImage instanceof File) {
      const blobUrl = URL.createObjectURL(values.profileImage);
      setPreview(blobUrl);

      return () => URL.revokeObjectURL(blobUrl);
    }
  }, [values.profileImage]);

  /* ================= DELETE HANDLER ================= */
  const handleDeleteImage = async () => {
    if (typeof values.profileImage === "string" && values.profileImageFileId) {
      try {
        await dispatch(deleteUserImage(values.profileImageFileId))
          .unwrap()
          .then((res) => {
            setSnackbar({
              open: true,
              message: "Profile Image Deleted successfully!",
              severity: "success",
            });
            console.log(res, "delete res");
            if (userId !== undefined) {
              dispatch(getUserById(userId));
            }
          });
      } catch (error: any) {
        setSnackbar({
          open: true,
          message: error?.message || "Failed to update user",
          severity: "error",
        });
        return; 
      }
    }

    // Clear Formik values (both backend & local file case)
    setFieldValue("profileImage", "");
    setFieldValue("profileImageFileId", null);
  };

  return (
    <>
      <Box>
        <Typography fontSize={14} fontWeight={600} mb={1.5}>
          Profile Image
        </Typography>

        <Box sx={uploadBox}>
          {preview && (
            <Box sx={{ position: "relative", mb: 1.5 }}>
              <img
                src={preview}
                alt="profile"
                style={{
                  ...(uploadPreview as any),
                  cursor: "pointer",
                }}
              />

              {!disabled && (
                <IconButton
                  size="small"
                  onClick={handleDeleteImage}
                  sx={{
                    position: "absolute",
                    top: 6,
                    right: 6,
                    bgcolor: "#fff",
                    color: PURPLE,
                    boxShadow: 1,
                    "&:hover": { bgcolor: "#f3e8ff" },
                  }}
                >
                  <CloseIcon fontSize="small" />
                </IconButton>
              )}
            </Box>
          )}

          {!disabled && (
            <Button
              startIcon={<UploadFileIcon sx={{ color: PURPLE }} />}
              component="label"
              variant="outlined"
              sx={{
                borderColor: PURPLE,
                color: PURPLE,
                mt: 0.5,
                "&:hover": {
                  borderColor: PURPLE,
                  bgcolor: "#f3e8ff",
                },
              }}
            >
              Upload
              <input
                hidden
                type="file"
                accept="image/*"
                onChange={(e) => {
                  const file = e.target.files?.[0];
                  if (!file) return;

                  // New file replaces backend image
                  setFieldValue("profileImage", file);
                  setFieldValue("profileImageFileId", null);
                }}
              />
            </Button>
          )}
        </Box>
      </Box>
      <CustomSnackbar
        open={snackbar.open}
        message={snackbar.message}
        severity={snackbar.severity}
        onClose={() => setSnackbar((prev) => ({ ...prev, open: false }))}
      />
    </>
  );
};

export default React.memo(ProfileUpload);
