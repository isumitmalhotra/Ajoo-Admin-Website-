const logger = require("../../utils/logger");

const getRequestId = (req) =>
    req.headers["x-request-id"]
    || req.headers["x-correlation-id"]
    || `req_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;

const logAdminMutation = async (req, {
    action,
    entity,
    entityId = null,
    before = null,
    after = null,
    meta = {},
}) => {
    try {
        logger.info("ADMIN_MUTATION_AUDIT", {
            requestId: getRequestId(req),
            adminId: req.admin?.adminId ?? null,
            action,
            entity,
            entityId,
            method: req.method,
            path: req.originalUrl,
            ip: req.ip,
            before,
            after,
            meta,
        });
    } catch (error) {
        logger.error("Failed to write admin mutation audit log", {
            message: error.message,
            stack: error.stack,
            entity,
            action,
            entityId,
        });
    }
};

module.exports = {
    logAdminMutation,
    getRequestId,
};
