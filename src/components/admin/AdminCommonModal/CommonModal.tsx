import React from "react";
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  IconButton,
  Button,
  Fade,
  Backdrop,
  Box,
  Typography,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import { styled } from "@mui/material/styles";

interface CommonModalProps {
  open: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
  onSubmit?: () => void;
  submitText?: string;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  loading?: boolean;
}

// Styled components for enhanced visual appeal
const StyledDialog = styled(Dialog)(() => ({
  '& .MuiDialog-paper': {
    borderRadius: '24px',
    background: 'linear-gradient(145deg, #ffffff 0%, #fafafa 100%)',
    boxShadow: '0 24px 48px rgba(139, 69, 193, 0.15), 0 8px 24px rgba(139, 69, 193, 0.08)',
    border: '1px solid rgba(139, 69, 193, 0.1)',
    padding: 0,
    position: 'relative',
    overflow: 'visible',
    '&::before': {
      content: '""',
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      height: '4px',
      background: 'linear-gradient(90deg, #1B2447 0%, #C16345 50%, #D9CFB8 100%)',
      borderRadius: '24px 24px 0 0',
    },
  },
}));

const StyledDialogTitle = styled(DialogTitle)(() => ({
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'space-between',
  padding: '32px 32px 16px 32px',
  background: 'transparent',
  '& .MuiTypography-root': {
    fontWeight: 700,
    fontSize: '1.5rem',
    color: '#1f2937',
    letterSpacing: '-0.025em',
    background: 'linear-gradient(135deg, #1B2447 0%, #C16345 100%)',
    WebkitBackgroundClip: 'text',
    WebkitTextFillColor: 'transparent',
    backgroundClip: 'text',
  },
}));

const StyledIconButton = styled(IconButton)(() => ({
  backgroundColor: 'rgba(139, 69, 193, 0.08)',
  color: '#1B2447',
  width: '40px',
  height: '40px',
  borderRadius: '12px',
  transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
  border: '1px solid rgba(139, 69, 193, 0.15)',
  '&:hover': {
    backgroundColor: 'rgba(139, 69, 193, 0.15)',
    transform: 'translateY(-2px)',
    boxShadow: '0 8px 16px rgba(139, 69, 193, 0.2)',
  },
  '&:active': {
    transform: 'translateY(0)',
  },
}));

const StyledDialogContent = styled(DialogContent)(() => ({
  padding: '0 32px 24px 32px',
  position: 'relative',
  '&::-webkit-scrollbar': {
    width: '6px',
  },
  '&::-webkit-scrollbar-track': {
    background: 'transparent',
  },
  '&::-webkit-scrollbar-thumb': {
    background: 'linear-gradient(180deg, #C16345, #D9CFB8)',
    borderRadius: '3px',
  },
}));

const StyledDialogActions = styled(DialogActions)(() => ({
  padding: '24px 32px 32px 32px',
  background: 'rgba(249, 250, 251, 0.8)',
  borderTop: '1px solid rgba(139, 69, 193, 0.08)',
  gap: '12px',
  margin: 0,
  borderRadius: '0 0 24px 24px',
}));

const CancelButton = styled(Button)(() => ({
  borderRadius: '16px',
  padding: '12px 24px',
  fontWeight: 600,
  textTransform: 'none',
  fontSize: '0.95rem',
  border: '2px solid rgba(139, 69, 193, 0.2)',
  color: '#1B2447',
  backgroundColor: 'transparent',
  transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
  '&:hover': {
    backgroundColor: 'rgba(139, 69, 193, 0.08)',
    borderColor: '#1B2447',
    transform: 'translateY(-1px)',
    boxShadow: '0 4px 12px rgba(139, 69, 193, 0.15)',
  },
}));

const SubmitButton = styled(Button)(() => ({
  borderRadius: '16px',
  padding: '12px 32px',
  fontWeight: 600,
  textTransform: 'none',
  fontSize: '0.95rem',
  background: 'linear-gradient(135deg, #1B2447 0%, #C16345 100%)',
  color: 'white',
  border: 'none',
  boxShadow: '0 4px 12px rgba(139, 69, 193, 0.3)',
  transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
  minWidth: '120px',
  '&:hover': {
    background: 'linear-gradient(135deg, #6d28d9 0%, #3F6B4E 100%)',
    transform: 'translateY(-2px)',
    boxShadow: '0 8px 20px rgba(139, 69, 193, 0.4)',
  },
  '&:active': {
    transform: 'translateY(-1px)',
  },
  '&:disabled': {
    background: 'rgba(139, 69, 193, 0.3)',
    color: 'rgba(255, 255, 255, 0.7)',
    transform: 'none',
    boxShadow: 'none',
  },
}));

const LoadingDots = styled(Box)({
  display: 'inline-flex',
  alignItems: 'center',
  gap: '4px',
  '& span': {
    width: '4px',
    height: '4px',
    borderRadius: '50%',
    backgroundColor: 'currentColor',
    animation: 'loading-dots 1.4s ease-in-out infinite both',
    '&:nth-of-type(1)': { animationDelay: '-0.32s' },
    '&:nth-of-type(2)': { animationDelay: '-0.16s' },
  },
  '@keyframes loading-dots': {
    '0%, 80%, 100%': {
      opacity: 0.3,
      transform: 'scale(0.8)',
    },
    '40%': {
      opacity: 1,
      transform: 'scale(1)',
    },
  },
});

const sizeConfig = {
  sm: 'sm' as const,
  md: 'md' as const,
  lg: 'lg' as const,
  xl: 'xl' as const,
};

const CommonModal: React.FC<CommonModalProps> = ({
  open,
  onClose,
  title,
  children,
  onSubmit,
  submitText = "Submit",
  size = 'md',
  loading = false,
}) => {
  const handleKeyDown = (event: React.KeyboardEvent) => {
    if (event.key === 'Enter' && event.ctrlKey && onSubmit && !loading) {
      onSubmit();
    }
  };

  return (
    <StyledDialog
      open={open}
      onClose={loading ? undefined : onClose}
      fullWidth
      maxWidth={sizeConfig[size]}
      TransitionComponent={Fade}
      TransitionProps={{
        timeout: 400,
      }}
      BackdropComponent={Backdrop}
      BackdropProps={{
        sx: {
          backgroundColor: 'rgba(15, 23, 42, 0.7)',
          backdropFilter: 'blur(8px)',
        },
      }}
      onKeyDown={handleKeyDown}
      disableEscapeKeyDown={loading}
    >
      <StyledDialogTitle>
        <Typography component="h2" variant="h6">
          {title}
        </Typography>
        <StyledIconButton 
          onClick={onClose} 
          size="small"
          disabled={loading}
          aria-label="Close dialog"
        >
          <CloseIcon fontSize="small" />
        </StyledIconButton>
      </StyledDialogTitle>

      <StyledDialogContent>
        {children}
      </StyledDialogContent>

      <StyledDialogActions>
        <CancelButton 
          onClick={onClose} 
          disabled={loading}
          variant="outlined"
        >
          Cancel
        </CancelButton>
        {onSubmit && (
          <SubmitButton
            variant="contained"
            onClick={onSubmit}
            disabled={loading}
          >
            {loading ? (
              <>
                <LoadingDots>
                  <span />
                  <span />
                  <span />
                </LoadingDots>
                <span style={{ marginLeft: '8px' }}>Processing...</span>
              </>
            ) : (
              submitText
            )}
          </SubmitButton>
        )}
      </StyledDialogActions>
    </StyledDialog>
  );
};

export default CommonModal;