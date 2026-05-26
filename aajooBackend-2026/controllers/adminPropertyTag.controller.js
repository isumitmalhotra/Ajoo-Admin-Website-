const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require("sequelize");

const createOrUpdatePropertyTag = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let tagId = reqData.tagId;
        const payload = {
            tag_name: reqData.tag_name,
            tag_isActive: reqData.tag_isActive,
            tag_isDelete: commonConfig.isNo,
        };
        if (tagId) {
            await model.tbl_tags.updateTag(tagId, payload);
        } else {
            const data = await model.tbl_tags.createTag(payload);
            tagId = data.tag_id;
        }
        return common.response(req, res, commonConfig.successStatus, true, "Tag saved successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const deleteTag = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const tagId = reqData.tagId;
        if (tagId) {
            const payload = { tag_isDelete: commonConfig.isYes, };
            await model.tbl_tags.updateTag(tagId, payload);
            return common.response(req, res, commonConfig.successStatus, true, "Tag deleted successfully");
        } else {
            return common.response(req, res, commonConfig.errorStatus, false, "Tag ID is required");
        }
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
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
        if (status) {
            whereClause.tag_isActive = status;
        }
        const { rows, count } = await model.tbl_tags.findAndCountAll({
            where: whereClause,
            limit,
            offset,
            order: [["tag_id", "DESC"]],
            raw: true,
        });
        if (rows.lenght === 0) {
            return common.response(req, res, commonConfig.successStatus, true, "No categories found");
        }
        const totalPages = Math.ceil(count / limit);
        return common.response(req, res, commonConfig.successStatus, true, "Tags fetched successfully", {
            page,
            limit,
            offset,
            totalCount: count,
            totalPages,
            search,
            data: rows,
        });

    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
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
        if (tags.length === 0) {
            return common.response(req, res, commonConfig.successStatus, true, "No tags found", []);
        }
        return common.response(req, res, commonConfig.successStatus, true, "Tags fetched successfully", tags);
    }
    catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const updateStatus = async (req, res) => {
    try {
        const { tagId, tag_isActive } = req.body;
        const tag = await model.tbl_tags.findByPk(tagId);
        if (!tag) {
            return common.response(req, res, commonConfig.errorStatus, false, "Tag not found");
        }
        await model.tbl_tags.updateTag(tagId, { tag_isActive, });
        return common.response(req, res, commonConfig.successStatus, true, "Tag status updated successfully");

    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const getTag = async (req, res) => {
    try {
        const tagId = req.body.tagId;
        const tag = await model.tbl_tags.findOne({
            where: {
                tag_id: tagId,
                tag_isDelete: commonConfig.isNo
            },
            raw: true
        });
        if (!tag) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "Tag not found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "Tag fetched successfully", tag);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
}


module.exports = {
    createOrUpdatePropertyTag,
    deleteTag,
    getTagListing,
    updateStatus,
    getTag,
    tagListingforDropdown
}