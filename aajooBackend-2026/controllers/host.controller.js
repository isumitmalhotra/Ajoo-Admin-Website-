const model = require("../models");
const sequelize = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const methods = require("../utils/methods");
const moduleConfig = require("../config/moduleConfigs");
const { CloudinaryManager } = require("../utils/cloudinary");
const { Op } = require("sequelize");

const cloudinaryInstance = new CloudinaryManager();

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

const getHostProfileData = async (hostId) => {
    const host = await model.tbl_user.findOne({
        raw: true,
        where: {
            user_id: hostId,
            user_isDelete: commonConfig.isNo,
            user_isHost: commonConfig.isYes,
        },
        attributes: [
            "user_id",
            "user_fullName",
            "user_pnumber",
            "user_dob",
            "user_address",
            "user_city",
            "user_zipcode",
            "user_isHost",
            "user_isUser",
            "user_isActive",
            "user_isVerified",
            "added_at",
        ]
    });
    if (!host) return null;

    const cred = await model.tbl_user_cred.findUser(
        { cred_user_id: hostId },
        ["cred_username", "cred_user_email", "cred_user_isHost"]
    );
    const credData = cred ?? {};

    const profileImage = await model.tbl_attachments.findOne({
        raw: true,
        where: {
            afile_type: moduleConfig.user_image_type,
            afile_record_id: hostId,
        },
        attributes: ["afile_id", "afile_cldId"],
    });
    const profileImageUrl = profileImage?.afile_cldId
        ? await cloudinaryInstance.getOptimizedUrl(profileImage.afile_cldId)
        : null;

    const kycDoc = await model.user_kyc_docs.findOne({
        raw: true,
        nest: true,
        where: { ud_user_id: hostId },
        attributes: ["ud_id", "ud_acc_doc_id", "ud_number", "ud_afile_id", "ud_isVerified"],
        include: [
            {
                model: model.tbl_doc_list,
                as: "docType",
                attributes: ["d_id", "d_title"],
                required: false,
            },
            {
                model: model.tbl_attachments,
                as: "docImage",
                attributes: ["afile_id", "afile_cldId"],
                required: false,
            }
        ]
    });
    const kycImageUrl = kycDoc?.docImage?.afile_cldId
        ? await cloudinaryInstance.getOptimizedUrl(kycDoc.docImage.afile_cldId)
        : null;

    const account = await model.tbl_host_acc_details.findOne({
        raw: true,
        where: {
            had_host_id: hostId,
            had_isDelete: commonConfig.isNo,
        },
        attributes: ["had_id", "had_acc_no", "had_ifsc", "had_status", "had_isVerified", "createdAt", "updatedAt"]
    });

    return {
        ...host,
        ...credData,
        profileImage: profileImage
            ? { afile_id: profileImage.afile_id, url: profileImageUrl }
            : null,
        kyc: kycDoc
            ? {
                id: kycDoc.ud_id,
                docType: kycDoc.docType ?? null,
                docNumber: kycDoc.ud_number,
                isVerified: kycDoc.ud_isVerified,
                documentImage: kycDoc.docImage
                    ? { afile_id: kycDoc.docImage.afile_id, url: kycImageUrl }
                    : null,
            }
            : null,
        payoutAccount: account ?? null,
    };
};



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

const getHostProfile = async (req, res) => {
    try {
        const hostId = req.user.userId;
        const host = await getHostProfileData(hostId);
        if (!host) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "Host not found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "success", { host });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const updateHostProfile = async (req, res) => {
    try {
        const hostId = req.user.userId;
        const reqData = { ...req.body };
        const payload = {};
        if (reqData.user_fullName !== undefined) payload.user_fullName = reqData.user_fullName;
        if (reqData.user_pnumber !== undefined) payload.user_pnumber = reqData.user_pnumber;
        if (reqData.user_address !== undefined) payload.user_address = reqData.user_address;
        if (reqData.user_city !== undefined) payload.user_city = reqData.user_city;
        if (reqData.user_zipcode !== undefined) payload.user_zipcode = reqData.user_zipcode;
        const updated = await model.tbl_user.updateUser(payload, hostId);
        if (updated[0] === 0) {
            return common.response(req, res, commonConfig.errorStatus, false, "No changes applied");
        }
        if (reqData.user_fullName) {
            await model.tbl_user_cred.update({ cred_username: reqData.user_fullName }, { where: { cred_user_id: hostId } });
        }
        const host = await getHostProfileData(hostId);
        return common.response(req, res, commonConfig.successStatus, true, "Profile updated successfully", { host });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const updateHostKyc = async (req, res) => {
    try {
        const hostId = req.user.userId;
        const reqData = { ...req.body };
        let afileId = null;
        if (req.file) {
            const existing = await model.tbl_attachments.getSingleAttachment({
                afile_type: moduleConfig.id_document_image_type,
                afile_record_id: hostId
            });
            if (existing) {
                await cloudinaryInstance.deleteSingleImage(existing.afile_cldId);
                await model.tbl_attachments.destroy({ where: { afile_id: existing.afile_id } });
            }
            const uploadResult = await cloudinaryInstance.uploadImage(req.file.path, moduleConfig.id_document_image_type, hostId);
            afileId = uploadResult.afileId;
        }
        const payload = {
            ud_user_id: hostId,
            ud_acc_doc_id: reqData.doc_type,
            ud_number: reqData.doc_number,
            ud_isVerified: commonConfig.isNo,
        };
        if (afileId) {
            payload.ud_afile_id = afileId;
        }
        const existingDoc = await model.user_kyc_docs.findOne({ where: { ud_user_id: hostId } });
        if (existingDoc) {
            await model.user_kyc_docs.update(payload, { where: { ud_user_id: hostId } });
        } else {
            await model.user_kyc_docs.create(payload);
        }
        const host = await getHostProfileData(hostId);
        return common.response(req, res, commonConfig.successStatus, true, "KYC updated successfully", { host });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const getHostOnboardingStatus = async (req, res) => {
    try {
        const hostId = req.user.userId;
        const user = await model.tbl_user.findOne({
            raw: true,
            where: { user_id: hostId, user_isDelete: commonConfig.isNo },
            attributes: ["user_isVerified", "user_isActive"]
        });
        if (!user) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "Host not found");
        }
        const kycDoc = await model.user_kyc_docs.findOne({
            raw: true,
            where: { ud_user_id: hostId }
        });
        const account = await model.tbl_host_acc_details.findOne({
            raw: true,
            where: { had_host_id: hostId, had_isDelete: commonConfig.isNo }
        });
        return common.response(req, res, commonConfig.successStatus, true, "success", {
            steps: {
                profile: true,
                kycSubmitted: !!kycDoc,
                kycVerified: kycDoc?.ud_isVerified === commonConfig.isYes,
                payoutAccountAdded: !!account,
                payoutAccountVerified: account?.had_isVerified === commonConfig.isYes,
            },
            isVerified: user.user_isVerified === commonConfig.isYes,
            isActive: user.user_isActive === commonConfig.isYes,
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const getHostDashboardSummary = async (req, res) => {
    try {
        const hostId = req.user.userId;
        const totalProperties = await model.tbl_properties.count({
            where: {
                property_host_id: hostId,
                is_deleted: commonConfig.isNo
            }
        });
        const totalBookings = await model.tbl_bookings.count({
            where: { book_host_id: hostId }
        });
        const activeBookings = await model.tbl_bookings.count({
            where: {
                book_host_id: hostId,
                book_status: { [Op.in]: [commonConfig.statusBooked, commonConfig.statusPaymentPending, commonConfig.paid] }
            }
        });
        const avgRating = await model.tbl_reviews.findOne({
            raw: true,
            where: { br_hostId: hostId, br_isDelete: commonConfig.isNo },
            attributes: [[model.sequelize.fn("AVG", model.sequelize.col("br_rating")), "avgRating"]]
        });
        const totalEarnings = await model.tbl_host_earnings.getTotalEarnings({
            he_host_id: hostId,
            he_isDeleted: commonConfig.isNo
        });
        return common.response(req, res, commonConfig.successStatus, true, "success", {
            totalProperties,
            totalBookings,
            activeBookings,
            averageRating: Number(avgRating?.avgRating ?? 0),
            totalEarnings: Number(totalEarnings ?? 0),
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const getHostEarningsSummary = async (req, res) => {
    try {
        const hostId = req.user.userId;
        const totalEarnings = await model.tbl_host_earnings.getTotalEarnings({
            he_host_id: hostId,
            he_isDeleted: commonConfig.isNo
        });
        const paidOut = await model.tbl_payout_history.sum("poh_amount", {
            where: { poh_host_id: hostId }
        });
        const pendingPayouts = await model.tbl_payout_req.sum("pay_req_amount", {
            where: {
                pay_req_host_id: hostId,
                pay_req_isDelete: commonConfig.isNo,
                pay_req_status: { [Op.in]: [commonConfig.statusPayoutPending, commonConfig.statusRunning] }
            }
        });
        return common.response(req, res, commonConfig.successStatus, true, "success", {
            totalEarnings: Number(totalEarnings ?? 0),
            totalPaidOut: Number(paidOut ?? 0),
            totalPendingPayout: Number(pendingPayouts ?? 0),
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const getHostEarningsList = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const hostId = req.user.userId;
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : commonConfig.listLimit;
        const offset = (page - 1) * limit;
        const whereClause = {
            he_host_id: hostId,
            he_isDeleted: commonConfig.isNo
        };
        const dateFilter = buildDateFilter(reqData.fromDate, reqData.toDate);
        if (dateFilter) {
            whereClause.createdAt = dateFilter;
        }
        const { rows, count } = await model.tbl_host_earnings.findAndCountAll({
            raw: true,
            where: whereClause,
            order: [["he_id", "DESC"]],
            limit,
            offset,
        });
        return common.response(req, res, commonConfig.successStatus, true, "success", {
            totalRecords: count,
            currentPage: page,
            totalPages: Math.ceil(count / limit),
            page,
            limit,
            earnings: rows ?? []
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const createSupportTicket = async (req, res) => {
    try {
        const hostId = req.user.userId;
        const reqData = { ...req.body };
        const payload = {
            hst_host_id: hostId,
            hst_subject: reqData.subject,
            hst_description: reqData.description,
            hst_category: reqData.category ?? null,
            hst_priority: reqData.priority ?? "medium",
            hst_status: "open",
        };
        const ticket = await model.tbl_host_support_ticket.create(payload);
        return common.response(req, res, commonConfig.successStatus, true, "Ticket created successfully", { ticket });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const listSupportTickets = async (req, res) => {
    try {
        const hostId = req.user.userId;
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : commonConfig.listLimit;
        const offset = (page - 1) * limit;
        const whereClause = {
            hst_host_id: hostId,
            hst_is_deleted: commonConfig.isNo
        };
        if (reqData.status) {
            whereClause.hst_status = reqData.status;
        }
        const { rows, count } = await model.tbl_host_support_ticket.findAndCountAll({
            raw: true,
            where: whereClause,
            order: [["hst_id", "DESC"]],
            limit,
            offset,
        });
        return common.response(req, res, commonConfig.successStatus, true, "success", {
            totalRecords: count,
            currentPage: page,
            totalPages: Math.ceil(count / limit),
            page,
            limit,
            tickets: rows ?? [],
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const getSupportTicketDetail = async (req, res) => {
    try {
        const hostId = req.user.userId;
        const { ticketId } = req.body;
        const ticket = await model.tbl_host_support_ticket.findOne({
            raw: true,
            where: {
                hst_id: ticketId,
                hst_host_id: hostId,
                hst_is_deleted: commonConfig.isNo
            }
        });
        if (!ticket) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "Ticket not found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "success", { ticket });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const updateSupportTicketStatus = async (req, res) => {
    try {
        const hostId = req.user.userId;
        const { ticketId, status, resolutionNote } = req.body;
        const payload = {
            hst_status: status,
        };
        if (resolutionNote !== undefined) {
            payload.hst_resolution_note = resolutionNote;
        }
        const updated = await model.tbl_host_support_ticket.update(payload, {
            where: { hst_id: ticketId, hst_host_id: hostId }
        });
        if (updated[0] === 0) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "Ticket not found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "Ticket updated successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const getMessageThreads = async (req, res) => {
    try {
        const hostId = String(req.user.userId);
        const reqData = { ...req.body };
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 50;
        const messages = await model.tbl_messages.findAll({
            raw: true,
            where: {
                [Op.or]: [
                    { sender_id: hostId },
                    { receiver_id: hostId }
                ]
            },
            order: [["created_at", "DESC"]],
            limit: limit * 5
        });
        const unreadCounts = await model.tbl_messages.findAll({
            raw: true,
            where: { receiver_id: hostId, is_read: 0 },
            attributes: ["sender_id", [model.sequelize.fn("COUNT", model.sequelize.col("message_id")), "unreadCount"]],
            group: ["sender_id"]
        });
        const unreadMap = new Map(unreadCounts.map(item => [String(item.sender_id), Number(item.unreadCount)]));
        const threads = new Map();
        messages.forEach((msg) => {
            const otherId = String(msg.sender_id) === hostId ? String(msg.receiver_id) : String(msg.sender_id);
            if (!threads.has(otherId)) {
                threads.set(otherId, {
                    userId: Number(otherId),
                    lastMessage: msg.message,
                    lastMessageAt: msg.created_at,
                    unreadCount: unreadMap.get(otherId) ?? 0,
                });
            }
        });
        const userIds = Array.from(threads.keys()).map(id => Number(id));
        const users = await model.tbl_user.findAll({
            raw: true,
            where: { user_id: userIds },
            attributes: ["user_id", "user_fullName"]
        });
        const userMap = new Map(users.map(u => [String(u.user_id), u]));
        const threadList = Array.from(threads.values()).map(t => ({
            ...t,
            user: userMap.get(String(t.userId)) ?? null
        }));
        return common.response(req, res, commonConfig.successStatus, true, "success", { threads: threadList });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const getMessagesWithUser = async (req, res) => {
    try {
        const hostId = String(req.user.userId);
        const { userId } = req.body;
        const messages = await model.tbl_messages.getConversation(hostId, String(userId));
        if (!messages || messages.length === 0) {
            return common.response(req, res, commonConfig.successStatus, true, "No messages found", { messages: [] });
        }
        return common.response(req, res, commonConfig.successStatus, true, "success", { messages });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const markMessagesRead = async (req, res) => {
    try {
        const hostId = String(req.user.userId);
        const { userId } = req.body;
        await model.tbl_messages.update(
            { is_read: 1 },
            {
                where: {
                    sender_id: String(userId),
                    receiver_id: hostId,
                    is_read: 0
                }
            }
        );
        return common.response(req, res, commonConfig.successStatus, true, "success");
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
    hostBookingHistory,
    getHostProfile,
    updateHostProfile,
    updateHostKyc,
    getHostOnboardingStatus,
    getHostDashboardSummary,
    getHostEarningsSummary,
    getHostEarningsList,
    createSupportTicket,
    listSupportTickets,
    getSupportTicketDetail,
    updateSupportTicketStatus,
    getMessageThreads,
    getMessagesWithUser,
    markMessagesRead
};
