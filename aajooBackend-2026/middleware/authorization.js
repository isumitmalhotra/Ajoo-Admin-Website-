const jwt = require('jsonwebtoken');
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");

const getJwtSecret = () => {
    if (!commonConfig.JWT_SECRET) {
        throw new Error("JWT secret is not configured");
    }
    return commonConfig.JWT_SECRET;
};

const extractBearerToken = (authHeader) => {
    if (!authHeader) {
        return { error: "Authorization token is required" };
    }
    if (!authHeader.startsWith("Bearer ")) {
        return { error: "Invalid authorization format" };
    }

    const token = authHeader.split(" ")[1];
    if (!token) {
        return { error: "Token is required" };
    }

    return { token };
};

const verifyJwt = (token) => jwt.verify(token, getJwtSecret());

exports.authenticateJWT = async (req, res, next) => {
    try {
        const { token, error } = extractBearerToken(req.headers["authorization"]);
        if (error) {
            return common.response(req, res, 401, false, error);
        }
        const decoded = verifyJwt(token);
        if (!decoded) {
            return common.response(req, res, 401, false, "token expired");
        }
        req.user = decoded;
        next();
    } catch (error) {
        if (error.message === "JWT secret is not configured") {
            return common.response(req, res, 500, false, error.message);
        }
        if (error.message == "jwt expired") {
            return common.response(req, res, 401, false, "Session expired, please try again");
        }
        return common.response(req, res, 401, false, error.message, error.errors);
    }
};

exports.hostAuthentication = async (req, res, next) => {
    try {
        const { token, error } = extractBearerToken(req.headers["authorization"]);
        if (error) {
            return common.response(req, res, 401, false, error);
        }
        const decoded = verifyJwt(token);
        if (!decoded) {
            return common.response(req, res, 401, false, "token expired");
        }
        req.user = decoded;
        next();
    } catch (error) {
        if (error.message === "JWT secret is not configured") {
            return common.response(req, res, 500, false, error.message);
        }
        return common.response(req, res, 401, false, error.message, error.errors);
    }
};


exports.adminAuth = (req, res, next) => {
    try {
        const { token, error } = extractBearerToken(req.headers.authorization);
        if (error) {
            return common.response(req, res, 401, false, error);
        }
        const decoded = verifyJwt(token);
        req.admin = decoded;
        req.token = token;
        next();
    } catch (error) {
        if (error.message === "JWT secret is not configured") {
            return common.response(req, res, 500, false, error.message);
        }
        if (error.name === "TokenExpiredError") {
            return common.response(req, res, 401, false, "Session expired, please login again");
        }
        return common.response(req, res, 401, false, "Invalid token");
    }
};

exports.adminAuthToken = async (req, res, next) => {
    try {
        const { token, error } = extractBearerToken(req.headers["authorization"]);
        if (error) {
          return common.response(req, res, 401, false, error);
        }
        const decoded = verifyJwt(token);
        if (!decoded) {
          return common.response(req, res, 401, false, "Invalid token");
        }
        req.admin = decoded;
        req.token = token;
        next();
      } catch (error) {
        if (error.message === "JWT secret is not configured") {
          return common.response(req, res, 500, false, error.message);
        }
        if (error.name === "TokenExpiredError") {
          return common.response(req, res, 401, false, "Session expired, please login again");
        }
        if (error.name === "JsonWebTokenError") {
          return common.response(req, res, 401, false, "Invalid token");
        }
        return common.response(req, res, 500, false, error.message);
      }
};

/**
 * RBAC role-gate middleware factory (A-13).
 * Taxonomy: admin / finance / host / support / guest.
 *
 * Usage — compose AFTER an auth middleware that decodes the token onto
 * req.user / req.admin (e.g. hostAuthentication, adminAuth, authenticateJWT):
 *
 *   const { hostAuthentication, requireRole } = require("../middleware/authorization");
 *   router.get("/host/secret", [hostAuthentication, requireRole("host", "admin")], handler);
 *
 * Back-compat: tokens minted before A-13 have no `role` claim; we derive one
 * from the legacy isAdmin / isHost flags so old sessions keep working.
 */
const deriveRoleFromDecoded = (decoded = {}) => {
    if (decoded.role) return decoded.role;
    if (Number(decoded.isAdmin) === 1 || decoded.admin_isAdmin === 1) return "admin";
    if (Number(decoded.isHost) === 1 || Number(decoded.user_isHost) === 1) return "host";
    return "guest";
};

exports.requireRole = (...allowedRoles) => {
    return (req, res, next) => {
        try {
            const decoded = req.admin || req.user || null;
            if (!decoded) {
                return common.response(req, res, 401, false, "Authentication required before role check");
            }
            const role = deriveRoleFromDecoded(decoded);
            // admin is a superuser — always allowed through role gates
            if (role === "admin" || allowedRoles.includes(role)) {
                req.role = role;
                return next();
            }
            return common.response(req, res, 403, false, "Forbidden: insufficient role");
        } catch (error) {
            return common.response(req, res, 500, false, error.message);
        }
    };
};

exports.deriveRoleFromDecoded = deriveRoleFromDecoded;
