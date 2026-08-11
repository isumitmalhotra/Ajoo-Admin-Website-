const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require("sequelize");
const { ensureRecord, buildPagedPayload, AdminServiceError } = require("../services/admin/adminCrud.service");
const { logAdminMutation } = require("../services/admin/adminAudit.service");

const addUpdateFaq = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const adminId = req.admin?.adminId ?? null;
        const faqId = reqData.faq_id ? Number(reqData.faq_id) : null;

        let existingFaq = null;
        if (faqId) {
            existingFaq = await model.tbl_faqs.findOne({
                where: { faq_id: faqId, faq_is_delete: commonConfig.isNo },
                raw: true
            });
            ensureRecord(existingFaq, "FAQ not found", commonConfig.notFoundStatus);
        }

        const payload = {
            faq_question: reqData.faq_question,
            faq_answer: reqData.faq_answer,
            faq_category: reqData.faq_category,
            faq_display_order: reqData.faq_display_order,
            faq_is_active: reqData.faq_is_active,
            faq_created_by: faqId ? existingFaq.faq_created_by ?? adminId : adminId,
            faq_updated_by: adminId,
        };

        if (faqId) {
            await model.tbl_faqs.update(payload, { where: { faq_id: faqId } });
            await logAdminMutation(req, {
                action: "update",
                entity: "faq",
                entityId: faqId,
                before: existingFaq,
                after: payload,
            });

            return common.response(req, res, commonConfig.successStatus, true, "FAQ updated successfully");
        }

        const createdFaq = await model.tbl_faqs.create(payload);
        await logAdminMutation(req, {
            action: "create",
            entity: "faq",
            entityId: createdFaq.faq_id,
            after: payload,
        });

        return common.response(req, res, commonConfig.createdStatus, true, "FAQ added successfully");
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

const listingFaq = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
        const offset = (page - 1) * limit;
        const search = reqData.search?.trim() || "";

        const whereClause = {
            faq_is_delete: commonConfig.isNo
        };

        if (search) {
            whereClause.faq_question = { [Op.like]: `%${search}%` };
        }

        const { count, rows } = await model.tbl_faqs.findAndCountAll({
            raw: true,
            where: whereClause,
            limit,
            offset,
            order: [["faq_display_order", "ASC"]],
            attributes: ["faq_id", "faq_question", "faq_answer", "faq_display_order", "faq_is_active", "faq_created_at"]
        });

        return common.response(req, res, commonConfig.successStatus, true, "Faq retrieved successfully", buildPagedPayload({
            rows,
            count,
            page,
            limit,
            offset,
            search,
            key: "sections",
        }));
    } catch (error) {
        return common.response(req, res, commonConfig.serverErrorStatus, false, error.message);
    }
};

const deleteFaq = async (req, res) => {
    try {
        const faqId = Number(req.body.faq_id);
        const existingFaq = await model.tbl_faqs.findOne({
            where: { faq_id: faqId, faq_is_delete: commonConfig.isNo },
            raw: true
        });

        ensureRecord(existingFaq, "FAQ not found", commonConfig.notFoundStatus);

        await model.tbl_faqs.update(
            { faq_is_delete: commonConfig.isYes },
            { where: { faq_id: faqId } }
        );

        await logAdminMutation(req, {
            action: "delete",
            entity: "faq",
            entityId: faqId,
            before: existingFaq,
            after: { faq_is_delete: commonConfig.isYes },
        });

        return common.response(req, res, commonConfig.successStatus, true, "FAQ deleted successfully");
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

const detailFaq = async (req, res) => {
    try {
        const faqId = Number(req.body.faq_id);
        const faqDetails = await model.tbl_faqs.findOne({
            where: { faq_id: faqId, faq_is_delete: commonConfig.isNo },
            raw: true,
            attributes: ["faq_id", "faq_question", "faq_answer", "faq_display_order", "faq_is_active"]
        });

        ensureRecord(faqDetails, "FAQ not found", commonConfig.notFoundStatus);

        return common.response(req, res, commonConfig.successStatus, true, "FAQ details retrieved successfully", faqDetails);
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

module.exports = {
    addUpdateFaq,
    listingFaq,
    deleteFaq,
    detailFaq
};
