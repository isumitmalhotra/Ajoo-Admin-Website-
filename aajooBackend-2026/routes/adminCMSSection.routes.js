const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminCMSSection.controller");
const schema = require("../schema/adminCMSSection.schema");
const validation = require("../middleware/validation");
const { upload } = require("../utils/fileHandler");
const { adminAuthToken } = require("../middleware/authorization");


router.post("/admin/cms/sectio/add", [validation(schema.cmsSchema), adminAuthToken], controller.addUpdateCMSSection);
router.post("/admin/cms/section/search", [adminAuthToken], controller.listingCMSSection);


router.post("/admin/cms/homepage/update", upload.single('image'), [validation(schema.homeCMSchema), adminAuthToken], controller.addUpdateHomePageCMSSection);
router.get("/admin/cms/homepage/get", [adminAuthToken], controller.getHomePageCMS);
router.get("/admin/cms/homepage/property/dropdown", [adminAuthToken], controller.propertydropdown);
router.get("/admin/cms/homepage/testimonial/dropdown", [adminAuthToken], controller.testimonialDronpdown);
router.post("/admin/cms/homepage/delete/image", [validation(schema.cmsIdsSchema), adminAuthToken], controller.deleteSingleImage);

router.post("/admin/cms/FaqPage/update", upload.single('adminFaqPageimage'), [validation(schema.faqCMSValidation), adminAuthToken], controller.addUpdateFAQPageCMS);
router.get("/admin/cms/FaqPage/get", [adminAuthToken], controller.getFAQPageCMS);

router.post("/admin/cms/TCPage/update", upload.single('adminTCPageimage'), [validation(schema.faqCMSValidation), adminAuthToken], controller.addUpdateTCPageCMS);
router.get("/admin/cms/TCPage/get", [adminAuthToken], controller.getTCPageCMS);

module.exports = router;