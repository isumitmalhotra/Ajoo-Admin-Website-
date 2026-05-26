const yup = require("yup");

exports.termsConditionSchema = yup.object().shape({
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


