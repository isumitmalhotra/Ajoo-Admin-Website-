const yup = require("yup");

exports.propertyCategorySchema = yup.object().shape({
    categoryId: yup.number().nullable(),

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

// module.exports = { propertyCategorySchema };
