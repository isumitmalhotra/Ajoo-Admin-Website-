const express = require("express");
const router = express.Router();
const controller = require("../controllers/property.controller");
const commonController = require("../controllers/common.controller");

router.get("/common/states", [], controller.states);
router.get("/common/country", [], controller.countries);
router.get("/common/amenties", [], controller.getAmenties);


router.get("/common/documents/list", [], commonController.documentListing);
router.get("/common/safety", [], commonController.safetyPage);
router.get("/common/about-us", [], commonController.aboutus);
router.get("/common/faq", [], commonController.faqs);
router.get("/common/term-condition-user", [], commonController.termAndConditionForUserController);
router.get("/common/term-condition-host", [], commonController.termAndConditionForHostController);
router.post("/common/privacy-policy", [], commonController.privacyPolicyForUserController);
router.get("/common/tags", [], commonController.tagsListing);
router.get("/common/categories", [], commonController.categoryListing);


module.exports = router;