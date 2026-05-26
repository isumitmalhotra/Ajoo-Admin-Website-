const yup = require("yup");

exports.createOrUpdateTagSchema = yup.object({
  tagId: yup
    .number()
    .typeError("Tag ID must be a number")
    .integer("Tag ID must be an integer")
    .positive("Tag ID must be greater than zero")
    .nullable()
    .optional(),

  tag_name: yup
    .string()
    .trim()
    .min(2, "Tag title must be at least 2 characters")
    .max(200, "Tag title cannot exceed 200 characters")
    .required("Tag title is required"),

  tag_isActive: yup
    .string()
    .oneOf(["0", "1"], "Tag status must be 0 (Inactive) or 1 (Active)")
    .required("Tag status is required"),
});
exports.deteletTagSchema = yup.object({
    tagId: yup
      .number()
      .typeError("Tag ID must be a number")
      .integer("Tag ID must be an integer")
      .positive("Tag ID must be greater than zero")
      .required("Tag ID is required")
});


exports.tagListingSchema = yup.object({
  page: yup
    .number()
    .integer("Page must be an integer")
    .min(1, "Page must be greater than 0")
    .optional(),

  limit: yup
    .number()
    .integer("Limit must be an integer")
    .min(1, "Limit must be greater than 0")
    .max(100, "Limit cannot exceed 100")
    .optional(),

  search: yup
    .string()
    .trim()
    .min(1, "Search must not be empty")
    .optional(),

  status: yup
    .mixed()
    .oneOf(["0", "1", 0, 1], "Status must be 0 or 1")
    .optional(),
});

exports.updateTagStatusSchema = yup.object({
    tagId: yup
      .number()
      .integer("Tag ID must be an integer")
      .positive("Tag ID must be greater than 0")
      .required("Tag ID is required"),
  
    tag_isActive: yup
      .string()
      .oneOf(["0", "1"], "Status must be 0 or 1")
      .required("Status is required"),
  });

