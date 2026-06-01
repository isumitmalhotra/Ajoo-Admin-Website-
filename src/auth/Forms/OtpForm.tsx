import { useEffect, useState } from "react";
import { Box, Button, CircularProgress, Typography } from "@mui/material";
import { AnimatePresence, motion } from "framer-motion";
import { useLocation, useNavigate } from "react-router-dom";
import { Form } from "../../components/Form/form";
import * as z from "zod";
import { animations } from "../../components/layout/loginLayout";
import { useNotificationStore } from "../../components/toast";
import useAnimateFn from "../../hooks/useAnimate";
import { verifyOtp, forgotPassword } from "../../redux/authSllice";
import { InputField } from "../../components/Form/inputField"; // Your custom input component

const schema = z.object({
    otp: z
        .string()
        .min(4, "Enter a valid 4-digit OTP")
        .max(6, "Enter a valid OTP")
        .refine((val) => /^\d+$/.test(val), "OTP must be numeric"),
});

type OtpValues = {
    otp: string;
};

export const VerifyOtpForm = () => {
    const navigate = useNavigate();
    const { addNotification } = useNotificationStore();
    const { animate } = useAnimateFn();

    const [loading, setLoading] = useState(false);
    const [resendLoading, setResendLoading] = useState(false);
    const [timer, setTimer] = useState(30);
    const { state: { email } } = useLocation();

    useEffect(() => {
        if (timer > 0) {
            const countdown = setInterval(() => setTimer((t) => t - 1), 1000);
            return () => clearInterval(countdown);
        }
    }, [timer]);

    const handleSubmit = async (values: OtpValues) => {
        try {
            setLoading(true);
            const response = await verifyOtp({
                userEmail: email,
                otp: values.otp,
            });
            console.log(response, "respo");
            if (response?.data) {
                addNotification({
                    type: "success",
                    title: "OTP Verified",
                    message: "Otp verified successfully",
                });
                navigate("/auth/reset-password", { state: { token: response.data?.token } })
            }
        } catch (error: any) {
            console.error(error);
            addNotification({
                type: "error",
                title: "Invalid OTP",
                message: error?.response?.data?.message,
            });
        } finally {
            setLoading(false);
        }
    };

    const handleResendOtp = async () => {
        try {
            setResendLoading(true);
            await forgotPassword(email);
            addNotification({
                type: "success",
                title: "OTP Resent",
                message: "A new OTP has been sent to your email.",
            });
            setTimer(30);
        } catch (error) {
            addNotification({
                type: "error",
                title: "Failed to resend OTP",
            });
        } finally {
            setResendLoading(false);
        }
    };

    return (
        <AnimatePresence>
            {animate && (
                <motion.div {...animations}>
                    <Box
                        className="otp-form"
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
                            Verify OTP
                        </Typography>
                        <Typography variant="body2" color="text.secondary" mb={3}>
                            Please enter the 4-digit OTP sent to your email.
                        </Typography>

                        <Form<OtpValues> onSubmit={handleSubmit} schema={schema}>
                            {({ register, formState }) => (
                                <>
                                    <InputField
                                        type="text"
                                        label="Enter OTP"
                                        placeholder="Please enter OTP"
                                        error={formState.errors["otp"]}
                                        registration={register("otp", {
                                            required: "OTP is required",
                                        })}
                                        onlyNumbers
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
                                                "Verify OTP"
                                            )}
                                        </Button>
                                    </Box>
                                </>
                            )}
                        </Form>

                        <Box textAlign="center" mt={3}>
                            <Typography fontSize={14} color="text.secondary">
                                Didn’t receive OTP?
                            </Typography>

                            <Button
                                onClick={handleResendOtp}
                                disabled={timer > 0 || resendLoading}
                                sx={{
                                    mt: 1,
                                    color: "#1B2447",
                                    textTransform: "none",
                                    fontWeight: 500,
                                }}
                            >
                                {resendLoading ? (
                                    <CircularProgress size={18} sx={{ color: "#1B2447" }} />
                                ) : timer > 0 ? (
                                    `Resend OTP in ${timer}s`
                                ) : (
                                    "Resend OTP"
                                )}
                            </Button>
                        </Box>
                    </Box>
                </motion.div>
            )}
        </AnimatePresence>
    );
};
