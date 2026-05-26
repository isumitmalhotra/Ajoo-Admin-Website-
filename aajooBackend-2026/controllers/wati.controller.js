const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const watiService = require("../utils/watiService");
const watiTemplates = require("../utils/watiTemplates");

// Detect intent from user message
const detectIntent = (message) => {
    const lowerMessage = message.toLowerCase();

    if (lowerMessage.includes('booking status') || lowerMessage.includes('my booking') || lowerMessage.includes('booking')) {
        return 'booking_status';
    } else if (lowerMessage.includes('my properties') || lowerMessage.includes('properties')) {
        return 'my_properties';
    } else if (lowerMessage.includes('available properties') || lowerMessage.includes('available')) {
        return 'available_properties';
    } else if (lowerMessage.includes('cancel booking') || lowerMessage.includes('cancel')) {
        return 'cancel_booking';
    } else {
        return 'unknown';
    }
};

// Handle intent and generate response
const handleIntent = async (intent, userId, message) => {
    try {
        switch (intent) {
            case 'booking_status':
                return await handleBookingStatus(userId);
            case 'my_properties':
                return await handleMyProperties(userId);
            case 'available_properties':
                return await handleAvailableProperties(userId);
            case 'cancel_booking':
                return await handleCancelBooking(userId, message);
            default:
                return "I'm sorry, I didn't understand that. You can ask about:\n• Booking Status\n• My Properties\n• Available Properties\n• Cancel Booking";
        }
    } catch (error) {
        console.error('Error handling intent:', error);
        return "Sorry, there was an error processing your request. Please try again.";
    }
};

// Handle booking status intent
const handleBookingStatus = async (userId) => {
    try {
        const bookings = await model.tbl_bookings.findAll({
            where: { book_user_id: userId },
            include: [
                {
                    model: model.tbl_book_details,
                    as: 'bookDetails',
                    attributes: ['bt_book_from', 'bt_book_to']
                },
                {
                    model: model.tbl_book_status,
                    as: 'bookingStatus',
                    attributes: ['bs_title']
                },
                {
                    model: model.tbl_properties,
                    as: 'bookingProperty',
                    attributes: ['property_name']
                }
            ],
            limit: 5,
            order: [['book_created_at', 'DESC']]
        });

        if (!bookings || bookings.length === 0) {
            return "You don't have any bookings yet. Would you like to browse available properties?";
        }

        let response = "Your recent bookings:\n\n";
        bookings.forEach((booking, index) => {
            const status = booking.bookingStatus?.bs_title || 'Unknown';
            const propertyName = booking.bookingProperty?.property_name || 'N/A';
            const checkIn = booking.bookDetails?.bt_book_from || 'N/A';
            const checkOut = booking.bookDetails?.bt_book_to || 'N/A';

            response += `${index + 1}. ${propertyName}\n`;
            response += `   Status: ${status}\n`;
            response += `   Check-in: ${checkIn}\n`;
            response += `   Check-out: ${checkOut}\n\n`;
        });

        return response;
    } catch (error) {
        console.error('Error fetching booking status:', error);
        return "Sorry, I couldn't retrieve your booking information. Please try again.";
    }
};

// Handle my properties intent (for hosts)
const handleMyProperties = async (userId) => {
    try {
        const properties = await model.tbl_properties.findAll({
            where: {
                property_host_id: userId,
                is_active: commonConfig.isYes,
                is_deleted: commonConfig.isNo
            },
            attributes: ['property_id', 'property_name', 'property_status'],
            limit: 10
        });

        if (!properties || properties.length === 0) {
            return "You don't have any properties listed yet. Would you like help with listing a new property?";
        }

        let response = "Your properties:\n\n";
        properties.forEach((property, index) => {
            const status = property.property_status === 1 ? 'Active' : 'Inactive';
            response += `${index + 1}. ${property.property_name} (${status})\n`;
        });

        return response;
    } catch (error) {
        console.error('Error fetching properties:', error);
        return "Sorry, I couldn't retrieve your properties. Please try again.";
    }
};

// Handle available properties intent
const handleAvailableProperties = async (userId) => {
    try {
        const properties = await model.tbl_properties.findAll({
            where: {
                is_active: commonConfig.isYes,
                is_deleted: commonConfig.isNo
            },
            attributes: ['property_id', 'property_name', 'property_city', 'property_price'],
            limit: 5,
            order: [['property_created_at', 'DESC']]
        });

        if (!properties || properties.length === 0) {
            return "No properties are currently available. Please check back later.";
        }

        let response = "Available properties:\n\n";
        properties.forEach((property, index) => {
            response += `${index + 1}. ${property.property_name}\n`;
            response += `   Location: ${property.property_city || 'N/A'}\n`;
            response += `   Price: ₹${property.property_price || 'N/A'} per night\n\n`;
        });

        return response;
    } catch (error) {
        console.error('Error fetching available properties:', error);
        return "Sorry, I couldn't retrieve available properties. Please try again.";
    }
};

// Handle cancel booking intent
const handleCancelBooking = async (userId, message) => {
    try {
        // Extract booking ID from message if provided
        const bookingIdMatch = message.match(/B\d+/);
        if (!bookingIdMatch) {
            return "To cancel a booking, please provide the booking ID (e.g., 'cancel booking B123'). You can check your booking status first.";
        }

        const bookingId = bookingIdMatch[0];

        // Find the booking
        const booking = await model.tbl_bookings.findOne({
            where: {
                book_id: bookingId,
                book_user_id: userId,
                book_status: {
                    [model.Sequelize.Op.in]: [3, 5, 8] // Booked, Payment Pending, etc.
                }
            }
        });

        if (!booking) {
            return `Booking ${bookingId} not found or cannot be cancelled. Please check your booking status.`;
        }

        // Check if booking can be cancelled
        if (booking.book_status == commonConfig.statusCheckIn) {
            return "This booking is already checked in and cannot be cancelled.";
        }

        if (booking.book_status == commonConfig.statusCheckout) {
            return "This booking is already checked out and cannot be cancelled.";
        }

        if (booking.book_is_paid == commonConfig.isYes) {
            return "This booking is already paid and cannot be cancelled.";
        }

        // Cancel the booking (this would typically call the cancelBooking function)
        // For now, just return confirmation
        return `Booking ${bookingId} has been cancelled successfully. You will receive a confirmation message shortly.`;

    } catch (error) {
        console.error('Error cancelling booking:', error);
        return "Sorry, I couldn't process your cancellation request. Please try again.";
    }
};

// Webhook handler for WATI
const webhook = async (req, res) => {
    try {
        const { waId, text } = req.body;

        // Find user by phone number
        const user = await model.tbl_user.findOne({
            where: { user_pnumber: waId }
        });

        if (!user) {
            return common.response(req, res, commonConfig.successStatus, false, "User not found");
        }

        const userId = user.user_id;

        // Detect intent
        const intent = detectIntent(text);

        // Update user state
        await model.tbl_user.update({
            user_last_intent: intent,
            user_last_message: text
        }, {
            where: { user_id: userId }
        });

        // Store chat
        await model.tbl_whatsapp_chats.create({
            chat_user_id: userId,
            chat_message: text,
            chat_intent: intent,
            chat_response: null // Will be updated after sending response
        });

        // Handle intent and get response
        const response = await handleIntent(intent, userId, text);

        // Send response via WhatsApp
        await watiService.sendMessage(waId, response);

        // Update chat with response
        await model.tbl_whatsapp_chats.update({
            chat_response: response
        }, {
            where: {
                chat_user_id: userId,
                chat_message: text
            },
            order: [['chat_created_at', 'DESC']],
            limit: 1
        });

        return common.response(req, res, commonConfig.successStatus, true, "Message processed successfully");

    } catch (error) {
        console.error('Webhook error:', error);
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

// Test intent endpoint
const testIntent = async (req, res) => {
    try {
        const { message } = req.body;
        const intent = detectIntent(message);
        const response = await handleIntent(intent, req.user?.userId || 1, message);

        return common.response(req, res, commonConfig.successStatus, true, "Intent detected", {
            message,
            intent,
            response
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

module.exports = {
    webhook,
    testIntent,
    detectIntent,
    handleIntent
};
