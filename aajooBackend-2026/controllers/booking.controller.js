const model = require("../models");
const common = require("../utils/common");
const methods = require("../utils/methods");
const commonConfig = require("../config/commonConfig");
const moduleConfig = require("../config/moduleConfigs");
const { sequelize } = require('../models');
const { Op, literal } = require('sequelize');
const { createOrder, verifyPayment } = require("../utils/razorpay");
const EmailManager = require("../utils/mailer");
const Razorpay = require('razorpay');
const { CloudinaryManager } = require("../utils/cloudinary");
const moment = require("moment");
const
    {
        notificationBookingMessage,
        notificationBookingMessageForHost,
        notificationBookingTitleForHost,
        notificationBookingTitle
    } = require("../utils/data");
const logger = require("../utils/logger");
const watiService = require("../utils/watiService");
const watiTemplates = require("../utils/watiTemplates");
const razorpay = new Razorpay(
    {
        key_id: moduleConfig.razor_pay_key_id,
        key_secret: moduleConfig.razor_pay_key_sec,
    });
const emailManager = new EmailManager();
const cloudinaryInstance = new CloudinaryManager();

// Helper function to send booking notifications and emails
const sendBookingNotifications = async (userId, hostId, bookingId, propertyData, reqData, totalBookingAmt, userEmail) => {
    try {
        const userDetail = await model.tbl_user.findUser({ user_id: userId }, ["user_fullName"]);
        let contentPayload = {
            username: userDetail.user_fullName,
            bookingId: bookingId,
            propertyName: propertyData.property_name,
            checkinDate: reqData.bookFrom,
            checkoutDate: reqData.bookTo,
            totalPrice: totalBookingAmt,
        };
        let content = emailManager.bookingMail(contentPayload);
        let emailData = emailManager.makeContent(content);
        let option = {
            to: userEmail,
            subject: 'Booking Confirmation',
            data: emailData,
            userId: userId,
            status: "email sent successfully",
            mailType: "user booking confirmation",
        };
        let notifyMessage = `${notificationBookingMessage} ${bookingId}`;
        let payloadData = {
            route: "/negotitation",
            type: "negotiation_request",
            propertyId: `${reqData.propertyId}`,
            userId: `${userId}`,
            receiverId: `${hostId}`,
            hostId: `${hostId}`,
            lat: `${propertyData.property_latitude}`,
            long: `${propertyData.property_longitude}`
        };
        let notifyMessageHost = `${notificationBookingMessageForHost} ${bookingId}`;
        emailManager.sendEmail(option);
        await methods.sendNotification(userId, notificationBookingTitle, notifyMessage, reqData.propertyId, {}, bookingId);
        await methods.sendNotification(hostId, notificationBookingTitleForHost, notifyMessageHost, reqData.propertyId, payloadData, bookingId);
    } catch (error) {
        logger.error(`Error sending booking notifications: ${error.message}`);
    }
};

// Helper function to send cancellation notifications
const sendCancellationNotifications = async (userId, hostId, bookingId, propertyId, userEmail) => {
    try {
        const userDetail = await model.tbl_user.findUser({ user_id: userId }, ["user_fullName"]);
        let userContentPayload = {
            name: userDetail.user_fullName,
            bookingId: bookingId,
        };
        let userContent = emailManager.bookingCancellforUser(userContentPayload);
        let userEmailData = emailManager.makeContent(userContent);
        let userOption = {
            to: userEmail,
            subject: `Booking ${bookingId} Cancelled`,
            data: userEmailData,
            userId: userId,
            status: "email sent successfully",
            mailType: "User cancel the booking",
        };
        emailManager.sendEmail(userOption);

        const hostDetail = await model.tbl_user.findUser({ user_id: hostId }, ["user_fullName"]);
        let hostEmailId = await model.tbl_user_cred.findUser({ cred_user_id: hostId }, ["cred_user_email"]);
        let hostContentPayload = {
            hostName: hostDetail.user_fullName,
            bookingId: bookingId,
            userName: userDetail.user_fullName,
        };
        let hostContent = emailManager.bookingCancellforHost(hostContentPayload);
        let hostEmailData = emailManager.makeContent(hostContent);
        let hostOption = {
            to: hostEmailId.cred_user_email,
            subject: `Booking ${bookingId} Cancelled By The User`,
            data: hostEmailData,
            userId: userId,
            status: "email sent successfully",
            mailType: "User Cancel the booking",
        };
        emailManager.sendEmail(hostOption);

        // Notifications
        let notifyTitle = `Booking ${bookingId} Cancelled`;
        let notifyMessage = `Booking ${bookingId} is cancelled successfully`;
        let notifyMessageHost = `Booking ${bookingId} is cancelled by the user`;
        await methods.sendNotification(userId, notifyTitle, notifyMessage, propertyId, {}, bookingId);
        await methods.sendNotification(hostId, notifyTitle, notifyMessageHost, propertyId, {}, bookingId);
    } catch (error) {
        logger.error(`Error sending cancellation notifications: ${error.message}`);
    }
};

const bookingCreate = async (req, res) => {
    const transaction = await sequelize.transaction();
    let isPaid = commonConfig.isNo;
    let isCod;
    let bookStatus;
    try {
        const reqData = { ...req.body };
        let userId = req.user.userId;
        let propWhereClause = {
            property_id: reqData.propertyId,
            is_active: commonConfig.isYes,
            is_deleted: commonConfig.isNo
        };
        const propertyData = await model.tbl_properties.getSingleProperty(propWhereClause, ["property_host_id", "property_name", "property_longitude", "property_latitude"])
        if (!propertyData) {
            await transaction.rollback();
            return common.response(req, res, commonConfig.errorStatus, false, "no property found");
        }
        let dateValidation = methods.validateBookingDates(reqData.bookFrom, reqData.bookTo)
        if (!dateValidation["success"]) {
            await transaction.rollback();
            return common.response(req, res, commonConfig.errorStatus, false, dateValidation["message"]);
        }
        let order_id = null;
        const bookingId = methods.genrateBookingId();
        let { tax, taxPercentage } = methods.calculateBookingtax(reqData.price);
        let totalBookingAmt = reqData.price + tax;
        if (!reqData.isCod) {
            order_id = await createOrder({ amount: totalBookingAmt });
            if (!order_id) {
                await transaction.rollback();
                return common.response(req, res, commonConfig.errorStatus, false, "Something went wrong, while creating order");
            }
            isCod = commonConfig.isNo;
            bookStatus = commonConfig.statusPaymentPending;
        } else {
            isCod = commonConfig.isYes;
            bookStatus = commonConfig.statusBooked;
        }
        let bookPriId;
        const payload = {
            book_id: `B${bookingId}`,
            book_invoice: `Inv_${bookingId}`,
            book_prop_id: reqData.propertyId,
            book_user_id: userId,
            book_host_id: propertyData.property_host_id,
            book_price: reqData.price,
            book_tax: tax,
            book_tax_percentagenatage: taxPercentage,
            book_total_amt: totalBookingAmt,
            book_is_paid: isPaid,
            book_is_cod: isCod,
            book_status: bookStatus,
            book_no_of_guests: reqData.no_of_guests ?? null,
            book_no_of_beds: reqData.no_of_beds ?? null
        };
        if (reqData.category || reqData.category !== null) {
            payload.book_prop_type = reqData.category;
        }
        const data = await model.tbl_bookings.create(payload, { transaction });
        bookPriId = data.dataValues.book_pri_id;
        let detailPayload = {
            bt_book_pri_id: bookPriId,
            bt_book_id: `B${bookingId}`,
            bt_book_from: reqData.bookFrom,
            bt_book_to: reqData.bookTo,
            
            bt_book_status: bookStatus,
        };
        await model.tbl_book_details.create(detailPayload, { transaction });
        let historyPayload = {
            bh_book_id: bookPriId,
            bh_user_id: userId,
            bh_host_id: propertyData.property_host_id,
            bh_price: reqData.price,
            bh_prop_id: reqData.propertyId,
            bh_status_id: bookStatus,
            bh_title: `Booking Successful`,
            bh_description: `Booking is create & payment pending`,
        };
        await model.tbl_book_history.create(historyPayload, { transaction });
        if (!reqData.isCod) {
            let paymentPayload = {
                pay_raz_id: "No id Yet,order created",
                pay_order_id: order_id ? order_id.id : "COD",
                pay_receipt_id: order_id ? order_id.receipt : "COD",
                pay_bookId: `B${bookingId}`,
                pay_book_pri_id: bookPriId,
                pay_userId: userId,
                pay_hostId: propertyData.property_host_id,
                pay_propId: reqData.propertyId,
                pay_invoice: `Inv_${bookingId}`,
                pay_amount: reqData.price,
                pay_status: bookStatus,
                pay_status_text: "Not Verified Yet",
            };
            await model.tbl_payment.create(paymentPayload, { transaction });
        }
        await transaction.commit();
        if (isCod) {
            sendBookingNotifications(userId, propertyData.property_host_id, `B${bookingId}`, propertyData, reqData, totalBookingAmt, req.user.email);
        }
        return common.response(req, res, commonConfig.successStatus, true, "success", {
            booking: {
                book_id: `B${bookingId}`,
                order: order_id
            }
        });
    } catch (error) {
        await transaction.rollback();
        logger.error(`Error in booking_Create: ${error.message}`, { stack: error.stack });
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const CreatePayment = async (req, res) => {
    let transaction = await sequelize.transaction();
    try {
        const reqData = { ...req.body };
        const paymentLink = await razorpay.paymentLink.create({
            amount: 100 * 100, // Amount in smallest currency unit (e.g., paise for INR)
            currency: "INR",
            description: 'Payment for your order',
            customer: {
                name: "ashish",
                // email: email,
                contact: "0987654321",
            },
            callback_url: 'http://your-website.com/payment-success',
            callback_method: 'get',
        });
        return common.response(req, res, commonConfig.successStatus, true, "success", paymentLink);
    } catch (error) {
        console.log(error)
        logger.error(`Error in create_Payment: ${error.message}`, { stack: error.stack });
        await transaction.rollback();
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const verifyUserPayment = async (req, res) => {
    const transaction = await sequelize.transaction();
    try {
        const reqData = { ...req.body };
        let userId = req.user.userId;
        let razOrderId = reqData.orderId;
        let razPaymentId = reqData.paymentId;
        let razSignature = reqData.signature;
        const findPayment = await model.tbl_payment.findOne({
            raw: true,
            where: { pay_order_id: razOrderId },
            attributes: ["pay_id", "pay_hostId", "pay_propId", "pay_amount", "pay_book_pri_id", "pay_invoice"]
        });
        if (!findPayment) {
            return common.response(req, res, commonConfig.successStatus, true, "No record found",);
        }

        const isVerify = await verifyPayment(razPaymentId, razOrderId, razSignature);
        if (isVerify) {
            let paymentPayload = {
                pay_raz_id: razPaymentId,
                pay_status: commonConfig.paid,
                pay_status_text: "Paid & Verified",
            }
            await model.tbl_payment.update(paymentPayload, { where: { pay_id: findPayment.pay_id } }, { transaction });
            let bookingPayload = {
                book_is_paid: commonConfig.isYes,
                book_status: commonConfig.paid
            };
            await model.tbl_bookings.update(bookingPayload, { where: { book_pri_id: findPayment.pay_book_pri_id } }, { transaction });
            await model.tbl_book_details.update({ bt_book_status: commonConfig.paid }, { where: { bt_book_pri_id: findPayment.pay_book_pri_id } }, { transaction });
            let historyPayload = {
                bh_book_id: findPayment.pay_book_pri_id,
                bh_user_id: userId,
                bh_host_id: findPayment.pay_hostId,
                bh_price: findPayment.pay_amount,
                bh_prop_id: findPayment.pay_propId,
                bh_status_id: commonConfig.paid,
                bh_title: `Payment Done`,
                bh_description: `Payment is done & verified`,
            };
            await model.tbl_book_history.create(historyPayload, { transaction });
            let hostEarningPayload = {
                he_booking_id: findPayment.pay_book_pri_id,
                he_host_id: findPayment.pay_hostId,
                he_payment_id: findPayment.pay_id,
                he_amount: findPayment.pay_amount,
                he_invoice: findPayment.pay_invoice,
                he_status: commonConfig.statusPaymentRecieved,
            };
            await model.tbl_host_earnings.create(hostEarningPayload, { transaction });
            let notifyTitle = "Payment Successfull";
            let notifyMessage = `Payment for ${findPayment.pay_invoice} is successful`;
            await methods.sendNotification(userId, notifyTitle, notifyMessage, findPayment.pay_propId, {}, null, findPayment.pay_book_pri_id);
            await transaction.commit();
            return common.response(req, res, commonConfig.successStatus, true, "payment verified",);
        }
        else {
            await transaction.rollback();
            return common.response(req, res, commonConfig.successStatus, true, "Unable to Verify,Something went wrong",);
        }
    } catch (error) {
        await transaction.rollback();
        logger.error(`Error in verify_User_Payment: ${error.message}`, { stack: error.stack });
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const cancelBooking = async (req, res) => {
    const transaction = await sequelize.transaction();
    try {
        const reqData = { ...req.body };
        let userId = req.user.userId;
        let userEmail = req.user.email;
        let whereClause = {
            book_id: reqData.bookingId,
            book_user_id: userId,
            book_status: {
                [Op.in]: [3, 5, 8,]
            }
        };
        let isBooking = await model.tbl_bookings.getBookings(whereClause, ["book_prop_id", "book_is_paid", "book_host_id", "book_is_cod", "book_pri_id", "book_status", "book_price"]);
        if (!isBooking) {
            return common.response(req, res, commonConfig.errorStatus, false, "Not allowed to cancel this booking");
        }
        let hostId = isBooking["book_host_id"]
        if (isBooking.book_status == commonConfig.statusCheckIn) {
            return common.response(req, res, commonConfig.errorStatus, false, "Booking is already checked in can't be cancelled");
        }
        if (isBooking.book_status == commonConfig.statusCheckout) {
            return common.response(req, res, commonConfig.errorStatus, false, "Booking is already checked out can't be cancelled");
        }
        if (isBooking.book_is_paid == commonConfig.isYes) {
            return common.response(req, res, commonConfig.errorStatus, false, "Booking is already paid can't be cancelled");
        }
        await model.tbl_bookings.update({ book_status: commonConfig.statusBookingCancelled }, { where: { book_pri_id: isBooking.book_pri_id } }, { transaction });
        await model.tbl_book_details.update({ bt_book_status: commonConfig.statusBookingCancelled }, { where: { bt_book_pri_id: isBooking.book_pri_id } }, { transaction });
        let historyPayload = {
            bh_book_id: isBooking.book_pri_id,
            bh_user_id: userId,
            bh_host_id: isBooking.book_host_id,
            bh_price: isBooking.book_price,
            bh_prop_id: isBooking.book_prop_id,
            bh_status_id: commonConfig.statusBookingCancelled,
            bh_title: `Booking Cancelled`,
            bh_description: `Booking is cancelled`,
        };
        await model.tbl_book_history.create(historyPayload, { transaction });
        await transaction.commit();
        // Send notifications after commit
        sendCancellationNotifications(userId, hostId, reqData.bookingId, isBooking.book_prop_id, userEmail);
        return common.response(req, res, commonConfig.successStatus, true, "Booking cancelled successfully",);
    } catch (error) {
        await transaction.rollback();
        logger.error(`Error in cancel_Booking: ${error.message}`, { stack: error.stack });
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const ongoingBookingsUser = async (req, res) => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    try {
        const userId = req.user.userId;
        const whereClause = {
            book_user_id: userId,
            book_status: { [Op.in]: [commonConfig.statusBooked, commonConfig.statusPaymentPending, commonConfig.paid] }
        };
        const { rows, count } = await model.tbl_bookings.findAndCountAll({
            raw: true,
            nest: true,
            where: whereClause,
            attributes: [
                "book_pri_id",
                "book_id",
                "book_invoice",
                "book_price",
                "book_is_paid",
                "book_is_cod",
                "book_status"
            ],
            include: [
                {
                    model: model.tbl_book_details,
                    as: "bookDetails",
                    required: true,
                    where: literal(`STR_TO_DATE(bt_book_from, '%d-%m-%Y') >= CURDATE()`),
                    attributes: ["bt_book_from", "bt_book_to"]
                },
                {
                    model: model.tbl_book_status,
                    as: "bookingStatus",
                    attributes: ["bs_title"]
                },
                {
                    model: model.tbl_properties,
                    as: "bookingProperty",
                    attributes: ["property_id", "property_name", "property_host_id"],
                    required: true,
                    include: {
                        model: model.tbl_user,
                        as: "HostDetails",
                        where: {
                            user_isActive: commonConfig.isYes,
                            user_isVerified: commonConfig.isYes,
                            user_isDelete: commonConfig.isNo,
                        },
                        attributes: ["user_fullName", "user_pnumber"],
                        required: true,
                    }
                }
            ]
        });

        if (rows.length === 0) {
            return common.response(req, res, commonConfig.successStatus, true, "No records found", { count: 0, bookings: [] });
        }
        const propertyIds = [...new Set(rows.map(item => item['bookingProperty.property_id']))];
        // Step 2: Get all attachments at once
        const attachments = await model.tbl_attachments.findAll({
            raw: true,
            where: {
                afile_type: moduleConfig.property_image_type,
                afile_record_id: { [Op.in]: propertyIds }
            },
            attributes: ["afile_path", "afile_name", "afile_cldId", "afile_record_id"]
        });
        const attachmentMap = {};
        for (const attachment of attachments) {
            const imgUrl = await cloudinaryInstance.getOptimizedUrl(attachment.afile_cldId);
            attachmentMap[attachment.afile_record_id] = imgUrl;
        }

        const formattedData = rows.map(item => ({
            ...item,
            book_is_paid: item.book_is_paid === 1,
            book_is_cod: item.book_is_cod === 1,
            property_image: attachmentMap[item['bookingProperty.property_id']] || null
        }));
        return common.response(req, res, commonConfig.successStatus, true, "success", { count, bookings: formattedData });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const test = async (req, res) => {
    try {
        const data = await methods.sendNotification(req.user.userId, "Test Title", "This is Test Notification");
        return common.response(req, res, commonConfig.successStatus, true, "success", data);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const createPaymentOrderOngoingBooking = async (req, res) => {
    const transaction = await sequelize.transaction();
    try {
        const transaction = await sequelize.transaction();
        const reqData = { ...req.body };
        const userId = req.user.userId;
        let whereClause = {
            book_id: reqData.bookingId,
            book_is_cod: 1,
        };
        let findBooking = await model.tbl_bookings.getBookings(whereClause, ["book_pri_id", "book_id", "book_host_id", "book_prop_id", "book_invoice", "book_price"]);
        if (!findBooking) {
            return common.response(req, res, commonConfig.errorStatus, false, "No Ongoing Booking found");
        }
        let order_id = await createOrder({ amount: findBooking["book_price"] });
        let paymentPayload = {
            pay_raz_id: "No id Yet,Only order created",
            pay_order_id: order_id ? order_id.id : null,
            pay_receipt_id: order_id ? order_id.receipt : null,
            pay_bookId: reqData.bookingId,
            pay_book_pri_id: findBooking.book_pri_id,
            pay_userId: userId,
            pay_hostId: findBooking.book_host_id,
            pay_propId: findBooking.book_prop_id,
            pay_invoice: findBooking.book_invoice,
            pay_amount: findBooking["book_price"],
            pay_status: commonConfig.statusPaymentPending,
            pay_status_text: "Not Verified Yet",
        };
        await model.tbl_payment.create(paymentPayload, { transaction: transaction });
        let historyPayload = {
            bh_book_id: findBooking.book_id,
            bh_user_id: userId,
            bh_host_id: findBooking.book_host_id,
            bh_price: findBooking["book_price"],
            bh_prop_id: findBooking.book_prop_id,
            bh_status_id: commonConfig.statusPaymentPending,
            bh_title: `Create Payment Order`,
            bh_description: `Order Created, Waiting for verification`,
        };
        await model.tbl_book_history.create(historyPayload, { transaction: transaction });
        await transaction.commit();
        return common.response(req, res, commonConfig.successStatus, true, "success", { order: order_id });
    } catch (error) {
        await transaction.rollback();
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const testSendEmail = async (req, res) => {
    try {
        const { to } = req.body; // you can pass target email in request body
        if (!to) {
            return res.status(400).json({
                success: false,
                message: "Receiver email (to) is required",
            });
        }

        const testHtml = emailManager.makeContent(`
        <main style="padding:20px; text-align:center;">
          <h2 style="color:#AB0241;">Test Email from Aajoo Homes</h2>
          <p>This is a <b>test email</b> sent using GoDaddy SMTP + Nodemailer.</p>
        </main>
      `);
        const info = await emailManager.sendEmail({
            to,
            subject: "Aajoo Homes - Test Email",
            data: testHtml,
            userId: 1, // test user/system
            status: "sent",
            mailType: "test",
        });
        if (!info) {
            return res.status(500).json({
                success: false,
                message: "Email failed to send. Check logs or credentials.",
            });
        }

        return res.status(200).json({
            success: true,
            message: `Test email sent successfully to ${to}`,
            messageId: info.messageId,
        });
    } catch (error) {
        console.error("Error in testSendEmail:", error);
        return res.status(500).json({
            success: false,
            message: "Internal server error while sending test email",
            error: error.message,
        });
    }
};


module.exports = {
    bookingCreate,
    CreatePayment,
    createPaymentOrderOngoingBooking,
    test,
    verifyUserPayment,
    ongoingBookingsUser,
    cancelBooking,
    testSendEmail
};
