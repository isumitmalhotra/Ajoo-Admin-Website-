const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminCoupons.controller");
const schema = require("../schema/adminCoupons.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { adminApiLimiter } = require("../middleware/rateLimiter");

router.post("/admin/coupon/add", adminApiLimiter, [validation(schema.couponAddSchema), adminAuthToken], controller.addUpdateCoupons);
router.post("/admin/coupon/delete", adminApiLimiter, [validation(schema.couponId), adminAuthToken], controller.deleteCoupons);
router.post("/admin/coupon/status/update", adminApiLimiter, [validation(schema.updateStatus), adminAuthToken], controller.updateStatus);
router.post("/admin/coupon/search", adminApiLimiter, [validation(schema.couponListingSchema), adminAuthToken], controller.couponListing);
router.post("/admin/coupon/detail", adminApiLimiter, [validation(schema.couponId), adminAuthToken], controller.detailedCoupon);


module.exports = router;
