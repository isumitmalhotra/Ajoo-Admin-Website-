const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminHost.controller");
const schema = require("../schema/adminUser.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { adminApiLimiter } = require("../middleware/adminRateLimiter");


router.post("/admin/host/search", [adminApiLimiter, adminAuthToken], controller.hostListing);
router.get("/admin/host/search/assign-property", [adminApiLimiter, adminAuthToken], controller.hostListForAssgnProperty);


module.exports = router;
