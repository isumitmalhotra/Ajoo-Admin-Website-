const yup = require("yup");
const { optionalInteger, optionalNullableNumber, optionalString } = require("./yupHelpers");

exports.termsConditionSchema = yup.object().shape({
    tc_id: optionalNullableNumber("Id must be a number")
        .integer("Id must be an integer")
        .positive("Id must be a positive number"),

    tc_title: yup
        .string()
        .trim()
        .max(255, "Title must be less than 255 characters")
        .required("Title is required"),

    tc_description: yup
        .string()
        .trim()
        .required("Description is required"),

    tc_type: yup
        .number()
        .integer()
        .required("Type is required"),

    tc_isActive: yup
        .number()
        .oneOf([0, 1], "Status must be 0 or 1")
        .required("Status is required"),
});
exports.termsConditionIdSchema = yup.object().shape({
    tc_id: yup
        .number()
        .integer()
        .required("Id is required")
});

exports.termsListingSchema = yup.object().shape({
    page: optionalInteger().min(1, "Page must be greater than 0").max(100000, "Page is too large"),
    limit: optionalInteger().min(1, "Limit must be greater than 0").max(100, "Limit cannot exceed 100"),
    search: optionalString({ max: 100 }).max(100, "Search cannot exceed 100 characters"),
});


