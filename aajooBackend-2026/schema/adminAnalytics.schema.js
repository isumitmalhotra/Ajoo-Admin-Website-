const yup = require("yup");
const { optionalDate, optionalString } = require("./yupHelpers");

exports.graphFilterSchema = yup.object({
    state: optionalString({ max: 100 }).max(100, "State cannot exceed 100 characters"),
    city: optionalString({ max: 100 }).max(100, "City cannot exceed 100 characters"),
    fromDate: optionalDate("fromDate must be a valid date"),
    toDate: optionalDate("toDate must be a valid date"),
});
