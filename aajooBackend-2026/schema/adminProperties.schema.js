const yup = require("yup");

//----------------AMENETIES SCHEMA----------------//
exports.createOrUpdateAmenitySchema = yup.object({
    amenetiesId: yup
        .number()
        .typeError("Amenity ID must be a number")
        .integer("Amenity ID must be an integer")
        .positive("Amenity ID must be greater than zero")
        .nullable()
        .optional(),

    amn_title: yup
        .string()
        .trim()
        .min(2, "Amenity title must be at least 2 characters")
        .max(200, "Amenity title cannot exceed 200 characters")
        .required("Amenity title is required"),

    amn_isActive: yup
        .string()
        .oneOf(["0", "1"], "Amenity status must be 0 (Inactive) or 1 (Active)")
        .required("Amenity status is required"),
});

exports.amenityId = yup.object({
    amenetiesId: yup
        .number()
        .typeError("Amenity ID must be a number")
        .integer("Amenity ID must be an integer")
        .positive("Amenity ID must be greater than zero")
        .required("Amenity ID is required"),
});

exports.amenityStatus = yup.object({
    amenetiesId: yup
        .number()
        .typeError("Amenity ID must be a number")
        .integer("Amenity ID must be an integer")
        .positive("Amenity ID must be greater than zero")
        .required("Amenity ID is required"),

    amn_isActive: yup
        .string()
        .oneOf(["0", "1"], "Amenity status must be 0 (Inactive) or 1 (Active)")
        .required("Amenity status is required"),
});


//----------------PROPERTIES SCHEMA----------------//

exports.propertyStatusSchema = yup.object({
    propertyId: yup.number()
        .required("Property ID is required"),

    status: yup.number()
        .oneOf([0, 1], "Status must be 0 or 1")
        .required("Status is required"),
});
exports.deletePropImageSchema = yup.object({
    property_id: yup.number()
        .required("Property ID is required"),

    afile_id: yup.number()
        .required("Attachment ID is required"),

});
exports.propertyIdSchema = yup.object({
    propertyId: yup.number()
        .required("Property ID is required"),
});

// import * as yup from "yup";

exports.propertySchema = yup.object().shape({
    propertyName: yup
        .string()
        .trim()
        .required("Property name is required"),

    propHostId: yup
        .number()
        .typeError("Host is required")
        .required("Host is required"),

    propAddress: yup
        .string()
        .trim()
        .required("Property address is required"),

    propLang: yup
        .number()
        .typeError("Longitude is required")
        .required("Longitude is required"),

    propLat: yup
        .number()
        .typeError("Latitude is required")
        .required("Latitude is required"),

    propDesc: yup
        .string()
        .trim()
        .required("Property description is required"),

    propPrice: yup
        .number()
        .typeError("Property price is required")
        .required("Property price is required"),

    propMiniPrice: yup
        .number()
        .transform((_, val) =>
            val === "" || val === null ? undefined : Number(val)
        )
        .typeError("Minimum price must be a number")
        .required("Minimum price is required")
        .test(
            "mini-less-than-price",
            "Minimum price must be less than property price",
            function (value) {
                const { property_price } = this.parent;
                if (value == null || property_price == null) return true;
                return value < property_price;
            }
        ),

    propCity: yup
        .string()
        .trim()
        .required("City is required"),

    propZip: yup
        .string()
        .trim()
        .required("Zip code is required"),

    propState: yup
        .string()
        .trim()
        .required("State is required"),

    propCountry: yup
        .string()
        .trim()
        .required("Country is required"),

    propContact: yup
        .string()
        .transform((value) => (value ? value.trim() : null))
        .nullable()
        .matches(
            /^[6-9]\d{9}$/,
            "Enter a valid 10-digit mobile number (without +91)"
        ),

    isActive: yup
        .boolean()
        .required("Active status is required"),

    isVerify: yup
        .number()
        .oneOf([0, 1, 2], "Verify must be 0 or 1 or 2")
        .required("Verify status is required"),

    isLuxury: yup
        .number()
        .oneOf([0, 1], "Luxury must be 0 or 1")
        .required("Luxury status is required"),

    propEmail: yup
        .string()
        .transform((value) =>
            value ? value.trim() : null
        )
        .nullable()
        .email("Invalid email format"),
    // ===== Property Details =====
    isPetFriendly: yup.boolean(),
    isSmoke: yup.boolean(),

    inTime: yup
        .string()
        .nullable(),

    outTime: yup
        .string()
        .nullable(),

    noOfBeds: yup
        .number()
        .integer()
        .min(0)
        .nullable(),

    noOfGuests: yup
        .number()
        .integer()
        .min(0)
        .nullable(),

    weeklyMiniPrice: yup
        .number()
        .min(0)
        .nullable(),

    weeklyMaxPrice: yup
        .number()
        .min(0)
        .nullable(),

    monthlySecurity: yup
        .number()
        .min(0)
        .nullable(),

    extra: yup
        .string()
        .nullable(),

    // ===== Relations =====
    ameneties: yup
        .array()
        .of(yup.number().typeError("Amenity id must be a number"))
        .nullable(),

    categories: yup
        .array()
        .of(yup.number().typeError("Category id must be a number"))
        .nullable(),

    tags: yup
        .array()
        .of(yup.number().typeError("Tag id must be a number"))
        .nullable(),
});
