const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require("sequelize");
const { ensureRecord, buildPagedPayload, AdminServiceError } = require("../services/admin/adminCrud.service");
const { logAdminMutation } = require("../services/admin/adminAudit.service");

const createUpdateAmeneties = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const amenetiesId = reqData.amenetiesId ? Number(reqData.amenetiesId) : null;

        let existingAmenity = null;
        if (amenetiesId) {
            existingAmenity = await model.tbl_amenities.findOne({
                where: { amn_id: amenetiesId, amn_isDelete: commonConfig.isNo },
                raw: true
            });
            ensureRecord(existingAmenity, "Amenity not found", commonConfig.notFoundStatus);
        }

        const payload = {
            amn_title: reqData.amn_title,
            amn_isActive: reqData.amn_isActive
        };

        if (amenetiesId) {
            await model.tbl_amenities.updateAmenity(amenetiesId, payload);
            await logAdminMutation(req, {
                action: "update",
                entity: "amenity",
                entityId: amenetiesId,
                before: existingAmenity,
                after: payload,
            });
            return common.response(req, res, commonConfig.successStatus, true, "Amenity updated successfully");
        }

        const createdAmenity = await model.tbl_amenities.createAmenity(payload);
        await logAdminMutation(req, {
            action: "create",
            entity: "amenity",
            entityId: createdAmenity.amn_id,
            after: payload,
        });
        return common.response(req, res, commonConfig.createdStatus, true, "Amenity saved successfully");
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

const deleteAmenity = async (req, res) => {
    try {
        const amenetiesId = Number(req.body.amenetiesId);
        if (!amenetiesId) {
            return common.response(req, res, commonConfig.badRequestStatus, false, "Amenity ID is required");
        }

        const amenity = await model.tbl_amenities.findOne({
            where: { amn_id: amenetiesId, amn_isDelete: commonConfig.isNo },
            raw: true
        });
        ensureRecord(amenity, "Amenity not found", commonConfig.notFoundStatus);

        await model.tbl_amenities.update({ amn_isDelete: commonConfig.isYes }, { where: { amn_id: amenetiesId } });
        await logAdminMutation(req, {
            action: "delete",
            entity: "amenity",
            entityId: amenetiesId,
            before: amenity,
            after: { amn_isDelete: commonConfig.isYes },
        });
        return common.response(req, res, commonConfig.successStatus, true, "Amenity deleted successfully");
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

const amenity = async (req, res) => {
    try {
        const amenetiesId = Number(req.body.amenetiesId);
        const amenityData = await model.tbl_amenities.getAmenety({
            amn_isDelete: commonConfig.isNo,
            amn_id: amenetiesId
        });
        ensureRecord(amenityData, "Amenity not found", commonConfig.notFoundStatus);
        return common.response(req, res, commonConfig.successStatus, true, "Amenity fetched successfully", amenityData);
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
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
        const whereClause = {
            amn_isDelete: commonConfig.isNo,
        };
        if (search) {
            whereClause.amn_title = { [Op.like]: `%${search}%` };
        }
        if (status !== "" && status !== null && status !== undefined) {
            whereClause.amn_isActive = status;
        }
        const { rows, count } = await model.tbl_amenities.findAndCountAll({
            where: whereClause,
            limit,
            offset,
            order: [["amn_id", "DESC"]],
            raw: true,
        });

        return common.response(req, res, commonConfig.successStatus, true, "Amenity listing fetched successfully", buildPagedPayload({
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

const updateStatus = async (req, res) => {
    try {
        const { amenetiesId, amn_isActive } = req.body;
        const amenityRecord = await model.tbl_amenities.findByPk(amenetiesId, { raw: true });
        ensureRecord(amenityRecord, "Amenity not found", commonConfig.notFoundStatus);

        await model.tbl_amenities.update(
            { amn_isActive },
            { where: { amn_id: amenetiesId } }
        );
        await logAdminMutation(req, {
            action: "status_update",
            entity: "amenity",
            entityId: amenetiesId,
            before: amenityRecord,
            after: { amn_isActive },
        });
        return common.response(req, res, commonConfig.successStatus, true, "Amenity status updated successfully");

    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

const amenetiesListingForDropdown = async (req, res) => {
    try {
        const amenities = await model.tbl_amenities.findAll({
            where: {
                amn_isDelete: commonConfig.isNo,
                amn_isActive: commonConfig.isYes
            },
            attributes: ["amn_id", "amn_title"],
            order: [["amn_title", "ASC"]],
            raw: true
        });
        return common.response(req, res, commonConfig.successStatus, true, "Amenity listing fetched successfully", amenities);
    } catch (error) {
        return common.response(req, res, commonConfig.serverErrorStatus, false, error.message);
    }
};

module.exports = {
    createUpdateAmeneties,
    deleteAmenity,
    amenity,
    amenetiesListing,
    updateStatus,
    amenetiesListingForDropdown
};
