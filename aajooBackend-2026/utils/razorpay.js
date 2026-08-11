const Razorpay = require('razorpay');
const crypto = require('crypto');
const { razorpay: razorpayConfig } = require("../config/payments.config");

const razorpay = new Razorpay({
    key_id: razorpayConfig.keyId,
    key_secret: razorpayConfig.keySecret,
});

const verifyPayment = async (paymentId, orderId, signature) => {
    try {
        const hmac = crypto.createHmac('sha256', razorpayConfig.keySecret); // single source: config/payments.config.js
        hmac.update(orderId + '|' + paymentId);
        const generatedSignature = hmac.digest('hex');
        if (generatedSignature === signature) {
            return true
        } else {
            return false
        }
    } catch (error) {
        throw new Error(error.message)
    }
};
const createOrder = async (payload) => {
    try {
        let amount = payload.amount * 100;
        const options = {
            amount: amount,
            currency: payload.currency || 'INR',
            receipt: `receipt_${Date.now()}`,
            payment_capture: 1
        };
        const order = await razorpay.orders.create(options);
        return order;
    } catch (error) {
        return error;
    }
};

const createPaymentReq = async (payload, bookignId) => {
    try {
        const paymentLink = await razorpay.paymentLink.create({
            amount: payload.price * 100, // Amount in smallest currency unit (e.g., paise for INR)
            currency: "INR",
            description: 'Payment for Booking',
            customer: {
                name: "test name",
                propertyId: payload.propertyId,
                bookignId: bookignId,
                contact: "0987654321",
            },
            callback_url: 'http://your-website.com/payment-success',
            callback_method: 'get',
        });
        return paymentLink;
    } catch (error) {
        return error
    }
};
const getPaymentStatus = async (paymentId) => {
    try {
        const paymentDetails = await razorpay.paymentLink.fetch(paymentId);
    } catch (error) {
        console.error("Error fetching payment details:", error);
    }
};
module.exports = { createPaymentReq, createOrder, verifyPayment, getPaymentStatus };

