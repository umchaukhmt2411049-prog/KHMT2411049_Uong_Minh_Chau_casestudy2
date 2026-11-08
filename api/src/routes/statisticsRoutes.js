const express = require("express");
const authMiddleware = require("../middleware/authMiddleware");
const { getStatistics } = require("../controllers/statisticsController");

const router = express.Router();
router.use(authMiddleware);
router.get("/", getStatistics);

module.exports = router;
