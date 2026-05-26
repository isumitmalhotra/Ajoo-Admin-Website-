const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { CloudinaryManager } = require("../utils/cloudinary");
const { Op, fn, col, literal } = require("sequelize");
const {
  tbl_bookings,
  tbl_properties,
  tbl_prop_to_cat,
  tbl_categories
} = require("../models");

exports.getBookingAnalytics = async (req, res) => {
  try {
    const { state, city, fromDate, toDate } = req.query;

    console.log("QUERY PARAMS 👉", {
      state,
      city,
      fromDate,
      toDate,
    });
    const bookingWhere = {
      book_is_delete: 0,
    };
    if (fromDate && toDate) {
      bookingWhere.book_added_at = {
        [Op.between]: [new Date(fromDate), new Date(toDate)],
      };
    }
    const propertyWhere = {};
    propertyWhere.property_state = {
      [Op.like]: state,
    };
    if (city) propertyWhere.property_city = city.trim();
    const data = await tbl_bookings.findAll({
      attributes: [
        [fn("MONTHNAME", col("tbl_bookings.book_added_at")), "month"],
        [col("bookingProperty->propertyCategories->category.cat_title"), "category"],
        [fn("COUNT", col("tbl_bookings.book_pri_id")), "count"],
      ],
      include: [
        {
          model: tbl_properties,
          as: "bookingProperty",
          attributes: [],
          where: propertyWhere,
          required: true,
          include: [
            {
              model: tbl_prop_to_cat,
              as: "propertyCategories",
              attributes: [],
              required: true,
              include: [
                {
                  model: tbl_categories,
                  as: "category",
                  attributes: [],
                  where: {
                    cat_isDelete: "0",
                    cat_isActive: "1",
                  },
                  required: true,
                },
              ],
            },
          ],
        },
      ],
      where: bookingWhere,
      group: [
        "month",
        "bookingProperty->propertyCategories->category.cat_title",
      ],
      raw: true,
    });
    const monthOrder = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];

    const monthMap = {};
    const categorySet = new Set();

    data.forEach((row) => {
      const monthShort = row.month.substring(0, 3);
      const category = row.category || "Other";

      if (!monthMap[monthShort]) {
        monthMap[monthShort] = {};
      }
      monthMap[monthShort][category] = Number(row.count);
      categorySet.add(category);
    });
    const categories = Object.keys(monthMap).sort((a, b) => {
      const getIndex = (m) =>
        monthOrder.findIndex((full) =>
          full.startsWith(m)
        );
      return getIndex(a) - getIndex(b);
    });
    const series = Array.from(categorySet).map((cat) => ({
      name: cat,
      data: categories.map(
        (month) => monthMap[month][cat] || 0
      ),
    }));
    const allValues = series.flatMap((s) => s.data);
    const maxVal = Math.max(...allValues, 0);
    const tick = getNiceTick(maxVal);
    const yMax = Math.ceil(maxVal / tick) * tick;
    return res.json({
      categories,
      series,
      yAxis: {
        min: 0,
        max: yMax,
        tick,
      },
    });

  } catch (err) {
    console.error(err);
    return res.status(500).json({
      message: "Internal server error",
    });
  }
};
function getNiceTick(max) {
  if (max <= 10) return 2;
  if (max <= 50) return 10;
  if (max <= 100) return 20;
  if (max <= 500) return 50;
  if (max <= 1000) return 100;
  return Math.ceil(max / 10);
}
