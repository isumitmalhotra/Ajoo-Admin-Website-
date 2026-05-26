const express = require("express");
const router = express.Router();
const controller = require("../controllers/admin.controller");
const schema = require("../schema/admin.schema");
const validation = require("../middleware/validation");
const { adminAuth } = require("../middleware/authorization");
const { upload } = require("../utils/fileHandler")


router.post("/admin/login", [validation(schema.adminLogin)], controller.adminLogin);
router.post("/admin/logout", [adminAuth], controller.adminLogout);
router.post("/admin/create", [], controller.addCreate);
router.get("/admin/dashboard", [adminAuth], controller.adminDashboard);



module.exports = router;