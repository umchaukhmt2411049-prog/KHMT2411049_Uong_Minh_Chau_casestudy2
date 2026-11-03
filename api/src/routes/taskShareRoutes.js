const express = require("express");
const authMiddleware = require("../middleware/authMiddleware");
const {
  getShares,
  addShares,
  updateShare,
  removeShare,
} = require("../controllers/taskShareController");

const router = express.Router();
router.use(authMiddleware);
router.get("/:id/shares", getShares);
router.post("/:id/shares", addShares);
router.patch("/:id/shares/:shareId", updateShare);
router.delete("/:id/shares/:shareId", removeShare);

module.exports = router;
