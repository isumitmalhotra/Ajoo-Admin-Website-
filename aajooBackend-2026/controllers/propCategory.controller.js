const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const methods = require("../utils/methods");
const moduleConfig = require("../config/moduleConfigs");

const propCategoriesforUser = async (req, res) => {
    try {
        let whereClause = {
            cat_isActive: commonConfig.isYes,
            cat_isDelete: commonConfig.isNo,
        };
        let attributes = ["cat_id", "cat_title"]
        const data = await model.tbl_categories.getCategories(whereClause, attributes);
        if (data.length == commonConfig.isNo) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found",);
        }
        return common.response(req, res, commonConfig.successStatus, true, "success", data);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
module.exports = {
    propCategoriesforUser,
}