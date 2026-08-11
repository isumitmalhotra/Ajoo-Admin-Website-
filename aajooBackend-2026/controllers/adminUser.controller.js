const fs = require("fs/promises");
const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require("sequelize");
const { CloudinaryManager } = require("../utils/cloudinary");
const moduleConfig = require("../config/moduleConfigs");
const methods = require("../utils/methods");
const { logAdminMutation } = require("../services/admin/adminAudit.service");
const { normalizeOptionalString, normalizeOptionalValue } = require("../utils/requestFilters");

const cloudinaryInstance = new CloudinaryManager();

const cleanupLocalFiles = async (filePaths = []) => {
    const uniquePaths = [...new Set(filePaths.filter(Boolean))];

    await Promise.all(uniquePaths.map(async (filePath) => {
        try {
            await fs.unlink(filePath);
        } catch (error) {
            if (error.code !== "ENOENT") {
                console.error(`Failed to delete temp file ${filePath}:`, error.message);
            }
        }
    }));
};

const deleteCloudinaryAssets = async (publicIds = []) => {
    const uniqueIds = [...new Set(publicIds.filter(Boolean))];

    await Promise.all(uniqueIds.map(async (publicId) => {
        try {
            await cloudinaryInstance.deleteSingleImage(publicId);
        } catch (error) {
            console.error(`Failed to delete Cloudinary asset ${publicId}:`, error.message);
        }
    }));
};

const uploadSingleAsset = async (file, folderName = "user_folder") => {
    if (!file?.path) {
        return null;
    }

    const uploadResult = await cloudinaryInstance.cloudinary.uploader.upload(file.path, {
        folder: folderName,
        resource_type: "auto",
    });

    return {
        publicId: uploadResult.public_id,
        secureUrl: uploadResult.secure_url,
        originalName: file.originalname,
        tempPath: file.path,
    };
};

const addUser = async (req, res) => {
    let transaction;
    const uploadedPublicIds = [];
    const stalePublicIds = [];
    const tempFilePaths = [];

    try {
        const reqData = { ...req.body };
        let userId = reqData.userId ? Number(reqData.userId) : null;
        let userIdAfileId = reqData.afileId ? Number(reqData.afileId) : null;
        const existingUser = userId
            ? await model.tbl_user.findOne({ where: { user_id: userId, user_isDelete: commonConfig.isNo }, raw: true })
            : null;
        const existingUserCred = userId
            ? await model.tbl_user_cred.findOne({ where: { cred_user_id: userId }, raw: true })
            : null;

        if (userId && !existingUser) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "User not found");
        }

        const [uploadedProfileImage, uploadedIdImage] = await Promise.all([
            uploadSingleAsset(req.files?.user_profile?.[0]),
            uploadSingleAsset(req.files?.user_id_image?.[0]),
        ]);

        [uploadedProfileImage, uploadedIdImage].filter(Boolean).forEach((file) => {
            uploadedPublicIds.push(file.publicId);
            tempFilePaths.push(file.tempPath);
        });

        transaction = await model.sequelize.transaction();

        const payload = {
            user_fullName: reqData.user_fullName,
            user_pnumber: reqData.user_pnumber,
            user_dob: reqData.user_dob,
            user_address: reqData.user_address,
            user_city: reqData.user_city,
            user_zipcode: reqData.user_zipcode,
            user_isHost: reqData.user_isHost,
            user_isUser: reqData.user_isUser,
            user_isActive: reqData.user_isActive,
            user_isVerified: reqData.user_isVerified,
        };

        const fallbackUsername = normalizeOptionalString(reqData.cred_username)
            || normalizeOptionalString(existingUserCred?.cred_username)
            || normalizeOptionalString(reqData.user_fullName);

        const credPayload = {
            cred_username: fallbackUsername,
            cred_user_email: reqData.cred_user_email,
            cred_user_refrel: reqData.cred_user_refrel ?? null,
        };

        if (reqData.cred_user_password) {
            credPayload.cred_user_password = await methods.hashPassword(reqData.cred_user_password);
        }

        if (userId) {
            await model.tbl_user.update(payload, { where: { user_id: userId }, transaction });
            await model.tbl_user_cred.update(credPayload, { where: { cred_user_id: userId }, transaction });
        } else {
            const userData = await model.tbl_user.create(payload, { transaction });

            if (!userData) {
                throw new Error("Error in user creation");
            }

            userId = userData.dataValues.user_id;
            credPayload.cred_user_id = userId;
            await model.tbl_user_cred.create(credPayload, { transaction });
        }

        if (uploadedProfileImage || uploadedIdImage) {
            const existingAttachments = await model.tbl_attachments.findAll({
                raw: true,
                where: {
                    afile_record_id: userId,
                    afile_type: {
                        [Op.in]: [
                            moduleConfig.user_image_type,
                            moduleConfig.id_document_image_type
                        ]
                    }
                },
                transaction
            });

            const attachmentByType = existingAttachments.reduce((acc, attachment) => {
                acc[attachment.afile_type] = attachment;
                return acc;
            }, {});

            if (uploadedProfileImage) {
                const existingProfileImage = attachmentByType[moduleConfig.user_image_type];

                if (existingProfileImage) {
                    stalePublicIds.push(existingProfileImage.afile_cldId);
                    await model.tbl_attachments.destroy({
                        where: { afile_id: existingProfileImage.afile_id },
                        transaction
                    });
                }

                await model.tbl_attachments.create({
                    afile_type: moduleConfig.user_image_type,
                    afile_record_id: userId,
                    afile_path: uploadedProfileImage.secureUrl,
                    afile_cldId: uploadedProfileImage.publicId,
                    afile_name: uploadedProfileImage.originalName,
                }, { transaction });
            }

            if (uploadedIdImage) {
                const existingIdImage = attachmentByType[moduleConfig.id_document_image_type];

                if (existingIdImage) {
                    stalePublicIds.push(existingIdImage.afile_cldId);
                    await model.tbl_attachments.destroy({
                        where: { afile_id: existingIdImage.afile_id },
                        transaction
                    });
                }

                const createdAttachment = await model.tbl_attachments.create({
                    afile_type: moduleConfig.id_document_image_type,
                    afile_record_id: userId,
                    afile_path: uploadedIdImage.secureUrl,
                    afile_cldId: uploadedIdImage.publicId,
                    afile_name: uploadedIdImage.originalName,
                }, { transaction });

                userIdAfileId = createdAttachment.afile_id;
            }
        }

        const userDocPayload = {
            ud_acc_doc_id: reqData.cred_user_doc_type,
            ud_user_id: userId,
            ud_number: reqData.cred_user_doc_number,
            ud_isVerified: commonConfig.isYes,
        };

        if (userIdAfileId) {
            userDocPayload.ud_afile_id = userIdAfileId;
        }

        const existingKyc = await model.user_kyc_docs.findOne({
            where: { ud_user_id: userId },
            transaction
        });

        if (existingKyc) {
            await model.user_kyc_docs.update(userDocPayload, {
                where: { ud_user_id: userId },
                transaction
            });
        } else {
            await model.user_kyc_docs.create(userDocPayload, { transaction });
        }

        await transaction.commit();
        await cleanupLocalFiles(tempFilePaths);
        await deleteCloudinaryAssets(stalePublicIds);
        await logAdminMutation(req, {
            action: existingUser ? "update" : "create",
            entity: "user",
            entityId: userId,
            before: existingUser,
            after: payload,
            meta: {
                hasProfileImage: Boolean(uploadedProfileImage),
                hasIdImage: Boolean(uploadedIdImage),
            },
        });

        return common.response(req, res, commonConfig.successStatus, true, "User added successfully");
    } catch (error) {
        if (transaction && !transaction.finished) {
            await transaction.rollback();
        }

        await deleteCloudinaryAssets(uploadedPublicIds);
        await cleanupLocalFiles(tempFilePaths);

        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const deleteuser = async (req, res) => {
    try {
        const { userId } = req.body;
        const existingUser = await model.tbl_user.findOne({
            where: { user_id: userId, user_isDelete: commonConfig.isNo },
            raw: true
        });
        if (!existingUser) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "User not found");
        }
        await model.tbl_user.updateUser({ user_isDelete: commonConfig.isYes }, userId);
        await logAdminMutation(req, {
            action: "delete",
            entity: "user",
            entityId: userId,
            before: existingUser,
            after: { user_isDelete: commonConfig.isYes },
        });
        return common.response(req, res, commonConfig.successStatus, true, "User Delete successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const verifyUser = async (req, res) => {
    try {
        const { userId, verifyStatus } = req.body;
        const existingUser = await model.tbl_user.findOne({
            where: { user_id: userId, user_isDelete: commonConfig.isNo },
            raw: true
        });
        if (!existingUser) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "User not found");
        }
        const payload = {
            user_isActive: commonConfig.isYes,
            user_isVerified: verifyStatus ?? commonConfig.isYes,
            user_isDelete: commonConfig.isNo,
        };

        await model.tbl_user.updateUser(payload, userId);
        await logAdminMutation(req, {
            action: "verify",
            entity: "user",
            entityId: userId,
            before: existingUser,
            after: payload,
        });
        return common.response(req, res, commonConfig.successStatus, true, "User Verified successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const updateStatus = async (req, res) => {
    try {
        const { userId, isActive } = req.body;
        const existingUser = await model.tbl_user.findOne({
            where: { user_id: userId, user_isDelete: commonConfig.isNo },
            raw: true
        });
        if (!existingUser) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "User not found");
        }
        await model.tbl_user.updateUser({ user_isActive: isActive }, userId);
        await logAdminMutation(req, {
            action: "status_update",
            entity: "user",
            entityId: userId,
            before: existingUser,
            after: { user_isActive: isActive },
        });
        return common.response(req, res, commonConfig.successStatus, true, "Status Updated Successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const deleteSingleImage = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const findAttachment = await model.tbl_attachments.findOne({
            where: { afile_id: reqData.afileId },
            raw: true
        });

        if (findAttachment) {
            await cloudinaryInstance.deleteSingleImage(findAttachment.afile_cldId);
            await model.tbl_attachments.destroy({ where: { afile_id: reqData.afileId } });
            await logAdminMutation(req, {
                action: "delete_image",
                entity: "user_attachment",
                entityId: reqData.afileId,
                before: findAttachment,
            });
        } else {
            return common.response(req, res, commonConfig.notFoundStatus, false, "Image not found");
        }

        return common.response(req, res, commonConfig.successStatus, true, "Image Deleted Successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const userListing = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
        const offset = (page - 1) * limit;
        const search = normalizeOptionalString(reqData.search);
        const status = normalizeOptionalValue(reqData.status);

        const whereClause = {
            user_isDelete: commonConfig.isNo
        };

        if (search) {
            whereClause[Op.or] = [
                { user_fullName: { [Op.like]: `%${search}%` } },
                { "$userCred.cred_user_email$": { [Op.like]: `%${search}%` } },
            ];
        }

        if (status !== null) {
            whereClause.user_isActive = status;
        }

        const { rows, count } = await model.tbl_user.findAndCountAll({
            where: whereClause,
            include: [
                {
                    model: model.tbl_user_cred,
                    as: "userCred",
                    required: true,
                    attributes: ["cred_user_email"]
                }
            ],
            limit,
            offset,
            order: [["added_at", "DESC"]],
            attributes: ["user_id", "user_fullName", "user_isActive", "user_isVerified", "added_at", "user_dob"]
        });

        if (!rows.length) {
            return common.response(req, res, commonConfig.successStatus, true, "No records found");
        }

        return common.response(req, res, commonConfig.successStatus, true, "User listing fetched successfully", {
            totalRecords: count,
            currentPage: page,
            totalPages: Math.ceil(count / limit),
            search,
            page,
            limit,
            offset,
            data: rows,
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const userById = async (req, res) => {
    try {
        const { userId } = req.body;
        const userData = await model.tbl_user.findOne({
            where: { user_id: userId, user_isDelete: commonConfig.isNo },
            attributes: ["user_id", "user_fullName", "user_pnumber", "user_dob", "user_address", "user_city", "user_zipcode", "user_isHost", "user_isUser", "user_isActive", "user_isVerified", "added_at"],
            include: [
                {
                    model: model.tbl_user_cred,
                    as: "userCred",
                    required: false,
                    attributes: ["cred_user_id", "cred_username", "cred_user_email"]
                },
                {
                    model: model.user_kyc_docs,
                    as: "userKycDocs",
                    required: false,
                    attributes: ["ud_id", "ud_acc_doc_id", "ud_number", "ud_afile_id"],
                }
            ],
        });

        if (!userData) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "No records found");
        }

        const userObj = userData.get({ plain: true });
        const [profileImage, kycImage] = await Promise.all([
            model.tbl_attachments.findOne({
                where: {
                    afile_record_id: userId,
                    afile_type: moduleConfig.user_image_type
                },
                attributes: ["afile_id", "afile_cldId"]
            }),
            model.tbl_attachments.findOne({
                where: {
                    afile_record_id: userId,
                    afile_type: moduleConfig.id_document_image_type
                },
                attributes: ["afile_id", "afile_cldId"]
            }),
        ]);

        const [profileImageUrl, kycImageUrl] = await Promise.all([
            profileImage?.afile_cldId
                ? cloudinaryInstance.getOptimizedUrl(profileImage.afile_cldId)
                : null,
            kycImage?.afile_cldId
                ? cloudinaryInstance.getOptimizedUrl(kycImage.afile_cldId)
                : null,
        ]);

        userObj.profileImage = profileImage
            ? {
                afile_id: profileImage.afile_id,
                url: profileImageUrl
            }
            : null;

        userObj.kycDocumentImage = kycImage
            ? {
                afile_id: kycImage.afile_id,
                url: kycImageUrl
            }
            : null;

        return common.response(req, res, commonConfig.successStatus, true, "User data fetched successfully", userObj);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

module.exports = {
    addUser,
    deleteuser,
    verifyUser,
    updateStatus,
    deleteSingleImage,
    userListing,
    userById
};
