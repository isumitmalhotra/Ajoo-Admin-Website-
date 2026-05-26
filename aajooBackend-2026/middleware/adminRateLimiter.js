const rateLimit = require("express-rate-limit");

const adminLoginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, 
    max: 5,                  
    message: {
        success: false,
        message: "Too many admin login attempts. Please try again after 15 minutes."
    },
    standardHeaders: true,
    legacyHeaders: false,
});


const adminApiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 200,                // admins make many requests
    message: {
        success: false,
        message: "Too many admin requests. Please slow down."
    },
    standardHeaders: true,
    legacyHeaders: false,
});


const adminCriticalLimiter = rateLimit({
    windowMs: 10 * 60 * 1000, // 10 minutes
    max: 20,
    message: {
        success: false,
        message: "Too many critical admin actions. Please wait."
    },
    standardHeaders: true,
    legacyHeaders: false,
});


module.exports = { adminApiLimiter, adminLoginLimiter, adminCriticalLimiter };






