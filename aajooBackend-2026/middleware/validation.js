const common = require("../utils/common");

const normalizeBracketNotation = (payload) => {
    if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
        return payload;
    }

    const normalized = {};

    Object.entries(payload).forEach(([key, value]) => {
        const isBracketArray = key.endsWith("[]");
        const normalizedKey = isBracketArray ? key.slice(0, -2) : key;
        const nextValue = isBracketArray ? [].concat(value) : value;

        if (!Object.prototype.hasOwnProperty.call(normalized, normalizedKey)) {
            normalized[normalizedKey] = nextValue;
            return;
        }

        normalized[normalizedKey] = []
            .concat(normalized[normalizedKey])
            .concat(nextValue);
    });

    return normalized;
};

const validation = (schema) => {
    return async (req, res, next) => {
        try {
            let dataToValidate;

            if (Array.isArray(req.body)) {
                dataToValidate = req.body;
            } else {
                req.body = normalizeBracketNotation(req.body);
                dataToValidate = {
                    ...req.body,
                    ...req.params,
                    ...req.query,
                };
            }

            const validatedData = await schema.validate(dataToValidate, {
                abortEarly: false,
                stripUnknown: true,
            });

            req.validated = validatedData;

            if (Array.isArray(req.body)) {
                req.body = validatedData;
            } else {
                const syncContainer = (containerName) => {
                    const container = req[containerName];
                    if (!container || typeof container !== "object") {
                        return;
                    }

                    const sanitized = {};
                    Object.keys(container).forEach((key) => {
                        if (Object.prototype.hasOwnProperty.call(validatedData, key)) {
                            sanitized[key] = validatedData[key];
                        }
                    });
                    req[containerName] = sanitized;
                };

                syncContainer("body");
                syncContainer("params");
                syncContainer("query");
            }

            next();
        } catch (error) {
            console.log(error,"kjiouycy")
            return common.response(req, res, 422, false, error.errors || error.message, error.errors);
        }
    };
};

module.exports = validation;
