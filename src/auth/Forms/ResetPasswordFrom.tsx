import { useState } from "react";
import { Box, Button, CircularProgress, Typography } from "@mui/material";
import { AnimatePresence, motion } from "framer-motion";
import { useLocation, useNavigate } from "react-router-dom";
import * as z from "zod";
import { Form } from "../../components/Form/form";
import { animations } from "../../components/layout/loginLayout";
import { useNotificationStore } from "../../components/toast";
import useAnimateFn from "../../hooks/useAnimate";
import { resetPassword } from "../../redux/authSllice";
import { InputField } from "../../components/Form/inputField";

const schema = z
  .object({
    password: z
      .string()
      .min(6, "Password must be at least 6 characters")
      .max(32, "Password must not exceed 32 characters"),
    confirmPassword: z.string().min(1, "Please confirm your password"),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Passwords do not match",
    path: ["confirmPassword"],
  });

type ResetPasswordValues = {
  password: string;
  confirmPassword: string;
};

export const ResetPasswordForm = () => {
  const navigate = useNavigate();
  const { animate } = useAnimateFn();
  const { addNotification } = useNotificationStore();
  const [loading, setLoading] = useState(false);

  const {
    state: { token },
  } = useLocation();
  const handleSubmit = async (values: ResetPasswordValues) => {
    try {
      setLoading(true);
      const response = await resetPassword({
        resetPasswordToken: token,
        newPassword: values.password,
        confirmPassword: values.confirmPassword,
      });
      console.log("Reset response:", response);
      addNotification({
        type: "success",
        title: "Password Reset",
        message: "Your password has been updated successfully.",
      });

      navigate("/auth/login");
    } catch (error) {
      console.error(error);
      addNotification({
        type: "error",
        title: "Failed",
        message: "Something went wrong. Please try again.",
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <AnimatePresence>
      {animate && (
        <motion.div {...animations}>
          <Box
            className="reset-password-form"
            sx={{
              maxWidth: 420,
              margin: "0 auto",
              padding: 4,
              borderRadius: 2,
              boxShadow: 3,
              bgcolor: "#fff",
            }}
          >
            <Typography variant="h5" fontWeight={600} mb={1}>
              Reset Password
            </Typography>
            <Typography variant="body2" color="text.secondary" mb={3}>
              Enter your new password and confirm it below.
            </Typography>

            <Form<ResetPasswordValues> onSubmit={handleSubmit} schema={schema}>
              {({ register, formState }) => (
                <>
                  <InputField
                    type="password"
                    label="New Password"
                    placeholder="Enter new password"
                    error={formState.errors["password"]}
                    registration={register("password", {
                      required: "Password is required",
                    })}
                  />

                  <InputField
                    type="password"
                    label="Confirm Password"
                    placeholder="Re-enter new password"
                    error={formState.errors["confirmPassword"]}
                    registration={register("confirmPassword", {
                      required: "Please confirm your password",
                    })}
                  />

                  <Box mt={4}>
                    <Button
                      type="submit"
                      fullWidth
                      variant="contained"
                      sx={{
                        backgroundColor: "#1B2447",
                        color: "#fff",
                        fontWeight: 600,
                        "&:hover": {
                          backgroundColor: "#a83956",
                        },
                        borderRadius: "8px",
                        py: 1.5,
                      }}
                      disabled={loading}
                    >
                      {loading ? (
                        <CircularProgress size={22} sx={{ color: "#fff" }} />
                      ) : (
                        "Reset Password"
                      )}
                    </Button>
                  </Box>
                </>
              )}
            </Form>
          </Box>
        </motion.div>
      )}
    </AnimatePresence>
  );
};
