const { Op, fn, col } = require("sequelize");
const {
  tbl_bookings,
  tbl_properties,
  tbl_prop_to_cat,
  tbl_categories
} = require("../models");

exports.getBookingAnalytics = async (req, res) => {
  try {
    const state = req.query.state?.trim() || "";
    const city = req.query.city?.trim() || "";
    const { fromDate, toDate } = req.query;

    const bookingWhere = {
      book_is_delete: 0,
    };

    if (fromDate && toDate) {
      bookingWhere.book_added_at = {
        [Op.between]: [new Date(fromDate), new Date(toDate)],
      };
    }

    const propertyWhere = {};

    if (state) {
      propertyWhere.property_state = {
        [Op.like]: `%${state}%`,
      };
    }

    if (city) {
      propertyWhere.property_city = {
        [Op.like]: `%${city}%`,
      };
    }

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
      const getIndex = (month) => monthOrder.findIndex((fullMonth) => fullMonth.startsWith(month));
      return getIndex(a) - getIndex(b);
    });

    const series = Array.from(categorySet).map((category) => ({
      name: category,
      data: categories.map((month) => monthMap[month][category] || 0),
    }));

    const allValues = series.flatMap((item) => item.data);
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
