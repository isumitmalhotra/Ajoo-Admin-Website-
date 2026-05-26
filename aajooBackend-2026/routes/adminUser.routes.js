const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminUser.controller");
const schema = require("../schema/adminUser.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { upload } = require("../utils/fileHandler");
const { adminLoginLimiter, adminApiLimiter } = require("../middleware/adminRateLimiter");


router.post(
    "/admin/user/create", adminApiLimiter, adminAuthToken, upload.fields(
        [{ name: "user_profile", maxCount: 1 }, { name: "user_id_image", maxCount: 1 },]),
    validation(schema.createUserSchema), controller.addUser
);
router.post("/admin/user/delete/image", adminApiLimiter, [validation(schema.deleteImage), adminAuthToken], controller.deleteSingleImage);
router.post("/admin/user/update/status", [validation(schema.updateStatus), adminAuthToken], controller.updateStatus);
router.post("/admin/user/verify", [validation(schema.verifyUser), adminAuthToken], controller.verifyUser);
router.post("/admin/user/delete", [validation(schema.userId), adminAuthToken], controller.deleteuser);
router.post("/admin/user/search", [adminAuthToken], controller.userListing);
router.post("/admin/user/single", [validation(schema.userId), adminAuthToken], controller.userById);


module.exports = router;


// Admin activity logging tabl