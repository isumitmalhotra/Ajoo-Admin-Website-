const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op, where } = require("sequelize");
const { normalizeOptionalString, normalizeOptionalValue } = require("../utils/requestFilters");

const reviewListing = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
        const offset = (page - 1) * limit;
        const search = normalizeOptionalString(reqData.keyword);
        let whereCodn = {
            br_isDelete: commonConfig.isNo,
        };
        let propWhereCond = {}
        if (search) {
            propWhereCond = {
                property_name: {
                    [Op.like]: `%${search}%`
                }
            };
        }
        const reviewStatus = normalizeOptionalValue(reqData.status);
        if (reviewStatus !== null) {
            whereCodn = {
                ...whereCodn,
                br_isActive: reviewStatus
            }
        }
        const rating = normalizeOptionalValue(reqData.rating);
        if (rating !== null) {
            whereCodn = {
                ...whereCodn,
                br_rating: rating
            }

        }
        const { rows, count } = await model.tbl_reviews.findAndCountAll({
            where: whereCodn,
            include: [
                {
                    model: model.tbl_properties,
                    as: "propReview",
                    where: propWhereCond,
                    attributes: ["property_name"],
                    required: search ? true : false
                },
                {
                    model: model.tbl_user,
                    as: "userReview",
                    attributes: ["user_fullName"]
                }
            ],
            attributes: ["br_id", "br_book_id", "br_propId", "br_rating", "br_isActive", "br_addedAt"],
            order: [["br_addedAt", "DESC"]],
            offset: offset,
            limit: limit,
        });
        if (rows.length == 0) {
            return common.response(req, res, commonConfig.notFoundStatus, true, "No review found");
        }
        const totalPages = Math.ceil(count / limit);
        return common.response(req, res, commonConfig.successStatus, true, "Review list", {
            page,
            limit,
            offset,
            totalRecords: count,
            currentPage: page,
            totalPages,
            reviews: rows
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const updateReview = async (req, res) => {
    let transaction = await model.sequelize.transaction();
    try {
        const reqData = { ...req.body };
        const bookingId = reqData.bookingId;
        const reviewData = await model.tbl_reviews.findOne({
            raw: true,
            where: {
                br_isDelete: commonConfig.isNo,
                br_book_id: bookingId
            },
            attributes: ["br_id"]
        });
        if (!reviewData) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "Review not found");
        }
        await model.tbl_reviews.update(
            {
                br_isActive: reqData.status
            },
            {
                where: {
                    br_book_id: bookingId
                },
                transaction
            }
        );
        await model.tbl_host_review.update(
            {
                hr_isActive: reqData.status
            },
            {
                where: {
                    hr_book_id: bookingId
                },
                transaction
            }
        );
        await model.tbl_host_review_for_user.update(
            {
                hru_isActive: reqData.status
            },
            {
                where: {
                    hru_bookingId: bookingId
                },
                transaction
            }
        );
        await model.tbl_platform_review.update(
            {
                pr_isActive: reqData.status
            },
            {
                where: {
                    pr_book_id: bookingId
                },
                transaction
            }
        );
        await transaction.commit();
        return common.response(req, res, commonConfig.successStatus, true, "Review status updated successfully");
    } catch (error) {
        await transaction.rollback();
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const detailedReview = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const reviewId = reqData.reviewId;
        const propReview = await model.tbl_reviews.findOne({
            raw: true,
            where: {
                br_isDelete: commonConfig.isNo,
                br_id: reviewId
            },
            attributes: ["br_id", "br_book_id", "br_rating", "br_title", "br_desc","br_isActive"],
        });
        if (!propReview) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "Review not found");
        }
        const bookingId = propReview.br_book_id;
        // return
        const hostReview = await model.tbl_host_review.findOne({
            raw: true,
            where: {
                hr_book_id: String(bookingId),
            },
            attributes: ["hr_id", "hr_book_id", "hr_rating", "hr_title", "hr_description"]
        });
        const platformReview = await model.tbl_platform_review.findOne({
            raw: true,
            where: {
                pr_book_id: String(bookingId),
            },
            attributes: ["pr_id", "pr_book_id", "pr_rating", "pr_title", "pr_description"]
        });
        const hostReviewForUser = await model.tbl_host_review_for_user.findOne({
            raw: true,
            where: {
                hru_bookingId: String(bookingId),
            },
            attributes: ["hru_id", "hru_bookingId", "hru_rating", "hru_title", "hru_description", "hru_userId", "hru_hostId"],
            include: [
                {
                    model: model.tbl_user,
                    as: "reviewUsername",
                    attributes: ["user_fullName"]
                },
                {
                    model: model.tbl_user,
                    as: "reviewHostName",
                    attributes: ["user_fullName"]
                },
                {
                    model: model.tbl_properties,
                    as: "reviewProp",
                    attributes: ["property_name"]
                },
            ]
        });
        const responseData = {
            propertyReview: propReview,
            hostReview: hostReview,
            platformReview: platformReview,
            hostReviewForUser: hostReviewForUser
        };
        return common.response(req, res, commonConfig.successStatus, true, "Success", responseData);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
}
module.exports = {
    reviewListing,
    updateReview,
    detailedReview
}
