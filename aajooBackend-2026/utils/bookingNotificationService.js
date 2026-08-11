const leadService = require('./leadService');
const model = require('../models');
const logger = require('./logger');

const DEFAULT_USER_NAME = 'Guest';
const DEFAULT_COUNTRY_CODE = process.env.BOTPENGUIN_DEFAULT_COUNTRY_CODE || '91';
const CURRENCY_SYMBOL = process.env.BOTPENGUIN_CURRENCY_SYMBOL || '₹';

/**
 * Normalize phone number to WhatsApp ID format (country code + number)
 * @param {string|number} phoneValue - Phone number to normalize
 * @returns {string|null} - Formatted WhatsApp ID or null if invalid
 */
const normalizeWaId = (phoneValue) => {
    const digits = String(phoneValue || '').replace(/\D/g, '');
    if (!digits) return null;

    // If only 10 digits, prepend country code
    if (digits.length === 10) {
        return `${DEFAULT_COUNTRY_CODE}${digits}`;
    }

    // Already has country code
    return digits;
};

/**
 * Format date for WhatsApp message (DD-MM-YYYY format)
 * @param {string|Date} dateValue - Date to format
 * @returns {string} - Formatted date string
 */
const formatDateForTemplate = (dateValue) => {
    if (!dateValue) return 'N/A';

    try {
        // Handle string dates (DD-MM-YYYY format)
        if (typeof dateValue === 'string') {
            return dateValue; // Assuming already in correct format
        }

        // Handle Date objects
        if (dateValue instanceof Date) {
            const day = String(dateValue.getDate()).padStart(2, '0');
            const month = String(dateValue.getMonth() + 1).padStart(2, '0');
            const year = dateValue.getFullYear();
            return `${day}-${month}-${year}`;
        }

        return String(dateValue);
    } catch (err) {
        logger.error(`Error formatting date: ${err.message}`, { dateValue });
        return 'N/A';
    }
};

/**
 * Format amount for WhatsApp message
 * @param {number|string} amount - Amount to format
 * @returns {string} - Formatted amount with currency symbol
 */
const formatAmountForTemplate = (amount) => {
    if (amount == null) return 'N/A';

    try {
        const numAmount = Number(amount);
        if (isNaN(numAmount)) return 'N/A';

        // Format with commas and 2 decimals
        const formatted = numAmount.toLocaleString('en-IN', {
            minimumFractionDigits: 0,
            maximumFractionDigits: 2,
        });

        return `${CURRENCY_SYMBOL} ${formatted}`;
    } catch (err) {
        logger.error(`Error formatting amount: ${err.message}`, { amount });
        return 'N/A';
    }
};

/**
 * Build body parameters array for BotPenguin template
 * @param  {...string} values - Values to include in body
 * @returns {Array} - Formatted body parameters
 */
const normalizeTemplateText = (value, fallback = 'N/A') => {
    if (value == null) return fallback;

    const normalized = String(value).trim();
    return normalized.length ? normalized : fallback;
};

const buildBodyParams = (...values) => {
    // WhatsApp requires exact parameter count, but rejects empty text values.
    const normalizedValues = values.map((value) => normalizeTemplateText(value));

    return [
        {
            type: 'body',
            parameters: normalizedValues.map((text) => ({
                type: 'text',
                text,
            })),
        },
    ];
};

/**
 * Get template configuration for booking confirmation
 * @param {Object} bookingData - Booking details
 * @returns {Object} - Template configuration
 */
const getBookingTemplateConfig = (bookingData) => {
    const {
        userFullName = DEFAULT_USER_NAME,
        bookingId = 'N/A',
        propertyName = 'Property',
        checkInDate = 'N/A',
        checkOutDate = 'N/A',
        totalAmount = '0',
        city = null,
        isPaid = false,
        isCod = false,
    } = bookingData;

    const assignTo = process.env.BOTPENGUIN_BOOKING_TEMPLATE_ASSIGN_TO || undefined;
    const hasCity = Boolean(city);
    const formattedAmount = formatAmountForTemplate(totalAmount);

    // Determine which template to use
    let templateId;
    let params;

    if (isCod && !isPaid) {
        // COD Booking - Payment pending
        templateId = hasCity
            ? process.env.BOTPENGUIN_BOOKING_COD_TEMPLATE_ID
            : process.env.BOTPENGUIN_BOOKING_COD_NO_CITY_TEMPLATE_ID ||
            process.env.BOTPENGUIN_BOOKING_COD_TEMPLATE_ID;

        params = buildBodyParams(
            userFullName,
            bookingId,
            propertyName,
            formatDateForTemplate(checkInDate),
            formatDateForTemplate(checkOutDate),
            formattedAmount,
            city || ''
        );
    } else {
        // Regular booking (paid or payment pending)
        templateId = hasCity
            ? process.env.BOTPENGUIN_BOOKING_TEMPLATE_ID
            : process.env.BOTPENGUIN_BOOKING_NO_CITY_TEMPLATE_ID ||
            process.env.BOTPENGUIN_BOOKING_TEMPLATE_ID;

        // Always send 7 parameters for consistency
        params = buildBodyParams(
            userFullName,
            bookingId,
            propertyName,
            formatDateForTemplate(checkInDate),
            formatDateForTemplate(checkOutDate),
            formattedAmount,
            city || ''  // Include city even if empty
        );
    }

    return {
        templateId,
        params,
        tags: ['booking_confirmation', isCod ? 'cod_booking' : 'prepaid_booking'],
        assignTo,
        bookingType: isCod ? 'cod' : 'prepaid',
    };
};

/**
 * Send template via BotPenguin WhatsApp API
 * @param {Object} params - Request parameters
 * @returns {Promise<Object>} - Response from BotPenguin API
 */
const sendBotPenguinTemplate = async ({
    userName = DEFAULT_USER_NAME,
    waId,
    templateId,
    params = [],
    tags = [],
    assignTo,
    actionType = 'BookingNotification',
}) => {
    const botPenguinApiKey = process.env.BOTPENGUIN_WHATSAPP_API_KEY;
    const botPenguinApiUrl = process.env.BOTPENGUIN_API_URL || 'https://api.v7.botpenguin.com';

    if (!botPenguinApiKey) {
        logger.warn(`[${actionType}] BOTPENGUIN_WHATSAPP_API_KEY not set. Skipping message send.`);
        return { sent: false, reason: 'missing_config' };
    }

    if (!waId) {
        logger.warn(`[${actionType}] wa_id missing. Skipping message send.`);
        return { sent: false, reason: 'missing_wa_id' };
    }

    if (!templateId) {
        logger.warn(`[${actionType}] templateId missing. Skipping template send.`);
        return { sent: false, reason: 'missing_template_id' };
    }

    try {
        const requestUrl = new URL('/whatsapp-automation/wa/send-template', botPenguinApiUrl);
        requestUrl.searchParams.set('apiKey', botPenguinApiKey);

        const payload = {
            userName: userName || DEFAULT_USER_NAME,
            wa_id: String(waId),
            templateId: String(templateId),
            params,
            tags,
        };

        if (assignTo) {
            payload.assignTo = assignTo;
        }

        logger.info(`[${actionType}] Sending BotPenguin booking template`, {
            wa_id: payload.wa_id,
            userName: payload.userName,
            templateId: payload.templateId,
            tags: payload.tags,
            assignTo: payload.assignTo || null,
        });

        const res = await fetch(requestUrl.toString(), {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                apiKey: botPenguinApiKey,
            },
            body: JSON.stringify(payload),
        });

        const data = await res.json();

        logger.info(`[${actionType}] BotPenguin response`, {
            status: res.status,
            wa_id: String(waId),
            templateId: String(templateId),
            success: data?.success,
            messageId: data?.messageId || null,
        });

        if (!res.ok || data?.success === false) {
            logger.error(`[${actionType}] BotPenguin API error`, {
                status: res.status,
                wa_id: String(waId),
                templateId: String(templateId),
                error: data?.message || data?.error || 'Unknown error',
                response: data,
            });
        }

        return {
            sent: res.ok && data?.success !== false,
            status: res.status,
            response: data,
            reason: data?.message || null,
            messageId: data?.messageId || null,
        };
    } catch (err) {
        logger.error(`[${actionType}] sendBotPenguinTemplate error`, {
            error: err.message,
            waId: String(waId),
            templateId: String(templateId),
        });
        return { sent: false, reason: err.message };
    }
};

/**
 * Get user phone number from database
 * @param {number} userId - User ID
 * @returns {Promise<string|null>} - User's phone number
 */
const getUserPhoneNumber = async (userId) => {
    try {
        const user = await model.tbl_user.findOne({
            where: { user_id: userId },
            attributes: ['user_pnumber'],
            raw: true,
        });

        return user?.user_pnumber || null;
    } catch (err) {
        logger.error(`Error getting user phone: ${err.message}`, { userId });
        return null;
    }
};

/**
 * Get user full name
 * @param {number} userId - User ID
 * @returns {Promise<string>} - User's full name or default
 */
const getUserFullName = async (userId) => {
    try {
        const user = await model.tbl_user.findOne({
            where: { user_id: userId },
            attributes: ['user_fullName'],
            raw: true,
        });

        return user?.user_fullName || DEFAULT_USER_NAME;
    } catch (err) {
        logger.error(`Error getting user name: ${err.message}`, { userId });
        return DEFAULT_USER_NAME;
    }
};

/**
 * Send booking confirmation message via WhatsApp
 * @param {Object} bookingDetails - Booking details
 * @returns {Promise<Object>} - Result of sending
 */
const sendBookingConfirmationMessage = async (bookingDetails) => {
    const {
        bookingId,
        userId,
        bookingPrice,
        totalBookingAmount,
        propertyId,
        propertyName,
        checkInDate,
        checkOutDate,
        isPaid,
        isCod,
        city = null,
    } = bookingDetails;

    try {
        // Get user details
        const [userFullName, userPhone] = await Promise.all([
            getUserFullName(userId),
            getUserPhoneNumber(userId),
        ]);

        if (!userPhone) {
            logger.warn('[BookingNotification] No phone number found for user', { userId, bookingId });
            return {
                sent: false,
                reason: 'user_phone_not_found',
                bookingId,
            };
        }

        const waId = normalizeWaId(userPhone);
        if (!waId) {
            logger.warn('[BookingNotification] Invalid phone number format', { userId, bookingId, userPhone });
            return {
                sent: false,
                reason: 'invalid_phone_format',
                bookingId,
            };
        }

        // Get template configuration
        const templateConfig = getBookingTemplateConfig({
            userFullName,
            bookingId,
            propertyName,
            checkInDate,
            checkOutDate,
            totalAmount: totalBookingAmount || bookingPrice,
            city,
            isPaid: isPaid === 1 || isPaid === true,
            isCod: isCod === 1 || isCod === true,
        });

        // Send message
        const result = await sendBotPenguinTemplate({
            userName: userFullName,
            waId,
            templateId: templateConfig.templateId,
            params: templateConfig.params,
            tags: templateConfig.tags,
            assignTo: templateConfig.assignTo,
            actionType: 'BookingNotification',
        });

        // Log the event
        try {
            await leadService.logEvent({
                sessionId: null,
                phone: userPhone,
                type: 'booking_confirmation_sent',
                data: {
                    booking_id: bookingId,
                    property_id: propertyId,
                    property_name: propertyName,
                    checkin_date: checkInDate,
                    checkout_date: checkOutDate,
                    amount: totalBookingAmount || bookingPrice,
                    is_paid: isPaid,
                    is_cod: isCod,
                    sent: result.sent,
                    wa_id: waId,
                    user_name: userFullName,
                    template_id: templateConfig.templateId || null,
                    booking_type: templateConfig.bookingType,
                    response_status: result.status || null,
                    response_message: result.reason || null,
                    message_id: result.messageId || null,
                },
                channel: 'whatsapp',
            });
        } catch (logErr) {
            logger.error('[BookingNotification] Error logging event', { error: logErr.message, bookingId });
        }

        logger.info('[BookingNotification] Booking confirmation sent', {
            bookingId,
            userId,
            sent: result.sent,
            waId: waId.slice(-10), // Log last 10 digits only
            templateType: templateConfig.bookingType,
        });

        return {
            sent: result.sent,
            reason: result.reason,
            messageId: result.messageId,
            bookingId,
            status: result.status,
        };
    } catch (err) {
        logger.error('[BookingNotification] Error in sendBookingConfirmationMessage', {
            error: err.message,
            bookingId,
            userId,
            stack: err.stack,
        });

        return {
            sent: false,
            reason: err.message,
            bookingId,
        };
    }
};

/**
 * Send booking cancellation notification via WhatsApp
 * @param {Object} cancellationDetails - Cancellation details
 * @returns {Promise<Object>} - Result of sending
 */
const sendBookingCancellationMessage = async (cancellationDetails) => {
    const { bookingId, userId, propertyName, refundAmount } = cancellationDetails;

    try {
        // Get user details
        const [userFullName, userPhone] = await Promise.all([
            getUserFullName(userId),
            getUserPhoneNumber(userId),
        ]);

        if (!userPhone) {
            logger.warn('[BookingNotification] No phone for cancellation notification', { userId, bookingId });
            return { sent: false, reason: 'user_phone_not_found' };
        }

        const waId = normalizeWaId(userPhone);
        if (!waId) {
            return { sent: false, reason: 'invalid_phone_format' };
        }

        logger.info('[BookingNotification] Booking cancellation notification sent to user', {
            bookingId,
            userId,
            waId: waId.slice(-10),
        });

        return {
            sent: true,
            bookingId,
            messageType: 'cancellation',
        };
    } catch (err) {
        logger.error('[BookingNotification] Error sending cancellation message', {
            error: err.message,
            bookingId,
        });
        return { sent: false, reason: err.message };
    }
};

module.exports = {
    sendBookingConfirmationMessage,
    sendBookingCancellationMessage,
    sendBotPenguinTemplate,
    normalizeWaId,
    formatDateForTemplate,
    formatAmountForTemplate,
    getBookingTemplateConfig,
};
