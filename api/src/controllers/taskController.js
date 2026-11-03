const mongoose = require("mongoose");
const Task = require("../models/Task");
const TaskShare = require("../models/TaskShare");

function parseDate(value) {
  if (value === undefined) return { provided: false };
  if (value === null || value === "") return { provided: true, value: null };
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return { provided: true, invalid: true };
  return { provided: true, value: date };
}

function validTaskId(id) {
  return mongoose.isValidObjectId(id);
}

function isTaskOwner(task, userId) {
  return task.createdBy.toString() === userId.toString();
}

async function getSharePermission(taskId, userId) {
  const share = await TaskShare.findOne({ taskId, userId }).select("permission").lean();
  return share?.permission || null;
}

async function canViewTask(task, userId) {
  if (isTaskOwner(task, userId)) return true;
  if (task.assigneeIds.some((id) => id.toString() === userId.toString())) return true;
  return Boolean(await TaskShare.exists({ taskId: task._id, userId }));
}

// GET /api/tasks - cong viec tao, duoc giao va duoc chia se
async function getTasks(req, res) {
  try {
    const sharedTaskIds = await TaskShare.find({ userId: req.userId }).distinct("taskId");
    const tasks = await Task.find({
      $or: [
        { createdBy: req.userId },
        { assigneeIds: req.userId },
        { _id: { $in: sharedTaskIds } },
      ],
    })
      .sort({ createdAt: -1 })
      .lean();

    return res.status(200).json({ count: tasks.length, tasks });
  } catch (error) {
    console.error("Get tasks error:", error.message);
    return res.status(500).json({ message: "Khong the lay danh sach cong viec" });
  }
}

// GET /api/tasks/:id
async function getTaskById(req, res) {
  try {
    const { id } = req.params;
    if (!validTaskId(id)) {
      return res.status(400).json({ message: "Ma cong viec khong hop le" });
    }

    const task = await Task.findById(id).lean();
    if (!task || !(await canViewTask(task, req.userId))) {
      return res.status(404).json({ message: "Khong tim thay cong viec" });
    }

    const isOwner = isTaskOwner(task, req.userId);
    const sharePermission = isOwner ? null : await getSharePermission(task._id, req.userId);
    const isAssignee = task.assigneeIds.some((userId) => userId.toString() === req.userId.toString());

    return res.status(200).json({
      task,
      permissions: {
        isOwner,
        sharePermission,
        isAssignee,
        canEdit: isOwner || sharePermission === "editor",
        canManage: isOwner,
        canUpdateStatus: isOwner || sharePermission === "editor" || isAssignee,
      },
    });
  } catch (error) {
    console.error("Get task detail error:", error.message);
    return res.status(500).json({ message: "Khong the lay chi tiet cong viec" });
  }
}

// POST /api/tasks
async function createTask(req, res) {
  try {
    const { title, description, startDate, dueDate, priority, status } = req.body;

    if (typeof title !== "string" || title.trim().length === 0 || title.trim().length > 200) {
      return res.status(400).json({ message: "Ten cong viec phai tu 1 den 200 ky tu" });
    }

    const start = parseDate(startDate);
    const due = parseDate(dueDate);
    if (start.invalid || due.invalid) {
      return res.status(400).json({ message: "Ngay thang khong hop le" });
    }

    const startValue = start.value ?? null;
    const dueValue = due.value ?? null;
    if (startValue && dueValue && dueValue < startValue) {
      return res.status(400).json({ message: "Han hoan thanh khong duoc truoc ngay bat dau" });
    }
    if (priority !== undefined && !["low", "medium", "high"].includes(priority)) {
      return res.status(400).json({ message: "Muc do uu tien khong hop le" });
    }
    if (status !== undefined && !["todo", "in_progress", "completed"].includes(status)) {
      return res.status(400).json({ message: "Trang thai cong viec khong hop le" });
    }
    if (description !== undefined && typeof description !== "string") {
      return res.status(400).json({ message: "Mo ta phai la chuoi" });
    }

    const task = await Task.create({
      title: title.trim(),
      description: description?.trim() || "",
      createdBy: req.userId,
      assigneeIds: [],
      primaryAssigneeId: null,
      startDate: startValue,
      dueDate: dueValue,
      priority: priority || "medium",
      status: status || "todo",
    });

    return res.status(201).json({ message: "Tao cong viec thanh cong", task });
  } catch (error) {
    console.error("Create task error:", error.message);
    return res.status(500).json({ message: "Khong the tao cong viec" });
  }
}

// PUT /api/tasks/:id
// Owner va editor duoc sua noi dung; assignee chi duoc cap nhat trang thai.
async function updateTask(req, res) {
  try {
    const { id } = req.params;
    if (!validTaskId(id)) {
      return res.status(400).json({ message: "Ma cong viec khong hop le" });
    }

    const task = await Task.findById(id);
    if (!task) return res.status(404).json({ message: "Khong tim thay cong viec" });

    const allowedFields = ["title", "description", "startDate", "dueDate", "priority", "status"];
    const incomingFields = Object.keys(req.body);
    const unknownFields = incomingFields.filter((field) => !allowedFields.includes(field));
    if (unknownFields.length > 0) {
      return res.status(400).json({ message: "Co truong du lieu khong duoc phep cap nhat", fields: unknownFields });
    }
    if (incomingFields.length === 0) {
      return res.status(400).json({ message: "Khong co thong tin hop le de cap nhat" });
    }

    const owner = isTaskOwner(task, req.userId);
    const permission = owner ? "owner" : await getSharePermission(task._id, req.userId);
    const isAssignee = task.assigneeIds.some((userId) => userId.toString() === req.userId.toString());
    const statusOnly = incomingFields.length === 1 && incomingFields[0] === "status";

    if (!owner && permission !== "editor" && !(isAssignee && statusOnly)) {
      return res.status(403).json({ message: "Ban khong co quyen sua cong viec nay" });
    }
    if (!owner && permission === "viewer" && !statusOnly) {
      return res.status(403).json({ message: "Quyen viewer chi duoc xem cong viec" });
    }

    const updates = {};
    if (req.body.title !== undefined) {
      if (typeof req.body.title !== "string" || req.body.title.trim().length === 0 || req.body.title.trim().length > 200) {
        return res.status(400).json({ message: "Ten cong viec phai tu 1 den 200 ky tu" });
      }
      updates.title = req.body.title.trim();
    }
    if (req.body.description !== undefined) {
      if (typeof req.body.description !== "string") {
        return res.status(400).json({ message: "Mo ta phai la chuoi" });
      }
      updates.description = req.body.description.trim();
    }
    if (req.body.priority !== undefined) {
      if (!["low", "medium", "high"].includes(req.body.priority)) {
        return res.status(400).json({ message: "Muc do uu tien khong hop le" });
      }
      updates.priority = req.body.priority;
    }
    if (req.body.status !== undefined) {
      if (!["todo", "in_progress", "completed"].includes(req.body.status)) {
        return res.status(400).json({ message: "Trang thai cong viec khong hop le" });
      }
      updates.status = req.body.status;
    }

    for (const field of ["startDate", "dueDate"]) {
      if (req.body[field] !== undefined) {
        const parsed = parseDate(req.body[field]);
        if (parsed.invalid) return res.status(400).json({ message: `${field} khong hop le` });
        updates[field] = parsed.value;
      }
    }

    const finalStart = updates.startDate !== undefined ? updates.startDate : task.startDate;
    const finalDue = updates.dueDate !== undefined ? updates.dueDate : task.dueDate;
    if (finalStart && finalDue && finalDue < finalStart) {
      return res.status(400).json({ message: "Han hoan thanh khong duoc truoc ngay bat dau" });
    }

    Object.assign(task, updates);
    await task.save();
    return res.status(200).json({ message: "Cap nhat cong viec thanh cong", task });
  } catch (error) {
    console.error("Update task error:", error.message);
    return res.status(500).json({ message: "Khong the cap nhat cong viec" });
  }
}

// DELETE /api/tasks/:id - chi nguoi tao duoc xoa
async function deleteTask(req, res) {
  try {
    const { id } = req.params;
    if (!validTaskId(id)) {
      return res.status(400).json({ message: "Ma cong viec khong hop le" });
    }

    const task = await Task.findById(id);
    if (!task) return res.status(404).json({ message: "Khong tim thay cong viec" });
    if (!isTaskOwner(task, req.userId)) {
      return res.status(403).json({ message: "Chi nguoi tao moi duoc xoa cong viec" });
    }

    await Promise.all([
      Task.deleteOne({ _id: id }),
      TaskShare.deleteMany({ taskId: id }),
    ]);

    return res.status(200).json({ message: "Xoa cong viec thanh cong" });
  } catch (error) {
    console.error("Delete task error:", error.message);
    return res.status(500).json({ message: "Khong the xoa cong viec" });
  }
}

module.exports = { getTasks, getTaskById, createTask, updateTask, deleteTask };
