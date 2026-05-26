const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminPropertyAmeneties.controller");
const schema = require("../schema/adminProperties.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { upload } = require("../utils/fileHandler");
const { generalLimiter, uploadLimiter } = require("../middleware/rateLimiter");

router.post("/admin/amenity/create", [validation(schema.createOrUpdateAmenitySchema), adminAuthToken], controller.createUpdateAmeneties);
router.post("/admin/amenity", [validation(schema.amenityId), adminAuthToken], controller.amenity);
router.post("/admin/amenity/delete", [validation(schema.amenityId), adminAuthToken], controller.deleteAmenity);
router.post("/admin/amenity/search", [adminAuthToken], controller.amenetiesListing);
router.get("/admin/amenity/list/dropdowns", [adminAuthToken], controller.amenetiesListingForDropdown);
router.post("/admin/amenity/update-status", [validation(schema.amenityStatus), adminAuthToken], controller.updateStatus);

module.exports = router;