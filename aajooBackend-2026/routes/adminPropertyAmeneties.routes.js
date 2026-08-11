const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminPropertyAmeneties.controller");
const schema = require("../schema/adminProperties.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { adminApiLimiter } = require("../middleware/rateLimiter");

router.post("/admin/amenity/create", adminApiLimiter, [validation(schema.createOrUpdateAmenitySchema), adminAuthToken], controller.createUpdateAmeneties);
router.post("/admin/amenity", adminApiLimiter, [validation(schema.amenityId), adminAuthToken], controller.amenity);
router.post("/admin/amenity/delete", adminApiLimiter, [validation(schema.amenityId), adminAuthToken], controller.deleteAmenity);
router.post("/admin/amenity/search", adminApiLimiter, [validation(schema.amenityListingSchema), adminAuthToken], controller.amenetiesListing);
router.get("/admin/amenity/list/dropdowns", adminApiLimiter, [adminAuthToken], controller.amenetiesListingForDropdown);
router.post("/admin/amenity/update-status", adminApiLimiter, [validation(schema.amenityStatus), adminAuthToken], controller.updateStatus);

module.exports = router;
