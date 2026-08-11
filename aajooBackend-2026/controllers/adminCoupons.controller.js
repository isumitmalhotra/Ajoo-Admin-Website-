const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require("sequelize");
const { ensureRecord, buildPagedPayload, AdminServiceError } = require("../services/admin/adminCrud.service");
const { logAdminMutation } = require("../services/admin/adminAudit.service");

const addUpdateCoupons = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const couponId = reqData.cpn_id ? Number(reqData.cpn_id) : null;

        let existingCoupon = null;
        if (couponId) {
            existingCoupon = await model.tbl_coupons.findOne({
                where: { cpn_id: couponId, cpn_isDeleted: commonConfig.isNo },
                raw: true
            });
            ensureRecord(existingCoupon, "Coupon not found", commonConfig.notFoundStatus);
        }

        const payload = {
            cpn_title: reqData.cpn_title,
            cpn_code: reqData.cpn_code,
            cpn_type: reqData.cpn_type ?? null,
            cpn_dsctn_type: reqData.cpn_dsctn_type,
            cpn_dsctn_percnt: reqData.cpn_dsctn_percnt,
            cpn_dsctn_amt: reqData.cpn_dsctn_amt,
            cpn_min_amt: reqData.cpn_min_amt,
            cpn_max_amt: reqData.cpn_max_amt,
            cpn_valid_from: reqData.cpn_valid_from,
            cpn_valid_to: reqData.cpn_valid_to,
            cpn_usage_limit: reqData.cpn_usage_limit,
            cpn_used_count: reqData.cpn_used_count,
            cpn_status: reqData.cpn_status,
        };

        const duplicateCoupon = await model.tbl_coupons.findOne({
            where: {
                cpn_code: reqData.cpn_code,
                cpn_isDeleted: commonConfig.isNo,
                ...(couponId ? { cpn_id: { [Op.ne]: couponId } } : {}),
            },
            raw: true
        });

        if (duplicateCoupon) {
            return common.response(req, res, commonConfig.conflictStatus, false, "Coupon code already exists. Try a different one");
        }

        if (couponId) {
            await model.tbl_coupons.update(payload, { where: { cpn_id: couponId } });
            await logAdminMutation(req, {
                action: "update",
                entity: "coupon",
                entityId: couponId,
                before: existingCoupon,
                after: payload,
            });

            return common.response(req, res, commonConfig.successStatus, true, "Coupon updated successfully");
        }

        const createdCoupon = await model.tbl_coupons.create(payload);
        await logAdminMutation(req, {
            action: "create",
            entity: "coupon",
            entityId: createdCoupon.cpn_id,
            after: payload,
        });

        return common.response(req, res, commonConfig.createdStatus, true, "Coupon added successfully");
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

const deleteCoupons = async (req, res) => {
    try {
        const couponId = Number(req.body.cpn_id);
        const existingCoupon = await model.tbl_coupons.findOne({
            where: { cpn_id: couponId, cpn_isDeleted: commonConfig.isNo },
            raw: true
        });

        ensureRecord(existingCoupon, "Coupon not found", commonConfig.notFoundStatus);

        await model.tbl_coupons.update({ cpn_isDeleted: commonConfig.isYes }, { where: { cpn_id: couponId } });
        await logAdminMutation(req, {
            action: "delete",
            entity: "coupon",
            entityId: couponId,
            before: existingCoupon,
            after: { cpn_isDeleted: commonConfig.isYes },
        });

        return common.response(req, res, commonConfig.successStatus, true, "Coupon deleted successfully");
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

const updateStatus = async (req, res) => {
    try {
        const couponId = Number(req.body.cpn_id);
        const status = req.body.cpn_status;
        const existingCoupon = await model.tbl_coupons.findOne({
            where: { cpn_id: couponId, cpn_isDeleted: commonConfig.isNo },
            raw: true
        });

        ensureRecord(existingCoupon, "Coupon not found", commonConfig.notFoundStatus);

        await model.tbl_coupons.update({ cpn_status: status }, { where: { cpn_id: couponId } });
        await logAdminMutation(req, {
            action: "status_update",
            entity: "coupon",
            entityId: couponId,
            before: existingCoupon,
            after: { cpn_status: status },
        });

        return common.response(req, res, commonConfig.successStatus, true, "Coupon status updated successfully");
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

const couponListing = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
        const offset = (page - 1) * limit;
        const search = reqData.search?.trim() || "";

        const whereClause = {
            cpn_isDeleted: commonConfig.isNo
        };

        if (search) {
            whereClause[Op.or] = [
                { cpn_title: { [Op.like]: `%${search}%` } },
                { cpn_code: { [Op.like]: `%${search}%` } }
            ];
        }

        const { rows, count } = await model.tbl_coupons.findAndCountAll({
            where: whereClause,
            order: [["createdAt", "DESC"]],
            limit,
            offset,
            attributes: ["cpn_id", "cpn_title", "cpn_code", "cpn_dsctn_percnt", "cpn_status"]
        });

        return common.response(req, res, commonConfig.successStatus, true, "Coupons retrieved successfully", buildPagedPayload({
            rows,
            count,
            page,
            limit,
            offset,
            search,
            key: "coupons",
        }));
    } catch (error) {
        return common.response(req, res, commonConfig.serverErrorStatus, false, error.message);
    }
};

const detailedCoupon = async (req, res) => {
    try {
        const couponId = Number(req.body.cpn_id);
        const coupon = await model.tbl_coupons.findOne({
            where: { cpn_id: couponId, cpn_isDeleted: commonConfig.isNo },
            attributes: ["cpn_id", "cpn_title", "cpn_type", "cpn_code", "cpn_dsctn_type", "cpn_dsctn_percnt", "cpn_dsctn_amt", "cpn_min_amt", "cpn_max_amt", "cpn_valid_from", "cpn_valid_to", "cpn_usage_limit", "cpn_used_count", "cpn_status"],
            raw: true
        });

        ensureRecord(coupon, "Coupon not found", commonConfig.notFoundStatus);

        return common.response(req, res, commonConfig.successStatus, true, "Coupon details retrieved successfully", coupon);
    } catch (error) {
        const status = error instanceof AdminServiceError ? error.status : commonConfig.serverErrorStatus;
        return common.response(req, res, status, false, error.message);
    }
};

module.exports = {
    addUpdateCoupons,
    deleteCoupons,
    updateStatus,
    couponListing,
    detailedCoupon
};
