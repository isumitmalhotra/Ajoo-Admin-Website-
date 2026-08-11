import React, { useState } from "react";
import { Box, Button, Typography, Modal, Backdrop, Paper } from "@mui/material";
import { motion } from "framer-motion";
import DeleteIcon from "@mui/icons-material/Delete";
import DeleteSnackbar from "../../snackbar/DeleteSnackbar";
import { SnackbarCloseReason } from "@mui/material/Snackbar";

interface ConfirmDeleteModalProps {
  open: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title?: string;
  description?: string;
}

const MotionPaper = motion.create(Paper);

const ConfirmDeleteModal: React.FC<ConfirmDeleteModalProps> = ({
  open,
  onClose,
  onConfirm,
  title = "Confirm Delete",
  description = "Are you sure you want to delete this item?",
}) => {
  const [snackbarOpen, setSnackbarOpen] = useState(false);

  const handleDelete = () => {
    onConfirm();
    setSnackbarOpen(true);
    onClose();
  };

  const handleSnackbarClose = (_: unknown, reason?: SnackbarCloseReason) => {
    if (reason === "clickaway") return;
    setSnackbarOpen(false);
  };

  return (
    <>
      <Modal
        open={open}
        onClose={onClose}
        closeAfterTransition
        slots={{ backdrop: Backdrop }}
        slotProps={{ backdrop: { timeout: 300 } }}
      >
        <Box
          sx={{
            position: "fixed",
            top: "50%",
            left: "50%",
            transform: "translate(-50%, -50%)",
            width: { xs: 340, sm: 450, md: 520 },
            outline: "none",
          }}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            transition={{ duration: 0.3 }}
          >
            <MotionPaper
              elevation={6}
              sx={{
                borderRadius: 4,
                px: 4,
                py: 5,
                bgcolor: "#fff",
                boxShadow: "0 10px 30px rgba(0,0,0,0.15)",
                textAlign: "center",
                fontFamily: "Lato",
              }}
            >
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1.3 }}
                transition={{ type: "spring", stiffness: 300 }}
              >
                <DeleteIcon
                  sx={{
                    fontSize: 60,
                    mb: 2,
                    color: "#dc2626", // red-600
                  }}
                />
              </motion.div>

              <Typography
                variant="h5"
                fontWeight={700}
                gutterBottom
                sx={{ fontFamily: "Lato", color: "#111827" }}
              >
                {title}
              </Typography>

              <Typography
                variant="body1"
                color="text.secondary"
                sx={{
                  mb: 4,
                  maxWidth: "85%",
                  mx: "auto",
                  fontSize: "1rem",
                  lineHeight: 1.6,
                  color: "#6b7280",
                  fontFamily: "Lato",
                }}
              >
                {description}
              </Typography>

              <Box
                display="flex"
                justifyContent="center"
                gap={2}
                flexWrap="wrap"
              >
                <Button
                  variant="outlined"
                  onClick={onClose}
                  sx={{
                    px: 4,
                    py: 1.5,
                    borderRadius: "0.75rem",
                    fontWeight: 600,
                    textTransform: "capitalize",
                    fontFamily: "Lato",
                    color: "#ef4444",
                    borderColor: "#ef4444",
                    "&:hover": {
                      backgroundColor: "rgba(239, 68, 68, 0.05)",
                      borderColor: "#ef4444",
                    },
                  }}
                >
                  Cancel
                </Button>

                <Button
                  variant="contained"
                  onClick={handleDelete}
                  sx={{
                    px: 4,
                    py: 1.5,
                    borderRadius: "0.75rem",
                    fontWeight: 600,
                    textTransform: "capitalize",
                    fontFamily: "Lato",
                    backgroundColor: "#dc2626",
                    "&:hover": {
                      backgroundColor: "#b91c1c",
                    },
                  }}
                >
                  Delete
                </Button>
              </Box>
            </MotionPaper>
          </motion.div>
        </Box>
      </Modal>
      <DeleteSnackbar
        open={snackbarOpen}
        message="Item deleted successfully"
        type="error" // 👈 forces RED color
        onClose={handleSnackbarClose}
      />
    </>
  );
};

export default ConfirmDeleteModal;
