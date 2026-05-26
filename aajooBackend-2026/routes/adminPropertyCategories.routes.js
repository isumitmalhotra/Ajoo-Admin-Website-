const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminPropertyCategories.controller");
const schema = require("../schema/adminPropertyCategories.Schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { upload } = require("../utils/fileHandler");
const { generalLimiter, uploadLimiter } = require("../middleware/rateLimiter");

router.post("/admin/category/create", [validation(schema.propertyCategorySchema), adminAuthToken], controller.createOrUpdatePropertyCategory);
router.post("/admin/categories", [adminAuthToken], controller.getPropertyCategories);
router.post("/admin/categories/delete", [adminAuthToken], controller.deleteCategory);
router.post("/admin/category", [validation(schema.categoryId), adminAuthToken], controller.getCategory);
router.get("/admin/category/list/dropdowns", [adminAuthToken], controller.categoriesForDropdown);
router.post("/admin/category/update-status", [validation(schema.updateCategoryStatusSchema), adminAuthToken], controller.updateStatus);





module.exports = router;