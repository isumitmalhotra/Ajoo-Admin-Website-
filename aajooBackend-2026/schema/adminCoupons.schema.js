const yup = require("yup");
const { optionalDate, optionalInteger, optionalNullableNumber, optionalString } = require("./yupHelpers");

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
  cpn_id: optionalNullableNumber("Coupon ID must be a number"),

  cpn_title: yup
    .string()
    .trim()
    .required("Coupon title is required"),

  cpn_type: optionalNullableNumber("Coupon type must be a number"),

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

  cpn_dsctn_amt: optionalNullableNumber("Discount amount must be a number"),

  cpn_min_amt: optionalNullableNumber("Minimum amount must be a number"),

  cpn_max_amt: optionalNullableNumber("Maximum amount must be a number"),

  cpn_valid_from: optionalDate("Valid from must be a valid date").nullable(),

  cpn_valid_to: optionalDate("Valid to must be a valid date").nullable(),

  cpn_usage_limit: optionalNullableNumber("Usage limit must be a number"),

  cpn_used_count: optionalNullableNumber("Used count must be a number"),

  cpn_status: yup
    .number()
    .oneOf([0, 1, 2], "Status must be 0, 1, or 2")
    .required("Coupon status is required"),
});

exports.couponListingSchema = yup.object().shape({
  page: optionalInteger().min(1, "Page must be greater than 0").max(100000, "Page is too large"),
  limit: optionalInteger().min(1, "Limit must be greater than 0").max(100, "Limit cannot exceed 100"),
  search: optionalString({ max: 100 }).max(100, "Search cannot exceed 100 characters"),
});

