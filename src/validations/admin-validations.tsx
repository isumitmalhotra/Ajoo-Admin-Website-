import * as Yup from "yup";

export const setupCategorySchema = Yup.object({
  cat_title: Yup.string().required("Title is required"),
  cat_isActive: Yup.string().required("Status is required"),
});

export const setupAmenitySchema = Yup.object({
  amn_title: Yup.string().required("Full name is required"),
  amn_isActive: Yup.string().required("Status is required"),
});

export const setupTagSchema = Yup.object({
  tag_name: Yup.string().required("Full name is required"),
  tag_isActive: Yup.string().required("Status is required"),
});

export const reviewSchema = Yup.object({
  status: Yup.string().required("Status is required"),
});

// import * as Yup from "yup";

export const setupPropertySchema = Yup.object({
  /* ---------- BASIC INFO ---------- */
  name: Yup.string().required("Property name is required"),

  hostId: Yup.number()
    .typeError("Host is required") // catches NaN
    .required("Host is required")
    .nullable(), // allows null for unselected state

  description: Yup.string().required("Description is required"),

  /* ---------- LOCATION ---------- */
  address: Yup.string().required("Address is required"),
  city: Yup.string().required("City is required"),
  state: Yup.string().required("State is required"),
  country: Yup.string().required("Country is required"),
  zip_code: Yup.string().required("Zip Code is required"),

  latitude: Yup.string().required("Latitude is required"),
  longitude: Yup.string().required("Longitude is required"),

  /* ---------- CONTACT ---------- */
  email: Yup.string().email("Invalid email").required("Email is required"),

  phone: Yup.string()
    .matches(/^[0-9]{10}$/, "Enter valid 10-digit number")
    .required("Phone is required"),

  /* ---------- PRICING ---------- */
  price: Yup.number()
    .typeError("Price must be a number")
    .required("Price is required"),

  minimum_price: Yup.number()
    .typeError("Minimum price must be a number")
    .required("Minimum Price is required"),

  weekly_minimum_price: Yup.number()
    .typeError("Weekly minimum price must be a number")
    .required("Weekly Minimum Price is required"),

  weekly_maximum_price: Yup.number()
    .typeError("Weekly maximum price must be a number")
    .required("Weekly Maximum Price is required"),

  monthly_security: Yup.number()
    .typeError("Monthly security must be a number")
    .required("Monthly Security is required"),

  /* ---------- TIME ---------- */
  check_in_time: Yup.string().required("Check in time is required"),
  check_out_time: Yup.string().required("Check out time is required"),

  /* ---------- STATUS FLAGS ---------- */
  status: Yup.string().required("Active status is required"),
  is_verified: Yup.string().required("Verify status is required"),
  is_luxury: Yup.string().required("Luxury status is required"),
  is_pet_friendly: Yup.string().required("Pet Friendly option is required"),
  is_smoking_free: Yup.string().required("Smoking Free option is required"),

  /* ---------- RELATIONS ---------- */
  amenities: Yup.array()
    .of(Yup.string())
    .min(1, "Select at least one amenity")
    .required("Amenity is required"),

  categories: Yup.array()
    .of(Yup.string())
    .min(1, "Select at least one category")
    .required("Category is required"),

  tags: Yup.array()
    .of(Yup.string())
    .min(1, "Select at least one tag")
    .required("Tag is required"),
});

export const validationSchemaAddUserHostModal = Yup.object({
  fullName: Yup.string().required("Full Name is required"),
  email: Yup.string().email("Invalid email").required("Email is required"),
  phone: Yup.string()
    .matches(/^[0-9]{10}$/, "Enter valid 10-digit number")
    .required("Phone is required"),
  // password: Yup.string()
  //   .min(8, "Password must be at least 8 characters")
  //   .required("Password is required"),
  documentType: Yup.string().required("Document type is required"),
  documentNumber: Yup.string().required("Document number is required"),
  dob: Yup.date().nullable().required("Date of Birth is required"),
  address: Yup.string().required("Address is required"),
  city: Yup.string().required("City is required"),
  zipcode: Yup.string().required("Zipcode is required"),
  status: Yup.string().required("Status is required"),
  verified: Yup.string().required("Verification status is required"),
});

export const statusListingSchema = Yup.object({
  id: Yup.number().required("ID is required"),
  name: Yup.string().required("Name is required"),
  text_color: Yup.string()
    .matches(/^#([0-9A-F]{3}){1,2}$/i, "Must be a valid hex color")
    .required("Text color is required"),
  bg_color: Yup.string()
    .matches(/^#([0-9A-F]{3}){1,2}$/i, "Must be a valid hex color")
    .required("Background color is required"),
});

export const statusSchema = Yup.object({
  rows: Yup.array().of(statusListingSchema),
});


export const bookingStatusRowSchema = Yup.object({
  bs_id: Yup.number().required("Status ID is required"),
  bs_title: Yup.string().required("Title is required"),
  bs_code: Yup.string().required("Color code is required"),
});

// export const bookingStatusSchema = Yup.object({
//   rows: Yup.array()
//     .of(bookingStatusRowSchema)
//     .required(),
// });

/* ==================== FINANCE MANAGEMENT SYSTEM ==================== */

export const payoutScheduleSchema = Yup.object({
  frequency: Yup.string()
    .oneOf(["DAILY", "WEEKLY", "BIWEEKLY", "MONTHLY"], "Invalid frequency")
    .required("Frequency is required"),
  minPayoutAmount: Yup.number()
    .typeError("Amount must be a number")
    .min(1, "Minimum payout must be at least ₹1")
    .required("Minimum payout amount is required"),
  payoutMethod: Yup.string()
    .oneOf(["BANK_TRANSFER", "UPI"], "Invalid payout method")
    .required("Payout method is required"),
  isActive: Yup.boolean().required("Active status is required"),
});

export const manualPayoutSchema = Yup.object({
  hostId: Yup.number()
    .typeError("Host is required")
    .required("Host is required"),
  amount: Yup.number()
    .typeError("Amount must be a number")
    .min(1, "Amount must be at least ₹1")
    .required("Amount is required"),
  payoutMethod: Yup.string()
    .oneOf(["BANK_TRANSFER", "UPI"], "Invalid payout method")
    .required("Payout method is required"),
  notes: Yup.string().max(500, "Notes cannot exceed 500 characters"),
});

export const reconciliationResolveSchema = Yup.object({
  action: Yup.string()
    .oneOf(["ADJUST", "WRITE_OFF", "ESCALATE"], "Invalid action")
    .required("Action is required"),
  notes: Yup.string()
    .min(10, "Please provide at least 10 characters")
    .max(1000, "Notes cannot exceed 1000 characters")
    .required("Resolution notes are required"),
});

export const reportFilterSchema = Yup.object({
  dateFrom: Yup.string().required("Start date is required"),
  dateTo: Yup.string()
    .required("End date is required")
    .test("is-after", "End date must be after start date", function (value) {
      const { dateFrom } = this.parent;
      if (!dateFrom || !value) return true;
      return new Date(value) >= new Date(dateFrom);
    }),
  groupBy: Yup.string()
    .oneOf(["day", "week", "month"], "Invalid grouping")
    .required("Group by is required"),
});
