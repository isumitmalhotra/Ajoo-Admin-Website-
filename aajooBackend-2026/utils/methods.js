const bcrypt = require('bcrypt');
const { createPrivateKey } = require('crypto');
const fs = require('fs');
const path = require('path');
const logger = require("./logger");
const jwt = require('jsonwebtoken');
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
/**
 * Derive the RBAC role claim from a token payload's existing flags.
 * Taxonomy: admin / finance / host / support / guest (A-13).
 * An explicit `role` on the payload always wins (lets us mint finance/support
 * tokens without new flags). Otherwise derive from isAdmin / isHost.
 */
const deriveRole = (data = {}) => {
    if (data.role) return data.role;
    if (Number(data.isAdmin) === 1 || data.admin_isAdmin === 1) return "admin";
    if (Number(data.isHost) === 1 || Number(data.user_isHost) === 1) return "host";
    return "guest";
};

const genrateToken = async (data, epx = "30d") => {
    try {
        // RBAC (A-13): always embed a `role` claim. Back-compat — existing fields
        // (userId, isHost, isAdmin, email) are preserved; we only ADD `role`.
        const payload = { ...data, role: deriveRole(data) };
        const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: epx });
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
    } catch (error) {
        return error;
    }
};
let firebaseAppInstance = null;
let firebaseInitError = null;

const getFirebaseServiceAccount = () => {
    const privateKey = process.env.FIREBASE_PRIVATE_KEY
        ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
        : null;

    if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && privateKey) {
        return {
            projectId: process.env.FIREBASE_PROJECT_ID,
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            privateKey,
        };
    }

    const serviceAccountPath = path.join(__dirname, "serviceFirebase.json");
    if (!fs.existsSync(serviceAccountPath)) {
        throw new Error("Firebase service account is not configured. Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY or add utils/serviceFirebase.json.");
    }

    const serviceAccount = require("./serviceFirebase.json");
    if (serviceAccount.private_key) {
        serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
    }
    return serviceAccount;
};

const getFirebaseAdminApp = () => {
    const admin = require("firebase-admin");

    if (firebaseAppInstance) {
        return { admin, app: firebaseAppInstance };
    }

    if (admin.apps.length) {
        firebaseAppInstance = admin.apps[0];
        return { admin, app: firebaseAppInstance };
    }

    try {
        const serviceAccount = getFirebaseServiceAccount();
        firebaseAppInstance = admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        });
        firebaseInitError = null;
        return { admin, app: firebaseAppInstance };
    } catch (error) {
        firebaseInitError = error;
        throw error;
    }
};

const validateFirebaseCredentials = async () => {
    try {
        const serviceAccount = getFirebaseServiceAccount();
        const normalizedServiceAccount = {
            project_id: serviceAccount.project_id || serviceAccount.projectId || null,
            client_email: serviceAccount.client_email || serviceAccount.clientEmail || null,
            private_key: serviceAccount.private_key || serviceAccount.privateKey || null,
        };

        const requiredFields = ['project_id', 'client_email', 'private_key'];
        const missingFields = requiredFields.filter((field) => !normalizedServiceAccount[field]);

        if (missingFields.length) {
            return {
                isValid: false,
                message: `Missing Firebase credential field(s): ${missingFields.join(', ')}`,
                missingFields,
                tokenVerified: false,
            };
        }

        if (
            !normalizedServiceAccount.private_key.includes('-----BEGIN PRIVATE KEY-----') ||
            !normalizedServiceAccount.private_key.includes('-----END PRIVATE KEY-----')
        ) {
            return {
                isValid: false,
                message: 'Firebase private key is not in a valid PEM format.',
                missingFields: [],
                tokenVerified: false,
            };
        }

        createPrivateKey({
            key: normalizedServiceAccount.private_key,
            format: 'pem',
        });

        const admin = require("firebase-admin");
        const credential = admin.credential.cert({
            projectId: normalizedServiceAccount.project_id,
            clientEmail: normalizedServiceAccount.client_email,
            privateKey: normalizedServiceAccount.private_key,
        });

        const accessToken = await credential.getAccessToken();
        firebaseInitError = null;

        return {
            isValid: true,
            message: 'Firebase credentials are valid and Google token fetch succeeded.',
            projectId: normalizedServiceAccount.project_id,
            clientEmail: normalizedServiceAccount.client_email,
            source: process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY
                ? 'env'
                : 'utils/serviceFirebase.json',
            tokenVerified: true,
            accessTokenExpiresAt: accessToken?.expirationTime || null,
        };
    } catch (error) {
        firebaseInitError = error;
        return {
            isValid: false,
            message: error?.message || 'Firebase credentials are invalid.',
            missingFields: [],
            tokenVerified: false,
            errorCode: error?.errorInfo?.code || error?.code || null,
        };
    }
};

const sendNotification = async (userId, title, message, propId, payloadData = {}, bookingId = null, bookPriId = null) => {
    const model = require("../models");
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
        const { admin } = getFirebaseAdminApp();
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
        const isFirebaseCredentialError =
            error?.errorInfo?.code === "app/invalid-credential" ||
            error?.code === "app/invalid-credential" ||
            error?.message?.includes("Invalid JWT Signature");

        if (isFirebaseCredentialError) {
            logger.error("Firebase notification credential error. Verify server time and rotate the Firebase Admin SDK key if it was revoked.", {
                firebaseConfiguredFromEnv: Boolean(
                    process.env.FIREBASE_PROJECT_ID &&
                    process.env.FIREBASE_CLIENT_EMAIL &&
                    process.env.FIREBASE_PRIVATE_KEY
                ),
                cachedInitError: firebaseInitError ? firebaseInitError.message : null,
                errorCode: error?.errorInfo?.code || error?.code || null,
                errorMessage: error?.errorInfo?.message || error?.message || null,
            });
            return false;
        }

        logger.error("Error sending notification", {
            errorCode: error?.errorInfo?.code || error?.code || null,
            errorMessage: error?.errorInfo?.message || error?.message || null,
            stack: error?.stack || null,
        });
        return false;
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
}

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
}



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
    getAttachedPropertyImages,
    validateFirebaseCredentials
}
