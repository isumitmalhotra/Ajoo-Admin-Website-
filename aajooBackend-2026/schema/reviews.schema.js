const yup = require("yup");

exports.reviewId = yup.object({
    reviewId: yup
        .number()
        .required("Review Id Is Required")
});
exports.userReviewAddedByHost = yup.object({
    bookingId: yup
        .string()
        .required("Booking id Is Required"),
    title: yup
        .string()
        .required("Title Is Required"),
    description: yup
        .string()
        .required("Description Is Required"),
    rating: yup
        .number()
        .required("Rating Is Required")
});
exports.checkoutSchema = yup.object({
    bookingId: yup
        .string()
        .required("Booking id Is Required"),
    desription: yup
        .string(),
    propertyRating: yup
        .number()
        .required("Property Rating Is Required"),
    hostRating: yup
        .number()
        .required("Host Rating Is Required"),
    platformRating: yup
        .number()
        .required("Platform Rating Is Required")
});