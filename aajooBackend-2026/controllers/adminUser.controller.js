const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require("sequelize");
const { CloudinaryManager } = require("../utils/cloudinary");
const moduleConfig = require("../config/moduleConfigs");
const methods = require("../utils/methods");

const cloudinaryInstance = new CloudinaryManager();

const addUser = async (req, res) => {
    const transaction = await model.sequelize.transaction();
    try {
        const reqData = { ...req.body };
        let userData;
        let loadUserImage;
        let userProAfileId;
        let userIdAfileId = reqData.afileId;
        let loadIdImage;
        let credData;
        let userDoc;
        let userId = reqData.userId;

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

        let credPayload = {
            cred_username: reqData.cred_username,
            cred_user_email: reqData.cred_user_email,
            cred_user_refrel: reqData.cred_user_refrel ?? null,
        };
        console.log(credPayload, "credPayload")
        if (reqData.cred_user_password) {
            let hashPassword = await methods.hashPassword(reqData.cred_user_password);
            credPayload.cred_user_password = hashPassword
        }

        if (reqData.userId) {
            await model.tbl_user.update(payload, { where: { user_id: userId }, transaction });
            const y = await model.tbl_user_cred.update(credPayload, { where: { cred_user_id: userId }, transaction });
        } else {
            userData = await model.tbl_user.create(payload, { transaction });
            if (userData == null) {
                throw new Error("Error in user creation");
            }
            userId = userData.dataValues.user_id;
            credPayload.cred_user_id = userId;
            credData = await model.tbl_user_cred.create(credPayload, { transaction });
        }

        if (req.files?.user_profile) {
            if (userId) {
                let findAttachment = await model.tbl_attachments.findOne({
                    where: { afile_type: moduleConfig.user_image_type, afile_record_id: userId },
                    raw: true
                });
                if (findAttachment) {
                    await cloudinaryInstance.deleteSingleImage(findAttachment.afile_cldId)
                    await model.tbl_attachments.destroy({
                        where: { afile_type: moduleConfig.user_image_type, afile_record_id: userId },
                    })
                }
            }
            let userImageUrl = req.files.user_profile[0].path;
            const loadUserImage = await cloudinaryInstance.uploadImage(userImageUrl, moduleConfig.user_image_type, userId);
            userProAfileId = loadUserImage.afileId;
        }

        if (req.files?.user_id_image) {
            if (userId) {
                let findAttachment = await model.tbl_attachments.findOne({
                    where: { afile_type: moduleConfig.id_document_image_type, afile_record_id: userId },
                    raw: true
                });
                if (findAttachment) {
                    await cloudinaryInstance.deleteSingleImage(findAttachment.afile_cldId)
                    await model.tbl_attachments.destroy({
                        where: { afile_type: moduleConfig.id_document_image_type, afile_record_id: userId },
                    })
                }
            }
            let imageUrl = req.files.user_id_image[0].path;
            loadIdImage = await cloudinaryInstance.uploadImage(imageUrl, moduleConfig.id_document_image_type, userId);
            userIdAfileId = loadIdImage.afileId;
        }
        let userDocPayload = {
            ud_acc_doc_id: reqData.cred_user_doc_type,
            ud_user_id: userId,
            ud_number: reqData.cred_user_doc_number,
            ud_isVerified: commonConfig.isYes,
        };
        if (userIdAfileId) {
            userDocPayload.ud_afile_id = userIdAfileId ?? 0
        }
        const existingKyc = await model.user_kyc_docs.findOne({
            where: { ud_user_id: userId },
            transaction
        });
        if (existingKyc) {
            const x = await model.user_kyc_docs.update(
                userDocPayload,
                { where: { ud_user_id: userId }, transaction }
            );
        } else {
            // userDoc = await model.user_kyc_docs.create(userDocPayload);
            const userDoc = await model.user_kyc_docs.create(
                userDocPayload,
                { transaction }
            );
        }
        await transaction.commit();
        return common.response(req, res, commonConfig.successStatus, true, "User added successfully");
    } catch (error) {
        if (!transaction.finished) {
            await transaction.rollback();
        }
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const deleteuser = async (req, res) => {
    try {
        const { userId } = req.body;
        await model.tbl_user.updateUser({ user_isDelete: commonConfig.isYes }, userId);
        return common.response(req, res, commonConfig.successStatus, true, "User Delete successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const verifyUser = async (req, res) => {
    try {
        const { userId, verifyStatus } = req.body;
        let payload = {
            user_isActive: commonConfig.isYes,
            user_isVerified: verifyStatus ?? commonConfig.isYes,
            user_isDelete: commonConfig.isNo,
        };
        await model.tbl_user.updateUser(payload, userId);
        return common.response(req, res, commonConfig.successStatus, true, "User Verified successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const updateStatus = async (req, res) => {
    try {
        const { userId, isActive } = req.body;
        await model.tbl_user.updateUser({ user_isActive: isActive }, userId);
        return common.response(req, res, commonConfig.successStatus, true, "Status Updated Successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const deleteSingleImage = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let findAttachment = await model.tbl_attachments.findOne({
            where: { afile_id: reqData.afileId },
            raw: true
        });
        if (findAttachment) {
            await cloudinaryInstance.deleteSingleImage(findAttachment.afile_cldId)
            await model.tbl_attachments.destroy({ where: { afile_id: reqData.afileId } });
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
        const limit = 10;
        const offset = (page - 1) * limit;
        const search = reqData.search?.trim() || "";
        const status = reqData.status ?? null;

        let whereClause = {
            user_isDelete: commonConfig.isNo
        };
        let credWhereClause = {};
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
                    where: credWhereClause,
                    required: true,
                    attributes: ["cred_user_email"]
                }
            ],
            limit,
            offset,
            order: [["added_at", "DESC"]],
            attributes: ["user_id", "user_fullName", "user_isActive", "user_isVerified", "added_at", "user_dob"]
        });
        if (!rows) {
            return common.response(req, res, commonConfig.successStatus, true, "No records found")
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

        const profileImageUrl = profileImage?.afile_cldId
            ? await cloudinaryInstance.getOptimizedUrl(profileImage.afile_cldId)
            : null;

        const kycImageUrl = kycImage?.afile_cldId
            ? await cloudinaryInstance.getOptimizedUrl(kycImage.afile_cldId)
            : null;

        userObj.profileImage = profileImage
            ?
            {
                afile_id: profileImage.afile_id,
                url: profileImageUrl
            }
            : null;

        userObj.kycDocumentImage = kycImage
            ?
            {
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
}