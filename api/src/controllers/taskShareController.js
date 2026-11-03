const mongoose = require("mongoose");
const Task = require("../models/Task");
const User = require("../models/User");
const TaskShare = require("../models/TaskShare");

function validId(value) {
  return mongoose.isValidObjectId(value);
}

async function loadOwnedTask(req, res) {
  if (!validId(req.params.id)) {
    res.status(400).json({ message: "Ma cong viec khong hop le" });
    return null;
  }

  const task = await Task.findById(req.params.id);
  if (!task) {
    res.status(404).json({ message: "Khong tim thay cong viec" });
    return null;
  }
  if (task.createdBy.toString() !== req.userId.toString()) {
    res.status(403).json({ message: "Chi nguoi tao moi duoc quan ly chia se" });
    return null;
  }
  return task;
}

function validPermission(permission) {
  return ["viewer", "editor"].includes(permission);
}

// GET /api/tasks/:id/shares
async function getShares(req, res) {
  try {
    const task = await loadOwnedTask(req, res);
    if (!task) return;

    const shares = await TaskShare.find({ taskId: task._id })
      .populate("userId", "fullName email avatarUrl")
      .sort({ createdAt: -1 })
      .lean();

    return res.status(200).json({ count: shares.length, shares });
  } catch (error) {
    console.error("Get shares error:", error.message);
    return res.status(500).json({ message: "Khong the lay danh sach chia se" });
  }
}

// POST /api/tasks/:id/shares { userIds: [], permission: "viewer"|"editor" }
async function addShares(req, res) {
  try {
    const task = await loadOwnedTask(req, res);
    if (!task) return;

    const { userIds, permission } = req.body;
    if (!Array.isArray(userIds) || userIds.length === 0 || userIds.some((id) => !validId(id))) {
      return res.status(400).json({ message: "Danh sach userIds khong hop le" });
    }
    if (!validPermission(permission)) {
      return res.status(400).json({ message: "Quyen chia se phai la viewer hoac editor" });
    }

    const uniqueIds = [...new Set(userIds.map(String))];
    if (uniqueIds.includes(req.userId.toString())) {
      return res.status(400).json({ message: "Khong can chia se cong viec cho chinh minh" });
    }

    const users = await User.find({ _id: { $in: uniqueIds } }).select("_id").lean();
    if (users.length !== uniqueIds.length) {
      return res.status(404).json({ message: "Mot hoac nhieu nguoi dung khong ton tai" });
    }

    const operations = uniqueIds.map((userId) => ({
      updateOne: {
        filter: { taskId: task._id, userId },
        update: {
          $set: { permission },
          $setOnInsert: { taskId: task._id, userId, sharedBy: req.userId },
        },
        upsert: true,
      },
    }));
    await TaskShare.bulkWrite(operations);

    const shares = await TaskShare.find({ taskId: task._id })
      .populate("userId", "fullName email avatarUrl")
      .sort({ createdAt: -1 })
      .lean();

    return res.status(200).json({
      message: "Chia se cong viec thanh cong",
      count: shares.length,
      shares,
    });
  } catch (error) {
    console.error("Add shares error:", error.message);
    return res.status(500).json({ message: "Khong the chia se cong viec" });
  }
}

// PATCH /api/tasks/:id/shares/:shareId { permission: "viewer"|"editor" }
async function updateShare(req, res) {
  try {
    const task = await loadOwnedTask(req, res);
    if (!task) return;

    const { shareId } = req.params;
    if (!validId(shareId)) {
      return res.status(400).json({ message: "Ma chia se khong hop le" });
    }
    if (!validPermission(req.body.permission)) {
      return res.status(400).json({ message: "Quyen chia se phai la viewer hoac editor" });
    }

    const share = await TaskShare.findOneAndUpdate(
      { _id: shareId, taskId: task._id },
      { $set: { permission: req.body.permission } },
      { new: true, runValidators: true }
    ).populate("userId", "fullName email avatarUrl");

    if (!share) {
      return res.status(404).json({ message: "Khong tim thay quyen chia se" });
    }

    return res.status(200).json({ message: "Cap nhat quyen chia se thanh cong", share });
  } catch (error) {
    console.error("Update share error:", error.message);
    return res.status(500).json({ message: "Khong the cap nhat quyen chia se" });
  }
}

// DELETE /api/tasks/:id/shares/:shareId
async function removeShare(req, res) {
  try {
    const task = await loadOwnedTask(req, res);
    if (!task) return;

    const { shareId } = req.params;
    if (!validId(shareId)) {
      return res.status(400).json({ message: "Ma chia se khong hop le" });
    }

    const result = await TaskShare.deleteOne({ _id: shareId, taskId: task._id });
    if (result.deletedCount === 0) {
      return res.status(404).json({ message: "Khong tim thay quyen chia se" });
    }

    return res.status(200).json({ message: "Da thu hoi quyen chia se" });
  } catch (error) {
    console.error("Remove share error:", error.message);
    return res.status(500).json({ message: "Khong the thu hoi quyen chia se" });
  }
}

module.exports = { getShares, addShares, updateShare, removeShare };
