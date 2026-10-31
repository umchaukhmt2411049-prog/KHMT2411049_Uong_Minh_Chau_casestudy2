const mongoose = require("mongoose");
const Task = require("../models/Task");

// GET /api/tasks
async function getTasks(req, res) {
  try {
    const tasks = await Task.find({
      $or: [
        { createdBy: req.userId },
        { assigneeIds: req.userId },
      ],
    })
      .select(
        "title description createdBy assigneeIds primaryAssigneeId startDate dueDate priority status createdAt updatedAt"
      )
      .sort({ createdAt: -1 })
      .lean();

    return res.status(200).json({
      count: tasks.length,
      tasks,
    });
  } catch (error) {
    console.error("Get tasks error:", error.message);

    return res.status(500).json({
      message: "Khong the lay danh sach cong viec",
    });
  }
}

// GET /api/tasks/:id
async function getTaskById(req, res) {
  try {
    const { id } = req.params;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        message: "Ma cong viec khong hop le",
      });
    }

    const task = await Task.findOne({
      _id: id,
      $or: [
        { createdBy: req.userId },
        { assigneeIds: req.userId },
      ],
    })
      .select(
        "title description createdBy assigneeIds primaryAssigneeId startDate dueDate priority status createdAt updatedAt"
      )
      .lean();

    if (!task) {
      return res.status(404).json({
        message: "Khong tim thay cong viec",
      });
    }

    return res.status(200).json({ task });
  } catch (error) {
    console.error("Get task detail error:", error.message);

    return res.status(500).json({
      message: "Khong the lay chi tiet cong viec",
    });
  }
}

module.exports = {
  getTasks,
  getTaskById,
};