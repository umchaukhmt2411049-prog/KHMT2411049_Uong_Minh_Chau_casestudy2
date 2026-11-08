const mongoose = require("mongoose");
const Notification = require("../models/Notification");

async function getNotifications(req, res) {
  try {
    const [notifications, unreadCount, totalCount] = await Promise.all([
      Notification.find({ recipientId: req.userId })
        .populate("actorId", "fullName email")
        .populate("taskId", "title status dueDate")
        .sort({ createdAt: -1 })
        .limit(100)
        .lean(),
      Notification.countDocuments({ recipientId: req.userId, isRead: false }),
      Notification.countDocuments({ recipientId: req.userId }),
    ]);
    return res.status(200).json({ totalCount, unreadCount, notifications });
  } catch (error) {
    console.error("Get notifications error:", error.message);
    return res.status(500).json({ message: "Không thể tải thông báo" });
  }
}

async function markNotificationRead(req, res) {
  try {
    const { id } = req.params;
    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({ message: "Mã thông báo không hợp lệ" });
    }
    const notification = await Notification.findOneAndUpdate(
      { _id: id, recipientId: req.userId },
      { $set: { isRead: true, readAt: new Date() } },
      { new: true }
    );
    if (!notification) return res.status(404).json({ message: "Không tìm thấy thông báo" });
    return res.status(200).json({ message: "Đã đánh dấu thông báo đã đọc", notification });
  } catch (error) {
    console.error("Mark notification read error:", error.message);
    return res.status(500).json({ message: "Không thể cập nhật thông báo" });
  }
}

async function markAllNotificationsRead(req, res) {
  try {
    const result = await Notification.updateMany(
      { recipientId: req.userId, isRead: false },
      { $set: { isRead: true, readAt: new Date() } }
    );
    return res.status(200).json({ message: "Đã đánh dấu tất cả là đã đọc", updatedCount: result.modifiedCount });
  } catch (error) {
    console.error("Mark all notifications read error:", error.message);
    return res.status(500).json({ message: "Không thể cập nhật thông báo" });
  }
}

module.exports = { getNotifications, markNotificationRead, markAllNotificationsRead };
