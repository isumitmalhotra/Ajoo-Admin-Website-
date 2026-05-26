const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require("sequelize");
const { CloudinaryManager } = require("../utils/cloudinary");
const moduleConfig = require("../config/moduleConfigs");
const methods = require("../utils/methods");
const cloudinaryInstance = new CloudinaryManager();

const PropertySearch = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = 10;
        const offset = (page - 1) * limit;
        const search = reqData.search?.trim() || "";
        const status = reqData.status ?? null;
        const forVerification = reqData.forVerification ? true : false;
        let whereCondition = {
            is_deleted: 0,
        };
        if (status) {
            whereCondition.is_active = status;
        }
        if (search) {
            whereCondition.property_name = { [Op.like]: `%${search}%` }
        }
        if (forVerification) {
            whereCondition.is_verify = { [Op.ne]: 1 };
        }
        const { count, rows } = await model.tbl_properties.findAndCountAll({
            where: whereCondition,
            limit: limit,
            offset: offset,
            include: [
                {
                    model: model.tbl_user,
                    as: 'HostDetails',
                    required: false,
                    attributes: ['user_fullName'],
                }
            ],
            order: [['property_id', 'DESC']],
            attributes: ["property_id", "property_name", "is_active","is_verify"],
            raw: true,
        });
        if (count === commonConfig.isNo) {
            return common.response(req, res, commonConfig.successStatus, false, "No property found", { totalRecords: 0, currentPage: page, properties: [], });
        }
        const propCategories = await model.tbl_prop_to_cat.findAll({
            where: {
                pt_cat_prop_id: rows.map(r => r.property_id)
            },
            include: [{
                model: model.tbl_categories,
                as: 'category',
                attributes: ['cat_title']
            }],
            raw: true
        });
        const categoryMap = {};
        propCategories.forEach(item => {
            const propId = item.pt_cat_prop_id;
            if (!categoryMap[propId]) categoryMap[propId] = [];
            categoryMap[propId].push(item['category.cat_title']);
        });
        const finalProperties = rows.map(prop => ({
            ...prop,
            categories: categoryMap[prop.property_id] || []
        }));
        return common.response(req, res, commonConfig.successStatus, true, "User listing fetched successfully", {
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
            return common.response(req, res, commonConfig.successStatus, false, "Property not found");
        }
        await model.tbl_properties.update({ is_active: status }, { where: { property_id: propertyId } });
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
            return common.response(req, res, commonConfig.successStatus, false, "Property not found");
        }
        await model.tbl_properties.update({ is_deleted: 1 }, { where: { property_id: propertyId } });
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
                    as: 'HostDetails',
                    required: false,
                    attributes: ['user_fullName']
                },
                {
                    model: model.tbl_property_detail,
                    as: 'propDetails',
                    required: false,
                    attributes: { exclude: ["propDetail_propId"] },
                }
            ],
            raw: true
        });
        if (!property) {
            return common.response(req, res, commonConfig.successStatus, false, "Property not found");
        }
        const PropertyImages = await methods.getAttachedPropertyImages(propertyId);
        const propertyCategories = await model.tbl_prop_to_cat.findAll({
            raw: true,
            where: { pt_cat_prop_id: propertyId },
            attributes: ['pt_cat_cat_id', 'pt_cat_id'],
            include: [{
                model: model.tbl_categories,
                as: 'category',
                attributes: ['cat_title']
            }]
        });
        const propertyTags = await model.tbl_prop_to_tag.findAll({
            raw: true,
            where: { pt_tag_prop_id: propertyId },
            attributes: ['pt_tag_tag_id', 'pt_tag_id'],
            include: [{
                model: model.tbl_tags,
                as: 'tag',
                attributes: ['tag_name']
            }]
        });
        const propertyAmenities = await model.tbl_prop_to_amenities.findAll({
            raw: true,
            where: { pa_prop_id: propertyId },
            attributes: ['pa_amn_id', 'pa_id'],
            include: [{
                model: model.tbl_amenities,
                as: 'amenity',
                attributes: ['amn_title']
            }]
        });
        return common.response(req, res, commonConfig.successStatus, true, "Property fetched successfully", {
            ...property,
            ...PropertyImages,
            categories: propertyCategories,
            tags: propertyTags,
            amenities: propertyAmenities,
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const createuUpdateProperty = async (req, res) => {
    let transaction = await model.sequelize.transaction();
    try {
        const reqData = { ...req.body };
        let files = req.files;
        let propertyId = reqData.propertyId ?? null;
        const isUpdate = Boolean(propertyId);
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
            model.tbl_properties.update(propertyPayload, { where: { property_id: propertyId }, transaction });
        } else {
            const creadtedData = await model.tbl_properties.create(propertyPayload, { transaction });
            propertyId = creadtedData.dataValues.property_id
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
            await model.tbl_property_detail.update(propertyDetailsPayload,
                {
                    where: { propDetail_propId: propertyId },
                    transaction
                });
        } else {
            await model.tbl_property_detail.create(propertyDetailsPayload, { transaction });
        }
        if (Array.isArray(reqData.categories)) {
            const categoryIds = [...new Set(
                reqData.categories.map(id => Number(id)).filter(Boolean)
            )];
            await model.tbl_prop_to_cat.destroy({ where: { pt_cat_prop_id: propertyId }, transaction });
            if (categoryIds.length) {
                const categoryPayload = categoryIds.map(catId => ({
                    pt_cat_prop_id: propertyId,
                    pt_cat_cat_id: catId,
                }));
                await model.tbl_prop_to_cat.bulkCreate(categoryPayload, { transaction });
            }
        }
        if (Array.isArray(reqData.ameneties)) {
            const amenityIds = reqData.ameneties
                .map(id => Number(id))
                .filter(Boolean);
            await model.tbl_prop_to_amenities.destroy({ where: { pa_prop_id: propertyId }, transaction });
            if (amenityIds.length) {
                const amenityPayload = amenityIds.map(amnId => ({
                    pa_prop_id: propertyId,
                    pa_amn_id: amnId,
                }));
                await model.tbl_prop_to_amenities.bulkCreate(amenityPayload, { transaction });
            }
        }
        if (Array.isArray(reqData.tags)) {
            const tagIds = [...new Set(
                reqData.tags.map(id => Number(id)).filter(Boolean)
            )];

            await model.tbl_prop_to_tag.destroy({
                where: { pt_tag_prop_id: propertyId },
                transaction,
            });
            if (tagIds.length) {
                const tagPayload = tagIds.map(tagId => ({
                    pt_tag_prop_id: propertyId,
                    pt_tag_tag_id: tagId,
                }));
                await model.tbl_prop_to_tag.bulkCreate(tagPayload, { transaction });
            }
        }
        if (files?.propertyCover?.length > 0) {
            let findCoverImg = await model.tbl_attachments.findOne(
                {
                    where:
                        { afile_type: moduleConfig.property_cover_image_type, afile_record_id: propertyId },
                    raw: true
                }
            );
            if (findCoverImg) {
                await cloudinaryInstance.deleteSingleImage(findCoverImg.afile_cldId);
                await model.tbl_attachments.destroy({ where: { afile_id: findCoverImg.afile_id } });
            }
            await cloudinaryInstance.uploadImage(files.propertyCover[0].path, moduleConfig.property_cover_image_type, propertyId);
        }
        if (files?.propertyImage?.length > 0) {
            let existingImages = await model.tbl_attachments.findAll(
                {
                    where:
                        { afile_type: moduleConfig.property_image_type, afile_record_id: propertyId },
                    raw: true
                });
            if (existingImages.length > 0) {
                for (const img of existingImages) {
                    if (img.afile_cldId) {
                        await cloudinaryInstance.deleteSingleImage(img.afile_cldId);
                    }
                }
                await model.tbl_attachments.destroy({
                    where: {
                        afile_id: existingImages.map(img => img.afile_id)
                    }
                });
            }
            await cloudinaryInstance.multipleImages(files.propertyImage, moduleConfig.property_image_type, propertyId, "property_folder");

        }
        if (files?.propertyDoc?.length > 0) {
            let existingDoc = await model.tbl_attachments.findAll(
                {
                    where:
                        { afile_type: moduleConfig.property_doc_type, afile_record_id: propertyId },
                    raw: true
                });
            if (existingDoc.length > 0) {
                for (const img of existingDoc) {
                    if (img.afile_cldId) {
                        await cloudinaryInstance.deleteSingleImage(img.afile_cldId);
                    }
                }
                await model.tbl_attachments.destroy({
                    where: {
                        afile_id: existingDoc.map(img => img.afile_id)
                    }
                });
            }
            await cloudinaryInstance.multipleImages(files.propertyDoc, moduleConfig.property_doc_type, propertyId, "property_folder");

        }
        await transaction.commit();
        return common.response(req, res, commonConfig.successStatus, true, "Property created/updated successfully");
    }
    catch (error) {
        // await transaction.rollback();
        if (!transaction.finished) {
            await transaction.rollback();
        }
        console.log(error, "error in property create/update")
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
            attributes: ['afile_id', 'afile_cldId', 'afile_type']
        });
        if (!findImage) {
            return common.response(req, res, commonConfig.successStatus, false, "Image not found");
        }
        await cloudinaryInstance.deleteSingleImage(findImage.afile_cldId);
        await model.tbl_attachments.destroy({ where: { afile_id: findImage.afile_id } });
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
}