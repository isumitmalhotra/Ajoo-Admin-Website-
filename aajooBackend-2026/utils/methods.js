const bcrypt = require('bcrypt');
const logger = require("./logger");
const jwt = require('jsonwebtoken');
const commonConfig = require("../config/commonConfig");
// const methods = require("./");

// const otpGenerator = require('otp-generator')

const hashPassword = async (password) => {
    try {
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);
        return hashedPassword;
    } catch (error) {
        return error;
    }
};
const genrateToken = async (data, epx = "24h") => {
    try {
        const secret = process.env.JWT_SECRET || commonConfig.JWT_SECRET;
        const token = jwt.sign(data, secret, { expiresIn: epx });
        return token;
    } catch (error) {
        return error;
    }
};
const genrateBookingId = () => {
    const timestamp = Date.now();
    const shortTimestamp = timestamp % 1000000;
    const randomNum = Math.floor(Math.random() * 100);
    const uniqueNumber = (shortTimestamp + randomNum) % 1000000;
    return uniqueNumber.toString().padStart(6, '0');
};
const generateOtp = () => {
    const otp = Math.floor(1000 + Math.random() * 9000);
    return otp.toString();
};
const returnIshostObj = (isHost) => {
    if (isHost == 1) {
        return { cred_user_isHost: 1 }
    } else {
        return { cred_user_isHost: 0 };
    }
};
const getAttchedProperties = async (rows, propIds) => {
    const model = require("../models");
    const { CloudinaryManager } = require("../utils/cloudinary");
    const moduleConfigs = require("../config/moduleConfigs");
    const cloudinaryInstance = new CloudinaryManager();
    try {
        const allImages = await model.tbl_attachments.findAll({
            raw: true,
            where: {
                afile_record_id: propIds,
                afile_type: moduleConfigs.property_image_type
            },
            // limit: 5
        });
        const coverImages = await model.tbl_attachments.findAll({
            raw: true,
            where: {
                afile_record_id: propIds,
                afile_type: moduleConfigs.property_cover_image_type
            }
        })
        const enhancedRows = await Promise.all(
            rows.map(async (row) => {
                const matchingImages = allImages.filter(image => image.afile_record_id === row.property_id);
                const imageUrls = matchingImages.length > 0 ? await Promise.all(
                    matchingImages.map(async (image) => {
                        const optimizedUrl = await cloudinaryInstance.getOptimizedUrl(image.afile_cldId);
                        return optimizedUrl;
                    })
                )
                    : [];
                const matchingCoverImage = coverImages.find(image => image.afile_record_id === row.property_id);
                const coverImageUrl = matchingCoverImage
                    ? await cloudinaryInstance.getOptimizedUrl(matchingCoverImage.afile_cldId)
                    : null;
                return { ...row, coverImage: coverImageUrl, images: imageUrls, };
            })
        );
        return enhancedRows;
    } catch (error) {
        return error;
    }
};
const getAttachedPropertyImages = async (propertyId) => {
    const model = require("../models");
    const { CloudinaryManager } = require("../utils/cloudinary");
    const moduleConfigs = require("../config/moduleConfigs");

    const cloudinaryInstance = new CloudinaryManager();

    try {
        // 🔹 Fetch all attachments (images + cover + documents)
        const attachments = await model.tbl_attachments.findAll({
            raw: true,
            where: {
                afile_record_id: propertyId,
                afile_type: [
                    moduleConfigs.property_image_type,
                    moduleConfigs.property_cover_image_type,
                    moduleConfigs.property_doc_type, // ✅ NEW
                ],
            },
            attributes: ["afile_id", "afile_type", "afile_cldId"],
        });

        // 🔹 Optimize Cloudinary URLs in parallel
        const attachmentsWithUrls = await Promise.all(
            attachments.map(async (file) => ({
                afile_id: file.afile_id,
                afile_type: file.afile_type,
                url: await cloudinaryInstance.getOptimizedUrl(file.afile_cldId),
            }))
        );

        // 🔹 Separate by type
        let coverImage = null;
        const images = [];
        const documents = []; // ✅ NEW

        attachmentsWithUrls.forEach((file) => {
            if (file.afile_type === moduleConfigs.property_cover_image_type) {
                coverImage = {
                    afile_id: file.afile_id,
                    url: file.url,
                };
            } else if (file.afile_type === moduleConfigs.property_image_type) {
                images.push({
                    afile_id: file.afile_id,
                    url: file.url,
                });
            } else if (file.afile_type === moduleConfigs.property_doc_type) {
                documents.push({
                    afile_id: file.afile_id,
                    url: file.url,
                });
            }
        });

        // ✅ Final structured response
        return {
            property_id: propertyId,
            coverImage,
            images,
            documents, // ✅ NEW
        };
    } catch (error) {
        return error;
    }
};

const verifyPassword = async (password, hashedPassword) => {
    try {
        const isMatch = await bcrypt.compare(password, hashedPassword);
        return isMatch;
        return isMatch;
    } catch (error) {
        return error;
    }
};
const sendNotification = async (userId, title, message, propId, payloadData = {}, bookingId = null, bookPriId = null) => {
    const model = require("../models");
    const admin = require("firebase-admin");
    try {
        logger.info(`sendNotification called with userId: ${userId}, title: ${title}, message: ${message}, propId: ${propId}, payloadData: ${JSON.stringify(payloadData)}`);
        const findDeviceToken = await model.tbl_notify_device.findOne({
            raw: true,
            where: { nd_user_id: userId },
            attributes: ["nd_device_token"]
        });
        if (!findDeviceToken) {
            return false
        }
        if (!admin.apps.length) {
            const serviceAccount = require("./serviceFirebase.json");
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
            });
        }
        const payload = {
            notification: {
                title,
                body: message,
            },
            data: payloadData || {},
            token: findDeviceToken.nd_device_token,
        };
        const response = await admin.messaging().send(payload);
        logger.info(`response: ${JSON.stringify(response)}`);
        let notificationPayload = {
            un_userId: userId,
            un_propId: propId ?? null,
            un_bookingId: bookingId,
            un_pri_bookingId: bookPriId,
            un_title: title,
            un_message: message,
            un_payload: JSON.stringify(payload),
        };
        await model.tbl_user_notification.create(notificationPayload);
        return response;
    } catch (error) {
        logger.info(`error from notification: ${JSON.stringify(error)}`);
        logger.error("Error sending notification:", error);
        console.error("Error sending notification:", error);
    }
};
const calculateBookingtax = (price) => {
    let tax;
    let taxPercentage;
    if (price > 7500) {
        taxPercentage = 18;
        tax = (price * taxPercentage) / 100;
    }
    if (price <= 7500) {
        taxPercentage = 12;
        tax = (price * taxPercentage) / 100;
    }
    return { tax, taxPercentage };
};
function parseCustomDate(dateStr) {
    const [day, month, year] = dateStr.split("-").map(Number);
    return new Date(year, month - 1, day); // month is 0-based
};
function validateBookingDates(fromDateStr, toDateStr) {
    if (!fromDateStr || !toDateStr) {
        return { success: false, message: "Both booking dates are required." };
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0); // normalize

    const maxDate = new Date();
    maxDate.setMonth(maxDate.getMonth() + 3); // 3 months from today

    const fromDate = parseCustomDate(fromDateStr);
    const toDate = parseCustomDate(toDateStr);

    // Check for invalid dates
    if (isNaN(fromDate.getTime()) || isNaN(toDate.getTime())) {
        return { success: false, message: "Invalid date format. Use dd-MM-yyyy." };
    }

    // Rule 1: fromDate must not be in the past
    if (fromDate < today) {
        return { success: false, message: "Booking start date cannot be in the past." };
    }

    // Rule 2: toDate must be after fromDate (minimum 1-day booking)
    if (toDate <= fromDate) {
        return { success: false, message: "Booking must be at least 1 day." };
    }

    // Rule 3: toDate must be within 3 months from today
    if (toDate > maxDate) {
        return { success: false, message: "Booking cannot be made more than 3 months in advance." };
    }

    // ✅ All checks passed
    return { success: true, message: "Valid booking dates." };
};



module.exports = {
    hashPassword,
    calculateBookingtax,
    getAttchedProperties,
    validateBookingDates,
    genrateToken,
    genrateBookingId,
    generateOtp,
    verifyPassword,
    returnIshostObj,
    sendNotification,
    getAttachedPropertyImages
}
