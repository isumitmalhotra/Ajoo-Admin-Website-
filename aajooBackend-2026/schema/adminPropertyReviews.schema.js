const yup = require("yup");
const { optionalChoice, optionalString } = require("./yupHelpers");

exports.reviewSearchSchema = yup.object().shape({
    keyword: optionalString()
        .typeError("Search must be text")
        .notRequired(),

    status: optionalChoice([0, 1, 2, "0", "1", "2"], "Status must be 0, 1, or 2")
        .notRequired(),

    rating: optionalChoice([1, 2, 3, 4, 5, "1", "2", "3", "4", "5"], "Rating must be between 1 and 5")
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

exports.reviewIdSchema = yup.object().shape({
    reviewId: yup
        .number()
        .integer("Review ID must be an integer")
        .positive("Review ID must be greater than 0")
        .required("Review ID is required"),
});

// module.exports = reviewSearchSchema;
