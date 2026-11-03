const express = require("express");
const authMiddleware = require("../middleware/authMiddleware");
const {
  getAssignees,
  addAssignees,
  updateAssignee,
  removeAssignee,
} = require("../controllers/assignmentController");

const router = express.Router();
router.use(authMiddleware);
router.get("/:id/assignees", getAssignees);
router.post("/:id/assignees", addAssignees);
router.patch("/:id/assignees/:userId", updateAssignee);
router.delete("/:id/assignees/:userId", removeAssignee);

module.exports = router;
