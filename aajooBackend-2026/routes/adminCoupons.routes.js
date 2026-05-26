const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminCoupons.controller");
const schema = require("../schema/adminCoupons.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");


router.post("/admin/coupon/add", [validation(schema.couponAddSchema), adminAuthToken], controller.addUpdateCoupons);
router.post("/admin/coupon/delete", [validation(schema.couponId), adminAuthToken], controller.deleteCoupons);
router.post("/admin/coupon/status/update", [validation(schema.updateStatus), adminAuthToken], controller.updateStatus);
router.post("/admin/coupon/search", [adminAuthToken], controller.couponListing);
router.post("/admin/coupon/detail", [validation(schema.couponId), adminAuthToken], controller.detailedCoupon);


module.exports = router;