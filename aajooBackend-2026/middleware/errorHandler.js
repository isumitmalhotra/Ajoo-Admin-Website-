const logger = require("../utils/logger");

const errorHandler = (err, req, res, next) => {
    // Log the error
    logger.error(`Error in ${req.method} ${req.path}: ${err.message}`, {
        stack: err.stack,
        body: req.body,
        params: req.params,
        query: req.query,
        user: req.user
    });

    // Determine status code
    let statusCode = err.statusCode || err.status || 500;
    if (statusCode < 400) statusCode = 500;

    // Determine message
    let message = err.message || 'Internal Server Error';

    // In production, don't leak error details
    if (process.env.NODE_ENV === 'production' && statusCode === 500) {
        message = 'Something went wrong';
    }

    // Send standardized response
    res.status(statusCode).json({
        success: false,
        message: message,
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
};

module.exports = errorHandler;
