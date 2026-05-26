const yup = require("yup");

exports.couponId = yup.object().shape({
  cpn_id: yup
    .number()
    .typeError("Coupon ID must be a number")
    .required("Coupon ID is required"),
})
exports.updateStatus = yup.object().shape({
  cpn_id: yup
    .number()
    .typeError("Coupon ID must be a number")
    .required("Coupon ID is required"),
  cpn_status: yup
    .number()
    .oneOf([0, 1, 2], "Status must be 0, 1, or 2")
    .required("Coupon status is required"),
})

exports.couponAddSchema = yup.object().shape({
  cpn_title: yup
    .string()
    .trim()
    .required("Coupon title is required"),

  cpn_code: yup
    .string()
    .trim()
    .uppercase()
    .required("Coupon code is required"),

  cpn_dsctn_type: yup
    .number()
    .oneOf([1, 2], "Discount type must be 1 (percentage) or 2 (amount)")
    .required("Discount type is required"),

  cpn_dsctn_percnt: yup
    .number()
    .typeError("Discount percent must be a number")
    .required("Discount percent is required")
    .min(0, "Discount percent cannot be negative")
    .max(100, "Discount percent cannot exceed 100"),

  cpn_dsctn_amt: yup
    .number()
    .typeError("Discount amount must be a number")
    .nullable(),

  cpn_min_amt: yup
    .number()
    .typeError("Minimum amount must be a number")
    .nullable(),

  cpn_max_amt: yup
    .number()
    .typeError("Maximum amount must be a number")
    .nullable(),

  cpn_valid_from: yup
    .date()
    .typeError("Valid from must be a valid date")
    .nullable(),

  cpn_valid_to: yup
    .date()
    .typeError("Valid to must be a valid date")
    .nullable(),

  cpn_usage_limit: yup
    .number()
    .typeError("Usage limit must be a number")
    .nullable(),

  cpn_used_count: yup
    .number()
    .typeError("Used count must be a number")
    .nullable(),

  cpn_status: yup
    .number()
    .oneOf([0, 1, 2], "Status must be 0, 1, or 2")
    .required("Coupon status is required"),
});

