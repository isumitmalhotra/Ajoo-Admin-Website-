const yup = require("yup");

exports.reviewSearchSchema = yup.object().shape({
    keyword: yup
        .string()
        .trim()
        .typeError("Search must be text")
        .notRequired(),

    status: yup
        .number()
        .oneOf([0, 1, 2], "Status must be 0, 1, or 2")
        .typeError("Status must be a number")
        .notRequired(),

    rating: yup
        .number()
        .min(1, "Rating must be at least 1")
        .max(5, "Rating cannot be more than 5")
        .typeError("Rating must be a number")
        .notRequired(),
});
exports.updateBookingStatusSchema = yup.object().shape({
    status: yup
        .number()
        .oneOf([0, 1, 2], "Status must be 0, 1, or 2")
        .required("Status is required")
        .typeError("Status must be a number"),

    bookingId: yup
        .string()
        .trim()
        .required("BookingId is required")
        .typeError("BookingId must be a string"),
});

// module.exports = reviewSearchSchema;