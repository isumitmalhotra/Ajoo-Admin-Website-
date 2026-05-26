const slugify = require("slugify");
const model = require("../models");

/**
 * Generate unique slug for property categories
 * @param {string} title
 * @param {number|null} ignoreId (for update case)
 */
const generateUniqueCategorySlug = async (title, ignoreId = null) => {
  let baseSlug = slugify(title, {
    lower: true,
    strict: true,
    trim: true,
  });

  let slug = baseSlug;
  let counter = 1;

  while (true) {
    const whereClause = { cat_slug: slug };

    if (ignoreId) {
      whereClause.cat_id = { $ne: ignoreId };
    }

    const existing = await model.tbl_categories.findOne({
      where: whereClause,
      attributes: ["cat_id"],
    });

    if (!existing) break;

    slug = `${baseSlug}-${counter}`;
    counter++;
  }

  return slug;
};

module.exports = { generateUniqueCategorySlug };
