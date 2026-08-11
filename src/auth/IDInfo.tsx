import { useEffect, useState } from "react";
import {
  Box,
  TextField,
  InputAdornment,
  MenuItem,
  Typography,
  Button,
  IconButton,
} from "@mui/material";
import { motion } from "framer-motion";
import BadgeIcon from "@mui/icons-material/Badge";
import FileUploadIcon from "@mui/icons-material/FileUpload";
import InsertDriveFileIcon from "@mui/icons-material/InsertDriveFile";
import CloseIcon from "@mui/icons-material/Close";
import { getDocumentTypes } from "../services/customerApi";

const PRIMARY = "#1B2447";

const fadeUp = {
  hidden: { opacity: 0, y: 20 },
  show: { opacity: 1, y: 0, transition: { duration: 0.4 } },
};

const IDInfo = ({ data, errors, onChange }: any) => {
  // Real KYC document types (id + title) from the backend.
  const [docTypes, setDocTypes] = useState<{ id: number; title: string }[]>([]);
  useEffect(() => {
    getDocumentTypes()
      .then(setDocTypes)
      .catch(() => setDocTypes([]));
  }, []);

  const isImage = (file: File) => file.type.startsWith("image/");

  const renderInput = (
    label: string,
    name: string,
    value: string,
    error: string,
    icon?: any,
    type = "text",
    selectOptions?: string[]
  ) => (
    <TextField
      fullWidth
      required
      select={!!selectOptions}
      type={type}
      label={label + " *"}
      value={value}
      error={!!error}
      helperText={error}
      onChange={(e) => onChange(name, e.target.value)}
      InputProps={
        icon
          ? {
              startAdornment: <InputAdornment position="start">{icon}</InputAdornment>,
            }
          : undefined
      }
      sx={{
        mb: 2,
        "& .MuiOutlinedInput-root": {
          borderRadius: "12px",
          "& fieldset": { borderColor: PRIMARY },
          "&.Mui-focused fieldset": { borderColor: PRIMARY },
        },
        "& label": { color: PRIMARY, fontWeight: 600 },
        "& .MuiInputLabel-root.Mui-focused": { color: PRIMARY }, // Keep label color on focus
      }}
    >
      {selectOptions &&
        selectOptions.map((opt) => (
          <MenuItem key={opt} value={opt}>
            {opt}
          </MenuItem>
        ))}
    </TextField>
  );

  return (
    <motion.div variants={fadeUp} initial="hidden" animate="show" style={{ width: "100%" }}>
      <Typography
        variant="h5"
        sx={{ fontWeight: 700, mb: 3, color: PRIMARY, textAlign: "center" }}
      >
        ID Information
      </Typography>

      <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
        {/* Document Type — real backend doc types (numeric id) */}
        <TextField
          fullWidth
          required
          select
          label="Document Type *"
          value={data.docType || ""}
          error={!!errors.docType}
          helperText={errors.docType}
          onChange={(e) => onChange("docType", Number(e.target.value))}
          sx={{
            mb: 2,
            "& .MuiOutlinedInput-root": {
              borderRadius: "12px",
              "& fieldset": { borderColor: PRIMARY },
              "&.Mui-focused fieldset": { borderColor: PRIMARY },
            },
            "& label": { color: PRIMARY, fontWeight: 600 },
            "& .MuiInputLabel-root.Mui-focused": { color: PRIMARY },
          }}
        >
          {docTypes.length === 0 ? (
            <MenuItem value="" disabled>
              Loading document types…
            </MenuItem>
          ) : (
            docTypes.map((d) => (
              <MenuItem key={d.id} value={d.id}>
                {d.title}
              </MenuItem>
            ))
          )}
        </TextField>

        {/* Document Number */}
        {renderInput("Document Number", "docNumber", data.docNumber, errors.docNumber, <BadgeIcon sx={{ color: PRIMARY }} />)}

        {/* File Upload */}
        <Button
          variant="contained"
          component="label"
          startIcon={<FileUploadIcon />}
          sx={{ backgroundColor: PRIMARY }}
        >
          Upload Document
          <input
            type="file"
            hidden
            onChange={(e) =>
              onChange("file", e.target.files ? e.target.files[0] : null)
            }
          />
        </Button>

        {/* Preview */}
        {data.file && (
          <Box
            sx={{
              mt: 2,
              width: "100%",
              height: 250,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              position: "relative",
              border: "2px dashed #ccc",
              borderRadius: 2,
              cursor: "pointer",
            }}
            onClick={() => {
              const url = URL.createObjectURL(data.file);
              window.open(url, "_blank");
            }}
          >
            {/* Cross button */}
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                onChange("file", null);
              }}
              sx={{ position: "absolute", top: 4, right: 4, color: PRIMARY }}
            >
              <CloseIcon fontSize="small" />
            </IconButton>

            {/* File / Image Preview */}
            {isImage(data.file) ? (
              <Box
                component="img"
                src={URL.createObjectURL(data.file)}
                alt="preview"
                sx={{ maxHeight: "100%", maxWidth: "100%", objectFit: "contain" }}
              />
            ) : (
              <InsertDriveFileIcon sx={{ fontSize: 80, color: "#999" }} />
            )}
          </Box>
        )}
      </Box>
    </motion.div>
  );
};

export default IDInfo;
