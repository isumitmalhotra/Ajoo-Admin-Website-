const yup = require("yup");
const { optionalChoice, optionalDate, optionalInteger, optionalString } = require("./yupHelpers");

exports.bookingId = yup.object({
    bookingId: yup
        .string()
        .typeError("bookingId must be a number")
        .required("bookingId is required")
});
exports.statusUpdate = yup.object({
    bs_id: yup
        .number()
        .typeError("status id must be a number")
        .required("status id is required"),
    bs_title: yup
        .string()
        .typeError("status title must be a string")
        .required("status title is required"),
    bs_code: yup
        .string()
        .typeError("status code must be a string")
        .required("status code is required")
});
exports.bookingStatusUpdate = yup.object({
    statusId: yup
        .number()
        .typeError("status id must be a number")
        .required("status id is required"),
    bookingId: yup
        .string()
        .typeError("bookingId must be a number")
        .required("bookingId is required")
});

exports.bookingSearchSchema = yup.object({
    page: optionalInteger().min(1, "Page must be greater than 0").max(100000, "Page is too large"),
    limit: optionalInteger().min(1, "Limit must be greater than 0").max(100, "Limit cannot exceed 100"),
    search: optionalString({ max: 100 }).max(100, "Search cannot exceed 100 characters"),
    status: optionalInteger(),
    paymentStatus: optionalChoice(["0", "1", 0, 1], "Payment status must be 0 or 1"),
    fromDate: optionalDate("fromDate must be a valid date"),
    toDate: optionalDate("toDate must be a valid date"),
});

exports.bookingStatusListingSchema = yup.object({
    page: optionalInteger().min(1, "Page must be greater than 0").max(100000, "Page is too large"),
    limit: optionalInteger().min(1, "Limit must be greater than 0").max(100, "Limit cannot exceed 100"),
});
