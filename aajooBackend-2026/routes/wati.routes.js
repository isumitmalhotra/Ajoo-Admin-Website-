const express = require("express");
const router = express.Router();
const watiController = require("../controllers/wati.controller");
const { generalLimiter, strictLimiter } = require("../middleware/rateLimiter");

// Webhook endpoint for WATI
router.post("/api/wati/webhook", (req, res) => {
  // Optional: Add API key validation
  logger.info("Received WATI webhook");
  
  watiController.webhook(req, res);
});

// Test endpoints
router.post("/test-intent", generalLimiter, watiController.testIntent);

module.exports = router;
