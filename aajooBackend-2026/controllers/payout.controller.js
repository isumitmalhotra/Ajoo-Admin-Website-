const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require('sequelize');
const xlsx = require("xlsx");

const addHostAccountDetails = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const hostId = req.user.userId;
        let payload = {
            had_host_id: hostId,
            had_acc_no: reqData.accountNumber,
            had_ifsc: reqData.accountIfsc,
            had_status: commonConfig.statusRunning
        };
        if (reqData.accountId) {
            delete payload.had_host_id;
            model.tbl_host_acc_details.update(payload, { where: { had_id: reqData.accountId } });
            return common.response(req, res, commonConfig.successStatus, true, "Account Details Updated successfully",);
        } else {
            await model.tbl_host_acc_details.create(payload);
            return common.response(req, res, commonConfig.successStatus, true, "Account Details Addedd successfully",);
        }
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const cretePayoutRequest = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const hostId = req.user.userId;
        let payload = {
            pay_req_host_id: hostId,
            pay_req_amount: reqData.amount,
            pay_req_status: commonConfig.statusPayoutPending,
        };
        //check the comming amnt is available in the host account
        await model.tbl_payout_req.create(payload);
        return common.response(req, res, commonConfig.successStatus, true, "Request Created Successfully",);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const getPayoutRequests = async (req, res) => {
    try {
        const hostId = req.user.userId;
        let hostTotalEarning = await model.tbl_host_earnings.getTotalEarnings({ he_host_id: hostId, he_status: commonConfig.statusPaymentRecieved, he_isRecieved: commonConfig.isYes });
        let paidAmount = await model.tbl_payout_req.sum(
            "pay_req_amount",
            {
                where:
                {
                    pay_req_host_id: hostId,
                    pay_req_status: {
                        [Op.or]: [commonConfig.statusPayoutPending, commonConfig.statusPayoutSuccessfull, commonConfig.statusRunning]
                    },
                    pay_req_isActive: commonConfig.isYes,
                    pay_req_isDelete: commonConfig.isNo
                }
            });
        let leftTotalEarning = Number(hostTotalEarning) - Number(paidAmount);
        let whereClause = {
            pay_req_host_id: hostId,
            pay_req_isDelete: commonConfig.isNo,
        };
        const payoutRequests = await model.tbl_payout_req.getPayoutRequest(whereClause,
            [
                "pay_req_id",
                "pay_req_amount",
                "pay_req_isActive",
                "createdAt"
            ]);
        let responseData = {
            hostTotalEarning: hostTotalEarning ?? 0,
            earningLeft: leftTotalEarning ?? 0,
            payoutRequests: payoutRequests ?? [],

        }
        return common.response(req, res, commonConfig.successStatus, true, "success", responseData);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const getHostAccountDetails = async (req, res) => {
    try {
        const hostId = req.user.userId;
        const account = await model.tbl_host_acc_details.findOne({
            raw: true,
            where: {
                had_host_id: hostId,
                had_isDelete: commonConfig.isNo,
            },
            attributes: ["had_id", "had_acc_no", "had_ifsc", "had_status", "had_isVerified", "createdAt", "updatedAt"]
        });
        return common.response(req, res, commonConfig.successStatus, true, "success", { account: account ?? null });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const buildDateFilter = (fromDate, toDate) => {
    if (!fromDate && !toDate) return null;
    const filter = {};
    if (fromDate && toDate) {
        filter[Op.between] = [new Date(fromDate), new Date(toDate)];
        return filter;
    }
    if (fromDate) {
        filter[Op.gte] = new Date(fromDate);
        return filter;
    }
    filter[Op.lte] = new Date(toDate);
    return filter;
};

const getPayoutHistory = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const hostId = req.user.userId;
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : commonConfig.listLimit;
        const offset = (page - 1) * limit;
        const whereClause = { poh_host_id: hostId };
        const dateFilter = buildDateFilter(reqData.fromDate, reqData.toDate);
        if (dateFilter) {
            whereClause.createdAt = dateFilter;
        }
        const { rows, count } = await model.tbl_payout_history.findAndCountAll({
            raw: true,
            where: whereClause,
            order: [["poh_id", "DESC"]],
            limit,
            offset,
        });
        return common.response(req, res, commonConfig.successStatus, true, "success", {
            totalRecords: count,
            currentPage: page,
            totalPages: Math.ceil(count / limit),
            page,
            limit,
            payouts: rows ?? [],
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const downloadPayoutHistory = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const hostId = req.user.userId;
        const whereClause = { poh_host_id: hostId };
        const dateFilter = buildDateFilter(reqData.fromDate, reqData.toDate);
        if (dateFilter) {
            whereClause.createdAt = dateFilter;
        }
        const rows = await model.tbl_payout_history.findAll({
            raw: true,
            where: whereClause,
            order: [["poh_id", "DESC"]],
            attributes: ["poh_id", "poh_invoice", "poh_amount", "poh_status", "createdAt"],
        });
        const worksheet = xlsx.utils.json_to_sheet(rows ?? []);
        const workbook = xlsx.utils.book_new();
        xlsx.utils.book_append_sheet(workbook, worksheet, "PayoutHistory");
        const buffer = xlsx.write(workbook, { type: "buffer", bookType: "xlsx" });
        res.setHeader("Content-Disposition", "attachment; filename=payout-history.xlsx");
        res.setHeader("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        return res.send(buffer);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

module.exports = {
    addHostAccountDetails,
    cretePayoutRequest,
    getPayoutRequests,
    getHostAccountDetails,
    getPayoutHistory,
    downloadPayoutHistory
}
