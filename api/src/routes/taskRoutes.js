const express = require("express");

const authMiddleware = require("../middleware/authMiddleware");

const {
  getTasks,
  getTaskById,
  createTask,
  updateTask,
  deleteTask,
} = require("../controllers/taskController");

const router = express.Router();

// Tat ca API cong viec deu yeu cau JWT
router.use(authMiddleware);

// GET /api/tasks - Danh sach cong viec
router.get("/", getTasks);

// POST /api/tasks - Tao cong viec
router.post("/", createTask);

// GET /api/tasks/:id - Chi tiet cong viec
router.get("/:id", getTaskById);

// PUT /api/tasks/:id - Cap nhat cong viec
router.put("/:id", updateTask);

// DELETE /api/tasks/:id - Xoa cong viec
router.delete("/:id", deleteTask);

module.exports = router;