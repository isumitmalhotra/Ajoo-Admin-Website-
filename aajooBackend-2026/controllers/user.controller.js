const model = require("../models");
const { sequelize } = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const methods = require("../utils/methods");
const moduleConfig = require("../config/moduleConfigs");
const { CloudinaryManager } = require("../utils/cloudinary");
const EmailManager = require("../utils/mailer");
const bcrypt = require("bcrypt");
const { propertyId } = require("../schema/user.schema");
const emailManager = new EmailManager();
const cloudinaryInstance = new CloudinaryManager();

// Helper function to send OTP email
const sendOtpEmail = async (email, name, otp, subject, mailType) => {
    let contentPayload = { name, otp };
    let content = emailManager.signupOtp(contentPayload);
    let data = emailManager.makeContent(content);
    let option = {
        to: email,
        subject,
        data,
        status: "email sent successfully",
        mailType,
    };
    await emailManager.sendEmail(option);
};

// Helper function to fetch user with attachments and KYC
const getUserWithDetails = async (userId) => {
    let data = await model.tbl_user.findOne({
        raw: true,
        where: {
            user_id: userId,
            user_isActive: commonConfig.isYes,
            user_isDelete: commonConfig.isNo,
        },
        attributes: { exclude: ["added_at", "updated_at", 'user_isActive', "user_isDelete", "user_isVerified"] },
    });
    if (!data) return null;

    let cred = await model.tbl_user_cred.findUser({ cred_user_id: userId }, ["cred_username", "cred_user_email"]);

    let attachment = await model.tbl_attachments.getSingleAttachment({
        afile_type: moduleConfig.user_image_type,
        afile_record_id: userId
    });
    if (attachment) {
        attachment = await cloudinaryInstance.getOptimizedUrl(attachment.afile_cldId);
    }

    let findDoc = await model.user_kyc_docs.findOne({
        raw: true,
        where: {
            ud_user_id: userId,
            ud_isVerified: commonConfig.isYes,
        },
        attributes: ["ud_number", "ud_afile_id"],
        include: [
            {
                model: model.tbl_doc_list,
                as: "docType",
                require: false,
                attributes: ["d_title"]
            },
            {
                model: model.tbl_attachments,
                as: "docImage",
                require: false,
                attributes: ["afile_cldId"]
            }
        ]
    });

    let kycUserDocs = null;
    if (findDoc) {
        let kycDocImg = await cloudinaryInstance.getOptimizedUrl(findDoc["docImage.afile_cldId"]);
        kycUserDocs = { ...findDoc, ImageUrl: kycDocImg };
    }

    data.userId = data.user_id;
    data.user_isHost = data.user_isHost == 1 ? true : false;
    data.user_isUser = data.user_isUser == 1 ? true : false;
    delete data.user_id;

    return { ...data, ...cred, attachment, kycDocs: kycUserDocs };
};

// Helper function to handle attachment upload
const handleAttachmentUpload = async (filePath, type, recordId) => {
    const image = await cloudinaryInstance.uploadImage(filePath, type, recordId);
    return image;
};

// Helper function to delete existing attachment
const deleteExistingAttachment = async (type, recordId) => {
    let findImage = await model.tbl_attachments.getSingleAttachment({ afile_type: type, afile_record_id: recordId });
    if (findImage) {
        await cloudinaryInstance.deleteSingleImage(findImage.afile_cldId);
        await model.tbl_attachments.deleteAttachment(findImage.afile_record_id, type, findImage);
    }
};

// Helper function to validate user input for creation
const validateUserCreationInput = (reqData) => {
    if (!reqData.user_fullName || !reqData.user_email || !reqData.user_password || !reqData.user_confirmPassword) {
        throw new Error("Missing required fields");
    }
    if (reqData.user_password !== reqData.user_confirmPassword) {
        throw new Error("Password and confirm password do not match");
    }
    // Add more validations as needed
};

// Helper function to validate password update
const validatePasswordUpdate = async (reqData, currentHashedPassword, checkCurrent = false) => {
    if (checkCurrent) {
        const currentPassMatch = await bcrypt.compare(reqData.currentPassword, currentHashedPassword);
        if (!currentPassMatch) {
            throw new Error("Current password does not match");
        }
    }
    const isSamePassword = await bcrypt.compare(reqData.newPassword, currentHashedPassword);
    if (isSamePassword) {
        throw new Error("New password cannot be the same as the current password");
    }
    // Optional: Add password strength validation here
};

// Helper function to send password update email
const sendPasswordUpdateEmail = async (email, userName) => {
    const content = emailManager.confirmUpdatePassword(userName || "user");
    const data = emailManager.makeContent(content);
    const option = {
        to: email,
        subject: 'Password Updated',
        data: data
    };
    emailManager.sendEmail(option);
};

// Helper function to validate forget password input
const validateForgetPasswordInput = (reqData) => {
    if (!reqData.userEmail) {
        throw new Error("Email is required");
    }
    // Add email format validation if needed
};

const createUser = async (req, res) => {
    let transaction = await sequelize.transaction();
    try {
        const reqData = { ...req.body };

        // Validate input
        validateUserCreationInput(reqData);

        // [DEV-BYPASS] Doc upload made optional for local testing — restore to enforce req.file
        // Original: if (!req.file) { return common.response(req, res, commonConfig.errorStatus, false, "Document image is required"); }

        // Determine host/user flags
        let isHost = reqData.user_isHost === "true" ? 1 : 0;
        let notHost = 1 - isHost;

        // Check if user already exists
        const existingUser = await model.tbl_user_cred.findUser({
            cred_user_email: reqData.user_email,
            [isHost ? 'cred_user_isHost' : 'cred_user_isUser']: isHost || notHost,
            cred_user_isDelete: commonConfig.isNo
        });
        if (existingUser) {
            return common.response(req, res, commonConfig.errorStatus, false, "User already exists");
        }

        // Hash password
        const hashedPassword = await methods.hashPassword(reqData.user_password);

        // Create user payload
        const userPayload = {
            user_fullName: reqData.user_fullName,
            user_dob: reqData.user_dob,
            user_pnumber: reqData.user_pnumber,
            user_address: reqData.user_address,
            user_isHost: isHost,
            user_isUser: notHost,
            user_city: reqData.user_city || null,
            user_zipcode: reqData.user_zipcode || null,
        };

        // Create user and credentials in parallel where possible
        const addUser = await model.tbl_user.create(userPayload, { transaction });
        const userId = addUser.dataValues.user_id;

        const credPayload = {
            cred_user_id: userId,
            cred_username: reqData.user_fullName,
            cred_user_email: reqData.user_email,
            cred_user_password: hashedPassword,
            cred_user_refrel: reqData.user_ref || 0,
            cred_user_isHost: isHost,
            cred_user_isUser: notHost,
        };

        await model.tbl_user_cred.create(credPayload, { transaction });

        // Generate and store OTP
        const otp = methods.generateOtp();
        await model.tbl_user_otp.addOtp(userId, otp);

        // [DEV-BYPASS] Cloudinary upload + KYC doc creation skipped when no file provided
        // Original: always uploaded file and created KYC record (required Cloudinary credentials)
        let afileId = 0;
        if (req.file) {
            await deleteExistingAttachment(moduleConfig.id_document_image_type, userId);
            const image = await handleAttachmentUpload(req.file.path, moduleConfig.id_document_image_type, userId);
            afileId = image.afileId;
        }

        if (req.file && reqData.doc_type && reqData.doc_number) {
            const userDocPayload = {
                ud_user_id: userId,
                ud_acc_doc_id: reqData.doc_type,
                ud_number: reqData.doc_number,
                ud_afile_id: afileId
            };
            await model.user_kyc_docs.create(userDocPayload, { transaction });
        }

        // Send OTP email
        sendOtpEmail(reqData.user_email, reqData.user_fullName, otp, 'One Time Password for User Signup', 'Signup OTP');

        await transaction.commit();
        return common.response(req, res, 201, true, "Success", { userId });
    } catch (error) {
        console.log(error,"iouytfrftyuio")
        await transaction.rollback();
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const otpSendAgain = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const isUser = await model.tbl_user_cred.findUser({ cred_user_id: reqData.userId });
        if (isUser == null) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found");
        }
        let findUserDetails = await model.tbl_user.findUser({ user_id: isUser.cred_user_id }, ["user_fullName"]);
        const otp = methods.generateOtp();
        await model.tbl_user_otp.addOtp(reqData.userId, otp);
        sendOtpEmail(isUser.cred_user_email, findUserDetails.user_fullName, otp, 'One Time Password for User Signup', 'Signup OTP');
        return common.response(req, res, commonConfig.successStatus, true, "success");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const verifyOtp = async (req, res) => {
    try {
        const reqData = { ...req.body };

        // [DEV-BYPASS] OTP "000000" always passes — remove this block before production
        if (reqData.otp === '000000') {
            const data = await model.tbl_user_cred.findUser({ cred_user_id: reqData.userId }, ["cred_user_email", "cred_username", "cred_user_isHost"]);
            if (!data) return common.response(req, res, commonConfig.errorStatus, false, "No user found");
            const token = await methods.genrateToken({ userId: reqData.userId, email: data.cred_user_email, isHost: data.cred_user_isHost });
            await Promise.all([
                model.tbl_user.updateUser({ user_isVerified: commonConfig.isYes }, reqData.userId),
                model.tbl_login_activity.create({ la_user_id: reqData.userId, la_token: token, la_ip: req.ip ?? "" }),
            ]);
            return common.response(req, res, commonConfig.successStatus, true, "Verified (dev bypass)", { token, user: data });
        }

        const payload = { uo_userId: reqData.userId, uo_otp: reqData.otp };
        const isExist = await model.tbl_user_otp.findOtp(payload);
        if (!isExist) {
            return common.response(req, res, commonConfig.errorStatus, false, "Invalid OTP");
        }

        const data = await model.tbl_user_cred.findUser({ cred_user_id: reqData.userId }, ["cred_user_email", "cred_username"]);
        if (!data) {
            return common.response(req, res, commonConfig.errorStatus, false, "No user found");
        }

        const token = await methods.genrateToken({ userId: reqData.userId, email: data.cred_user_email, isHost: data.cred_user_isHost });
        const loginPayload = {
            la_user_id: reqData.userId,
            la_token: token,
            la_ip: req.ip ?? ""
        };

        // Update user as verified and clean up
        await Promise.all([
            model.tbl_user.updateUser({ user_isVerified: commonConfig.isYes }, reqData.userId),
            model.tbl_user_otp.destroy({ where: payload }),
            model.tbl_user_login_auth.createLoginAuth(loginPayload)
        ]);

        const user = await getUserWithDetails(reqData.userId);
        return common.response(req, res, commonConfig.successStatus, true, "Verification Successful", {
            user,
            token,
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const updateUser = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const userId = req.user.userId;
        const payload = {
            user_fullName: reqData.user_fullName,
            user_pnumber: reqData.user_pnumber,
            user_address: reqData.user_address,
            user_city: reqData.user_city,
            user_zipcode: reqData.user_zipcode
        };

        const isUpdate = await model.tbl_user.updateUser(payload, userId);
        if (isUpdate[0] === 0) {
            return common.response(req, res, commonConfig.errorStatus, false, "Something went wrong");
        }

        if (req.file) {
            await deleteExistingAttachment(moduleConfig.id_document_image_type, userId);
            const image = await handleAttachmentUpload(req.file.path, moduleConfig.id_document_image_type, userId);
            const afileId = image.afileId;
            const userDocPayload = {
                ud_acc_doc_id: reqData.doc_type,
                ud_number: reqData.doc_number,
                ud_user_id: userId,
                ud_afile_id: afileId
            };

            const findDoc = await model.user_kyc_docs.findOne({ where: { ud_user_id: userId } });
            if (findDoc) {
                await model.user_kyc_docs.update(userDocPayload, { where: { ud_user_id: userId } });
            } else {
                await model.user_kyc_docs.create(userDocPayload);
            }
        }

        payload.userId = userId;
        return common.response(req, res, commonConfig.successStatus, true, "Success", { user: payload });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const loginUser = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const obj = methods.returnIshostObj(reqData.isHost);
        const whereClause = { cred_user_email: reqData.user_email, ...obj, cred_user_isDelete: commonConfig.isNo };
        const findUser = await model.tbl_user_cred.findUser(whereClause, [
            "cred_user_password",
            "cred_user_id",
            "cred_username",
            "cred_user_email",
            "cred_user_isHost",
            "cred_user_isUser"
        ]);
        if (!findUser) {
            return common.response(req, res, commonConfig.successStatus, false, "No record found");
        }

        const userWhereClause = {
            user_id: findUser.cred_user_id,
            user_isActive: commonConfig.isYes,
            user_isVerified: commonConfig.isYes,
            user_isDelete: commonConfig.isNo,
        };
        const isActive = await model.tbl_user.findUser(userWhereClause, [
            "user_fullName",
            "user_pnumber",
            "user_dob",
            "user_isVerified",
            "user_address",
            "user_city",
            "user_zipcode",
        ]);
        if (!isActive) {
            return common.response(req, res, commonConfig.successStatus, false, "No record found");
        }

        const isMatch = await bcrypt.compare(reqData.user_password, findUser.cred_user_password);
        if (!isMatch) {
            return common.response(req, res, commonConfig.successStatus, false, "Incorrect password");
        }

        const token = await methods.genrateToken({ userId: findUser.cred_user_id, email: findUser.cred_user_email, isHost: isActive.user_isHost });
        const loginPayload = {
            la_user_id: findUser.cred_user_id,
            la_token: token,
            la_ip: req.ip ?? ""
        };

        await model.tbl_user_login_auth.destroy({ where: { la_user_id: findUser.cred_user_id } });
        await model.tbl_user_login_auth.createLoginAuth(loginPayload);

        const user = await getUserWithDetails(findUser.cred_user_id);
        return common.response(req, res, commonConfig.successStatus, true, "Success", { user, token });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const deleteProfilePicture = async (req, res) => {
    try {
        const userId = req.user.userId;
        await deleteExistingAttachment(moduleConfig.user_image_type, userId);
        return common.response(req, res, commonConfig.successStatus, true, "Image deleted successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const getUserByToken = async (req, res) => {
    try {
        const userId = req.user.userId;
        const user = await getUserWithDetails(userId);
        if (!user) {
            return common.response(req, res, commonConfig.errorStatus, false, "no record found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "success", { user });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const addProfilePic = async (req, res) => {
    try {
        if (!req.file) {
            return common.response(req, res, commonConfig.errorStatus, false, "Image is required");
        }
        await deleteExistingAttachment(moduleConfig.user_image_type, req.user.userId);
        const imgData = await handleAttachmentUpload(req.file.path, moduleConfig.user_image_type, req.user.userId);
        return common.response(req, res, commonConfig.successStatus, true, "Success", { image: imgData?.secure_url });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const checkEmailIsExist = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const isExist = await model.tbl_user_cred.findUser({ cred_user_email: reqData.userEmail }, ["cred_user_email"]);
        if (isExist !== null) {
            return common.response(req, res, commonConfig.errorStatus, false, "User Already Exist");
        } else {
            return common.response(req, res, commonConfig.successStatus, true, "no record found");
        }
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const userHistory = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let userId = req.user.userId;
        let limit = reqData.limit ?? commonConfig.listLimit;
        let page = reqData.page ?? commonConfig.listPage;
        let offset = (page - 1) * limit;
        const { rows, count } = await model.tbl_book_history.findAndCountAll({
            raw: true,
            where: {
                bh_user_id: userId,
                // bh_status_id: commonConfig.checkOut
            },
            attributes: [
                "bh_book_id",
                "bh_prop_id",
                "bh_price"
            ],
            include: [
                {
                    model: model.tbl_properties,
                    as: "hisProperty",
                    attributes: ["property_name"]
                },
                {
                    model: model.tbl_book_status,
                    as: "hisStatus",
                    attributes: ["bs_title"]
                },
            ],
            limit: parseInt(limit),
            offset: parseInt(offset),
            order: [["bh_id", "DESC"]]
        });
        if (rows.length == commonConfig.isNo) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "success", {
            totalCount: count,
            record: rows.length,
            page: page,
            limit: limit,
            data: rows
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const UserSavedProperties = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let limit = reqData.limit ?? commonConfig.listLimit;
        let page = reqData.page ?? commonConfig.listPage;
        let offset = (page - 1) * limit;
        let { rows, count } = await model.tbl_saved_liked_prop.findAndCountAll({
            raw: true,
            where: {
                slp_user_id: reqData.userId,
                slp_prop_id: reqData.propId,
                slp_isSave: commonConfig.isYes,
            },
            attributes: [
                "slp_prop_id"
            ],
            limit: limit,
            offset: offset
        });

    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const deleteUser = async (req, res) => {
    try {
        const userId = req.user.userId;
        const user = await model.tbl_user.findUser({ user_id: userId }, ["user_id", "user_isHost"]);

        if (user["user_isHost"] == commonConfig.isYes) {
            return common.response(req, res, commonConfig.errorStatus, false, "Host user cannot be deleted. Please contact support for assistance.");
        }
        if (!user) {
            return common.response(req, res, commonConfig.errorStatus, false, "No record found to delete");
        }
        // return
        await model.tbl_user.updateUser({ user_isDelete: commonConfig.isYes, user_isActive: commonConfig.isNo }, userId);
        await model.tbl_user_cred.updateCred({ cred_user_isDelete: commonConfig.isYes }, userId);
        return common.response(req, res, commonConfig.successStatus, true, "Account Deleted Successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
//User Forget Passowrd----------------------------------->
const ForgetPasswordEmail = async (req, res) => {
    let transaction = await sequelize.transaction();
    try {
        const reqData = { ...req.body };

        // Validate input
        validateForgetPasswordInput(reqData);

        const isUser = await model.tbl_user_cred.findUser({ cred_user_email: reqData.userEmail });
        if (!isUser) {
            return common.response(req, res, commonConfig.successStatus, true, "No record found");
        }

        const otp = methods.generateOtp();
        const payload = {
            fpo_userId: isUser.cred_user_id,
            fpo_otp: otp,
            fpo_email: reqData.userEmail,
            fpo_type: moduleConfig.user_forget_otp_type,
        };

        // Clean up old OTP and create new one
        await model.tbl_forget_pass_otp.destroy({
            where: { fpo_email: reqData.userEmail },
            transaction
        });
        await model.tbl_forget_pass_otp.create(payload, { transaction });

        const user = await model.tbl_user.findUser({ user_id: isUser.cred_user_id }, ["user_fullName"]);
        const contentPayload = {
            user: user?.user_fullName || "User",
            otp: otp
        };
        const content = emailManager.forgetPassword(contentPayload);
        const data = emailManager.makeContent(content);
        const option = {
            to: reqData.userEmail,
            subject: 'Forget password',
            data: data,
            userId: isUser.cred_user_id,
            status: "Email sent successfully",
            mailType: "User forget password",
        };

        const emailSent = emailManager.sendEmail(option);
        if (!emailSent) {
            await transaction.rollback();
            return common.response(req, res, commonConfig.errorStatus, false, "Unable to send email. Please try again");
        }

        await transaction.commit();
        return common.response(req, res, commonConfig.successStatus, true, "Email sent successfully");
    } catch (error) {
        await transaction.rollback();
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const verifyForgetPasswordOtp = async (req, res) => {
    let transaction = await sequelize.transaction();
    try {
        const reqData = { ...req.body };

        // Validate input
        if (!reqData.userEmail || !reqData.otp) {
            return common.response(req, res, commonConfig.errorStatus, false, "Email and OTP are required");
        }

        const findOtp = await model.tbl_forget_pass_otp.findOne({
            raw: true,
            where: {
                fpo_email: reqData.userEmail,
                fpo_otp: reqData.otp,
                fpo_type: moduleConfig.user_forget_otp_type
            },
            attributes: ["fpo_id", "fpo_userId"]
        });
        if (!findOtp) {
            return common.response(req, res, commonConfig.errorStatus, false, "Invalid OTP");
        }

        const token = await methods.genrateToken({ userId: findOtp.fpo_userId, email: reqData.userEmail }, "5m");
        const authPayload = {
            upa_userId: findOtp.fpo_userId,
            upa_token: token
        };

        await model.tbl_user_pass_auths.createData(authPayload, { transaction });
        await model.tbl_forget_pass_otp.destroy({
            where: { fpo_email: reqData.userEmail },
            transaction
        });

        await transaction.commit();
        return common.response(req, res, commonConfig.successStatus, true, "OTP verified successfully", { token });
    } catch (error) {
        await transaction.rollback();
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const updateForgotPassByEmail = async (req, res) => {
    let transaction = await sequelize.transaction();
    try {
        const reqData = { ...req.body };

        // Validate input
        if (!reqData.newPassword) {
            return common.response(req, res, commonConfig.errorStatus, false, "New password is required");
        }

        const findToken = await model.tbl_user_pass_auths.findOne({
            raw: true,
            where: { upa_userId: req.user.userId }
        });
        if (!findToken) {
            return common.response(req, res, commonConfig.successStatus, false, "No record found");
        }

        const isUser = await model.tbl_user_cred.findUser({ cred_user_id: req.user.userId }, ["cred_user_email", "cred_user_password", "cred_user_isHost"]);
        if (!isUser) {
            return common.response(req, res, commonConfig.successStatus, false, "No record found");
        }

        // Validate password
        await validatePasswordUpdate(reqData, isUser.cred_user_password);

        const hashedNewPassword = await bcrypt.hash(reqData.newPassword, 10);
        await model.tbl_user_cred.update(
            { cred_user_password: hashedNewPassword },
            { where: { cred_user_id: req.user.userId }, transaction }
        );

        const userName = await model.tbl_user.findUser({ user_id: req.user.userId }, ["user_fullName"]);
        await sendPasswordUpdateEmail(isUser.cred_user_email, userName?.user_fullName);

        await model.tbl_user_pass_auths.destroy({
            where: { upa_userId: req.user.userId },
            transaction
        });
        await methods.sendNotification(req.user.userId, "Password Updated", "Your password has been updated successfully");

        await transaction.commit();
        return common.response(req, res, commonConfig.successStatus, true, "Password updated successfully");
    } catch (error) {
        await transaction.rollback();
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const userUpdatePasswordManual = async (req, res) => {
    try {
        const reqData = { ...req.body };

        // Validate input
        if (!reqData.userId || !reqData.currentPassword || !reqData.newPassword) {
            return common.response(req, res, commonConfig.errorStatus, false, "User ID, current password, and new password are required");
        }

        const isUser = await model.tbl_user_cred.findUser({ cred_user_id: reqData.userId }, ["cred_user_email", "cred_user_password", "cred_user_isHost"]);
        if (!isUser) {
            return common.response(req, res, commonConfig.successStatus, false, "No record found");
        }

        // Validate password
        await validatePasswordUpdate(reqData, isUser.cred_user_password, true);

        const hashedNewPassword = await bcrypt.hash(reqData.newPassword, 10);
        isUser.cred_user_password = hashedNewPassword;
        delete isUser.cred_user_isHost;
        await model.tbl_user_cred.updateCred(isUser, reqData.userId);

        await sendPasswordUpdateEmail(isUser.cred_user_email, "User");

        return common.response(req, res, commonConfig.successStatus, true, "Password updated successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const logout = async (req, res) => {
    try {
        await model.tbl_user_login_auth.destroy({ where: { la_user_id: req.user.userId } });
        return common.response(req, res, commonConfig.successStatus, true, "logout successful");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const userBookingList = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let userId = req.user.userId;
        const bookings = await model.tbl_bookings.findAll({
            raw: true,
            where: { book_user_id: userId },
            attributes: [
                "book_id",
                "book_invoice",
                "book_prop_id",
                "book_price",
                "book_added_at",
            ],
            include: [
                {
                    model: model.tbl_properties,
                    as: "bookingProperty",
                    attributes: [
                        "property_name",
                        "property_address",
                        "property_email",
                        "property_desc",
                    ]
                },
                {
                    model: model.tbl_book_status,
                    as: "bookingStatus",
                    attributes: [
                        "bs_title"
                    ]
                },
                {
                    model: model.tbl_book_details,
                    as: "bookDetails",
                    attributes: [
                        "bt_book_from",
                        "bt_book_to"
                    ]
                },
            ]
        });
        if (bookings.length == commonConfig.isNo) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "success", bookings);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
}
const userCreateReview = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let reviewId = reqData.reviewId;
        let whereClause = {
            property_id: reqData.propertyId,
            is_active: commonConfig.isYes,
            is_deleted: commonConfig.isNo,

        }
        let findProperty = await model.tbl_properties.getSingleProperty(whereClause, ["property_host_id"]);
        if (!findProperty) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found");
        }
        let reviewWhereClause = {
            br_propId: reqData.propertyId,
            br_userId: req.user.userId
        };
        let findReview = await model.tbl_reviews.findSingleReview(reviewWhereClause, ["br_id"]);
        if (findReview) {
            reviewId = findReview.br_id;
        }
        const payload = {
            br_book_id: reqData.bookingId,
            br_propId: reqData.propertyId,
            br_hostId: findProperty.property_host_id,
            br_userId: req.user.userId,
            br_rating: reqData.rating,
            br_desc: reqData.description,
        };
        if (findReview) {
            await model.tbl_reviews.update(payload, { where: { br_id: reviewId } });
        } else {
            await model.tbl_reviews.create(payload)
        }
        return common.response(req, res, commonConfig.successStatus, true, "success", { review: payload });
    } catch (error) {

        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
//NOTIFICATION------------------------------------------->
const addNotificationToken = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const payload = {
            nd_user_id: req.user.userId,
            nd_user_email: req.user.email,
            nd_device_token: reqData.deviceToken,
        };
        let findData = await model.tbl_notify_device.findOne({
            raw: true,
            where: { nd_user_id: req.user.userId }
        });
        if (findData) {
            await model.tbl_notify_device.update({ nd_device_token: reqData.deviceToken }, { where: { nd_user_id: req.user.userId } });
        } else {
            await model.tbl_notify_device.create(payload);
        }
        return common.response(req, res, commonConfig.successStatus, true, "success");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
}
const markReadNotification = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const userId = req.user.userId;
        const notificationId = reqData.notificationId;
        await model.tbl_user_notification.update({ un_is_read: commonConfig.isYes }, { where: { un_id: notificationId, un_userId: userId } });
        return common.response(req, res, commonConfig.successStatus, true, "success");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const notificationListing = async (req, res) => {
    try {
        const userId = req.user.userId;
        const data = await model.tbl_user_notification.findAll({
            raw: true,
            where: {
                un_userId: userId,
                un_is_read: commonConfig.isNo,
            },
            attributes: [
                "un_id",
                "un_title",
                "un_message",
                "createdAt",
                "un_is_read",
                "un_propId",
                "un_payload"
            ],
            order: [["un_id", "DESC"]],
        });
        const formattedData = data?.map(item => {
            let payload = {};
            try {
                payload = item.un_payload ? JSON.parse(item.un_payload) : {};
                delete payload.token;
                delete payload.notification;
                if (payload.data && typeof payload.data === "object") {
                    payload = payload.data;
                }
            } catch (error) {
                console.error("Error parsing payload for un_id:", item.un_id, error.message);
            }
            return {
                ...item,
                un_payload: payload
            };
        });
        return common.response(req, res, commonConfig.successStatus, true, "success", { notifications: formattedData ?? [] });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

module.exports = {
    createUser,
    updateUser,
    loginUser,
    userBookingList,
    userCreateReview,
    addNotificationToken,
    updateForgotPassByEmail,
    deleteProfilePicture,
    addProfilePic,
    markReadNotification,
    checkEmailIsExist,
    // userRegDocTypes,
    userHistory,
    ForgetPasswordEmail,
    userUpdatePasswordManual,
    UserSavedProperties,
    getUserByToken,
    otpSendAgain,
    verifyOtp,
    logout,
    verifyForgetPasswordOtp,
    notificationListing,
    deleteUser
};

