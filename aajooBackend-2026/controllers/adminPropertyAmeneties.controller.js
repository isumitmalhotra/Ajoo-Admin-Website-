const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require("sequelize");

const createUpdateAmeneties = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let amenetiesId = reqData.amenetiesId;
        let payload = {
            amn_title: reqData.amn_title,
            amn_isActive: reqData.amn_isActive
        };
        if (amenetiesId) {
            await model.tbl_amenities.updateAmenity(amenetiesId, payload);
        } else {
            await model.tbl_amenities.createAmenity(payload);
        }
        return common.response(req, res, commonConfig.successStatus, true, "Amenity saved successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const deleteAmenity = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const amenetiesId = reqData.amenetiesId;
        if (!amenetiesId) {
            return common.response(req, res, commonConfig.errorStatus, false, "Amenity ID is required");
        }
        await model.tbl_amenities.update({ amn_isDelete: 1 }, { where: { amn_id: amenetiesId } });
        return common.response(req, res, commonConfig.successStatus, true, "Amenity deleted successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const amenity = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const amenetiesId = reqData.amenetiesId;
        let whereClause = {
            amn_isDelete: commonConfig.isNo,
            amn_id: reqData.amenetiesId
        };
        const amenityData = await model.tbl_amenities.getAmenety(whereClause);
        if (!amenityData) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "Amenity not found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "Amenity fetched successfully", amenityData);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const amenetiesListing = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
        const offset = (page - 1) * limit;
        const search = reqData.search?.trim() || "";
        const status = reqData.status ?? null;
        let whereClause = {
            amn_isDelete: commonConfig.isNo,
        };
        if (search) {
            whereClause.amn_title = { [Op.like]: `%${search}%` };
        }
        if (status !== "") {
            whereClause.amn_isActive = status;
        }
        const { rows, count } = await model.tbl_amenities.findAndCountAll({
            where: whereClause,
            limit,
            offset,
            order: [["amn_id", "DESC"]],
            raw: true,
        });
        if (rows.length === 0) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "No amenities found");

        }
        return common.response(req, res, commonConfig.successStatus, true, "Amenity listing fetched successfully", {
            page,
            limit,
            offset,
            search,
            totalRecords: count,
            currentPage: page,
            totalPages: Math.ceil(count / limit),
            search,
            data: rows,
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const updateStatus = async (req, res) => {
    try {
        const { amenetiesId, amn_isActive } = req.body;
        const amenity = await model.tbl_amenities.findByPk(amenetiesId);
        if (!amenity) {
            return common.response(req, res, commonConfig.errorStatus, false, "Amenity not found");
        }
        await model.tbl_amenities.update(
            { amn_isActive: amn_isActive },
            { where: { amn_id: amenetiesId } }
        );
        return common.response(req, res, commonConfig.successStatus, true, "Amenity status updated successfully");

    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const amenetiesListingForDropdown = async (req, res) => {
    try {
        const amenities = await model.tbl_amenities.findAll({
            where: {
                amn_isDelete: commonConfig.isNo,
                amn_isActive: commonConfig.isYes
            },
            attributes: ['amn_id', 'amn_title'],
            order: [['amn_title', 'ASC']],
            raw: true
        });
        if (amenities.length === 0) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "No amenities found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "Amenity listing fetched successfully", amenities);
        
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
}

module.exports = {
    createUpdateAmeneties,
    deleteAmenity,
    amenity,
    amenetiesListing,
    updateStatus,
    amenetiesListingForDropdown
}