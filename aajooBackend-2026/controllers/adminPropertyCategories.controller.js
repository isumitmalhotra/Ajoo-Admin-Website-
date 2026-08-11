const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require("sequelize");
const { generateUniqueCategorySlug } = require("../utils/slugify");
const { ensureRecord, buildPagedPayload, AdminServiceError } = require("../services/admin/adminCrud.service");
const { logAdminMutation } = require("../services/admin/adminAudit.service");

const createOrUpdatePropertyCategory = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let categoryId = reqData.categoryId ? Number(reqData.categoryId) : null;

        let existingCategory = null;
        if (categoryId) {
            existingCategory = await model.tbl_categories.findOne({
                where: { cat_id: categoryId, cat_isDelete: commonConfig.isNo },
                raw: true
            });
            ensureRecord(existingCategory, "Category not found", commonConfig.notFoundStatus);
        }

        const slug = await generateUniqueCategorySlug(reqData.cat_title, categoryId || null);
        const payload = {
            cat_title: reqData.cat_title,
            cat_slug: `${slug}`,
            cat_isActive: reqData.cat_isActive,
            cat_isDelete: commonConfig.isNo,
        };

        if (categoryId) {
            await model.tbl_categories.updateCategory(categoryId, payload);
            await logAdminMutation(req, {
                action: "update",
                entity: "category",
                entityId: categoryId,
                before: existingCategory,
                after: payload,
            });
            return common.response(req, res, commonConfig.successStatus, true, "Category updated successfully");
        }

        const data = await model.tbl_categories.createCategory(payload);
        categoryId = data.cat_id;
        await logAdminMutation(req, {
            action: "create",
            entity: "category",
            entityId: categoryId,
            after: payload,
        });
        return common.response(req, res, commonConfig.createdStatus, true, "Category saved successfully");
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

const categoriesForDropdown = async (req, res) => {
    try {
        const categories = await model.tbl_categories.findAll({
            where: {
                cat_isActive: commonConfig.isYes,
                cat_isDelete: commonConfig.isNo,
            },
            attributes: ["cat_id", "cat_title"],
            order: [["cat_title", "ASC"]],
            raw: true,
        });
        return common.response(req, res, commonConfig.successStatus, true, "Categories fetched successfully", categories);
    } catch (error) {
        return common.response(req, res, commonConfig.serverErrorStatus, false, error.message);
    }
};

const getPropertyCategories = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
        const offset = (page - 1) * limit;
        const search = reqData.search?.trim() || "";
        const status = reqData.status ?? null;

        const whereClause = { cat_isDelete: commonConfig.isNo };
        if (search) {
            whereClause.cat_title = { [Op.like]: `%${search}%` };
        }
        if (status !== null) {
            whereClause.cat_isActive = status;
        }

        const { rows, count } = await model.tbl_categories.findAndCountAll({
            where: whereClause,
            limit,
            offset,
            raw: true
        });

        return common.response(req, res, commonConfig.successStatus, true, "Categories fetched successfully", buildPagedPayload({
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

const deleteCategory = async (req, res) => {
    try {
        const categoryId = Number(req.body.categoryId);
        if (!categoryId) {
            return common.response(req, res, commonConfig.badRequestStatus, false, "Category ID is required");
        }

        const category = await model.tbl_categories.findOne({
            where: { cat_id: categoryId, cat_isDelete: commonConfig.isNo },
            raw: true
        });
        ensureRecord(category, "Category not found", commonConfig.notFoundStatus);

        await model.tbl_categories.updateCategory(categoryId, { cat_isDelete: commonConfig.isYes });
        await logAdminMutation(req, {
            action: "delete",
            entity: "category",
            entityId: categoryId,
            before: category,
            after: { cat_isDelete: commonConfig.isYes },
        });
        return common.response(req, res, commonConfig.successStatus, true, "Category deleted successfully");
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

const getCategory = async (req, res) => {
    try {
        const category = await model.tbl_categories.findOne({
            where: {
                cat_id: Number(req.body.categoryId),
                cat_isDelete: commonConfig.isNo
            },
            raw: true
        });
        ensureRecord(category, "Category not found", commonConfig.notFoundStatus);
        return common.response(req, res, commonConfig.successStatus, true, "Category fetched successfully", category);
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

const updateStatus = async (req, res) => {
    try {
        const { categoryId, status } = req.body;
        const category = await model.tbl_categories.findOne({
            where: {
                cat_id: categoryId,
                cat_isDelete: commonConfig.isNo,
            },
            raw: true,
        });
        ensureRecord(category, "Category not found", commonConfig.notFoundStatus);

        await model.tbl_categories.updateCategory(categoryId, { cat_isActive: status });
        await logAdminMutation(req, {
            action: "status_update",
            entity: "category",
            entityId: categoryId,
            before: category,
            after: { cat_isActive: status },
        });
        return common.response(req, res, commonConfig.successStatus, true, "Category status updated successfully");
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

module.exports = {
    createOrUpdatePropertyCategory,
    getPropertyCategories,
    deleteCategory,
    getCategory,
    updateStatus,
    categoriesForDropdown
};
