const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require('sequelize');

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
            await model.tbl_host_acc_details.update(payload, { where: { had_id: reqData.accountId } });
            return common.response(req, res, commonConfig.successStatus, true, "Account Details Updated successfully",);
        } else {
            const existing = await model.tbl_host_acc_details.findOne({
                where: { had_host_id: hostId, had_isDelete: commonConfig.isNo }
            });
            if (existing) {
                await model.tbl_host_acc_details.update(payload, { where: { had_id: existing.had_id } });
                return common.response(req, res, commonConfig.successStatus, true, "Account Details Updated successfully",);
            }
            await model.tbl_host_acc_details.create(payload);
            return common.response(req, res, commonConfig.successStatus, true, "Account Details Added successfully",);
        }
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const getHostAccountDetails = async (req, res) => {
    try {
        const hostId = req.user.userId;
        const accountDetails = await model.tbl_host_acc_details.findOne({
            where: {
                had_host_id: hostId,
                had_isDelete: commonConfig.isNo
            },
            attributes: ["had_id", "had_acc_no", "had_ifsc", "had_status", "had_isVerified"]
        });
        return common.response(req, res, commonConfig.successStatus, true, "success", accountDetails ?? null);
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


module.exports = {
    addHostAccountDetails,
    getHostAccountDetails,
    cretePayoutRequest,
    getPayoutRequests
}