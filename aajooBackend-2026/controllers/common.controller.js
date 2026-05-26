const model = require("../models");
const sequelize = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const methods = require("../utils/methods");
const moduleConfig = require("../config/moduleConfigs");
const {
    aboutUs,
    safety,
    faqData,
    termsAndConditionForUser,
    termsAndConditionForHost,
    privacyPolicyForUser,
    privacyPolicyForHost,
    states
} = require("../utils/data");

const aboutus = async (req, res) => {
    try {
        return common.response(req, res, commonConfig.successStatus, true, "success", { "aboutData": aboutUs });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const safetyPage = async (req, res) => {
    try {
        return common.response(req, res, commonConfig.successStatus, true, "success", { "safetyData": safety });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const faqs = async (req, res) => {
    try {
        return common.response(req, res, commonConfig.successStatus, true, "success", { "faqData": faqData });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const termAndConditionForUserController = async (req, res) => {
    try {
        return common.response(req, res, commonConfig.successStatus, true, "success", { "termsAndCondion": termsAndConditionForUser });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const termAndConditionForHostController = async (req, res) => {
    try {
        return common.response(req, res, commonConfig.successStatus, true, "success", { "termsAndCondion": termsAndConditionForHost });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const privacyPolicyForUserController = async (req, res) => {
    try {
        if (req.body.isHost == true) {
            return common.response(req, res, commonConfig.successStatus, true, "success", { "privacyPolicy": privacyPolicyForHost });
        }
        return common.response(req, res, commonConfig.successStatus, true, "success", { "privacyPolicy": privacyPolicyForUser });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const tagsListing = async (req, res) => {
    try {
        const tags = await model.tbl_tags.getTags(
            {
                tag_isDelete: commonConfig.isNo,
                tag_isActive: commonConfig.isYes,
            },
            ["tag_id", "tag_name"]
        );
        return common.response(req, res, commonConfig.successStatus, true, "success", { "tags": tags });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
}
const categoryListing = async (req, res) => {
    try {
        let whereClause = {
            cat_isActive: commonConfig.isYes,
            cat_isDelete: commonConfig.isNo
        }
        const data = await model.tbl_categories.getCategories(whereClause, ["cat_id", "cat_title"]);
        if (data.length == commonConfig.isNo) {
            return common.response(req, res, commonConfig.successStatus, true, "success");
        }
        return common.response(req, res, commonConfig.successStatus, true, "success", { "categories": data });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const documentListing = async (req, res) => {
    try {
        const data = await model.tbl_doc_list.getDocList();
        return common.response(req, res, commonConfig.successStatus, true, "success", data);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

module.exports = {
    aboutus,
    documentListing,
    safetyPage,
    faqs,
    termAndConditionForUserController,
    termAndConditionForHostController,
    privacyPolicyForUserController,
    tagsListing,
    categoryListing
}