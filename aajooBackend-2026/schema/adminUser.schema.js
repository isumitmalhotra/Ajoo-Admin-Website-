const yup = require("yup");
const {
    optionalChoice,
    optionalInteger,
    optionalNullableNumber,
    optionalString,
} = require("./yupHelpers");

exports.createUserSchema = yup.object().shape({
    userId: optionalNullableNumber("User ID must be a number")
        .integer("User ID must be an integer")
        .positive("User ID must be greater than zero"),

    afileId: optionalNullableNumber("Attachment ID must be a number")
        .integer("Attachment ID must be an integer")
        .positive("Attachment ID must be greater than zero"),

    user_fullName: yup
        .string()
        .trim()
        .min(3, "Full name must be at least 3 characters")
        .max(100, "Full name is too long")
        .required("Full name is required"),

    user_pnumber: yup
        .string()
        .matches(/^[0-9]{10}$/, "Phone number must be 10 digits")
        .required("Phone number is required"),

    user_dob: yup
        .string()
        .required("Date of birth is required")
        .matches(
            /^\d{4}-\d{2}-\d{2}$/,
            "Date must be in YYYY-MM-DD format (e.g., 2026-04-14)"
        ),


    user_address: yup
        .string()
        .trim()
        .min(5, "Address is too short")
        .required("Address is required"),

    user_city: yup
        .string()
        .trim()
        .required("City is required"),

    user_zipcode: yup
        .string()
        .matches(/^[0-9]{5,6}$/, "Invalid zipcode")
        .required("Zipcode is required"),

    user_isHost: yup
        .number()
        .required("user_isHost is required"),

    user_isUser: yup
        .number()
        .required("user_isUser is required"),

    user_isActive: yup
        .number()
        .required("user_isActive is required"),

    user_isVerified: yup
        .number()
        .required("user_isVerified is required"),

    cred_username: yup
        .string()
        .trim()
        .min(4, "Username must be at least 4 characters"),
        // .required("Username is required"),

    cred_user_email: yup
        .string()
        .email("Invalid email address")
        .required("Email is required"),

    cred_user_password: yup
        .string()
        .transform((value, originalValue) => {
            if (typeof originalValue === "string" && originalValue.trim() === "") {
                return undefined;
            }
            return value;
        })
        .trim()
        .min(8, "Password must be at least 8 characters")
        .matches(
            /^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])/,
            "Password must contain at least one letter, one number, and one special character"
        )
        .when("userId", {
            is: (userId) => !userId,
            then: (schema) => schema.required("Password is required"),
            otherwise: (schema) => schema.optional(),
        }),

    cred_user_doc_type: yup
        .number()
        .oneOf([1, 2, 3], "Invalid document type")
        .required("Document type is required"),

    cred_user_doc_number: yup
        .string()
        .required("Document number is required")
        .when("cred_user_doc_type", (docType, schema) => {
            if (docType === 1) {
                // Aadhaar
                return schema.matches(/^\d{12}$/, "Aadhaar number must be 12 digits");
            }

            if (docType === 2) {
                // Driving License
                return schema.matches(
                    /^[A-Z]{2}[0-9]{13}$/,
                    "Driving License must be like MH0123456789012"
                );
            }

            if (docType === 3) {
                // Passport
                return schema.matches(
                    /^[A-Z][0-9]{7}$/,
                    "Passport must be like A1234567"
                );
            }

            return schema;
        }),


    cred_user_refrel: yup
        .string()
        .nullable()
        .trim(),
});

exports.deleteImage = yup.object().shape({
    afileId: yup
        .number()
        .required("Attachment ID is required"),
});

exports.updateStatus = yup.object().shape({
    userId: yup
        .number()
        .required("User ID is required"),
    isActive: yup
        .number()
        .oneOf([0, 1], "isActive must be 0 or 1")
        .required("isActive status is required"),
});
exports.verifyUser = yup.object().shape({
    userId: yup
        .number()
        .required("User ID is required"),
    verifyStatus: yup
        .number()
        .oneOf([0, 1], "isVerified must be 0 or 1")
        .required("isVerified status is required"),
});

exports.userId =  yup.object().shape({
    userId: yup
        .number()
        .required("User ID is required"),
});

exports.hostSearchSchema = yup.object().shape({
    page: optionalInteger().min(1, "Page must be greater than 0").max(100000, "Page is too large"),
    limit: optionalInteger().min(1, "Limit must be greater than 0").max(100, "Limit cannot exceed 100"),
    search: optionalString({ max: 100 }).max(100, "Search cannot exceed 100 characters"),
    status: optionalChoice(["0", "1", 0, 1], "Status must be 0 or 1"),
    user_isVerified: optionalChoice(["0", "1", 0, 1], "Verified status must be 0 or 1"),
});

exports.hostAssignPropertySearchSchema = yup.object().shape({
    search: optionalString({ max: 100 }).max(100, "Search cannot exceed 100 characters"),
});

exports.userSearchSchema = yup.object().shape({
    page: optionalInteger().min(1, "Page must be greater than 0").max(100000, "Page is too large"),
    limit: optionalInteger().min(1, "Limit must be greater than 0").max(100, "Limit cannot exceed 100"),
    search: optionalString({ max: 100 }).max(100, "Search cannot exceed 100 characters"),
    status: optionalChoice(["0", "1", 0, 1], "Status must be 0 or 1"),
});



