const yup = require("yup");

const isBlankValue = (value) =>
    value === undefined ||
    value === null ||
    (typeof value === "string" && value.trim() === "");

const emptyToUndefined = (value, originalValue) => (
    isBlankValue(originalValue) ? undefined : value
);

const emptyToNull = (value, originalValue) => (
    isBlankValue(originalValue) ? null : value
);

const optionalInteger = ({ min, max, typeError } = {}) => {
    let schema = yup.number().transform(emptyToUndefined).integer("Value must be an integer");

    if (typeError) {
        schema = schema.typeError(typeError);
    }
    if (min !== undefined) {
        schema = schema.min(min, `Value must be at least ${min}`);
    }
    if (max !== undefined) {
        schema = schema.max(max, `Value cannot exceed ${max}`);
    }

    return schema.optional();
};

const optionalString = ({ max, min, trim = true } = {}) => {
    let schema = yup.string().transform(emptyToUndefined);

    if (trim) {
        schema = schema.trim();
    }
    if (min !== undefined) {
        schema = schema.min(min, `Value must be at least ${min} characters`);
    }
    if (max !== undefined) {
        schema = schema.max(max, `Value cannot exceed ${max} characters`);
    }

    return schema.optional();
};

const optionalBoolean = () =>
    yup.boolean().transform((value, originalValue) => {
        if (isBlankValue(originalValue)) {
            return undefined;
        }

        if (typeof originalValue === "string") {
            const normalized = originalValue.trim().toLowerCase();
            if (normalized === "true" || normalized === "1") {
                return true;
            }
            if (normalized === "false" || normalized === "0") {
                return false;
            }
        }

        return value;
    }).optional();

const optionalDate = (typeError) =>
    yup.date()
        .transform(emptyToUndefined)
        .typeError(typeError)
        .optional();

const optionalChoice = (choices, message) =>
    yup.mixed()
        .transform(emptyToUndefined)
        .oneOf(choices, message)
        .optional();

const optionalNullableNumber = (typeError) =>
    yup.number()
        .transform(emptyToNull)
        .typeError(typeError)
        .nullable()
        .optional();

module.exports = {
    optionalBoolean,
    optionalChoice,
    optionalDate,
    optionalInteger,
    optionalNullableNumber,
    optionalString,
};
