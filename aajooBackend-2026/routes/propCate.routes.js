const express = require("express");
const router = express.Router();
const controller = require("../controllers/propCategory.controller");
const schema = require("../schema/blog.schema");
const validation = require("../middleware/validation");
const { authenticateJWT } = require("../middleware/authorization");
const { upload } = require("../utils/fileHandler")
const { generalLimiter } = require("../middleware/rateLimiter");
router.post("/property/cate-filert", generalLimiter, [authenticateJWT], controller.propCategoriesforUser);      




module.exports = router;