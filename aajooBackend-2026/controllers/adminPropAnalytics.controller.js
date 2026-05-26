const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require("sequelize");
const { Sequelize } = require("sequelize");

const calculateBookingAnalytics = (bookings) => {
    let totalRevenue = 0;
    let upcomingRevenue = 0;
    let totalBookings = bookings.length;
    bookings.forEach(b => {
        const amount = Number(b.book_total_amt) || 0;
        totalRevenue += amount;
        if (b.book_status === 1) {
            upcomingRevenue += amount;
        }
    });
    const avgBookingPrice = totalBookings > 0 ? totalRevenue / totalBookings : 0;
    return {
        totalRevenue,
        upcomingRevenue,
        avgBookingPrice,
        totalBookings
    };
};
const buildRevenueGraphData = (bookings) => {
    const monthRevenue = {};
    bookings.forEach(b => {
        if (!b.book_added_at) return;
        const date = new Date(b.book_added_at);
        const month = date.toLocaleString("default", {
            month: "short",
            year: "numeric"
        });
        const revenue = Number(b.book_total_amt) || 0;
        if (!monthRevenue[month]) {
            monthRevenue[month] = 0;
        }
        monthRevenue[month] += revenue;
    });
    const chartData = Object.keys(monthRevenue).map(month => ({
        month,
        revenue: monthRevenue[month]
    }));
    const yAxisMax = Math.max(...chartData.map(i => i.revenue), 0);
    return { chartData, yAxisMax };
};
const propAnalytics = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
        const offset = (page - 1) * limit;
        const search = reqData.search?.trim() || "";
        let findBookedProperties = await model.tbl_bookings.findAll({
            raw: true,
            attributes: ["book_prop_id"],
            group: ["book_prop_id"]
        });
        const uniquePropertyIds = findBookedProperties.map(p => p.book_prop_id);
        let whereCodn = {
            property_id: {
                [Op.in]: uniquePropertyIds
            },
            is_deleted: commonConfig.isNo,
        };
        if (search) {
            whereCodn = {
                ...whereCodn,
                [Op.or]: [
                    {
                        property_name: {
                            [Op.like]: `%${search}%`
                        }
                    },
                    {
                        "$HostDetails.user_fullName$": {
                            [Op.like]: `%${search}%`
                        }
                    }
                ]
            };  
        }
        if (reqData.status !== undefined) {
            whereCodn.is_active = reqData.status;
        }
        if (reqData.isLuxury) {
            whereCodn.is_luxury = reqData.isLuxury;
        }
        const propertyAnalytics = await model.tbl_properties.findAll({
            raw: true,
            where: whereCodn,
            attributes: [
                "property_id",
                "property_name",
                "property_price",
                "is_active",
                "is_verify",
                "is_luxury",
                [
                    Sequelize.literal(`(
                        SELECT COUNT(*)
                        FROM tbl_bookings
                        WHERE tbl_bookings.book_prop_id = tbl_properties.property_id
                       )`),
                    "total_bookings"
                ]
            ],
            include: [
                {
                    model: model.tbl_user,
                    as: "HostDetails",
                    attributes: ["user_fullName"]
                }
            ],
            order: [["created_at", "DESC"]],
            offset: offset,
            limit: limit,
        });
        if (propertyAnalytics.length == 0) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "No review found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "Property analytics listing", propertyAnalytics);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const propAnalyticDetail = async (req, res) => {
    try {
        const propId = req.body.propertyId;
        const propertyDetail = await model.tbl_properties.findOne({
            raw: true,
            where: {
                property_id: propId,
                is_deleted: commonConfig.isNo,
            },
            attributes: [
                "property_id",
                "property_name",
                "property_price",
            ],
            include: [
                {
                    model: model.tbl_user,
                    as: "HostDetails",
                    attributes: ["user_fullName"]
                }
            ],
        });
        if (!propertyDetail) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "Property not found");
        }
        const propertyCategories = await model.tbl_prop_to_cat.findAll({
            raw: true,
            where: { pt_cat_prop_id: propId },
            attributes: [],
            include: [{
                model: model.tbl_categories,
                as: 'category',
                attributes: ['cat_title']
            }]
        });

        const categoryTitles = propertyCategories.map(item => item["category.cat_title"]);
        const { rows, count } = await model.tbl_bookings.findAndCountAll({
            raw: true,
            where: { book_prop_id: propId },
            attributes: ["book_id", "book_user_id", "book_total_amt", "book_status"],
            include: [
                {
                    model: model.tbl_user,
                    as: "userDetails",
                    attributes: ["user_fullName"],
                    required: false
                },
                {
                    model: model.tbl_reviews,
                    as: "bookingReview",
                    attributes: ["br_rating"],
                    required: false
                },
                {
                    model: model.tbl_book_status,
                    as: "bookingStatus",
                    attributes: ["bs_title", "bs_code"],
                    required: false
                }
            ]
        });
        const analytics = calculateBookingAnalytics(rows);
        const graphBookings = await model.tbl_bookings.findAll({
            raw: true,
            where: {
                book_prop_id: propId,
                book_is_delete: 0
            },
            attributes: [
                "book_total_amt",
                "book_added_at"
            ]
        });
        const revenueGraph = buildRevenueGraphData(graphBookings);
        return common.response(req, res, commonConfig.successStatus, true, "Booking analytics", {
            propertyDetail,
            categoryTitles,
            bookings: rows,
            totalRecords: count,
            analytics,
            revenueGraph,
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

module.exports = {
    propAnalytics,
    propAnalyticDetail
}