const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op, fn, col } = require("sequelize");

const calculateBookingAnalytics = (bookings) => {
    let totalRevenue = 0;
    let upcomingRevenue = 0;
    const totalBookings = bookings.length;

    bookings.forEach((booking) => {
        const amount = Number(booking.book_total_amt) || 0;
        totalRevenue += amount;

        if (booking.book_status === 1) {
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

    bookings.forEach((booking) => {
        if (!booking.book_added_at) {
            return;
        }

        const date = new Date(booking.book_added_at);
        const month = date.toLocaleString("default", {
            month: "short",
            year: "numeric"
        });

        const revenue = Number(booking.book_total_amt) || 0;
        monthRevenue[month] = (monthRevenue[month] || 0) + revenue;
    });

    const chartData = Object.keys(monthRevenue).map((month) => ({
        month,
        revenue: monthRevenue[month]
    }));

    const yAxisMax = Math.max(...chartData.map((item) => item.revenue), 0);
    return { chartData, yAxisMax };
};

const propAnalytics = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
        const offset = (page - 1) * limit;
        const search = reqData.search?.trim() || "";

        const bookingSummary = await model.tbl_bookings.findAll({
            raw: true,
            where: {
                book_is_delete: commonConfig.isNo
            },
            attributes: [
                "book_prop_id",
                [fn("COUNT", col("book_id")), "total_bookings"]
            ],
            group: ["book_prop_id"]
        });

        const uniquePropertyIds = bookingSummary
            .map((item) => item.book_prop_id)
            .filter(Boolean);

        if (!uniquePropertyIds.length) {
            return common.response(req, res, commonConfig.successStatus, true, "Property analytics listing", {
                totalRecords: 0,
                currentPage: page,
                totalPages: 0,
                page,
                limit,
                offset,
                properties: []
            });
        }

        const bookingCountMap = new Map(
            bookingSummary.map((item) => [item.book_prop_id, Number(item.total_bookings) || 0])
        );

        const whereCondition = {
            property_id: {
                [Op.in]: uniquePropertyIds
            },
            is_deleted: commonConfig.isNo,
        };

        if (search) {
            whereCondition[Op.or] = [
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
            ];
        }

        if (reqData.status !== undefined) {
            whereCondition.is_active = reqData.status;
        }

        if (reqData.isLuxury !== undefined) {
            whereCondition.is_luxury = reqData.isLuxury;
        }

        const { rows, count } = await model.tbl_properties.findAndCountAll({
            raw: true,
            where: whereCondition,
            attributes: [
                "property_id",
                "property_name",
                "property_price",
                "is_active",
                "is_verify",
                "is_luxury",
            ],
            include: [
                {
                    model: model.tbl_user,
                    as: "HostDetails",
                    attributes: ["user_fullName"],
                    required: false
                }
            ],
            order: [["created_at", "DESC"]],
            offset,
            limit,
        });

        if (!rows.length) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "No review found");
        }

        const properties = rows.map((property) => ({
            ...property,
            total_bookings: bookingCountMap.get(property.property_id) || 0
        }));

        return common.response(req, res, commonConfig.successStatus, true, "Property analytics listing", {
            totalRecords: count,
            currentPage: page,
            totalPages: Math.ceil(count / limit),
            page,
            limit,
            offset,
            properties
        });
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

        const [propertyCategories, bookingData, graphBookings] = await Promise.all([
            model.tbl_prop_to_cat.findAll({
                raw: true,
                where: { pt_cat_prop_id: propId },
                attributes: [],
                include: [{
                    model: model.tbl_categories,
                    as: "category",
                    attributes: ["cat_title"]
                }]
            }),
            model.tbl_bookings.findAndCountAll({
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
            }),
            model.tbl_bookings.findAll({
                raw: true,
                where: {
                    book_prop_id: propId,
                    book_is_delete: commonConfig.isNo
                },
                attributes: [
                    "book_total_amt",
                    "book_added_at"
                ]
            })
        ]);

        const categoryTitles = propertyCategories.map((item) => item["category.cat_title"]);
        const analytics = calculateBookingAnalytics(bookingData.rows);
        const revenueGraph = buildRevenueGraphData(graphBookings);

        return common.response(req, res, commonConfig.successStatus, true, "Booking analytics", {
            propertyDetail,
            categoryTitles,
            bookings: bookingData.rows,
            totalRecords: bookingData.count,
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
};
