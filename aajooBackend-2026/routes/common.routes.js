const express = require("express");
const router = express.Router();
const controller = require("../controllers/property.controller");
const commonController = require("../controllers/common.controller");
const { generalLimiter } = require("../middleware/rateLimiter");

router.get("/common/states", [generalLimiter], controller.states);
router.get("/common/country", [generalLimiter], controller.countries);
router.get("/common/amenties", [generalLimiter], controller.getAmenties);


router.get("/common/documents/list", [generalLimiter], commonController.documentListing);
router.get("/common/safety", [generalLimiter], commonController.safetyPage);
router.get("/common/about-us", [generalLimiter], commonController.aboutus);
router.get("/common/faq", [generalLimiter], commonController.faqs);
router.get("/common/term-condition-user", [generalLimiter], commonController.termAndConditionForUserController);
router.get("/common/term-condition-host", [generalLimiter], commonController.termAndConditionForHostController);
router.post("/common/privacy-policy", [generalLimiter], commonController.privacyPolicyForUserController);
router.get("/common/tags", [generalLimiter], commonController.tagsListing);
router.get("/common/categories", [generalLimiter], commonController.categoryListing);


module.exports = router;