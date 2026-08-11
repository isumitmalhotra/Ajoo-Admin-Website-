import React from "react";
import {
  Box,
  Typography,
  IconButton,
  Modal,
  Avatar,
  Divider,
  Rating,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import { motion, AnimatePresence } from "framer-motion";

interface HostDetailsModalProps {
  open: boolean;
  onClose: () => void;
  user: {
    name: string;
    image: string;
    contact: string;
    address: string;
    propertyCount: number;
    rating?: number;
  };
}

const MotionBox = motion.create(Box);

const HostDetailsModal: React.FC<HostDetailsModalProps> = ({
  open,
  onClose,
  user,
}) => {
  return (
    <AnimatePresence>
      {open && (
        <Modal
          open={open}
          onClose={onClose}
          sx={{
            backdropFilter: "blur(8px)", // ✅ subtle backdrop blur
            backgroundColor: "rgba(0, 0, 0, 0.3)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 9999,
          }}
        >
          <MotionBox
            initial={{ opacity: 0, scale: 0.8, y: 50 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.8, y: 50 }}
            transition={{ duration: 0.3 }}
            sx={{
              position: "relative",
              width: { xs: "90%", sm: 400 },
              bgcolor: "#fff",
              borderRadius: "20px",
              boxShadow: 8,
              p: 3,
              overflow: "hidden",
            }}
          >
            {/* ❌ Close Button */}
            <IconButton
              onClick={onClose}
              sx={{
                position: "absolute",
                top: 10,
                right: 10,
                color: "#1B2447",
                bgcolor: "#fff",
                "&:hover": { bgcolor: "#f7f7f7" },
                boxShadow: 1,
              }}
            >
              <CloseIcon />
            </IconButton>

            {/* 👤 User Info */}
            <MotionBox
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2, duration: 0.4 }}
              sx={{ textAlign: "center", mt: 2 }}
            >
              <motion.div
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.3, duration: 0.4 }}
              >
                <Avatar
                  src={user.image}
                  alt={user.name}
                  sx={{
                    width: 100,
                    height: 100,
                    mx: "auto",
                    border: "3px solid #1B2447",
                    mb: 1.5,
                  }}
                />
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4, duration: 0.4 }}
              >
                <Typography
                  variant="h6"
                  sx={{ fontWeight: 600, color: "#1B2447", mb: 0.5 }}
                >
                  {user.name}
                </Typography>
                <Typography
                  variant="body2"
                  sx={{ color: "text.secondary", mb: 1 }}
                >
                  Aajoo Verified User
                </Typography>
                {user.rating && user.rating > 0 ? (
                  <Box
                    sx={{
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      gap: 0.75,
                      mb: 2,
                    }}
                  >
                    <Rating
                      value={user.rating}
                      precision={0.5}
                      readOnly
                      size="small"
                      sx={{ color: "#C16345" }}
                    />
                    <Typography sx={{ fontSize: "0.85rem", fontWeight: 700, color: "#1B2447" }}>
                      {user.rating.toFixed(1)}
                    </Typography>
                  </Box>
                ) : null}
              </motion.div>
            </MotionBox>

            <Divider sx={{ mb: 2 }} />

            {/* 📋 Details Section */}
            <MotionBox
              initial="hidden"
              animate="visible"
              variants={{
                hidden: {},
                visible: {
                  transition: { staggerChildren: 0.1, delayChildren: 0.5 },
                },
              }}
              sx={{ display: "flex", flexDirection: "column", gap: 1.5 }}
            >
              {[
                { label: "📞 Contact", value: user.contact },
                { label: "📍 Address", value: user.address },
                {
                  label: "🏠 Properties Listed",
                  value: `${user.propertyCount} with Aajoo Homes`,
                },
              ].map((item, index) => (
                <motion.div
                  key={index}
                  variants={{
                    hidden: { opacity: 0, y: 10 },
                    visible: { opacity: 1, y: 0 },
                  }}
                  transition={{ duration: 0.4 }}
                >
                  <Typography
                    variant="body2"
                    sx={{ fontWeight: 600, color: "#333" }}
                  >
                    {item.label}:
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {item.value}
                  </Typography>
                </motion.div>
              ))}
            </MotionBox>
          </MotionBox>
        </Modal>
      )}
    </AnimatePresence>
  );
};

export default HostDetailsModal;
