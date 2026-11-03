const mongoose = require("mongoose");
const Task = require("../models/Task");
const User = require("../models/User");
const TaskShare = require("../models/TaskShare");

function validId(value) {
  return mongoose.isValidObjectId(value);
}

function isOwner(task, userId) {
  return task.createdBy.toString() === userId.toString();
}

async function loadTask(req, res) {
  if (!validId(req.params.id)) {
    res.status(400).json({ message: "Ma cong viec khong hop le" });
    return null;
  }

  const task = await Task.findById(req.params.id);
  if (!task) {
    res.status(404).json({ message: "Khong tim thay cong viec" });
    return null;
  }
  return task;
}

async function requireOwner(task, req, res) {
  if (!isOwner(task, req.userId)) {
    res.status(403).json({ message: "Chi nguoi tao moi duoc quan ly nguoi duoc giao" });
    return false;
  }
  return true;
}

// GET /api/tasks/:id/assignees
async function getAssignees(req, res) {
  try {
    const task = await loadTask(req, res);
    if (!task) return;

    const owner = isOwner(task, req.userId);
    const assigned = task.assigneeIds.some((id) => id.toString() === req.userId.toString());
    const shared = await TaskShare.exists({ taskId: task._id, userId: req.userId });
    if (!owner && !assigned && !shared) {
      return res.status(403).json({ message: "Ban khong co quyen xem cong viec nay" });
    }

    const users = await User.find({ _id: { $in: task.assigneeIds } })
      .select("fullName email avatarUrl")
      .sort({ fullName: 1 })
      .lean();

    return res.status(200).json({
      count: users.length,
      primaryAssigneeId: task.primaryAssigneeId,
      assignees: users,
    });
  } catch (error) {
    console.error("Get assignees error:", error.message);
    return res.status(500).json({ message: "Khong the lay danh sach nguoi duoc giao" });
  }
}

// POST /api/tasks/:id/assignees { userIds: [], primaryAssigneeId?: string }
async function addAssignees(req, res) {
  try {
    const task = await loadTask(req, res);
    if (!task) return;
    if (!(await requireOwner(task, req, res))) return;

    const userIds = req.body.userIds;
    if (!Array.isArray(userIds) || userIds.length === 0 || userIds.some((id) => !validId(id))) {
      return res.status(400).json({ message: "Danh sach userIds khong hop le" });
    }

    const uniqueIds = [...new Set(userIds.map(String))];
    const users = await User.find({ _id: { $in: uniqueIds } }).select("_id").lean();
    if (users.length !== uniqueIds.length) {
      return res.status(404).json({ message: "Mot hoac nhieu nguoi dung khong ton tai" });
    }

    const finalIds = new Set(task.assigneeIds.map((id) => id.toString()));
    uniqueIds.forEach((id) => finalIds.add(id));

    if (req.body.primaryAssigneeId !== undefined) {
      if (req.body.primaryAssigneeId !== null && !validId(req.body.primaryAssigneeId)) {
        return res.status(400).json({ message: "primaryAssigneeId khong hop le" });
      }
      if (req.body.primaryAssigneeId && !finalIds.has(String(req.body.primaryAssigneeId))) {
        return res.status(400).json({ message: "Nguoi phu trach chinh phai nam trong danh sach duoc giao" });
      }
      task.primaryAssigneeId = req.body.primaryAssigneeId || null;
    }

    task.assigneeIds = [...finalIds];
    await task.save();

    const assignees = await User.find({ _id: { $in: task.assigneeIds } })
      .select("fullName email avatarUrl")
      .sort({ fullName: 1 })
      .lean();

    return res.status(200).json({
      message: "Giao cong viec thanh cong",
      primaryAssigneeId: task.primaryAssigneeId,
      assignees,
    });
  } catch (error) {
    console.error("Add assignees error:", error.message);
    return res.status(500).json({ message: "Khong the giao cong viec" });
  }
}

// PATCH /api/tasks/:id/assignees/:userId { isPrimary: true|false }
async function updateAssignee(req, res) {
  try {
    const task = await loadTask(req, res);
    if (!task) return;
    if (!(await requireOwner(task, req, res))) return;

    const { userId } = req.params;
    if (!validId(userId)) {
      return res.status(400).json({ message: "Ma nguoi dung khong hop le" });
    }
    if (!task.assigneeIds.some((id) => id.toString() === userId)) {
      return res.status(404).json({ message: "Nguoi dung chua duoc giao cong viec nay" });
    }
    if (typeof req.body.isPrimary !== "boolean") {
      return res.status(400).json({ message: "isPrimary phai la true hoac false" });
    }

    if (req.body.isPrimary) {
      task.primaryAssigneeId = userId;
    } else if (task.primaryAssigneeId?.toString() === userId) {
      task.primaryAssigneeId = null;
    }
    await task.save();

    return res.status(200).json({
      message: "Cap nhat nguoi phu trach thanh cong",
      primaryAssigneeId: task.primaryAssigneeId,
    });
  } catch (error) {
    console.error("Update assignee error:", error.message);
    return res.status(500).json({ message: "Khong the cap nhat nguoi duoc giao" });
  }
}

// DELETE /api/tasks/:id/assignees/:userId
async function removeAssignee(req, res) {
  try {
    const task = await loadTask(req, res);
    if (!task) return;
    if (!(await requireOwner(task, req, res))) return;

    const { userId } = req.params;
    if (!validId(userId)) {
      return res.status(400).json({ message: "Ma nguoi dung khong hop le" });
    }

    const existed = task.assigneeIds.some((id) => id.toString() === userId);
    if (!existed) {
      return res.status(404).json({ message: "Nguoi dung khong nam trong danh sach duoc giao" });
    }

    task.assigneeIds = task.assigneeIds.filter((id) => id.toString() !== userId);
    if (task.primaryAssigneeId?.toString() === userId) {
      task.primaryAssigneeId = null;
    }
    await task.save();

    return res.status(200).json({ message: "Da huy giao viec" });
  } catch (error) {
    console.error("Remove assignee error:", error.message);
    return res.status(500).json({ message: "Khong the huy giao viec" });
  }
}

module.exports = { getAssignees, addAssignees, updateAssignee, removeAssignee };
