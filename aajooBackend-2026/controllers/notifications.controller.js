'use strict';
/**
 * Controller: notifications (admin + host).
 * Sprint: Full Delivery 2026-06-09..18 (A-14).
 */
const models = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const logger = require("../utils/logger");

const safePaging = (src) => {
    const page = Math.max(1, parseInt(src?.page, 10) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(src?.limit, 10) || 20));
    return { page, limit };
};

/**
 * Shared search by role. Returns notifications addressed to this recipient
 * OR broadcast to the role (recipient_id NULL).
 */
const searchByRole = async (req, res, role, recipientId) => {
    try {
        const { page, limit } = safePaging(req.query);
        const category = req.query.category || null;
        const unreadOnly = String(req.query.unreadOnly) === "true";

        const { Op } = require("sequelize");
        const where = {
            ntf_recipient_role: role,
            [Op.or]: [
                { ntf_recipient_id: recipientId },
                { ntf_recipient_id: null },
            ],
            ...(category ? { ntf_category: category } : {}),
            ...(unreadOnly ? { ntf_is_read: 0 } : {}),
        };

        const { items, totalRecords } = await models.tbl_notifications.search(where, { page, limit });
        const unreadCount = await models.tbl_notifications.count({
            where: {
                ntf_recipient_role: role,
                [Op.or]: [{ ntf_recipient_id: recipientId }, { ntf_recipient_id: null }],
                ntf_is_read: 0,
            },
        }).catch(() => 0);

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            items, unreadCount,
            totalRecords, currentPage: page,
            totalPages: Math.max(1, Math.ceil(totalRecords / limit)), limit,
        });
    } catch (error) {
        logger.error("notifications search failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "notifications search failed");
    }
};

/** GET /admin/notifications/search */
exports.adminSearch = (req, res) => {
    const adminId = req.admin?.adminId || req.admin?.id || null;
    return searchByRole(req, res, "ADMIN", adminId);
};

/** GET /host/notifications/search */
exports.hostSearch = (req, res) => {
    const hostId = req.user?.userId || req.user?.user_id || null;
    return searchByRole(req, res, "HOST", hostId);
};

/** PUT /admin/notifications/:id/read  +  /host/notifications/:id/read */
exports.markRead = async (req, res) => {
    try {
        const id = parseInt(req.params.id, 10);
        await models.tbl_notifications.update({ ntf_is_read: 1 }, { where: { ntf_id: id } });
        return common.response(req, res, commonConfig.successStatus, true, "success", { id, isRead: true });
    } catch (error) {
        logger.error("notifications markRead failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "mark read failed");
    }
};
