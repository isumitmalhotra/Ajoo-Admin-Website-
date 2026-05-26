const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require("sequelize");

const { generateUniqueCategorySlug } = require("../utils/slugify");


const createOrUpdatePropertyCategory = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let categoryId = reqData.categoryId;

        const slug = await generateUniqueCategorySlug(reqData.cat_title, categoryId || null);
        const payload = {
            cat_title: reqData.cat_title,
            cat_slug: `${slug}`,
            cat_isActive: reqData.cat_isActive,
            cat_isDelete: commonConfig.isNo,
        };
        if (categoryId) {
            await model.tbl_categories.updateCategory(categoryId, payload);
        } else {
            const data = await model.tbl_categories.createCategory(payload);
            categoryId = data.cat_id;
        }
        return common.response(req, res, commonConfig.successStatus, true, "Category saved successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
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
        if (categories.length === 0) {
            return common.response(req, res, commonConfig.successStatus, true, "No categories found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "Categories fetched successfully", categories);
        
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
}

const getPropertyCategories = async (req, res) => {
    // GET /api/property/categories?search=lux&page=1&limit=10
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
        const offset = (page - 1) * limit;
        const search = reqData.search?.trim() || "";
        const status = reqData.status ?? null;

        const whereClause = { cat_isDelete: commonConfig.isNo };
        if (search) {
            whereClause.cat_title = { [Op.like]: `%${search}%`, };
        }
        if (status !== "") {
            whereClause.cat_isActive = status;
        }
        const { rows, count } = await model.tbl_categories.findAndCountAll({
            where: whereClause,
            limit: limit,
            offset: offset,
            raw: true
        });
        if (rows.lenght === 0) {
            return common.response(req, res, commonConfig.successStatus, true, "No categories found");
        }
        const totalPages = Math.ceil(count / limit);
        return common.response(req, res, commonConfig.successStatus, true, "Categories fetched successfully", {
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

const deleteCategory = async (req, res) => {
    try {
        const categoryId = req.body.categoryId;
        if (!categoryId) {
            return common.response(req, res, commonConfig.badRequestStatus, false, "Category ID is required");
        }
        await model.tbl_categories.updateCategory(categoryId, { cat_isDelete: commonConfig.isYes });
        return common.response(req, res, commonConfig.successStatus, true, "Category deleted successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const getCategory = async (req, res) => {
    try {
        const category = await model.tbl_categories.findOne({
            where: {
                cat_id: req.body.categoryId,
                cat_isDelete: commonConfig.isNo
            },
            raw: true
        });
        if (!category) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "Category not found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "Category fetched successfully", category);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
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
        if (!category) {
            return common.response(req, res, commonConfig.notFoundStatus || 404, false, "Category not found");
        }
        await model.tbl_categories.updateCategory(categoryId, { cat_isActive: status });
        return common.response(req, res, commonConfig.successStatus, true, "Category status updated successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};



module.exports = {
    createOrUpdatePropertyCategory,
    getPropertyCategories,
    deleteCategory,
    getCategory,
    updateStatus,
    categoriesForDropdown
}