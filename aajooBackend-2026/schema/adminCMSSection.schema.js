const yup = require("yup");

exports.cmsSchema = yup.object().shape({
  cs_title: yup
    .string()
    .trim()
    .required("Title is required"),

  cs_description: yup
    .string()
    .trim()
    .nullable(),

  cs_isActive: yup
    .number()
    .oneOf([0, 1], "Status must be 0 or 1")
    .typeError("Status must be a number")
    .required("Status is required"),
  cs_order: yup
    .number()
    .typeError("Order must be a number")
    .required("Order is required"),
  cs_url: yup
    .string()
    .trim()
    .required("URL is required")
});

exports.homeCMSchema = yup.object().shape({
  cp_page_id: yup.number().required(),

  featureTitle: yup.string().required(),
  featureDesc: yup.string().required(),

  properties: yup.mixed().nullable(),

  labelTitle: yup.string().required(),
  labelDesc: yup.string().required(),
  buttonTitle: yup.string().nullable(),
  buttonUrl: yup.string().nullable(),
  buttonTarget: yup.string().oneOf(['_self', '_blank']),

  testimonialTitle: yup.string().required(),
  testimonialDesc: yup.string().required(),
  testimonials: yup.mixed().nullable()
});

exports.cmsIdsSchema = yup.object().shape({
  cp_page_id: yup
    .number()
    .typeError("Page ID must be a number")
    .required("Page ID is required"),

  cp_section_id: yup
    .number()
    .typeError("Section ID must be a number")
    .required("Section ID is required"),
});

exports.faqCMSValidation = yup.object().shape({
  cp_page_id: yup
    .number()
    .required("Page ID is required"),

  headerTitle: yup.string().nullable(),
  headerDesc: yup.string().nullable(),

  contactTitle: yup.string().nullable(),
  contactDesc: yup.string().nullable(),
  contactBtnTitle: yup.string().nullable(),
  contactBtnUrl: yup.string().nullable(),
  contactTarget: yup.string().nullable(),

  // Label Section
  labelTitle: yup.string().nullable(),
  labelDesc: yup.string().nullable(),
  labelBtnTitle: yup.string().nullable(),
  labelBtnUrl: yup.string().nullable(),
  labelTarget: yup.string().nullable()
});


exports.tcCMSValidation = yup.object().shape({
  cp_page_id: yup
    .number()
    .required("Page ID is required"),
  headerTitle: yup.string().nullable(),
  headerDesc: yup.string().nullable(),
  labelTitle: yup.string().nullable(),
  labelDesc: yup.string().nullable()
});
