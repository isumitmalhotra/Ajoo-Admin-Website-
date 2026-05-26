const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op, where } = require("sequelize");
const { CloudinaryManager } = require("../utils/cloudinary");
const moduleConfig = require("../config/moduleConfigs");
const methods = require("../utils/methods");

const getBookingList = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
        const offset = (page - 1) * limit;
        const search = reqData.search?.trim() || "";
        const statusId = reqData.status ? Number(reqData.status) : null;
        let paymentStatus = reqData.paymentStatus;
        const fromDate = reqData.fromDate ? new Date(reqData.fromDate) : null;
        const toDate = reqData.toDate ? new Date(reqData.toDate) : null;
        let whereClause = {
            book_is_delete: commonConfig.isNo,
        };
        if (search) {
            whereClause.book_id = {
                [Op.like]: `%${search}%`,
            };
        }
        if (statusId) {
            whereClause.book_status = statusId;
        }
        if (paymentStatus !== undefined) {
            whereClause.book_is_paid = paymentStatus;
        }
        if (fromDate && toDate) {
            whereClause.book_added_at = {
                [Op.between]: [fromDate, toDate],
            };
        } else if (fromDate) {
            whereClause.book_added_at = {
                [Op.gte]: fromDate,
            };
        } else if (toDate) {
            whereClause.book_added_at = {
                [Op.lte]: toDate,
            };
        }
        const { rows, count } = await model.tbl_bookings.findAndCountAll({
            where: whereClause,
            limit,
            offset,
            include: [
                {
                    model: model.tbl_book_details,
                    as: "bookDetails",
                    attributes: ["bt_book_checkIn", "bt_book_checkout"]
                },
                {
                    model: model.tbl_user,
                    as: "userDetails",
                    attributes: ["user_fullName"]
                },
                {
                    model: model.tbl_properties,
                    as: "bookingProperty",
                    attributes: ["property_name"]
                },
                {
                    model: model.tbl_book_status,
                    as: "bookingStatus",
                    attributes: ["bs_title", "bs_code"]
                }
            ],
            attributes: ["book_pri_id", "book_id", "book_total_amt", "book_is_paid", "book_added_at"],
            order: [["book_added_at", "DESC"]],
            raw: true
        });
        if (rows.length === 0) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "No bookings found");
        }
        const totalPages = Math.ceil(count / limit);
        return common.response(req, res, commonConfig.successStatus, true, "Booking listing fetched successfully", {
            page,
            limit,
            offset,
            totalRecords: count,
            currentPage: page,
            totalPages,
            bookings: rows
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const bpokingDetail = async (req, res) => {
    try {
        const bookId = req.body.bookingId;
        const bookingDetails = await model.tbl_bookings.findOne({
            where: {
                book_id: bookId,
                book_is_delete: commonConfig.isNo
            },
            include: [
                {
                    model: model.tbl_book_details,
                    as: "bookDetails",
                    attributes: ["bt_book_checkIn", "bt_book_checkout"]
                },
                {
                    model: model.tbl_user,
                    as: "userDetails",
                    attributes: ["user_fullName", "user_pnumber"],
                    include: {
                        model: model.tbl_user_cred,
                        as: "userCred",
                        attributes: ["cred_user_email"]
                    }
                },
                {
                    model: model.tbl_properties,
                    as: "bookingProperty",
                    attributes: ["property_name", "property_contact", "property_email"],
                    include: {
                        model: model.tbl_user,
                        as: "HostDetails",
                        attributes: ["user_fullName", "user_pnumber"],
                        include: {
                            model: model.tbl_user_cred,
                            as: "userCred",
                            attributes: ["cred_user_email"]
                        }
                    }
                },
                {
                    model: model.tbl_book_status,
                    as: "bookingStatus",
                    attributes: ["bs_id", "bs_title", "bs_code"]
                }
            ],
            attributes: [
                "book_pri_id", "book_id",
                "book_total_amt", "book_is_paid", "book_added_at",
                "book_price", "book_tax", "book_tax_percentagenatage",
                "book_total_amt", "book_is_paid", "book_is_cod"
            ],
            raw: true
        });
        if (!bookingDetails) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "Booking not found");
        }
        const bookHistory = await model.tbl_book_history.findAll({
            raw: true,
            where: {
                bh_book_id: bookingDetails.book_pri_id
            },
            attributes: ["bh_title", "bh_description"]
        })
        return common.response(req, res, commonConfig.successStatus, true, "Booking details fetched successfully", { bookingDetails, bookHistory });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const updateBookingStatusforBookings = async (req, res) => {
    const transaction = await model.sequelize.transaction();
    try {
        const reqData = { ...req.body };
        const bookingId = reqData.bookingId;

        const findBooking = await model.tbl_bookings.findOne({
            where: {
                book_id: bookingId,
                book_is_delete: commonConfig.isNo
            },
            attributes: ["book_pri_id", "book_id", "book_status"],
            transaction
        });

        if (!findBooking) {
            await transaction.rollback();
            return common.response(req, res, commonConfig.notFoundStatus, false, "Booking not found");
        }

        await model.tbl_bookings.update(
            { book_status: reqData.statusId },
            { where: { book_pri_id: findBooking.book_pri_id }, transaction }
        );

        await model.tbl_book_history.create(
            {
                bh_book_id: findBooking.book_pri_id,
                bh_title: "Booking status updated",
                bh_description: `Booking status updated to ${reqData.statusId}`
            },
            { transaction }
        );

        await transaction.commit();
        return common.response(req, res, commonConfig.successStatus, true, "Booking status updated successfully");
    } catch (error) {
        await transaction.rollback();
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const bookingStatusListing = async (req, res) => {
    try {
        const { rows, count } = await model.tbl_book_status.findAndCountAll({
            where: {
                bs_isDelete: commonConfig.isNo
            },
            attributes: ["bs_id", "bs_title", "bs_code"],
            raw: true
        });
        if (rows.length === 0) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "No booking status found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "Booking status listing fetched successfully", {
            totalRecords: count,
            bookingStatus: rows
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const updateBookingStatus = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const statusId = reqData.bs_id;
        const payload = {
            bs_title: reqData.bs_title,
            bs_code: reqData.bs_code,
        };
        await model.tbl_book_status.update(payload, { where: { bs_id: statusId } });
        return common.response(req, res, commonConfig.successStatus, true, "Booking status updated successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const bookingStatusListingforAdminPage = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
        const offset = (page - 1) * limit;
        const { rows, count } = await model.tbl_book_status.findAndCountAll({
            where: { bs_isDelete: commonConfig.isNo },
            attributes: ["bs_id", "bs_title", "bs_code"],
            raw: true,
            limit: 10,
            offset: offset,
            order: [["bs_id", "DESC"]],
            raw: true
        });
        if (rows.length === 0) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "No booking status found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "Booking status listing fetched successfully", {
            page,
            limit,
            offset,
            totalRecords: count,
            currentPage: page,
            totalPages: Math.ceil(count / limit),
            bookings: rows
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
}

module.exports = {
    getBookingList,
    bpokingDetail,
    bookingStatusListing,
    updateBookingStatus,
    updateBookingStatusforBookings,
    bookingStatusListingforAdminPage
}   