const yup = require("yup");

exports.createUserSchema = yup.object().shape({
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

    // user_dob: yup
    //     .string()
    //     .required("Date of birth is required")
    //     .matches(
    //         /^(0[1-9]|[12][0-9]|3[01])\/(0[1-9]|1[0-2])\/(\d{2}|\d{4})$/,
    //         "Date must be in DD/MM/YY or DD/MM/YYYY format"
    //     )
    //     .transform((value) => {
    //         if (!value) return value; // 🔐 guard

    //         const parts = value.split("/");
    //         if (parts.length !== 3) return value;

    //         const [day, month, year] = parts;
    //         const fullYear = year.length === 2 ? `20${year}` : year;

    //         return `${fullYear}-${month}-${day}`;
    //     }),


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

    // user_isVerified: yup
    //     .number()
    //     .required("user_isVerified is required"),

    cred_username: yup
        .string()
        .trim()
        .min(4, "Username must be at least 4 characters"),
        // .required("Username is required"),

    cred_user_email: yup
        .string()
        .email("Invalid email address")
        .required("Email is required"),

    // cred_user_password: yup
    //     .string()
    //     .min(8, "Password must be at least 8 characters")
    //     .matches(
    //         /^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])/,
    //         "Password must contain at least one letter, one number, and one special character"
    //     ),
        // .required("Password is required"),

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



