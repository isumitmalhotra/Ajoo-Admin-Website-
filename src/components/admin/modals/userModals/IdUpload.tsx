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

const INDIGO = "#1B2447";

const IdUpload = ({
  disabled,
  userId,
}: {
  disabled: boolean;
  userId?: number;
}) => {
  const dispatch = useAppDispatch();
  const { setFieldValue, values } = useFormikContext<any>();

  const [preview, setPreview] = useState<string>("");
  const [snackbar, setSnackbar] = useState<{
    open: boolean;
    message: string;
    severity: "success" | "error";
  }>({ open: false, message: "", severity: "success" });

  /* ================= PREVIEW HANDLING ================= */
  useEffect(() => {
    if (!values.idImage) {
      setPreview("");
      return;
    }

    console.log(values.idImage, "values.idImage");
    console.log(values.idImageFileId, "values.idImageFileId");

    // Backend image URL
    if (typeof values.idImage === "string") {
      setPreview(values.idImage);
      return;
    }

    // Newly selected file
    if (values.idImage instanceof File) {
      const blobUrl = URL.createObjectURL(values.idImage);
      setPreview(blobUrl);

      return () => URL.revokeObjectURL(blobUrl);
    }
  }, [values.idImage]);

  /* ================= DELETE HANDLER ================= */
  const handleDeleteImage = async () => {
    if (typeof values.idImage === "string" && values.idImageFileId) {
      console.log(values.idImageFileId, "values.idImageFileId");
      try {
        await dispatch(deleteUserImage(values.idImageFileId))
          .unwrap()
          .then(() => {
            setSnackbar({
              open: true,
              message: "ID Document Image deleted successfully!",
              severity: "success",
            });

            if (userId !== undefined) {
              dispatch(getUserById(userId));
            }
          });
      } catch (error: any) {
        setSnackbar({
          open: true,
          message: error?.message || "Failed to delete ID image",
          severity: "error",
        });
        return;
      }
    }

    // Clear Formik values
    setFieldValue("idImage", "");
    setFieldValue("idImageFileId", null);
  };

  return (
    <>
      <Box>
        <Typography fontSize={14} fontWeight={600} mb={1.5}>
          ID Document Image
        </Typography>

        <Box sx={uploadBox}>
          {preview && (
            <Box sx={{ position: "relative", mb: 1.5 }}>
              <img
                src={preview}
                alt="id-document"
                onClick={() => window.open(preview, "_blank")}
                style={{ cursor: "pointer", ...(uploadPreview as any) }}
              />
              {!disabled && (
                <IconButton
                  size="small"
                  onClick={(e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    handleDeleteImage();
                  }}
                  sx={{
                    position: "absolute",
                    top: 6,
                    right: 6,
                    bgcolor: "#fff",
                    color: INDIGO,
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
              startIcon={<UploadFileIcon sx={{ color: INDIGO }} />}
              component="label"
              variant="outlined"
              sx={{
                borderColor: INDIGO,
                color: INDIGO,
                mt: 0.5,
                "&:hover": {
                  borderColor: INDIGO,
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

                  setFieldValue("idImage", file);
                  setFieldValue("idImageFileId", null);
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

export default React.memo(IdUpload);
