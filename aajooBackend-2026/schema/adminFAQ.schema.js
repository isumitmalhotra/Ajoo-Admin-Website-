const yup = require("yup");

exports.faqId = yup
    .object({
        faq_id: yup
            .number()
            .typeError("FAQ Id must be a number")
            .required("FAQ Id is required")
            .integer("FAQ Id must be an integer")
            .positive("FAQ Id must be a positive number"),
    })
    .noUnknown(true, "Unknown fields are not allowed");
exports.faqSchema = yup.object().shape({
    faq_id: yup
        .number()
        .integer()
        .nullable()
        .notRequired(),

    faq_question: yup
        .string()
        .trim()
        .max(255, "FAQ question must be less than 255 characters")
        .required("FAQ question is required"),

    faq_answer: yup
        .string()
        .trim()
        .required("FAQ answer is required"),

    faq_category: yup
        .string()
        .trim()
        .max(100, "Category must be less than 100 characters"),
    // .required("FAQ category is required"),

    faq_display_order: yup
        .number()
        .integer()
        .min(0, "Display order must be 0 or greater")
        .required("Display order is required"),

    faq_is_active: yup
        .number()
        .oneOf([0, 1], "Status must be 0 or 1")
        .required("FAQ status is required"),
});

// module.exports = faqSchema;