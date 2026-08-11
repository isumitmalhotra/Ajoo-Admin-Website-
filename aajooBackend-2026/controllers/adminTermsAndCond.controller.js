const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require("sequelize");
const { ensureRecord, buildPagedPayload, AdminServiceError } = require("../services/admin/adminCrud.service");
const { logAdminMutation } = require("../services/admin/adminAudit.service");

const addUpdateTerms = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const tcId = reqData.tc_id ? Number(reqData.tc_id) : null;

        let existingTerms = null;
        if (tcId) {
            existingTerms = await model.tbl_terms_Condition.findOne({
                where: { tc_id: tcId, tc_isdeleted: commonConfig.isNo },
                raw: true
            });
            ensureRecord(existingTerms, "Terms and Condition not found", commonConfig.notFoundStatus);
        }

        const payload = {
            tc_title: reqData.tc_title,
            tc_description: reqData.tc_description,
            tc_type: reqData.tc_type,
            tc_isActive: reqData.tc_isActive,
        };

        if (tcId) {
            await model.tbl_terms_Condition.update(payload, { where: { tc_id: tcId } });
            await logAdminMutation(req, {
                action: "update",
                entity: "terms_condition",
                entityId: tcId,
                before: existingTerms,
                after: payload,
            });

            return common.response(req, res, commonConfig.successStatus, true, "Terms and Condition updated successfully");
        }

        const createdTerms = await model.tbl_terms_Condition.create(payload);
        await logAdminMutation(req, {
            action: "create",
            entity: "terms_condition",
            entityId: createdTerms.tc_id,
            after: payload,
        });

        return common.response(req, res, commonConfig.createdStatus, true, "Terms and Condition added successfully");
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

const listingTerms = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
        const offset = (page - 1) * limit;
        const search = reqData.search?.trim() || "";

        const whereClause = {
            tc_isdeleted: commonConfig.isNo
        };

        if (search) {
            whereClause.tc_title = { [Op.like]: `%${search}%` };
        }

        const { count, rows } = await model.tbl_terms_Condition.findAndCountAll({
            raw: true,
            where: whereClause,
            limit,
            offset,
            order: [["tc_created_at", "DESC"]],
            attributes: ["tc_id", "tc_title", "tc_type", "tc_isActive", "tc_created_at"]
        });

        return common.response(req, res, commonConfig.successStatus, true, "Terms and Condition listing", buildPagedPayload({
            rows,
            count,
            page,
            limit,
            offset,
            search,
            key: "terms",
        }));
    } catch (error) {
        return common.response(req, res, commonConfig.serverErrorStatus, false, error.message);
    }
};

const detailTerms = async (req, res) => {
    try {
        const tcId = Number(req.body.tc_id);
        const details = await model.tbl_terms_Condition.findOne({
            raw: true,
            where: { tc_id: tcId, tc_isdeleted: commonConfig.isNo },
            attributes: ["tc_id", "tc_title", "tc_description", "tc_type", "tc_isActive"]
        });

        ensureRecord(details, "Terms and Condition not found", commonConfig.notFoundStatus);

        return common.response(req, res, commonConfig.successStatus, true, "Terms and Condition details", details);
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

const deleteTerms = async (req, res) => {
    try {
        const tcId = Number(req.body.tc_id);
        const existingTerms = await model.tbl_terms_Condition.findOne({
            where: { tc_id: tcId, tc_isdeleted: commonConfig.isNo },
            raw: true
        });

        ensureRecord(existingTerms, "Terms and Condition not found", commonConfig.notFoundStatus);

        await model.tbl_terms_Condition.update(
            { tc_isdeleted: commonConfig.isYes },
            { where: { tc_id: tcId } }
        );

        await logAdminMutation(req, {
            action: "delete",
            entity: "terms_condition",
            entityId: tcId,
            before: existingTerms,
            after: { tc_isdeleted: commonConfig.isYes },
        });

        return common.response(req, res, commonConfig.successStatus, true, "Terms and Condition deleted successfully");
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

module.exports = {
    addUpdateTerms,
    listingTerms,
    detailTerms,
    deleteTerms
};
