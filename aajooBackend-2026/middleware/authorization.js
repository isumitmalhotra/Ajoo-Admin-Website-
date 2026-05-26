const jwt = require('jsonwebtoken');
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");

const jwtSecret = process.env.JWT_SECRET || commonConfig.JWT_SECRET;

exports.authenticateJWT = async (req, res, next) => {
    try {
        const token = req.headers['authorization'];
        if (!token) {
            return common.response(req, res, 400, false, "token is required");
        }
        const actualToken = token.split(' ')[1];
        const decoded = jwt.verify(actualToken, jwtSecret);
        if (!decoded) {
            return common.response(req, res, 400, false, "token expired");
        }
        req.user = decoded;
        next();
    } catch (error) {
        if (error.message == "jwt expired") {
            return common.response(req, res, 400, false, "Session expired, please try again");
        }
        return common.response(req, res, 400, false, error.message, error.errors);
    }
};

exports.hostAuthentication = async (req, res, next) => {
    try {
        const token = req.headers['authorization'];
        if (!token) {
            return common.response(req, res, 400, false, "token is required");
        }
        const actualToken = token.split(' ')[1];
        const decoded = jwt.verify(actualToken, jwtSecret);
        if (!decoded) {
            return common.response(req, res, 400, false, "token expired");
        }
        req.user = decoded;
        next();
    } catch (error) {
        return common.response(req, res, 400, false, error.message, error.errors);
    }
};


    exports.adminAuth = (req, res, next) => {
        try {
            const authHeader = req.headers.authorization;
            if (!authHeader || !authHeader.startsWith("Bearer ")) {
                return common.response(req, res, 401, false, "Unauthorized");
            }
            const token = authHeader.split(" ")[1];
            const decoded = jwt.verify(token, jwtSecret);
            req.admin = decoded;
            req.token = token;
            next();
        } catch (error) {
            return common.response(req, res, 401, false, "Invalid token");
        }
    };

exports.adminAuthToken = async (req, res, next) => {
    try {
        const authHeader = req.headers["authorization"];
        if (!authHeader) {
          return common.response(req, res, 401, false, "Authorization token is required");
        }
        if (!authHeader.startsWith("Bearer ")) {
          return common.response(req, res, 401, false, "Invalid authorization format");
        }
        const token = authHeader.split(" ")[1];
        if (!token) {
          return common.response(req, res, 401, false, "Token is required");
        }
        const decoded = jwt.verify(token, jwtSecret);

        if (!decoded) {
          return common.response(req, res, 401, false, "Invalid token");
        }
        req.admin = decoded;
        next();
      } catch (error) {
        if (error.name === "TokenExpiredError") {
          return common.response(req, res, 401, false, "Session expired, please login again");
        }
        if (error.name === "JsonWebTokenError") {
          return common.response(req, res, 401, false, "Invalid token");
        }    
        return common.response(req, res, 500, false, error.message);
      }
};
