const isBlankValue = (value) =>
    value === undefined ||
    value === null ||
    (typeof value === "string" && value.trim() === "");

const normalizeOptionalValue = (value) => (
    isBlankValue(value) ? null : value
);

const normalizeOptionalString = (value) => {
    if (isBlankValue(value)) {
        return "";
    }

    return String(value).trim();
};

const normalizeBooleanFlag = (value) => {
    if (value === true || value === false) {
        return value;
    }

    if (typeof value === "string") {
        const normalized = value.trim().toLowerCase();
        if (normalized === "true" || normalized === "1") {
            return true;
        }
        if (normalized === "false" || normalized === "0" || normalized === "") {
            return false;
        }
    }

    if (typeof value === "number") {
        return value === 1;
    }

    return false;
};

module.exports = {
    normalizeBooleanFlag,
    normalizeOptionalString,
    normalizeOptionalValue,
};
