const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminPropertyCategories.controller");
const schema = require("../schema/adminPropertyCategories.Schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { adminApiLimiter } = require("../middleware/rateLimiter");

router.post("/admin/category/create", adminApiLimiter, [validation(schema.propertyCategorySchema), adminAuthToken], controller.createOrUpdatePropertyCategory);
router.post("/admin/categories", adminApiLimiter, [validation(schema.categoryListingSchema), adminAuthToken], controller.getPropertyCategories);
router.post("/admin/categories/delete", adminApiLimiter, [adminAuthToken], controller.deleteCategory);
router.post("/admin/category", adminApiLimiter, [validation(schema.categoryId), adminAuthToken], controller.getCategory);
router.get("/admin/category/list/dropdowns", adminApiLimiter, [adminAuthToken], controller.categoriesForDropdown);
router.post("/admin/category/update-status", adminApiLimiter, [validation(schema.updateCategoryStatusSchema), adminAuthToken], controller.updateStatus);

module.exports = router;
