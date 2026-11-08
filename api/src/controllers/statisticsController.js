const Task = require("../models/Task");
const TaskShare = require("../models/TaskShare");

async function getStatistics(req, res) {
  try {
    const sharedTaskIds = await TaskShare.find({ userId: req.userId }).distinct("taskId");
    const tasks = await Task.find({
      $or: [
        { createdBy: req.userId },
        { assigneeIds: req.userId },
        { _id: { $in: sharedTaskIds } },
      ],
    }).select("createdBy assigneeIds status dueDate").lean();

    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const sevenDaysLater = new Date(today);
    sevenDaysLater.setDate(sevenDaysLater.getDate() + 7);

    const statusCounts = { todo: 0, in_progress: 0, completed: 0 };
    let createdByMe = 0;
    let assignedToMe = 0;
    let sharedWithMe = 0;
    let overdueTasks = 0;
    let dueSoonTasks = 0;

    for (const task of tasks) {
      if (statusCounts[task.status] !== undefined) statusCounts[task.status] += 1;
      if (String(task.createdBy) === String(req.userId)) createdByMe += 1;
      if ((task.assigneeIds || []).some((id) => String(id) === String(req.userId))) assignedToMe += 1;
      if (sharedTaskIds.some((id) => String(id) === String(task._id)) && String(task.createdBy) !== String(req.userId)) sharedWithMe += 1;
      if (task.status !== "completed" && task.dueDate) {
        const due = new Date(task.dueDate);
        if (due < today) overdueTasks += 1;
        else if (due >= today && due <= sevenDaysLater) dueSoonTasks += 1;
      }
    }

    return res.status(200).json({
      statistics: {
        totalTasks: tasks.length,
        statusCounts,
        createdByMe,
        assignedToMe,
        sharedWithMe,
        overdueTasks,
        dueSoonTasks,
      },
    });
  } catch (error) {
    console.error("Get statistics error:", error.message);
    return res.status(500).json({ message: "Không thể tải thống kê công việc" });
  }
}

module.exports = { getStatistics };
