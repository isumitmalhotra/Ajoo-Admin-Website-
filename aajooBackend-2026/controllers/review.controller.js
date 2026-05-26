const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const moduleConfigs = require("../config/moduleConfigs");
const { sequelize } = require('../models');
const { CloudinaryManager } = require("../utils/cloudinary");

const cloudinaryInstance = new CloudinaryManager();

const userLikedProperty = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let userId = req.user.userId;
        const whereClause = {
            rl_review_id: reqData.reviewId,
        };
        let dislikes;
        const isExist = await model.tbl_review_likes.findOne({
            raw: true,
            where: whereClause
        });
        if (isExist && isExist.rl_dislike && isExist.rl_dislike !== null) {
            dislikes = JSON.parse(isExist.rl_dislike)
            const isDislike = dislikes.includes(userId);
            if (isDislike) {
                dislikes.splice(dislikes.indexOf(userId), 1);
            }
            let payload = { rl_dislike: dislikes.length == 0 ? null : dislikes }
            await model.tbl_review_likes.update(payload, { where: { rl_review_id: reqData.reviewId, } });
        }
        if (isExist || isExist !== null) {
            if (isExist.rl_list == null) {
                const payload = {
                    rl_list: [userId],
                };
                await model.tbl_review_likes.update(payload, { where: { rl_review_id: reqData.reviewId } });
                return common.response(req, res, commonConfig.successStatus, true, "like added");
            }
            let rlListArray = JSON.parse(isExist.rl_list);
            const isLike = rlListArray.includes(userId);
            if (isLike) {
                rlListArray.splice(rlListArray.indexOf(userId), 1);
                if (rlListArray.length == 0) {
                    await model.tbl_review_likes.destroy({ where: { rl_review_id: reqData.reviewId } });
                    return common.response(req, res, commonConfig.successStatus, true, "like removed");
                } else {
                    await model.tbl_review_likes.update({ rl_list: rlListArray }, { where: { rl_review_id: reqData.reviewId } });
                    return common.response(req, res, commonConfig.successStatus, true, "like added");
                }
            } else {
                rlListArray.push(userId);
                await model.tbl_review_likes.update({ rl_list: rlListArray }, { where: { rl_review_id: reqData.reviewId } });
                return common.response(req, res, commonConfig.successStatus, true, "like added");
            }
        }
        else {
            const payload = {
                rl_review_id: reqData.reviewId,
                rl_user_id: userId,
                rl_list: [userId],
            };
            await model.tbl_review_likes.create(payload);
            return common.response(req, res, commonConfig.successStatus, true, "like added");
        }
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const userDislikeProperty = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let userId = req.user.userId;
        const whereClause = { rl_review_id: reqData.reviewId };
        let likes;
        const isExist = await model.tbl_review_likes.findOne({
            raw: true,
            where: whereClause
        });
        if (isExist && isExist.rl_list !== null) {
            likes = JSON.parse(isExist.rl_list);
            const islike = likes.includes(userId);
            if (islike) {
                likes.splice(likes.indexOf(userId), 1);
            }
            let payload = { rl_dislike: likes.length == 0 ? null : likes };
            await model.tbl_review_likes.update(payload, { where: { rl_review_id: reqData.reviewId, } });
        }
        if (isExist || isExist !== null) {
            if (isExist.rl_dislike == null) {
                const payload = { rl_dislike: [userId] };
                await model.tbl_review_likes.update(payload, { where: { rl_review_id: reqData.reviewId } });
                return common.response(req, res, commonConfig.successStatus, true, "Dislike");
            }
            let rlListArray = JSON.parse(isExist.rl_dislike);
            const isDislike = rlListArray.includes(userId);
            if (isDislike) {
                rlListArray.splice(rlListArray.indexOf(userId), 1);
                if (rlListArray.length == 0) {
                    await model.tbl_review_likes.destroy({ where: { rl_review_id: reqData.reviewId } });
                    return common.response(req, res, commonConfig.successStatus, true, "Dislike removed");
                } else {
                    await model.tbl_review_likes.update({ rl_list: rlListArray }, { where: { rl_review_id: reqData.reviewId } });
                    return common.response(req, res, commonConfig.successStatus, true, "Dislike added");
                }
            } else {
                rlListArray.push(userId);
                await model.tbl_review_likes.update({ rl_list: rlListArray }, { where: { rl_review_id: reqData.reviewId } });
                return common.response(req, res, commonConfig.successStatus, true, "Dislike added");
            }
        }
        else {
            const payload = {
                rl_review_id: reqData.reviewId,
                rl_dislike: [userId],
            };
            await model.tbl_review_likes.create(payload);
            return common.response(req, res, commonConfig.successStatus, true, "Dislike added");
        }
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const UserDeleteRview = async (req, res) => {
    try {
        const reqData = { ...req.body };
        await model.tbl_reviews.update({ br_isDelete: commonConfig.isYes }, { where: { br_userId: req.user.userId, br_id: reqData.reviewId } });
        return common.response(req, res, commonConfig.successStatus, true, "success");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
//--------------------CHECKOUT-PAGE---------------------
const checkoutPage = async (req, res) => {
    let transaction = await sequelize.transaction();
    try {
        const reqData = { ...req.body };
        const userId = req.user.userId;
        let reviewImages = req.files;
        let findReview = await model.tbl_reviews.findOne({
            raw: true,
            where: {
                br_book_id: reqData.bookingId,
                br_userId: userId
            },
            attributes: ["br_id"]
        });
        if (findReview) {
            return common.response(req, res, commonConfig.errorStatus, false, "You have already given the review for this Booking");
        }
        let whereClause = {
            book_id: reqData.bookingId,
            book_user_id: userId,
        };
        let attributes = [
            "book_pri_id",
            "book_host_id",
            "book_prop_id",
        ];
        const findBooking = await model.tbl_bookings.getBookings(whereClause, attributes);
        if (!findBooking) {
            return common.response(req, res, commonConfig.errorStatus, false, "Booking not found");
        }
        let propReviewPayload = {
            br_book_id: reqData.bookingId,
            br_propId: reqData.propertyId,
            br_hostId: findBooking["book_host_id"],
            br_userId: userId,
            br_rating: reqData.propertyRating,
            br_desc: reqData.desription ?? null,
        };
        const propReviewData = await model.tbl_reviews.create(propReviewPayload, { transaction });

        let hostReviewPayload = {
            hr_book_id: reqData.bookingId,
            hr_host_id: findBooking["book_host_id"],
            hr_user_id: userId,
            hr_rating: reqData.hostRating,
            hr_description: reqData.desription ?? null,
        };
        await model.tbl_host_review.create(hostReviewPayload, { transaction });
        let platformReviewPayload = {
            pr_book_id: reqData.bookingId,
            pr_host_id: findBooking["book_host_id"],
            pr_user_id: userId,
            pr_rating: reqData.platformRating,
            pr_description: reqData.desription ?? null,
        }
        await model.tbl_platform_review.create(platformReviewPayload, { transaction });
        await model.tbl_bookings.update({ book_status: commonConfig.statusCheckout },
            {
                where: { book_pri_id: findBooking["book_pri_id"] }
            },
            {
                transaction: transaction
            }
        );
        await model.tbl_book_details.update({ bt_book_status: commonConfig.statusCheckout },
            {
                where: { bt_book_pri_id: findBooking["book_pri_id"] }
            },
            {
                transaction: transaction
            }
        );
        if (reviewImages && reviewImages.length > 0) {
            await cloudinaryInstance.multipleImages(reviewImages, moduleConfigs.checkout_review_img, propReviewData.dataValues.br_id, 'property_reviews');
        };
        await transaction.commit();
        return common.response(req, res, commonConfig.successStatus, true, "success");
    } catch (error) {
        await transaction.rollback();
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
//--------------------HOST GIVE REVIEW TO USER---------------------
const hostGiveReviewToUserAddData = async (req, res) => {
    try {
        const reqData = { ...req.body };
        if (req.files && req.files.length > 0) {
            if (req.files.length > 4) {
                return common.response(req, res, commonConfig.errorStatus, false, "You can upload only 4 images");
            }
        }
        const findBooking = await model.tbl_bookings.getBookings({ book_id: reqData.bookingId, book_status: commonConfig.statusCheckout },
            [
                "book_pri_id",
                "book_prop_id",
                "book_prop_type",
                "book_user_id",
                "book_host_id",
                "book_status",
            ]
        );
        if (!findBooking) {
            return common.response(req, res, commonConfig.errorStatus, false, "Booking not found");
        }
        let payload = {
            hru_hostId: findBooking.book_host_id,
            hru_userId: findBooking.book_user_id,
            hru_bookingPriId: findBooking.book_pri_id,
            hru_bookingId: reqData.bookingId,
            hru_propId: findBooking.book_prop_id,
            hru_title: reqData.title,
            hru_description: reqData.description,
            hru_rating: reqData.rating,
        };
        const addedData = await model.tbl_host_review_for_user.create(payload);
        if (!addedData) {
            return common.response(req, res, commonConfig.errorStatus, false, "Something went wrong");
        }
        let hruId = addedData.dataValues.hru_id;
        if (req.files && req.files.length > 0) {
            await cloudinaryInstance.multipleImages(req.files, moduleConfigs.host_giver_user_review_img, hruId, "review_folder");

        }
        return common.response(req, res, commonConfig.successStatus, true, "Review added successfully");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const hostGiveReviewToUserListing = async (req, res) => {
    try {
        const userId = req.user.userId;
        let whereClause = {
            hru_userId: userId,
            hru_isDelete: commonConfig.isNo,
            hru_isActive: commonConfig.isYes,
        }
        const data = await model.tbl_host_review_for_user.findAll({
            raw: true,
            where: whereClause,
            attributes: [
                "hru_id",
                "hru_bookingId",
                "hru_title",
                "hru_description",
                "hru_rating",
            ],
        })
        if (data.length == 0) {
            return common.response(req, res, commonConfig.errorStatus, false, "No record found");
        }
        let attachments = await model.tbl_attachments.findAll({
            raw: true,
            where: {
                afile_type: moduleConfigs.host_giver_user_review_img,
                afile_record_id: data.map((item) => item.hru_id),
            }
        });
        const imageMap = {};
        if (attachments) {
            // Create a map of hru_id to its images
            for (let attachment of attachments) {
                const recordId = attachment.afile_record_id;
                const publicId = attachment.afile_cldId;

                if (!imageMap[recordId]) imageMap[recordId] = [];
                imageMap[recordId].push(publicId);
            }
            for (let review of data) {
                const hruId = review.hru_id;
                const publicIds = imageMap[hruId] || [];

                const urls = await Promise.all(
                    publicIds.map((publicId) => cloudinaryInstance.getOptimizedUrl(publicId))
                );

                review.images = urls; // attach URLs to each review
            }
        }
        return common.response(req, res, commonConfig.successStatus, true, "success", { "review": data });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

module.exports = {
    userLikedProperty,
    userDislikeProperty,
    UserDeleteRview,
    checkoutPage,
    hostGiveReviewToUserAddData,
    hostGiveReviewToUserListing
};