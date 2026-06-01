// components/RegulationModal.tsx
import React from "react";
import { Modal, Box, Typography, IconButton } from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";

interface RegulationModalProps {
  open: boolean;
  onClose: () => void;
  title: string;
  content: string;
}

const RegulationModal: React.FC<RegulationModalProps> = ({
  open,
  onClose,
  title,
  content,
}) => {
  return (
    <Modal open={open} onClose={onClose}>
      <Box
        sx={{
          position: "absolute",
          top: "50%",
          left: "50%",
          transform: "translate(-50%, -50%)",
          bgcolor: "#fff",
          borderRadius: "12px",
          boxShadow: 24,
          width: { xs: "90%", md: "70%" },
          maxHeight: "80vh",
          overflowY: "auto",
          p: 4,
          fontFamily: "'Poppins', sans-serif",
        }}
      >
        <Box sx={{ display: "flex", justifyContent: "space-between", mb: 2 }}>
          <Typography variant="h6" sx={{ fontWeight: 600, color: "#1B2447" }}>
            {title}
          </Typography>
          <IconButton onClick={onClose}>
            <CloseIcon />
          </IconButton>
        </Box>

        <Typography
          variant="body1"
          component="div"
          sx={{
            color: "#444",
            lineHeight: 1.8,
            whiteSpace: "pre-line",
          }}
        >
          {content}
        </Typography>
      </Box>
    </Modal>
  );
};

export default RegulationModal;
