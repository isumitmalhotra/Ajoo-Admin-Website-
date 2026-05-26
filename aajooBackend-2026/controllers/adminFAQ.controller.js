const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require("sequelize");

const addUpdateFaq = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const adminId = req.admin.adminId;
        let faqId = reqData.faq_id ? reqData.faq_id : null;
        let payload = {
            faq_question: reqData.faq_question,
            faq_answer: reqData.faq_answer,
            faq_category: reqData.faq_category,
            faq_display_order: reqData.faq_display_order,
            faq_is_active: reqData.faq_is_active,
            faq_created_by: adminId,
            faq_updated_by: adminId,
        };
        if (faqId) {
            await model.tbl_faqs.update(payload, { where: { faq_id: faqId } });
        } else {
            await model.tbl_faqs.create(payload);
        }
        return common.response(req, res, commonConfig.successStatus, true, "FAQ added/Updated successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const listingFaq = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
        const offset = (page - 1) * limit;
        const search = reqData.search?.trim() || "";
        let whereClause = {
            faq_is_delete: commonConfig.isNo
        };
        if (search) {
            whereClause.faq_question = { [Op.like]: `%${search}%` }
        }
        const { count, rows } = await model.tbl_faqs.findAndCountAll({
            raw: true,
            where: whereClause,
            limit,
            offset,
            order: [['faq_display_order', 'ASC']],
            attributes: ['faq_id', 'faq_question', 'faq_answer', 'faq_display_order', 'faq_is_active', 'faq_created_at']
        });
        if (rows.length === 0) {
            return common.response(req, res, commonConfig.successStatus, true, "No CMS Sections found");
        }
        const totalPages = Math.ceil(count / limit);
        return common.response(req, res, commonConfig.successStatus, true, "Faq retrieved successfully", {
            totalRecords: count,
            currentPage: page,
            totalPages: totalPages,
            search,
            page,
            limit,
            offset,
            sections: rows,
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const deleteFaq = async (req, res) => {
    try {
        const faqId = req.body.faq_id;
        await model.tbl_faqs.update(
            {
                faq_is_delete: commonConfig.isYes,
            },
            { where: { faq_id: faqId } }
        );
        return common.response(req, res, commonConfig.successStatus, true, "FAQ deleted successfully");
    } catch (error) {
        console.log(error);
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const detailFaq = async (req, res) => {
    try {
        const faqId = req.body.faq_id;
        const faqDetails = await model.tbl_faqs.findOne({
            where: { faq_id: faqId, faq_is_delete: commonConfig.isNo },
            raw: true,
            attributes: ['faq_id', 'faq_question', 'faq_answer', 'faq_display_order', 'faq_is_active']
        });
        if (!faqDetails) {
            return common.response(req, res, commonConfig.successStatus, true, "FAQ not found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "FAQ details retrieved successfully", faqDetails);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};


module.exports = {
    addUpdateFaq,
    listingFaq,
    deleteFaq,
    detailFaq

}