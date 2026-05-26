const rateLimit = require('express-rate-limit');

const generalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    message: 'Too many requests from this IP, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
});

// Strict limiter for sensitive endpoints like login, signup, OTP (e.g., 5 requests per 15 minutes per IP)
const strictLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    // max: 5, // Adjusted to 50 for demonstration; change back to 5 in production
    max: 50,
    message: 'Too many attempts, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
});

// Limiter for password reset and OTP resend (e.g., 5 requests per hour per IP)
const otpLimiter = rateLimit({
    windowMs: 60 * 60 * 1000,
    max: 10,
    message: 'Too many OTP requests, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
});

// Limiter for file uploads (e.g., 50 uploads per hour per IP)
const uploadLimiter = rateLimit({
    windowMs: 60 * 60 * 1000,
    max: 50,
    message: 'Too many uploads, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
});

module.exports = {
    generalLimiter,
    strictLimiter,
    otpLimiter,
    uploadLimiter,
};