const yup = require("yup");

exports.createBooking = yup.object({
    propertyId: yup
        .number()
        .required("property id is required"),
    price: yup
        .number()
        .required('Price is required') // Ensures the price field is provided
        .min(0, 'Price cannot be negative') // Ensures price is non-negative
        .test(
            'is-decimal',
            'Price must be a valid decimal value',
            (value) => /^\d+(\.\d{1,2})?$/.test(value) // Validates up to two decimal places
        ),
    bookFrom: yup
        .string()
        .required("check in date is required"),
    bookTo: yup
        .string()
        .required("check out date is required"),
    isCod: yup
        .boolean()
        .required("cod flag is required"),
    no_of_guests: yup
        .number()
        .integer("Number of guests must be an integer")
        .min(1, "Number of guests must be at least 1")
        .optional(),
    no_of_beds: yup
        .number()
        .integer("Number of beds must be an integer")
        .min(1, "Number of beds must be at least 1")
        .optional()
});
exports.payment = yup.object({
    pay_bookId: yup
        .string()
        .required("Booking ID is required"),// Validate as a required number
    // .positive("Booking ID must be a positive number"),
    pay_userId: yup
        .number()
        .required("User ID is required") // Validate as a required number
        .positive("User ID must be a positive number"),
    pay_propId: yup
        .number()
        .required("Property ID is required") // Validate as a required number
        .positive("Property ID must be a positive number"),
    pay_hostId: yup
        .number()
        .required("Host ID is required") // Validate as a required number
        .positive("Host ID must be a positive number"),
    pay_invoice: yup
        .string()
        .required("Invoice number is required"), // Validate as a required string
    // .matches(/^[a-zA-Z0-9_-]+$/, "Invoice must contain only alphanumeric characters, dashes, or underscores"),
    pay_amount: yup
        .number()
        .required("Payment amount is required") // Validate as a required number
        .positive("Payment amount must be a positive number"),
})
exports.verifyPayment = yup.object({
    paymentId: yup
        .string()
        .required("payment id is required"),
    orderId: yup
        .string()
        .required("order id is required"),
    signature: yup
        .string()
        .required("signature is required")
});
exports.cancelBooking = yup.object({
    bookingId: yup
        .string()
        .required("Booking id is required"),
});
exports.ongoingBookingPayment = yup.object({
    bookingId: yup
        .string()
        .required("Booking id is required")
});

