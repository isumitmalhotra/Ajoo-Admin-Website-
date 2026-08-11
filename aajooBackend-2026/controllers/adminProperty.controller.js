const fs = require("fs/promises");
const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require("sequelize");
const { CloudinaryManager } = require("../utils/cloudinary");
const moduleConfig = require("../config/moduleConfigs");
const methods = require("../utils/methods");
const { logAdminMutation } = require("../services/admin/adminAudit.service");
const {
    normalizeBooleanFlag,
    normalizeOptionalString,
    normalizeOptionalValue,
} = require("../utils/requestFilters");

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

const uploadFilesToCloudinary = async (files = [], folderName = "property_folder") => {
    return Promise.all(
        files.filter(Boolean).map(async (file) => {
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
        })
    );
};

const PropertySearch = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
        const offset = (page - 1) * limit;
        const search = normalizeOptionalString(reqData.search);
        const status = normalizeOptionalValue(reqData.status);
        const forVerification = normalizeBooleanFlag(reqData.forVerification);

        const whereCondition = {
            is_deleted: commonConfig.isNo,
        };

        if (status !== null) {
            whereCondition.is_active = status;
        }

        if (search) {
            whereCondition.property_name = { [Op.like]: `%${search}%` };
        }

        if (forVerification) {
            whereCondition.is_verify = { [Op.ne]: commonConfig.isYes };
        }

        const { count, rows } = await model.tbl_properties.findAndCountAll({
            where: whereCondition,
            limit,
            offset,
            include: [
                {
                    model: model.tbl_user,
                    as: "HostDetails",
                    required: false,
                    attributes: ["user_fullName"],
                }
            ],
            order: [["property_id", "DESC"]],
            attributes: ["property_id", "property_name", "is_active", "is_verify"],
            raw: true,
        });

        if (count === commonConfig.isNo) {
            return common.response(req, res, commonConfig.successStatus, true, "No property found", {
                totalRecords: 0,
                currentPage: page,
                properties: [],
            });
        }

        const propCategories = await model.tbl_prop_to_cat.findAll({
            where: {
                pt_cat_prop_id: rows.map((row) => row.property_id)
            },
            include: [{
                model: model.tbl_categories,
                as: "category",
                attributes: ["cat_title"]
            }],
            raw: true
        });

        const categoryMap = {};
        propCategories.forEach((item) => {
            const propId = item.pt_cat_prop_id;
            if (!categoryMap[propId]) {
                categoryMap[propId] = [];
            }
            categoryMap[propId].push(item["category.cat_title"]);
        });

        const finalProperties = rows.map((property) => ({
            ...property,
            categories: categoryMap[property.property_id] || []
        }));

        return common.response(req, res, commonConfig.successStatus, true, "Properties fetched successfully", {
            totalRecords: count,
            currentPage: page,
            totalPages: Math.ceil(count / limit),
            search,
            page,
            limit,
            offset,
            properties: finalProperties,
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const updateStatus = async (req, res) => {
    try {
        const { propertyId, status } = req.body;
        const property = await model.tbl_properties.findOne({ where: { property_id: propertyId } });

        if (!property) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "Property not found");
        }

        await model.tbl_properties.update({ is_active: status }, { where: { property_id: propertyId } });
        await logAdminMutation(req, {
            action: "status_update",
            entity: "property",
            entityId: propertyId,
            before: { is_active: property.is_active },
            after: { is_active: status },
        });
        return common.response(req, res, commonConfig.successStatus, true, "Property status updated successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const deleteProperty = async (req, res) => {
    try {
        const { propertyId } = req.body;
        const property = await model.tbl_properties.findOne({ where: { property_id: propertyId } });

        if (!property) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "Property not found");
        }

        await model.tbl_properties.update({ is_deleted: commonConfig.isYes }, { where: { property_id: propertyId } });
        await logAdminMutation(req, {
            action: "delete",
            entity: "property",
            entityId: propertyId,
            before: { is_deleted: property.is_deleted },
            after: { is_deleted: commonConfig.isYes },
        });
        return common.response(req, res, commonConfig.successStatus, true, "Property deleted successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const getPropetyById = async (req, res) => {
    try {
        const { propertyId } = req.body;

        const property = await model.tbl_properties.findOne({
            where: { property_id: propertyId },
            attributes: { exclude: ["is_deleted", "created_at", "updated_at"] },
            include: [
                {
                    model: model.tbl_user,
                    as: "HostDetails",
                    required: false,
                    attributes: ["user_fullName"]
                },
                {
                    model: model.tbl_property_detail,
                    as: "propDetails",
                    required: false,
                    attributes: { exclude: ["propDetail_propId"] },
                }
            ],
            raw: true
        });

        if (!property) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "Property not found");
        }

        const [propertyImages, propertyCategories, propertyTags, propertyAmenities] = await Promise.all([
            methods.getAttachedPropertyImages(propertyId),
            model.tbl_prop_to_cat.findAll({
                raw: true,
                where: { pt_cat_prop_id: propertyId },
                attributes: ["pt_cat_cat_id", "pt_cat_id"],
                include: [{
                    model: model.tbl_categories,
                    as: "category",
                    attributes: ["cat_title"]
                }]
            }),
            model.tbl_prop_to_tag.findAll({
                raw: true,
                where: { pt_tag_prop_id: propertyId },
                attributes: ["pt_tag_tag_id", "pt_tag_id"],
                include: [{
                    model: model.tbl_tags,
                    as: "tag",
                    attributes: ["tag_name"]
                }]
            }),
            model.tbl_prop_to_amenities.findAll({
                raw: true,
                where: { pa_prop_id: propertyId },
                attributes: ["pa_amn_id", "pa_id"],
                include: [{
                    model: model.tbl_amenities,
                    as: "amenity",
                    attributes: ["amn_title"]
                }]
            })
        ]);

        return common.response(req, res, commonConfig.successStatus, true, "Property fetched successfully", {
            ...property,
            ...propertyImages,
            categories: propertyCategories,
            tags: propertyTags,
            amenities: propertyAmenities,
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const createuUpdateProperty = async (req, res) => {
    let transaction;
    const uploadedPublicIds = [];
    const stalePublicIds = [];
    const tempFilePaths = [];

    try {
        const reqData = { ...req.body };
        const files = req.files || {};
        let propertyId = reqData.propertyId ? Number(reqData.propertyId) : null;
        const isUpdate = propertyId !== null;
        const existingProperty = isUpdate
            ? await model.tbl_properties.findOne({ where: { property_id: propertyId }, raw: true })
            : null;

        if (isUpdate && !existingProperty) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "Property not found");
        }

        const [uploadedCoverFiles, uploadedImageFiles, uploadedDocFiles] = await Promise.all([
            uploadFilesToCloudinary(files.propertyCover || [], "property_folder"),
            uploadFilesToCloudinary(files.propertyImage || [], "property_folder"),
            uploadFilesToCloudinary(files.propertyDoc || [], "property_folder"),
        ]);

        [...uploadedCoverFiles, ...uploadedImageFiles, ...uploadedDocFiles].forEach((file) => {
            uploadedPublicIds.push(file.publicId);
            tempFilePaths.push(file.tempPath);
        });

        transaction = await model.sequelize.transaction();

        const propertyPayload = {
            property_name: reqData.propertyName,
            property_host_id: reqData.propHostId,
            property_address: reqData.propAddress,
            property_longitude: reqData.propLang,
            property_latitude: reqData.propLat,
            property_desc: reqData.propDesc,
            property_price: reqData.propPrice,
            property_mini_price: reqData.propMiniPrice,
            property_city: reqData.propCity,
            property_zip: reqData.propZip,
            property_state: reqData.propState,
            property_contry: reqData.propCountry,
            property_contact: reqData.propContact,
            property_email: reqData.propEmail,
            is_active: reqData.isActive ? 1 : 0,
            is_verify: reqData.isVerify,
            is_luxury: reqData.isLuxury,
        };

        if (isUpdate) {
            await model.tbl_properties.update(propertyPayload, { where: { property_id: propertyId }, transaction });
        } else {
            const createdData = await model.tbl_properties.create(propertyPayload, { transaction });
            propertyId = createdData.dataValues.property_id;
        }

        const propertyDetailsPayload = {
            propDetail_propId: propertyId,
            propDetail_isPetFriendly: reqData.isPetFriendly ? 1 : 0,
            propDetail_isSmoke: reqData.isSmoke ? 1 : 0,
            propDetail_inTime: reqData.inTime,
            propDetail_outTime: reqData.outTime,
            propDetail_no_of_beds: reqData.noOfBeds,
            propDetail_no_of_guests: reqData.noOfGuests,
            propDetail_weeklyMini_price: reqData.weeklyMiniPrice,
            propDetail_weeklyMax_price: reqData.weeklyMaxPrice,
            propDetail_monthly_security: reqData.monthlySecurity,
            propDetail_extra: reqData.extra
        };

        if (isUpdate) {
            await model.tbl_property_detail.update(propertyDetailsPayload, {
                where: { propDetail_propId: propertyId },
                transaction
            });
        } else {
            await model.tbl_property_detail.create(propertyDetailsPayload, { transaction });
        }

        if (Array.isArray(reqData.categories)) {
            const categoryIds = [...new Set(reqData.categories.map((id) => Number(id)).filter(Boolean))];
            await model.tbl_prop_to_cat.destroy({ where: { pt_cat_prop_id: propertyId }, transaction });

            if (categoryIds.length) {
                await model.tbl_prop_to_cat.bulkCreate(
                    categoryIds.map((catId) => ({
                        pt_cat_prop_id: propertyId,
                        pt_cat_cat_id: catId,
                    })),
                    { transaction }
                );
            }
        }

        if (Array.isArray(reqData.ameneties)) {
            const amenityIds = [...new Set(reqData.ameneties.map((id) => Number(id)).filter(Boolean))];
            await model.tbl_prop_to_amenities.destroy({ where: { pa_prop_id: propertyId }, transaction });

            if (amenityIds.length) {
                await model.tbl_prop_to_amenities.bulkCreate(
                    amenityIds.map((amenityId) => ({
                        pa_prop_id: propertyId,
                        pa_amn_id: amenityId,
                    })),
                    { transaction }
                );
            }
        }

        if (Array.isArray(reqData.tags)) {
            const tagIds = [...new Set(reqData.tags.map((id) => Number(id)).filter(Boolean))];
            await model.tbl_prop_to_tag.destroy({
                where: { pt_tag_prop_id: propertyId },
                transaction,
            });

            if (tagIds.length) {
                await model.tbl_prop_to_tag.bulkCreate(
                    tagIds.map((tagId) => ({
                        pt_tag_prop_id: propertyId,
                        pt_tag_tag_id: tagId,
                    })),
                    { transaction }
                );
            }
        }

        if (uploadedCoverFiles.length || uploadedImageFiles.length || uploadedDocFiles.length) {
            const existingAttachments = await model.tbl_attachments.findAll({
                raw: true,
                where: {
                    afile_record_id: propertyId,
                    afile_type: {
                        [Op.in]: [
                            moduleConfig.property_cover_image_type,
                            moduleConfig.property_image_type,
                            moduleConfig.property_doc_type
                        ]
                    }
                },
                transaction
            });

            const existingByType = existingAttachments.reduce((acc, attachment) => {
                if (!acc[attachment.afile_type]) {
                    acc[attachment.afile_type] = [];
                }
                acc[attachment.afile_type].push(attachment);
                return acc;
            }, {});

            if (uploadedCoverFiles.length) {
                const currentCoverFiles = existingByType[moduleConfig.property_cover_image_type] || [];
                stalePublicIds.push(...currentCoverFiles.map((item) => item.afile_cldId).filter(Boolean));

                if (currentCoverFiles.length) {
                    await model.tbl_attachments.destroy({
                        where: { afile_id: currentCoverFiles.map((item) => item.afile_id) },
                        transaction
                    });
                }

                await model.tbl_attachments.create({
                    afile_type: moduleConfig.property_cover_image_type,
                    afile_record_id: propertyId,
                    afile_path: uploadedCoverFiles[0].secureUrl,
                    afile_cldId: uploadedCoverFiles[0].publicId,
                    afile_name: uploadedCoverFiles[0].originalName,
                }, { transaction });
            }

            if (uploadedImageFiles.length) {
                const currentImages = existingByType[moduleConfig.property_image_type] || [];
                stalePublicIds.push(...currentImages.map((item) => item.afile_cldId).filter(Boolean));

                if (currentImages.length) {
                    await model.tbl_attachments.destroy({
                        where: { afile_id: currentImages.map((item) => item.afile_id) },
                        transaction
                    });
                }

                await model.tbl_attachments.bulkCreate(
                    uploadedImageFiles.map((file) => ({
                        afile_type: moduleConfig.property_image_type,
                        afile_record_id: propertyId,
                        afile_path: file.secureUrl,
                        afile_cldId: file.publicId,
                        afile_name: file.originalName,
                    })),
                    { transaction }
                );
            }

            if (uploadedDocFiles.length) {
                const currentDocs = existingByType[moduleConfig.property_doc_type] || [];
                stalePublicIds.push(...currentDocs.map((item) => item.afile_cldId).filter(Boolean));

                if (currentDocs.length) {
                    await model.tbl_attachments.destroy({
                        where: { afile_id: currentDocs.map((item) => item.afile_id) },
                        transaction
                    });
                }

                await model.tbl_attachments.bulkCreate(
                    uploadedDocFiles.map((file) => ({
                        afile_type: moduleConfig.property_doc_type,
                        afile_record_id: propertyId,
                        afile_path: file.secureUrl,
                        afile_cldId: file.publicId,
                        afile_name: file.originalName,
                    })),
                    { transaction }
                );
            }
        }

        await transaction.commit();
        await cleanupLocalFiles(tempFilePaths);
        await deleteCloudinaryAssets(stalePublicIds);
        await logAdminMutation(req, {
            action: isUpdate ? "update" : "create",
            entity: "property",
            entityId: propertyId,
            before: existingProperty,
            after: propertyPayload,
            meta: {
                hasCoverUpload: uploadedCoverFiles.length > 0,
                imageCount: uploadedImageFiles.length,
                documentCount: uploadedDocFiles.length,
            },
        });

        return common.response(req, res, commonConfig.successStatus, true, "Property created/updated successfully");
    } catch (error) {
        if (transaction && !transaction.finished) {
            await transaction.rollback();
        }

        await deleteCloudinaryAssets(uploadedPublicIds);
        await cleanupLocalFiles(tempFilePaths);

        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const deletePropertyImages = async (req, res) => {
    try {
        const reqData = req.body;
        const findImage = await model.tbl_attachments.findOne({
            raw: true,
            where: {
                afile_id: reqData.afile_id,
                afile_type: {
                    [Op.in]: [
                        moduleConfig.property_cover_image_type,
                        moduleConfig.property_image_type,
                        moduleConfig.property_doc_type
                    ]
                },
            },
            attributes: ["afile_id", "afile_cldId", "afile_type"]
        });

        if (!findImage) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "Image not found");
        }

        await cloudinaryInstance.deleteSingleImage(findImage.afile_cldId);
        await model.tbl_attachments.destroy({ where: { afile_id: findImage.afile_id } });
        await logAdminMutation(req, {
            action: "delete_image",
            entity: "property_attachment",
            entityId: findImage.afile_id,
            before: findImage,
        });
        return common.response(req, res, commonConfig.successStatus, true, "Image deleted successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

module.exports = {
    PropertySearch,
    updateStatus,
    deleteProperty,
    getPropetyById,
    createuUpdateProperty,
    deletePropertyImages
};
