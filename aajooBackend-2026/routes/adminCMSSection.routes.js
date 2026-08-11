const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminCMSSection.controller");
const schema = require("../schema/adminCMSSection.schema");
const validation = require("../middleware/validation");
const { upload } = require("../utils/fileHandler");
const { adminAuthToken } = require("../middleware/authorization");
const { adminApiLimiter } = require("../middleware/rateLimiter");

router.post("/admin/cms/section/add", adminApiLimiter, [validation(schema.cmsSchema), adminAuthToken], controller.addUpdateCMSSection);
router.post("/admin/cms/section/search", adminApiLimiter, [validation(schema.cmsListingSchema), adminAuthToken], controller.listingCMSSection);

router.post("/admin/cms/homepage/update", adminApiLimiter, upload.single('image'), [validation(schema.homeCMSchema), adminAuthToken], controller.addUpdateHomePageCMSSection);
router.get("/admin/cms/homepage/get", adminApiLimiter, [adminAuthToken], controller.getHomePageCMS);
router.get("/admin/cms/homepage/property/dropdown", adminApiLimiter, [adminAuthToken], controller.propertydropdown);
router.get("/admin/cms/homepage/testimonial/dropdown", adminApiLimiter, [adminAuthToken], controller.testimonialDronpdown);
router.post("/admin/cms/homepage/delete/image", adminApiLimiter, [validation(schema.cmsIdsSchema), adminAuthToken], controller.deleteSingleImage);

router.post("/admin/cms/faq-page/update", adminApiLimiter, upload.single('adminFaqPageimage'), [validation(schema.faqCMSValidation), adminAuthToken], controller.addUpdateFAQPageCMS);
router.post("/admin/cms/FaqPage/update", adminApiLimiter, upload.single('adminFaqPageimage'), [validation(schema.faqCMSValidation), adminAuthToken], controller.addUpdateFAQPageCMS);
router.get("/admin/cms/faq-page/get", adminApiLimiter, [adminAuthToken], controller.getFAQPageCMS);
router.get("/admin/cms/FaqPage/get", adminApiLimiter, [adminAuthToken], controller.getFAQPageCMS);

router.post("/admin/cms/tc-page/update", adminApiLimiter, upload.single('adminTCPageimage'), [validation(schema.tcCMSValidation), adminAuthToken], controller.addUpdateTCPageCMS);
router.post("/admin/cms/TCPage/update", adminApiLimiter, upload.single('adminTCPageimage'), [validation(schema.tcCMSValidation), adminAuthToken], controller.addUpdateTCPageCMS);
router.get("/admin/cms/tc-page/get", adminApiLimiter, [adminAuthToken], controller.getTCPageCMS);
router.get("/admin/cms/TCPage/get", adminApiLimiter, [adminAuthToken], controller.getTCPageCMS);

module.exports = router;
