const yup = require("yup");

exports.getLongLatProperty = yup.object({
    latitude: yup
        .number()
        .required('Latitude is required')
        .min(-90, 'Latitude must be greater than or equal to -90')
        .max(90, 'Latitude must be less than or equal to 90'),
    longitude: yup
        .number()
        .required('Longitude is required')
        .min(-180, 'Longitude must be greater than or equal to -180')
        .max(180, 'Longitude must be less than or equal to 180')
});
exports.getSingleProperty = yup.object({
    propId: yup
        .number()
        .required("property id is required"),
});
exports.createProperty = yup.object({
    property_name: yup
        .string()
        .required("title is required"),
    property_address: yup
        .string()
        .required("address is required"),
    property_longitude: yup
        .string()
        .typeError("Longitude must be a valid number")
        .min(-180, "Longitude must be greater than or equal to -180")
        .max(180, "Longitude must be less than or equal to 180")
        .required("Longitude is required"),
    // .required("cordinates are required"),
    property_latitude: yup
        .string()
        .typeError("Latitude must be a valid number")
        .min(-90, "Latitude must be greater than or equal to -90")
        .max(90, "Latitude must be less than or equal to 90")
        .required("cordinates are required"),
    property_city: yup
        .string()
        .required("city is required"),
    property_state: yup
        .number()
        .required("state is required"),
    // property_contry: yup
    //     .number()
    //     .required("country is required"),
    property_desc: yup
        .string()
        .required("description is required"),
    property_price: yup
        .number()
        .required("price is required"),
    property_mini_price: yup
        .number()
        .required("minimum price is required"),
    property_isPetAllow: yup
        .boolean(),
    // .required("pet allowance information is required"),
    property_isSmoke: yup
        .boolean(),
    // .required("smoking allowance information is required"),
    no_of_guests: yup
        .number()
        .integer("Number of guests must be an integer")
        .min(1, "Number of guests must be at least 1")
        .optional(),
    no_of_beds: yup
        .number()
        .integer("Number of beds must be an integer")
        .min(1, "Number of beds must be at least 1")
        .optional(),
});
exports.propCoverPic = yup.object({
    property_id: yup
        .number()
        .required("property id is required")
});
exports.userSaveProp = yup.object({
    // userId: yup
    //     .number()
    //     .required("user id is required"),
    propId: yup
        .number()
        .required("property id is required")
});
exports.propertyList = yup.object({
    propertyId: yup
        .number()
        .required("property id is required")

})