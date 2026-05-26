const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require("sequelize");

const addUpdateTerms = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const adminId = req.admin.adminId;
        let tcId = reqData.tc_id ? reqData.tc_id : null;
        let payload = {
            tc_title: reqData.tc_title,
            tc_description: reqData.tc_description,
            tc_type: reqData.tc_type,
            tc_isActive: reqData.tc_isActive,
        };
        if (tcId) {
            await model.tbl_terms_Condition.update(payload, { where: { tc_id: tcId } });
        } else {
            await model.tbl_terms_Condition.create(payload);
        }
        return common.response(req, res, commonConfig.successStatus, true, "Terms and Condition added/Updated successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const listingTerms = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
        const offset = (page - 1) * limit;
        const search = reqData.search?.trim() || "";
        let whereClause = {
            tc_isdeleted: commonConfig.isNo
        };
        if (search) {
            whereClause.tc_title = { [Op.like]: `%${search}%` }
        }
        const { count, rows } = await model.tbl_terms_Condition.findAndCountAll({
            raw: true,
            where: whereClause,
            limit,
            offset,
            order: [['tc_created_at', 'DESC']],
            attributes: ['tc_id', 'tc_title', 'tc_type', 'tc_isActive', 'tc_created_at']
        });
        if (rows.length === 0) {
            return common.response(req, res, commonConfig.successStatus, true, "No Terms and Condition found");
        }
        const totalPages = Math.ceil(count / limit);
        return common.response(req, res, commonConfig.successStatus, true, "Terms and Condition listing", {
            totalRecords: count,
            currentPage: page,
            totalPages: totalPages,
            search,
            page,
            limit,
            offset,
            terms: rows,
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const detailTerms = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const tcId = reqData.tc_id;
        const details = await model.tbl_terms_Condition.findOne({
            raw: true,
            where: { tc_id: tcId, tc_isdeleted: commonConfig.isNo },
            attributes: ['tc_id', 'tc_title', 'tc_description', 'tc_type', 'tc_isActive']
        });
        if (!details) {
            return common.response(req, res, commonConfig.errorStatus, false, "Terms and Condition not found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "Terms and Condition details", details);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const deleteTerms = async (req, res) => {
    try {
        const tcId = req.body.tc_id;
        await model.tbl_terms_Condition.update({ tc_isdeleted: commonConfig.isYes, }, { where: { tc_id: tcId } });
        return common.response(req, res, commonConfig.successStatus, true, "Terms and Condition deleted successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
}

module.exports = {
    addUpdateTerms,
    listingTerms,
    detailTerms,
    deleteTerms
}