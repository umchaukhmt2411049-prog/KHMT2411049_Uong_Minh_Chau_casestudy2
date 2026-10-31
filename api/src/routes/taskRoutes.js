const express = require("express");
const authMiddleware = require("../middleware/authMiddleware");

const {
  getTasks,
  getTaskById,
} = require("../controllers/taskController");

const router = express.Router();

router.get("/", authMiddleware, getTasks);
router.get("/:id", authMiddleware, getTaskById);

module.exports = router;