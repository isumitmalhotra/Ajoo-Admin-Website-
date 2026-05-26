const express = require("express");
const router = express.Router();
const controller = require("../controllers/payout.controller");
const schema = require("../schema/payout.schema");
const validation = require("../middleware/validation");
const { hostAuthentication } = require("../middleware/authorization");
// const { upload } = require("../utils/fileHandler")


router.post("/payout/account/details-add", [validation(schema.createHostAccDetails), hostAuthentication], controller.addHostAccountDetails);
router.get("/payout/account/details", [hostAuthentication], controller.getHostAccountDetails);
router.post("/payout/request/create", [validation(schema.createPayoutRequest), hostAuthentication], controller.cretePayoutRequest);
router.get("/payout/request/list", [hostAuthentication], controller.getPayoutRequests);
router.post("/payout/history", [validation(schema.payoutHistoryList), hostAuthentication], controller.getPayoutHistory);
router.post("/payout/history/download", [validation(schema.payoutHistoryList), hostAuthentication], controller.downloadPayoutHistory);

module.exports = router;
