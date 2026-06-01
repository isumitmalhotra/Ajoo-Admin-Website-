import { Dialog, DialogTitle, DialogContent, DialogActions, Button, Typography, Box } from "@mui/material";

interface ConfirmDialogProps {
  open: boolean;
  title: string;
  message: string;
  highlight?: string;
  onClose: () => void;
  onConfirm: () => void;
  confirmText?: string;
  cancelText?: string;
  highlightColor?: string;
}

export default function ConfirmDialog({
  open,
  title,
  message,
  highlight,
  onClose,
  onConfirm,
  confirmText = "Confirm",
  cancelText = "Cancel",
  highlightColor = "#1B2447",
}: ConfirmDialogProps) {
  return (
    <Dialog open={open} onClose={onClose} PaperProps={{ sx: { borderRadius: 4, p: 1 } }}>
      <DialogTitle sx={{ fontWeight: 600, pb: 1 }}>{title}</DialogTitle>
      <DialogContent>
        <Typography>
          {message}{" "}
          {highlight && (
            <Box component="span" sx={{ fontWeight: 600, color: highlightColor }}>
              {highlight}
            </Box>
          )}
        </Typography>
      </DialogContent>
      <DialogActions sx={{ p: 3, pt: 2 }}>
        <Button onClick={onClose} variant="outlined" sx={{ borderRadius: 2, textTransform: "none" }}>
          {cancelText}
        </Button>
        <Button onClick={onConfirm} variant="contained" color="error" sx={{ borderRadius: 2, ml: 2 }}>
          {confirmText}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
