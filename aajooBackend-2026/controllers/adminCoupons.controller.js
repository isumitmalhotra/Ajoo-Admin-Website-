const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require("sequelize");

const addUpdateCoupons = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let copounId = reqData.cpn_id ? reqData.cpn_id : null;

        let payload = {
            cpn_title: reqData.cpn_title,
            cpn_code: reqData.cpn_code,
            cpn_type: reqData.cpn_code,
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
        if (copounId) {
            await model.tbl_coupons.update(reqData, { where: { cpn_id: copounId } });
        } else {
            let findByCode = await model.tbl_coupons.findOne({ where: { cpn_code: reqData.cpn_code } });
            if (!findByCode) {
                await model.tbl_coupons.create(payload);
            } else {
                return common.response(req, res, commonConfig.errorStatus, false, "❌ Coupon code already exists. Try a different one 🔄");
            }
        }
        return common.response(req, res, commonConfig.successStatus, true, "Coupon added successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const deleteCoupons = async (req, res) => {
    try {
        const copounId = req.body.cpn_id;
        await model.tbl_coupons.update({ cpn_isDeleted: commonConfig.isYes }, { where: { cpn_id: copounId } });
        return common.response(req, res, commonConfig.successStatus, true, "Coupon deleted successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const updateStatus = async (req, res) => {
    try {
        const copounId = req.body.cpn_id;
        const status = req.body.cpn_status;
        await model.tbl_coupons.update({ cpn_status: status }, { where: { cpn_id: copounId } });
        return common.response(req, res, commonConfig.successStatus, true, "Coupon status updated successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const couponListing = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
        const offset = (page - 1) * limit;
        const search = reqData.search?.trim() || "";
        let whereClause = {
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
        if (rows.length === 0) {
            return common.response(req, res, commonConfig.successStatus, true, "No coupons found");
        }
        const totalPages = Math.ceil(count / limit);
        return common.response(req, res, commonConfig.successStatus, true, "Coupons retrieved successfully", {
            totalRecords: count,
            currentPage: page,
            totalPages: totalPages,
            search,
            page,
            limit,
            offset,
            coupons: rows,
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const detailedCoupon = async (req, res) => {
    try {
        const cpn_id = req.body.cpn_id;
        const coupon = await model.tbl_coupons.findOne({
            where: { cpn_id, cpn_isDeleted: commonConfig.isNo },
            attributes: ["cpn_id", "cpn_title", "cpn_type", "cpn_code", "cpn_dsctn_type", "cpn_dsctn_percnt", "cpn_dsctn_amt", "cpn_min_amt", "cpn_max_amt", "cpn_valid_from", "cpn_valid_to", "cpn_usage_limit", "cpn_used_count", "cpn_status"]
        });
        if (!coupon) {
            return common.response(req, res, commonConfig.errorStatus, false, "Coupon not found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "Coupon details retrieved successfully", coupon);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

module.exports = {
    addUpdateCoupons,
    deleteCoupons,
    updateStatus,
    couponListing,
    couponListing,
    detailedCoupon,
    detailedCoupon
}