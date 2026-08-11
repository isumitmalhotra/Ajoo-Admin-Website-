const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require("sequelize");
const { ensureRecord, buildPagedPayload, AdminServiceError } = require("../services/admin/adminCrud.service");
const { logAdminMutation } = require("../services/admin/adminAudit.service");

const createOrUpdatePropertyTag = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let tagId = reqData.tagId ? Number(reqData.tagId) : null;

        let existingTag = null;
        if (tagId) {
            existingTag = await model.tbl_tags.findOne({
                where: { tag_id: tagId, tag_isDelete: commonConfig.isNo },
                raw: true
            });
            ensureRecord(existingTag, "Tag not found", commonConfig.notFoundStatus);
        }

        const payload = {
            tag_name: reqData.tag_name,
            tag_isActive: reqData.tag_isActive,
            tag_isDelete: commonConfig.isNo,
        };

        if (tagId) {
            await model.tbl_tags.updateTag(tagId, payload);
            await logAdminMutation(req, {
                action: "update",
                entity: "tag",
                entityId: tagId,
                before: existingTag,
                after: payload,
            });
            return common.response(req, res, commonConfig.successStatus, true, "Tag updated successfully");
        }

        const data = await model.tbl_tags.createTag(payload);
        tagId = data.tag_id;
        await logAdminMutation(req, {
            action: "create",
            entity: "tag",
            entityId: tagId,
            after: payload,
        });
        return common.response(req, res, commonConfig.createdStatus, true, "Tag saved successfully");
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

const deleteTag = async (req, res) => {
    try {
        const tagId = Number(req.body.tagId);
        if (!tagId) {
            return common.response(req, res, commonConfig.badRequestStatus, false, "Tag ID is required");
        }

        const existingTag = await model.tbl_tags.findOne({
            where: { tag_id: tagId, tag_isDelete: commonConfig.isNo },
            raw: true
        });
        ensureRecord(existingTag, "Tag not found", commonConfig.notFoundStatus);

        await model.tbl_tags.updateTag(tagId, { tag_isDelete: commonConfig.isYes });
        await logAdminMutation(req, {
            action: "delete",
            entity: "tag",
            entityId: tagId,
            before: existingTag,
            after: { tag_isDelete: commonConfig.isYes },
        });

        return common.response(req, res, commonConfig.successStatus, true, "Tag deleted successfully");
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

const getTagListing = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
        const offset = (page - 1) * limit;
        const search = reqData.search?.trim() || "";
        const status = reqData.status ?? null;

        const whereClause = {
            tag_isDelete: commonConfig.isNo,
        };
        if (search) {
            whereClause.tag_name = { [Op.like]: `%${search}%` };
        }
        if (status !== null) {
            whereClause.tag_isActive = status;
        }
        const { rows, count } = await model.tbl_tags.findAndCountAll({
            where: whereClause,
            limit,
            offset,
            order: [["tag_id", "DESC"]],
            raw: true,
        });

        return common.response(req, res, commonConfig.successStatus, true, "Tags fetched successfully", buildPagedPayload({
            rows,
            count,
            page,
            limit,
            offset,
            search,
            key: "data",
        }));
    } catch (error) {
        return common.response(req, res, commonConfig.serverErrorStatus, false, error.message);
    }
};

const tagListingforDropdown = async (req, res) => {
    try {
        const tags = await model.tbl_tags.findAll({
            where: {
                tag_isDelete: commonConfig.isNo,
                tag_isActive: commonConfig.isYes,
            },
            attributes: ["tag_id", "tag_name"],
            order: [["tag_name", "ASC"]],
            raw: true,
        });
        return common.response(req, res, commonConfig.successStatus, true, "Tags fetched successfully", tags);
    }
    catch (error) {
        return common.response(req, res, commonConfig.serverErrorStatus, false, error.message);
    }
};

const updateStatus = async (req, res) => {
    try {
        const { tagId, tag_isActive } = req.body;
        const tag = await model.tbl_tags.findByPk(tagId, { raw: true });
        ensureRecord(tag, "Tag not found", commonConfig.notFoundStatus);

        await model.tbl_tags.updateTag(tagId, { tag_isActive });
        await logAdminMutation(req, {
            action: "status_update",
            entity: "tag",
            entityId: tagId,
            before: tag,
            after: { tag_isActive },
        });

        return common.response(req, res, commonConfig.successStatus, true, "Tag status updated successfully");

    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

const getTag = async (req, res) => {
    try {
        const tagId = Number(req.body.tagId);
        const tag = await model.tbl_tags.findOne({
            where: {
                tag_id: tagId,
                tag_isDelete: commonConfig.isNo
            },
            raw: true
        });
        ensureRecord(tag, "Tag not found", commonConfig.notFoundStatus);
        return common.response(req, res, commonConfig.successStatus, true, "Tag fetched successfully", tag);
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

module.exports = {
    createOrUpdatePropertyTag,
    deleteTag,
    getTagListing,
    updateStatus,
    getTag,
    tagListingforDropdown
};
