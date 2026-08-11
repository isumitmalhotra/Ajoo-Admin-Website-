const yup = require("yup");
const { optionalChoice, optionalInteger, optionalNullableNumber, optionalString } = require("./yupHelpers");

exports.propertyCategorySchema = yup.object().shape({
    categoryId: optionalNullableNumber("Category ID must be a number"),

    cat_title: yup
        .string()
        .trim()
        .min(2, "Category name too short")
        .max(200, "Category name too long")
        .required("Category name is required"),

    cat_isActive: yup
        .string()
        .oneOf(["0", "1"], "Status must be either 0 (Inactive) or 1 (Active)")
        .required("Status is required"),

});
exports.categoryId = yup.object().shape({
    categoryId: yup
        .number()
        .required("Category ID is required"),
});

exports.updateCategoryStatusSchema = yup.object({
    categoryId: yup
        .number()
        .typeError("Category ID must be a number")
        .integer("Category ID must be an integer")
        .positive("Category ID must be greater than zero")
        .required("Category ID is required"),

    status: yup
        .string()
        .oneOf(["0", "1"], "Status must be either 0 (Inactive) or 1 (Active)")
        .required("Status is required"),

});

exports.categoryListingSchema = yup.object({
    page: optionalInteger().min(1, "Page must be greater than 0").max(100000, "Page is too large"),
    limit: optionalInteger().min(1, "Limit must be greater than 0").max(100, "Limit cannot exceed 100"),
    search: optionalString({ max: 100 }).max(100, "Search cannot exceed 100 characters"),
    status: optionalChoice(["0", "1", 0, 1], "Status must be 0 or 1"),
});

// module.exports = { propertyCategorySchema };
