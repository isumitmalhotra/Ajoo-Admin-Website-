const express = require("express");
const router = express.Router();  // Initialize the router
const controller = require("../controllers/property.controller");
const schema = require("../schema/properties.schema");
const validation = require("../middleware/validation");
const { authenticateJWT, hostAuthentication } = require("../middleware/authorization");
const { upload } = require("../utils/fileHandler");
const { generalLimiter, uploadLimiter } = require("../middleware/rateLimiter");
//-------------BASIC--------------------
router.post("/properties/add", uploadLimiter, upload.fields([
    { name: "property_img", maxCount: 15 },
    { name: "property_doc", maxCount: 5 }
]), [validation(schema.createProperty), hostAuthentication], controller.addProperty);

router.post("/properties/search", generalLimiter, [validation(schema.getLongLatProperty)], controller.getProperties);
router.get("/properties/:propId", generalLimiter, [validation(schema.getSingleProperty), authenticateJWT], controller.getProperty);
router.post("/properties/add/cover-pic", uploadLimiter, upload.single("property_img"), [validation(schema.propCoverPic), hostAuthentication], controller.setPropCoverImg);
router.post("/properties/delete", generalLimiter, [validation(schema.getSingleProperty), hostAuthentication], controller.deleteProperty);
router.post("/properties/inactive", generalLimiter, [validation(schema.getSingleProperty), hostAuthentication], controller.deactivateProperty);
router.post("/properties/list", generalLimiter, [authenticateJWT], controller.propertyListing);
//----------------USER ACTION -------------
router.post("/properties/user-saveProp", generalLimiter, [validation(schema.userSaveProp), authenticateJWT], controller.savePropertyByUser);
// router.post("/properties/user-likeProp", [validation(schema.userSaveProp), authenticateJWT], controller.userLikedProperty);
// router.post("/properties/user-dislikeProp", [validation(schema.userSaveProp), authenticateJWT], controller.userDislikeProperty);
//---------------REVIEWS-------------------
router.post("/properties/reviews/list", generalLimiter, [validation(schema.propertyList), authenticateJWT], controller.propertyReviews);
//-----------------ADMIN-------------------
router.post("/admin/properties/search", generalLimiter, [], controller.adminPropSearch);
router.post("/admin/properties/load", uploadLimiter, upload.single("property_file"), controller.loadPropertiesUsingFile);


module.exports = router;