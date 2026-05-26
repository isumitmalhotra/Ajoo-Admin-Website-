const model = require("../models");
const { Op, Sequelize } = require("sequelize");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const methods = require("../utils/methods");
const moduleConfig = require("../config/moduleConfigs");
const xlsx = require("xlsx");
const { CloudinaryManager } = require("../utils/cloudinary");

const EARTH_RADIUS_KM = 6371;

function calculateRatings(allRating) {
    let allRatings = {};
    let totalRating = 0;

    allRating.forEach(review => {
        const rating = parseFloat(review.br_rating);
        allRatings[rating] = (allRatings[rating] || 0) + 1;
        totalRating += rating;
    });

    const averageRating = (totalRating / allRating.length).toFixed(2);

    return { allRatings, averageRating };
};
async function removeFromLikesSaveProerties() {
    try {
        const whereClause = {
            slp_isSave: 0,
            slp_isLike: 0,
            slp_isDislike: 0,
        }
        await model.tbl_saved_liked_prop.destroy({ where: whereClause });
        return true
    } catch (error) {
        return error;
    }
};
//-------------CONTROLLERS----------------
const getProperties = async (req, res) => {
    const { Sequelize } = require('sequelize');
    try {
        const {
            latitude,
            longitude,
            category,
            radius,
            maxPrice,
            minPrice,
        } = req.body;
        let kmRadius = radius ? radius : 5;
        let attributes =
            [
                "property_id",
                "property_longitude",
                "property_latitude",
                "property_price",
            ];
        const distanceCondition = Sequelize.where(
            Sequelize.literal(`(
                6371 * acos(
                    cos(radians(:latitude)) *
                    cos(radians(property_latitude)) *
                    cos(radians(property_longitude) - radians(:longitude)) +
                    sin(radians(:latitude)) *
                    sin(radians(property_latitude))
                )
            )`),
            '<=',
            kmRadius
        );
        const conditions = [distanceCondition];
        conditions.push({ is_active: commonConfig.isYes }, { is_deleted: commonConfig.isNo });
        if (minPrice && maxPrice) {
            conditions.push({
                property_price: {
                    [Sequelize.Op.between]: [minPrice, maxPrice],
                },
            });
        };

        const finalWhereClause = Sequelize.and(...conditions);
        let rows = await model.tbl_properties.findAll({
            attributes: [
                "property_id",
                "property_name",
                "property_address",
                "property_desc",
                "property_price",
                "property_city",
                "property_longitude",
                "property_latitude",
                "property_host_id",
                "property_zip",
                "property_contact",
                [
                    Sequelize.literal(`(
                            6371 * acos(
                                cos(radians(:latitude)) *
                                cos(radians(property_latitude)) *
                                cos(radians(property_longitude) - radians(:longitude)) +
                                sin(radians(:latitude)) *
                                sin(radians(property_latitude))
                            )
                        )`),
                    'distance'
                ],
            ],
            where: finalWhereClause,
            replacements: { latitude, longitude, radius },
            order: Sequelize.literal('distance ASC'),
            include: [
                {
                    model: model.tbl_property_detail,
                    as: "propDetails",
                    attributes: [
                        "propDetail_isPetFriendly",
                        "propDetail_isSmoke",
                        "propDetail_inTime",
                        "propDetail_outTime",
                        "propDetail_extra",
                        "propDetail_no_of_guests",
                    ]
                },
                {
                    model: model.tbl_prop_to_cat,
                    as: "propertyCategories",
                    include: {
                        model: model.tbl_categories,
                        as: "category",
                        attributes: ["cat_id", "cat_title", "cat_slug"],
                        where: { cat_isActive: commonConfig.isYes, cat_isDelete: commonConfig.isNo }
                    }
                },
                {
                    model: model.tbl_prop_to_amenities,
                    as: "propertyAmenities",
                    include: {
                        model: model.tbl_amenities,
                        as: "amenity",
                        attributes: ["amn_id", "amn_title"],
                        where: { amn_isActive: commonConfig.isYes, amn_isDelete: commonConfig.isNo }
                    }
                },
                {
                    model: model.tbl_prop_to_tag,
                    as: "propertyTags",
                    include: {
                        model: model.tbl_tags,
                        as: "tag",
                        attributes: ["tag_id", "tag_name"],
                        where: { tag_isActive: commonConfig.isYes, tag_isDelete: commonConfig.isNo }
                    }
                }
            ]
        });

        rows = rows.map(row => row.toJSON());
        if (rows.length == commonConfig.isNo) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found");
        }
        let propIds = rows.map(p => p.property_id);
        let attachmentsRows = await methods.getAttchedProperties(rows, propIds)
        let filteredRows;
        if (category) {
            filteredRows = attachmentsRows.filter(row => {
                const categories = row.propertyCategories ? row.propertyCategories.map(pc => pc.category.cat_id) : [];
                return categories.includes(Number(category));
            }).map(row => {
                const categoryTitles = row.propertyCategories ? row.propertyCategories.map(pc => pc.category.cat_title).filter(Boolean) : null;
                const amenities = row.propertyAmenities ? row.propertyAmenities.map(pa => pa.amenity.amn_title).filter(Boolean) : null;
                const tags = row.propertyTags ? row.propertyTags.map(pt => pt.tag.tag_name).filter(Boolean) : null;

                const flattenedRow = {
                    ...row,
                    category_titles: categoryTitles && categoryTitles.length > 0 ? categoryTitles : null,
                    amenities: amenities && amenities.length > 0 ? amenities : null,
                    tags: tags && tags.length > 0 ? tags : null
                };

                if (row.propDetails) {
                    Object.keys(row.propDetails).forEach(key => {
                        let value = row.propDetails[key];
                        if (key === 'propDetail_isPetFriendly' || key === 'propDetail_isSmoke') {
                            value = !!value;
                        }
                        flattenedRow[`propDetails.${key}`] = value;
                    });
                }

                delete flattenedRow.propertyCategories;
                delete flattenedRow.propertyAmenities;
                delete flattenedRow.propertyTags;
                delete flattenedRow.propDetails;

                return flattenedRow;
            });
        } else {
            filteredRows = attachmentsRows.map(row => {
                const categoryTitles = row.propertyCategories ? row.propertyCategories.map(pc => pc.category.cat_title).filter(Boolean) : null;
                const amenities = row.propertyAmenities ? row.propertyAmenities.map(pa => pa.amenity.amn_title).filter(Boolean) : null;
                const tags = row.propertyTags ? row.propertyTags.map(pt => pt.tag.tag_name).filter(Boolean) : null;

                const flattenedRow = {
                    ...row,
                    category_titles: categoryTitles && categoryTitles.length > 0 ? categoryTitles : null,
                    amenities: amenities && amenities.length > 0 ? amenities : null,
                    tags: tags && tags.length > 0 ? tags : null
                };

                if (row.propDetails) {
                    Object.keys(row.propDetails).forEach(key => {
                        let value = row.propDetails[key];
                        if (key === 'propDetail_isPetFriendly' || key === 'propDetail_isSmoke') {
                            value = !!value;
                        }
                        flattenedRow[`propDetails.${key}`] = value;
                    });
                }

                delete flattenedRow.propertyCategories;
                delete flattenedRow.propertyAmenities;
                delete flattenedRow.propertyTags;
                delete flattenedRow.propDetails;

                return flattenedRow;
            });
        }
        return common.response(req, res, commonConfig.successStatus, true, "successful", { property: filteredRows });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const getProperty = async (req, res) => {
    try {
        const propId = req.params.propId;
        let whereClause = {
            is_active: commonConfig.isYes,
            is_deleted: commonConfig.isNo,
            property_id: propId,
        };
        const property = await model.tbl_properties.findOne({
            where: whereClause,
            attributes: { exclude: ["is_deleted", "created_at", "updated_at"] },
            include: [
                {
                    model: model.tbl_property_detail,
                    as: "propDetails",
                    attributes: [
                        "propDetail_id",
                        "propDetail_propId",
                        "propDetail_no_of_guests",
                        "propDetail_no_of_beds",
                        "propDetail_weeklyMini_price",
                        "propDetail_weeklyMax_price",
                        "propDetail_monthly_security",
                        "propDetail_isPetFriendly",
                        "propDetail_isSmoke",
                        "propDetail_inTime",
                        "propDetail_outTime",
                        "propDetail_extra",
                    ]
                },
                {
                    model: model.tbl_prop_to_cat,
                    as: "propertyCategories",
                    include: {
                        model: model.tbl_categories,
                        as: "category",
                        attributes: ["cat_id", "cat_title", "cat_slug"],
                        where: { cat_isActive: commonConfig.isYes, cat_isDelete: commonConfig.isNo }
                    }
                },
                {
                    model: model.tbl_prop_to_amenities,
                    as: "propertyAmenities",
                    include: {
                        model: model.tbl_amenities,
                        as: "amenity",
                        attributes: ["amn_id", "amn_title"],
                        where: { amn_isActive: commonConfig.isYes, amn_isDelete: commonConfig.isNo }
                    }
                },
                {
                    model: model.tbl_prop_to_tag,
                    as: "propertyTags",
                    include: {
                        model: model.tbl_tags,
                        as: "tag",
                        attributes: ["tag_id", "tag_name"],
                        where: { tag_isActive: commonConfig.isYes, tag_isDelete: commonConfig.isNo }
                    }
                }
            ]
        });
        if (property == null) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found");
        }
        let row = property.toJSON();
        let attachmentsRows = await methods.getAttchedProperties([row], [propId]);
        let filteredRow = attachmentsRows.map(row => {
            const categories = row.propertyCategories
                ? row.propertyCategories.map(pc => pc.category).sort((a, b) => a.cat_id - b.cat_id)
                : null;
            const amenities = row.propertyAmenities ? row.propertyAmenities.map(pa => pa.amenity.amn_title).filter(Boolean) : null;
            const tags = row.propertyTags ? row.propertyTags.map(pt => pt.tag) : null;

            const flattenedRow = {
                ...row,
                categories: categories && categories.length > 0 ? categories : null,
                amenities: amenities && amenities.length > 0 ? amenities : null,
                tags: tags && tags.length > 0 ? tags : null
            };

            if (row.propDetails) {
                Object.keys(row.propDetails).forEach(key => {
                    let value = row.propDetails[key];
                    if (key === 'propDetail_isPetFriendly' || key === 'propDetail_isSmoke') {
                        value = !!value;
                    }
                    flattenedRow[`propDetails.${key}`] = value;
                });
            }

            delete flattenedRow.propertyCategories;
            delete flattenedRow.propertyAmenities;
            delete flattenedRow.propertyTags;
            delete flattenedRow.propDetails;

            return flattenedRow;
        })[0];
        return common.response(req, res, commonConfig.successStatus, true, "success", filteredRow);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const savePropertyByUser = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const payload = {
            slp_user_id: req.user.userId,
            slp_prop_id: reqData.propId,
            slp_isSave: commonConfig.isYes
        };
        let isExist = await model.tbl_saved_liked_prop.getSingle(payload);
        if (isExist) {
            await model.tbl_saved_liked_prop.update({ slp_isSave: commonConfig.isNo }, { where: { slp_id: isExist.slp_id } });
            await removeFromLikesSaveProerties();
            return common.response(req, res, commonConfig.successStatus, true, "property unsave");
        } else {
            const isData = await model.tbl_saved_liked_prop.findOne({
                raw: true,
                where: {
                    slp_user_id: req.user.userId,
                    slp_prop_id: reqData.propId,
                },
            });
            if (isData) {
                await model.tbl_saved_liked_prop.update({ slp_isSave: commonConfig.isYes }, { where: { slp_id: isData.slp_id } });
            } else {
                await model.tbl_saved_liked_prop.createData(payload);
            }
            return common.response(req, res, commonConfig.successStatus, true, "success");
        }
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const propertyListing = async (req, res) => {
    try {
        const { query, filters, sort_by, order, limit, offset, isLuxury, radius } = req.body;
        const { latitude, longitude } = req.body;
        let whereClause = {
            is_active: 1,
            is_deleted: 0
        };
        if (filters) {
            if (filters.city) {
                whereClause.property_city = filters.city;
            }
            if (filters.area) {
                whereClause.property_address = { [Op.like]: `%${filters.area}%` };
            }
            if (filters.price_range) {
                whereClause.property_price = {
                    [Op.between]: [filters.price_range.min, filters.price_range.max]
                };
            }
            if (filters.rating) {
                whereClause.property_rating = {
                    [Op.between]: [filters.rating.min, filters.rating.max]
                };
            }
            if (filters.amenities) {
                whereClause.property_amenities = {
                    [Op.contains]: filters.amenities
                };
            }
        }
        if (query) {
            whereClause[Op.or] = [
                { property_name: { [Op.like]: `%${query}%` } },
                { property_address: { [Op.like]: `%${query}%` } },
                { property_desc: { [Op.like]: `%${query}%` } }
            ];
        }

        let distanceQuery = null;
        if (latitude && longitude) {
            // Haversine formula for filtering properties within the radius
            distanceQuery = Sequelize.literal(`
                (${EARTH_RADIUS_KM} * acos(
                    cos(radians(${latitude})) * cos(radians(property_latitude)) *
                    cos(radians(property_longitude) - radians(${longitude})) +
                    sin(radians(${latitude})) * sin(radians(property_latitude))
                ))
            `);
            whereClause[Op.and] = [
                Sequelize.where(distanceQuery, { [Op.lte]: radius })
            ];
        };
        if (isLuxury) {
            whereClause.is_luxury = 1;
        }
        let varOrder = order ?? "DESC";
        let orderBy = [];
        if (sort_by && sort_by !== "rating") {
            orderBy.push([sort_by, varOrder || "desc"]);
        }
        let properties = await model.tbl_properties.findAll({
            attributes: distanceQuery ? { include: [[distanceQuery, "distance"]] } : undefined,
            where: whereClause,
            order: orderBy.length > 0 ? orderBy : [["property_id", "desc"]],
            limit: limit || 10,
            offset: offset || 0,
            include: [
                {
                    model: model.tbl_property_detail,
                    as: "propDetails",
                    attributes: [
                        "propDetail_isPetFriendly",
                        "propDetail_isSmoke",
                        "propDetail_inTime",
                        "propDetail_outTime",
                        "propDetail_extra",
                        "propDetail_no_of_guests"
                    ]
                },
                {
                    model: model.tbl_prop_to_cat,
                    as: "propertyCategories",
                    include: {
                        model: model.tbl_categories,
                        as: "category",
                        attributes: ["cat_id", "cat_title", "cat_slug", "cat_isActive", "cat_isDelete"]
                    }
                },
                {
                    model: model.tbl_prop_to_amenities,
                    as: "propertyAmenities",
                    include: {
                        model: model.tbl_amenities,
                        as: "amenity",
                        attributes: ["amn_id", "amn_title", "amn_isActive", "amn_isDelete"]
                    }
                },
                {
                    model: model.tbl_prop_to_tag,
                    as: "propertyTags",
                    include: {
                        model: model.tbl_tags,
                        as: "tag",
                        attributes: ["tag_id", "tag_name", "tag_isActive", "tag_isDelete"]
                    }
                }
            ]
        });

        properties = properties.map(row => row.toJSON());
        if (properties.length == 0) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found");
        }
        const propIds = properties.map(p => p.property_id);
        let attachmentsRows = await methods.getAttchedProperties(properties, propIds);

        let filteredRows = attachmentsRows.map(row => {
            const categoryTitles = row.propertyCategories ? row.propertyCategories.filter(pc => pc.category && pc.category.cat_isActive == commonConfig.isYes && pc.category.cat_isDelete == commonConfig.isNo).map(pc => pc.category.cat_title).filter(Boolean) : null;
            const amenities = row.propertyAmenities ? row.propertyAmenities.filter(pa => pa.amenity && pa.amenity.amn_isActive == commonConfig.isYes && pa.amenity.amn_isDelete == commonConfig.isNo).map(pa => pa.amenity.amn_title).filter(Boolean) : null;
            const tags = row.propertyTags ? row.propertyTags.filter(pt => pt.tag && pt.tag.tag_isActive == commonConfig.isYes && pt.tag.tag_isDelete == commonConfig.isNo).map(pt => pt.tag.tag_name).filter(Boolean) : null;

            const flattenedRow = {
                ...row,
                category_titles: categoryTitles && categoryTitles.length > 0 ? categoryTitles : null,
                amenities: amenities && amenities.length > 0 ? amenities : null,
                tags: tags && tags.length > 0 ? tags : null
            };

            if (row.propDetails) {
                Object.keys(row.propDetails).forEach(key => {
                    let value = row.propDetails[key];
                    if (key === 'propDetail_isPetFriendly' || key === 'propDetail_isSmoke') {
                        value = !!value;
                    }
                    flattenedRow[`propDetails.${key}`] = value;
                });
            }

            delete flattenedRow.propertyCategories;
            delete flattenedRow.propertyAmenities;
            delete flattenedRow.propertyTags;
            delete flattenedRow.propDetails;

            return flattenedRow;
        });

        return common.response(req, res, commonConfig.successStatus, true, "success", filteredRows);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const propertyReviews = async (req, res) => {
    try {
        const userId = req.user.userId;
        const propId = req.body.propertyId;

        // Fetch property reviews and user reviews concurrently
        const [findPropertyById, findUserReviews] = await Promise.all([
            model.tbl_reviews.findAll({
                raw: true,
                where: { br_propId: propId, br_isDelete: commonConfig.isNo },
                attributes: ["br_id", "br_propId", "br_hostId", "br_userId", "br_rating", "br_desc", "br_addedAt"],
                include: [
                    {
                        model: model.tbl_user,
                        as: "userReview",
                        attributes: ["user_fullName"]
                    },
                    {
                        model: model.tbl_review_likes,
                        as: "ReviewLikesDislikes",
                        attributes: ["rl_dislike", "rl_list"]
                    }
                ]
            }),
            model.tbl_reviews.findAll({
                raw: true,
                where: { br_userId: userId, br_isDelete: commonConfig.isNo },
                include: {
                    model: model.tbl_user,
                    as: "userReview",
                    attributes: ["user_fullName"]
                }
            })
        ]);

        if (findPropertyById.length === 0) {
            return common.response(req, res, commonConfig.successStatus, true, "No record found", {
                reviews: null,
                myReview: null
            });
        }

        // Process reviews and calculate likes/dislikes efficiently
        const finalReviews = findPropertyById.map((review) => {
            return {
                ...review,
                dislike: review["ReviewLikesDislikes.rl_dislike"] ? JSON.parse(review["ReviewLikesDislikes.rl_dislike"]).length : 0,
                like: review["ReviewLikesDislikes.rl_list"] ? JSON.parse(review["ReviewLikesDislikes.rl_list"]).length : 0
            };
        });

        // Calculate average rating
        const allRating = findPropertyById.map(review => ({ br_rating: review.br_rating }));
        const { allRatings, averageRating } = calculateRatings(allRating);

        // Prepare response
        return common.response(req, res, commonConfig.successStatus, true, "Success", {
            reviews: finalReviews,
            averageRating,
            allRatings,
            myReview: findUserReviews.length ? findUserReviews : null
        });

    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
//-----------------HOST-CONTROLLER------------------------------ 
const addProperty = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let images = [];
        const hostId = req.user.userId;
        let propertyId = reqData.propertyId;
        let createProperty = {};
        const payload = {
            property_name: reqData.property_name,
            property_host_id: hostId,
            property_address: reqData.property_address,
            property_longitude: reqData.property_longitude,
            property_latitude: reqData.property_latitude,
            property_city: reqData.property_city,
            property_state: reqData.property_state,
            property_contry: reqData.property_contry,
            property_desc: reqData.property_desc,
            property_price: reqData.property_price,
            property_mini_price: reqData.property_mini_price,
            property_contact: reqData.property_contact,
            property_email: reqData.property_email,
            is_luxury: (reqData.is_luxury === true || reqData.is_luxury === "true" || reqData.is_luxury === 1 || reqData.is_luxury === "1") ? 1 : 0,

        };
        if (propertyId) {
            await model.tbl_properties.updateProperty(payload, propertyId);
        } else {
            createProperty = await model.tbl_properties.create(payload);
            propData = createProperty.dataValues
            propertyId = createProperty.dataValues.property_id;
        }
        if (!propertyId) {
            throw new Error("Some problem occur in data creation");
        }
        if (reqData.property_isPetAllow || reqData.property_isSmoke) {
            reqData.property_isPetAllow = reqData.property_isPetAllow == "true" ? 1 : 0;
            reqData.property_isSmoke = reqData.property_isSmoke == "true" ? 1 : 0;
        }
        if (!propertyId) {
            throw new Error("Property ID is undefined or null after creation.");
        }
        let PropertyDetailPayload = {
            propDetail_propId: propertyId,
            propDetail_isPetFriendly: reqData.property_isPetAllow,
            propDetail_isSmoke: reqData.property_isSmoke,
            propDetail_inTime: reqData.property_inTime,
            propDetail_outTime: reqData.property_outTime,
            propDetail_no_of_beds: reqData.bedsNumber ?? null,
            propDetail_no_of_guests: reqData.no_of_guests ?? null,
            propDetail_weeklyMini_price: reqData.weeklyMinPrice,
            propDetail_weeklyMax_price: reqData.weeklyMaxPrice,
            propDetail_monthly_security: reqData.monthlySecurity,
            propDetail_extra: reqData.PropRule,
        };
        if (propertyId) {
            await model.tbl_property_detail.destroy({ where: { propDetail_propId: propertyId } });
            await model.tbl_property_detail.create(PropertyDetailPayload);
        }
        if (Array.isArray(reqData.property_category) && reqData.property_category.length > 0) {
            await model.tbl_prop_to_cat.createPropCategories(reqData.property_category, propertyId);
        }
        if (Array.isArray(reqData.property_tag) && reqData.property_tag.length > 0) {
            await model.tbl_prop_to_tag.createPropertyTag(reqData.property_tag, propertyId);
        }
        if (Array.isArray(reqData.property_amenities) && reqData.property_amenities.length > 0) {
            await model.tbl_prop_to_amenities.createPropAmenities(reqData.property_amenities, propertyId);
        }
        if (req.files) {
            const cloudinaryInstance = new CloudinaryManager();
            if (req.files["property_img"]) {
                images = await cloudinaryInstance.multipleImages(req.files["property_img"], moduleConfig.property_image_type, propertyId);
            }
            if (req.files["property_doc"]) {
                await cloudinaryInstance.multipleImages(req.files["property_doc"], moduleConfig.property_doc_type, propertyId);

            }
        }
        let response = { ...propData, images };
        return common.response(req, res, commonConfig.successStatus, true, "success", response);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const addPropertyDocument = async (req, res) => {
    try {

    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
}
const deleteProperty = async (req, res) => {
    try {
        const reqData = { ...req.body };
        await model.tbl_properties.updateProperty({ is_deleted: commonConfig.isYes }, { property_id: reqData.propId });
        return common.response(req, res, commonConfig.successStatus, true, "success");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const deactivateProperty = async (req, res) => {
    try {
        const reqData = { ...req.body };
        await model.tbl_properties.updateProperty({ is_active: commonConfig.isNo }, { property_id: reqData.propId });
        return common.response(req, res, commonConfig.successStatus, true, "success");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
}
const setPropCoverImg = async (req, res) => {
    try {
        const { property_id } = req.body;
        if (!req.file) {
            return common.response(req, res, commonConfig.errorStatus, false, "image is required");
        }
        const file = req.file;
        const cloudinaryInstance = new CloudinaryManager();
        await cloudinaryInstance.uploadImage(req.file.path, moduleConfig.property_cover_image_type, property_id);
        return common.response(req, res, commonConfig.successStatus, true, "success");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const countries = async (req, res) => {
    try {
        return common.response(req, res, commonConfig.successStatus, true, "success", moduleConfig.countries);
        // const data;
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const states = async (req, res) => {
    try {
        return common.response(req, res, commonConfig.successStatus, true, "success", moduleConfig.state);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const getAmenties = async (req, res) => {
    try {
        const data = await model.tbl_amenities.allData({ amn_isActive: commonConfig.isYes, amn_isDelete: commonConfig.isYes });
        if (data.length === commonConfig.isNo) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "success", data);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
//--------------ADMIN-DASHBOARD-------------------
const adminPropSearch = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const limit = reqData.limit ?? commonConfig.listLimit;
        const page = reqData.page ?? commonConfig.listPage;
        const offset = (page - 1) * limit;
        const attributes = [
            "property_id",
            "property_name",
            "is_active",
        ]
        let whereClause = {
            is_deleted: commonConfig.isNo
        };

        const { rows, count } = await model.tbl_properties.findAndCountAll({
            raw: true,
            where: whereClause,
            limit: limit,
            attributes: attributes,
            offset: offset,
            orders: [["property_id", "DESC"]]
        });
        if (rows.length == commonConfig.isNo) {
            return common.response(req, res, commonConfig.errorStatus, false, "No Record Found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "success", {
            limit: limit,
            TotalRecords: count,
            page: page,
            count: rows.length,
            records: rows
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const loadPropertiesUsingFile = async (req, res) => {
    try {
        const workbook = xlsx.readFile(req.file.path);
        const sheetName = workbook.SheetNames[0];
        const sheetData = xlsx.utils.sheet_to_json(workbook.Sheets[sheetName]);
        const filerproperties = sheetData.filter(row => row.property_latitude && row.property_longitude);
        for (const property of filerproperties) {
            let proppayload = {
                property_host_id: 1,
                property_name: property.property_name,
                property_address: property.property_name,
                property_longitude: parseFloat(property.property_longitude),
                property_latitude: parseFloat(property.property_latitude),
                property_desc: "My home has a warm and inviting atmosphere, with a lot of natural light filtering through large windows.",
                property_price: property.property_price || 1000,
                property_mini_price: property.property_mini_price || 110,
                property_city: property.property_city || "Lahore",
                property_zip: property.property_zip || "001023",
                property_state: property.property_state || 'HP',
                property_contry: property.property_country || null,
                property_contact: property.property_contact ? property.property_contact.toString() : null,
                property_email: property.property_email || null,
            };
            let createProperty = await model.tbl_properties.create(proppayload);
            let propertyId = createProperty.dataValues.property_id;
            const detailPayload = {
                propDetail_propId: propertyId,
                propDetail_isSmoke: property.propDetail_isSmoke ? 1 : 0,
                propDetail_isPetFriendly: property.propDetail_isPetFriendly ? 1 : 0,
                propDetail_inTime: property.propDetail_inTime || null,
                propDetail_outTime: property.propDetail_outTime || null,
            }
            await model.tbl_property_detail.create(detailPayload);
        }
        return common.response(req, res, commonConfig.successStatus, true, "success");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
}

module.exports = {
    addProperty,
    propertyReviews,
    getProperties,
    getProperty,
    countries,
    loadPropertiesUsingFile,
    states,
    setPropCoverImg,
    propertyListing,
    deleteProperty,
    deactivateProperty,
    savePropertyByUser,
    // userLikedProperty,
    getAmenties,
    adminPropSearch,
    // userDislikeProperty,
};


