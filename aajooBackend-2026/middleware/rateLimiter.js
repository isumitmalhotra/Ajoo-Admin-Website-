const rateLimit = require('express-rate-limit');
const { ipKeyGenerator } = require('express-rate-limit');

// Skip rate limiting for localhost AND development mode
const skipLocalhost = (req) => {
    // Skip if in development mode
    if (process.env.NODE_ENV === 'development') {
        return true;
    }
    
    // Skip for localhost IPs
    return req.ip === '127.0.0.1' || req.ip === '::1' || req.ip === 'localhost';
};

// Log NODE_ENV on startup
console.log(`⚙️ Rate Limiter Mode: NODE_ENV = ${process.env.NODE_ENV}`);
if (process.env.NODE_ENV === 'development') {
    console.log('✅ Rate limiting is DISABLED in development mode');
} else {
    console.log('⚠️ Rate limiting is ENABLED (production mode)');
}

// Smart key generator: Uses user ID if authenticated, otherwise IP + User-Agent
const smartKeyGenerator = (req) => {
    // If user is authenticated, use their ID
    if (req.user?.id) {
        return `user:${req.user.id}`;
    }
    // Otherwise, use IP + User-Agent for device-level differentiation
    return `ip:${ipKeyGenerator(req)}:${req.headers['user-agent'] || 'unknown'}`;
};

const generalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    message: 'Too many requests from this IP, please try again later.',
    keyGenerator: smartKeyGenerator,
    skip: skipLocalhost,
    standardHeaders: true,
    legacyHeaders: false,
});

// Strict limiter for sensitive endpoints like login, signup, OTP (e.g., 5 requests per 15 minutes per IP)
const strictLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    // max: 5, // Adjusted to 50 for demonstration; change back to 5 in production
    max: 50,
    message: 'Too many attempts, please try again later.',
    keyGenerator: smartKeyGenerator,
    skip: skipLocalhost,
    standardHeaders: true,
    legacyHeaders: false,
});

// Limiter for password reset and OTP resend (e.g., 5 requests per hour per IP)
const otpLimiter = rateLimit({
    windowMs: 60 * 60 * 1000,
    max: 10,
    message: 'Too many OTP requests, please try again later.',
    keyGenerator: smartKeyGenerator,
    skip: skipLocalhost,
    standardHeaders: true,
    legacyHeaders: false,
});

// Limiter for file uploads (e.g., 50 uploads per hour per IP)
const uploadLimiter = rateLimit({
    windowMs: 60 * 60 * 1000,
    max: 50,
    message: 'Too many uploads, please try again later.',
    keyGenerator: smartKeyGenerator,
    skip: skipLocalhost,
    standardHeaders: true,
    legacyHeaders: false,
});

const adminLoginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, 
    max: 50,                  
    message: {
        success: false,
        message: "Too many admin login attempts. Please try again after 15 minutes."
    },
    keyGenerator: (req) => {
        // For login, admin ID won't exist yet, use IP + User-Agent
        if (req.admin?.id) {
            return `admin:${req.admin.id}`;
        }
        return `admin-ip:${ipKeyGenerator(req)}:${req.headers['user-agent'] || 'unknown'}`;
    },
    skip: skipLocalhost,
    standardHeaders: true,
    legacyHeaders: false,
});


const adminApiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 500,                // admins make many requests 
    message: {
        success: false,
        message: "Too many admin requests. Please slow down."
    },
    keyGenerator: (req) => {
        // Use admin ID if authenticated, otherwise IP + User-Agent
        if (req.admin?.id) {
            return `admin:${req.admin.id}`;
        }
        return `admin-ip:${ipKeyGenerator(req)}:${req.headers['user-agent'] || 'unknown'}`;
    },
    skip: skipLocalhost,
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
    keyGenerator: (req) => {
        // Use admin ID if authenticated, otherwise IP + User-Agent
        if (req.admin?.id) {
            return `admin:${req.admin.id}`;
        }
        return `admin-ip:${ipKeyGenerator(req)}:${req.headers['user-agent'] || 'unknown'}`;
    },
    skip: skipLocalhost,
    standardHeaders: true,
    legacyHeaders: false,
});

module.exports = {
    generalLimiter,
    strictLimiter,
    otpLimiter,
    uploadLimiter,
    adminLoginLimiter,
    adminApiLimiter,
    adminCriticalLimiter
};