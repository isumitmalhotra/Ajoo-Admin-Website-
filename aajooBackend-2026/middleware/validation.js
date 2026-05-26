const common = require("../utils/common");
// const validation = (schema) => {
//     return async (req, res, next) => {
//         try {
//             const dataToValidate = { ...req.body, ...req.params, ...req.query };
//             await schema.validate(dataToValidate, { abortEarly: false });
//             next();
//         } catch (error) {
//             return common.response(req, res, 422, false, error.message, error.errors);
//         }
//     }
// };
// const common = require("../utils/common");

const validation = (schema) => {
    return async (req, res, next) => {
        try {
            let dataToValidate;

            // ✅ If body is array → validate directly
            if (Array.isArray(req.body)) {
                dataToValidate = req.body;
            } else {
                // ✅ If object → merge normally
                dataToValidate = {
                    ...req.body,
                    ...req.params,
                    ...req.query
                };
            }

            await schema.validate(dataToValidate, {
                abortEarly: false,
                stripUnknown: true
            });

            next();
        } catch (error) {
            console.log(error,"kjiouycy")
            return common.response(req, res, 422, false, error.errors || error.message, error.errors);
        }
    };
};

// module.exports = validation;
module.exports = validation;    