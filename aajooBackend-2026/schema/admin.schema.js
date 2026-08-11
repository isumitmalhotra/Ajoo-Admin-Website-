const yup = require("yup");

exports.adminLogin = yup.object({
    username: yup
        .string()
        .required("username is required"),
    password: yup
        .string()
        .required("password is required"),

});

exports.adminCreate = yup.object({
    admin_name: yup
        .string()
        .trim()
        .min(3, "Admin name must be at least 3 characters")
        .max(100, "Admin name cannot exceed 100 characters")
        .required("admin_name is required"),
    admin_username: yup
        .string()
        .transform((value, originalValue) => {
            if (typeof originalValue === "string" && originalValue.trim() === "") {
                return undefined;
            }
            return value;
        })
        .trim()
        .min(3, "Admin username must be at least 3 characters")
        .max(100, "Admin username cannot exceed 100 characters")
        .optional(),
    admin_email: yup
        .string()
        .trim()
        .lowercase()
        .email("Valid admin_email is required")
        .required("admin_email is required"),
    admin_password: yup
        .string()
        .trim()
        .min(8, "Admin password must be at least 8 characters")
        .matches(
            /^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])/,
            "Admin password must contain at least one letter, one number, and one special character"
        )
        .required("admin_password is required"),
    admin_isAdmin: yup
        .number()
        .transform((value, originalValue) => {
            if (originalValue === "" || originalValue === null || originalValue === undefined) {
                return undefined;
            }
            return Number(originalValue);
        })
        .oneOf([0, 1], "admin_isAdmin must be 0 or 1")
        .optional(),
    admin_isActive: yup
        .number()
        .transform((value, originalValue) => {
            if (originalValue === "" || originalValue === null || originalValue === undefined) {
                return undefined;
            }
            return Number(originalValue);
        })
        .oneOf([0, 1], "admin_isActive must be 0 or 1")
        .optional(),
});
