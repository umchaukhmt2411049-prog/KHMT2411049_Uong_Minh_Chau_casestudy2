const express = require("express");
const authMiddleware = require("../middleware/authMiddleware");
const { getEmailLogs } = require("../controllers/emailLogController");

const router = express.Router();
router.use(authMiddleware);
router.get("/", getEmailLogs);

module.exports = router;
