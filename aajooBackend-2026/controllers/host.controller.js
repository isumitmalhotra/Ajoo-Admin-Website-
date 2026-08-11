const model = require("../models");
const sequelize = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const methods = require("../utils/methods");
const moduleConfig = require("../config/moduleConfigs");
const { CloudinaryManager } = require("../utils/cloudinary");



const confirmBooking = async (req, res) => {
    let transaction = await sequelize.transaction();
    try {
        const reqData = { ...req.body };
        let findBook = await model.tbl_bookings.getBookings({ book_pri_id: reqData.bookPriId },
            [
                "book_id",
                "book_prop_id",
                "book_user_id",
                "book_host_id",
            ]);
        if (findBook == null) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found");
        }
        let payload = {
            book_status: commonConfig.bookConfirm
        };
        await model.tbl_bookings.update(payload, { where: { book_pri_id: reqData.bookPriId } }, { transaction });
        let hisPayload = {
            bh_book_id: findBook.book_id,
            bh_user_id: findBook.book_user_id,
            bh_host_id: findBook.book_host_id,
            bh_prop_id: findBook.book_prop_id,
            bh_status_id: commonConfig.bookConfirm,
            bh_title: `booking confirmed by host`,
        };
        await model.tbl_book_history.create(hisPayload, { transaction });
        await transaction.commit()
        return common.response(req, res, commonConfig.successStatus, true, "success");
    } catch (error) {
        await transaction.rollback();
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const getOngoingBook = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let hostId = req.user.userId;
        const { rows, count } = await model.tbl_bookings.findAndCountAll({
            raw: true,
            where: {
                book_host_id: hostId,
                book_status: [4, 5, 6]
            },
            attributes: [
                "book_pri_id",
                "book_id",
                "book_prop_id",
                "book_user_id",
                'book_host_id',
                'book_status',
            ],
            include: [
                {
                    model: model.tbl_book_details,
                    as: "bookDetails",
                    attributes: ["bt_book_from", "bt_book_to"]
                },
                {
                    model: model.tbl_user,
                    as: "userDetails",
                    attributes: ["user_pnumber", "user_fullName"]
                },
                {
                    model: model.tbl_book_status,
                    as: "bookingStatus",
                    attributes: ["bs_title", "bs_code"]
                }
            ],
            // limit: parseInt(limit),
            // offset: parseInt(offset),
        });
        if (rows.length === commonConfig.isNo) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found");
        }
        const propIds = rows.map(d => d.book_prop_id);
        let attachmentwhere = {
            afile_type: moduleConfig.property_cover_image_type,
            afile_record_id: propIds,
        };
        const attachments = await model.tbl_attachments.getAllAttachments(attachmentwhere);
        const result = common.mergeData(rows, attachments);
        return common.response(req, res, commonConfig.successStatus, true, "success",
            {
                totalcount: count,
                records: result.length,
                // page: page,
                // limit: limit,
                bookings: result
            });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const hostProperties = async (req, res) => {    
    try {
        const reqData = { ...req.body };
        let hostId = req.user.userId;
        let whereClause = {
            property_host_id: hostId,
            is_deleted: commonConfig.isNo
        };
        if (reqData.category) {
            let propToCatWhereClause = {
                pt_cat_cat_id: reqData.category,
            };
            let getCatePropId = await model.tbl_prop_to_cat.getCateId(propToCatWhereClause);
            if (getCatePropId.length == 0) {
                return common.response(req, res, commonConfig.successStatus, true, "no record  found")
            }
            let CatePropId = getCatePropId.map(p => p.pt_cat_prop_id);
            const uniquePropIds = [...new Set(CatePropId)];
            whereClause.property_id = uniquePropIds;
        }
        let { rows, count } = await model.tbl_properties.findAndCountAll({
            raw: true,
            where: whereClause,
            attributes: { exclude: ["is_deleted", "created_at", "updated_at"] },
            include: [
                {
                    model: model.tbl_property_detail,
                    as: "propDetails",
                    attributes: [
                        "propDetail_isPetFriendly",
                        "propDetail_isSmoke",
                        "propDetail_inTime",
                        "propDetail_outTime",
                        "propDetail_extra",
                    ]
                }
            ],
            order: [["property_id", "DESC"]]

        });
        if (rows.length == 0) {
            return common.response(req, res, commonConfig.successStatus, true, "no record  found",)
        }
        let propIds = rows.map(p => p.property_id);
        let attachmentsRows = await methods.getAttchedProperties(rows, propIds);
        return common.response(req, res, commonConfig.successStatus, true, "success",
            {
                // totalcount: count,
                Properties: attachmentsRows
            });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const updatePropertySatatus = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let status = 1;
        if (reqData.status == false) {
            status = 0;
        }
        let payload = { is_active: status };
        let whereClause = { property_host_id: req.user.userId, property_id: reqData.propertyId };
        await model.tbl_properties.updatePropertyByWhereClause(payload, whereClause);
        return common.response(req, res, commonConfig.successStatus, true, "success");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const deleteProperty = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let payload = { is_deleted: commonConfig.isYes };
        let whereClause = { property_host_id: req.user.userId, property_id: reqData.propertyId };
        await model.tbl_properties.updatePropertyByWhereClause(payload, whereClause);
        return common.response(req, res, commonConfig.successStatus, true, "success");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const updatePropertyCoverImage = async (req, res) => {
    const cloudinaryInstance = new CloudinaryManager();
    try {
        const reqData = { ...req.body };
        if (!req.file) {
            return common.response(req, res, commonConfig.errorStatus, false, "cover image is required");
        }
        const findCover = await model.tbl_attachments.getSingleAttachment({
            afile_type: moduleConfig.property_cover_image_type,
            afile_record_id: reqData.propertyId
        });
        if (findCover) {
            await cloudinaryInstance.deleteSingleImage(findCover.afile_cldId)
            await model.tbl_attachments.destroy({ where: { afile_id: findCover.afile_id } });
        }
        const data = await cloudinaryInstance.uploadImage(req.file.path, moduleConfig.property_cover_image_type, reqData.propertyId);
        return common.response(req, res, commonConfig.successStatus, true, "success", data.url);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const hostBookingHistory = async (req, res) => {
    try {
        const hostId = req.user.userId;
        const bookings = await model.tbl_bookings.findAll({
            raw: true,
            where: { book_host_id: hostId },
            attributes: ["book_id", "book_invoice", "book_price", "book_is_paid", "book_is_cod", "book_added_at"],
            order: [["book_pri_id", "DESC"]],

            include: [
                {
                    model: model.tbl_book_details,
                    as: "bookDetails",
                    attributes: ["bt_book_from", "bt_book_to"],
                    required: false,
                },
                {
                    model: model.tbl_book_status,
                    as: "bookingStatus",
                    attributes: ["bs_title", "bs_code"],
                    required: false,
                },
                {
                    model: model.tbl_user,
                    as: "userDetails",
                    attributes: ["user_fullName", "user_pnumber"],
                    required: false,
                }
            ]
        });
        if (bookings.length == 0) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found");
        }
        const result = bookings.map((b) => ({
            ...b,
            book_is_paid: b.book_is_paid == 1,
            book_is_cod: b.book_is_cod == 1,
        }));
        return common.response(req, res, commonConfig.successStatus, true, "success", result);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const hostTransactionHistory = async (req, res) => {
    try {
        const hostId = req.user.userId;
        const data = await model.tbl_payment.findAll({
            raw: true,
            where: { pay_hostId: hostId },
            attributes: ["pay_id", "pay_invoice", "pay_raz_id", "pay_amount", "pay_status_text", "pay_addedAt"],
            order: [["pay_id", "DESC"]],
            include: [
                {
                    model: model.tbl_user,
                    as: "userPayment",
                    attributes: ["user_fullName"],
                },
                {
                    model: model.tbl_properties,
                    as: "paymentProperty",
                    attributes: ["property_name"],
                },
                {
                    model: model.tbl_book_status,
                    as: "paymentStatus",
                    attributes: ["bs_title", "bs_code"],
                },
            ]
        });
        if (data.length == 0) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "success", data);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};


module.exports = {
    confirmBooking,
    getOngoingBook,
    hostProperties,
    updatePropertyCoverImage,
    updatePropertySatatus,
    deleteProperty,
    hostTransactionHistory,
    hostBookingHistory
};