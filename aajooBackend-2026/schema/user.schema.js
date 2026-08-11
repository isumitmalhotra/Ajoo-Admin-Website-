const yup = require("yup");

exports.createUser = yup.object({
    user_fullName: yup
        .string()
        .required('First name is required')
        .min(2, 'First name must be at least 2 characters')
        .max(50, 'First name must be less than 50 characters'),

    user_username: yup
        .string(),

    user_dob: yup
        .string()
        .required("date of birth is required"),

    // NOTE: user_email MUST be declared here. The validation middleware
    // sanitizes req.body to only schema-known keys (stripUnknown), so any
    // field omitted here is removed before the controller runs — which caused
    // signup to fail with "Missing required fields" even though the client
    // sent the email.
    user_email: yup
        .string()
        .email('Must be a valid email')
        .required('Email is required'),

    user_password: yup
        .string()
        .required('Password is required')
        .min(8, 'Password must be at least 8 characters')
        .matches(/[a-zA-Z]/, 'Password must contain both uppercase and lowercase letters')
        .matches(/\d/, 'Password must contain at least one number'),

    user_confirmPassword: yup
        .string()
        .oneOf([yup.ref('user_password'), null], 'Passwords must match')
        .required('Please confirm your password'),

    user_pnumber: yup
        .string()
        .required('Phone number is required')
        .matches(/^\d{10}$/, 'Phone number must be exactly 10 digits'),

    user_address: yup
        .string()
        .required('Address is required'),

    user_city: yup
        .string(),
    // .required('City is required'),

    user_zipcode: yup
        .string(),
    // .required('Zipcode is required'),

    user_isHost: yup
        .boolean()
        .required('Host status is required')
        .oneOf([true, false], 'Host status must be true or false'),

    doc_type: yup
        .number()
        .required('document type is required'),

    doc_number: yup
        .string()
        .required("Document number is required")
        .when("doc_type", {
            is: 1, // Aadhaar card
            then: (schema) =>
                schema.matches(/^\d{12}$/, "Aadhaar number must be exactly 12 digits"),
        })
        .when("doc_type", {
            is: 2, // Voter card
            then: (schema) =>
                schema.matches(/^[A-Z]{3}\d{7}$/, "Voter ID must be 3 letters followed by 7 digits (e.g., ABC1234567)"),
        })
        .when("doc_type", {
            is: 3, // Driving licence
            then: (schema) =>
                schema.matches(/^[A-Z]{2}\d{13}$/, "Driving licence must be in format: 2 letters + 13 digits (e.g., DL1420110023456)"),
        }),

    // Optional referral code. Declared so stripUnknown keeps it in req.body.
    user_ref: yup
        .string()
        .nullable()
        .optional(),
});

exports.updateUser = yup.object({
    user_fullName: yup
        .string()
        .min(2, "First name must be at least 2 characters")
        .max(50, "First name must be less than 50 characters"),

    user_pnumber: yup
        .string()
        .matches(/^\d{10}$/, "Phone number must be exactly 10 digits"),

    user_address: yup.string(),

    user_city: yup.string(),

    doc_type: yup
        .number()
        .required("Document type is required"),

    doc_number: yup
        .string()
        .required("Document number is required")
        .when("doc_type", {
            is: 1, // Aadhaar card
            then: (schema) =>
                schema.matches(/^\d{12}$/, "Aadhaar number must be exactly 12 digits"),
        })
        .when("doc_type", {
            is: 2, // Voter ID
            then: (schema) =>
                schema.matches(/^[A-Z]{3}\d{7}$/, "Voter ID must be 3 letters followed by 7 digits (e.g., ABC1234567)"),
        })
        .when("doc_type", {
            is: 3, // Driving Licence
            then: (schema) =>
                schema.matches(/^[A-Z]{2}\d{13}$/, "Driving licence must be in format: 2 letters + 13 digits (e.g., DL1420110023456)"),
        }),
});

exports.login = yup.object({
    user_email: yup
        .string()
        .email('Must be a valid email')
        .required('Email is required'),

    user_password: yup
        .string()
        .required('Password is required')
        .min(8, 'Password must be at least 8 characters')
        .matches(/[a-zA-Z]/, 'Password must contain both uppercase and lowercase letters')
        .matches(/\d/, 'Password must contain at least one number'),
    isHost: yup
        .boolean()
        .required('isHost is required')
        .oneOf([true, false], 'isHost must be a boolean value (true or false)'),
});
exports.isUserExist = yup.object({
    userEmail: yup
        .string()
        .email('Must be a valid email')
        .required('Email is required'),
});
exports.userId = yup.object({
    userId: yup
        .number()
        .required("user id is required")
});
exports.verifyOtp = yup.object({
    userId: yup
        .number()
        .required("user id is required"),
    otp: yup
        .string()
        .required("OTP is required")
});
exports.updateForgetPasswordOtp = yup.object({
    otp: yup
        .string()
        .required("OTP is required")
})
exports.forgotPassword = yup.object({
    userEmail: yup
        .string()
        .email("is should be email")
        .required("email is required")
});
exports.updateForgetPassword = yup.object({
    newPassword: yup
        .string()
        .required('Password is required')
        .min(8, 'Password must be at least 8 characters')
        .matches(/[a-z]/, 'Password must contain at least one lowercase letter')
        .matches(/[A-Z]/, 'Password must contain at least one uppercase letter')
        .matches(/\d/, 'Password must contain at least one number'),
    confirmPassword: yup
        .string()
        .required('Confirm password is required')
        .oneOf([yup.ref('newPassword'), null], 'Passwords must match'),
});
exports.savedPropList = yup.object({
    // userId comes from the JWT (req.user.userId) — never trusted from body.
    // propId removed because this endpoint lists ALL of a user's saved
    // properties; filtering to one prop was a leftover design bug.
    // Pagination is optional.
    limit: yup.number().integer().min(1).max(100).notRequired(),
    page: yup.number().integer().min(1).notRequired(),
});
exports.verifyOptForgetPass = yup.object({
    otp: yup
        .string()
        .required("token is required"),
    userEmail: yup
        .string()
        .required("email is required")
});
exports.token = yup.object({
    token: yup
        .string()
        .trim() // removes extra spaces
        .required("Token is required")
        .min(10, "Token seems too short — must be at least 10 characters")
        .max(1000, "Token seems too long — must be less than 1000 characters"),
});


exports.updatePassword = yup.object({
    userId: yup
        .number()
        .required("user id is required"),
    newPassword: yup
        .string()
        .required('Password is required')
        .min(8, 'Password must be at least 8 characters long')
        .matches(/[A-Z]/, 'Password must include at least one uppercase letter')
        .matches(/[a-z]/, 'Password must include at least one lowercase letter')
        .matches(/\d/, 'Password must include at least one number')
        .matches(/[!@#$%^&*(),.?":{}|<>]/, 'Password must include at least one special character')
        .matches(/^\S*$/, 'Password must not contain spaces'),
    currentPassword: yup
        .string()
        .required("current password is required"),
    confirmPassword: yup
        .string()
        .required("confirm password is required")
        .oneOf([yup.ref('newPassword'), null], 'Passwords must match'),
});
exports.addUpdateReview = yup.object({
    propertyId: yup
        .number()
        .required("property id is required"),
    rating: yup
        .number()
        .required("rating is required"),
    description: yup
        .string()
        .required("description is required"),
});
exports.allowNotification = yup.object({
    deviceToken: yup
        .string()
        .required("Device token is required")
});
exports.markReadNotification = yup.object({
    notificationId: yup
        .array()
        .of(yup.number().required("Each notification id must be a number"))
        .min(1, "At least one notification id is required")
        .required("Notification id is required"),
});

//Host-Schema------------------------------------------>

exports.confirmBook = yup.object({
    bookPriId: yup.
        number()
        .required("booking id is required"),
});
exports.ongoing = yup.object({
    hostId: yup
        .number()
        .required("id is required")
});
exports.hostId = yup.object({
    hostId: yup
        .number()
        .required("host id is required")
});
exports.updateStatus = yup.object({
    propertyId: yup
        .number()
        .required("property id is required"),
    status: yup
        .boolean()
        .required("status is required")

});
exports.propertyId = yup.object({
    propertyId: yup
        .number()
        .required("property id is required"),
});