const express = require("express");
const router = express.Router();
const controller = require("../controllers/blog.controller");
const schema = require("../schema/blog.schema");
const validation = require("../middleware/validation");
const { authenticateJWT } = require("../middleware/authorization");
const { upload } = require("../utils/fileHandler");
const { generalLimiter, uploadLimiter } = require("../middleware/rateLimiter");

router.post("/blog/create", uploadLimiter, upload.single("blog_image"), [validation(schema.createBlog)], controller.createBlog);
router.post("/blog/search", generalLimiter, controller.blogs);
router.post("/blog/test-img", uploadLimiter, upload.single("test_img"), controller.testImage);




module.exports = router;