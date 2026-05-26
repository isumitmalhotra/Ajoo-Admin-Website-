const yup = require("yup");

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
        .typeError("status id must be a nu  mber")
        .required("status id is required"),
    bookingId: yup
        .string()
        .typeError("bookingId must be a number")
        .required("bookingId is required")
});