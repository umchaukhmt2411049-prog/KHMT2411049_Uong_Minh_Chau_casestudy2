const EmailLog = require("../models/EmailLog");

async function getEmailLogs(req, res) {
  try {
    const logs = await EmailLog.find({ senderId: req.userId })
      .populate("recipientId", "fullName email")
      .populate("taskId", "title")
      .sort({ createdAt: -1 })
      .limit(100)
      .lean();
    return res.status(200).json({ count: logs.length, logs });
  } catch (error) {
    console.error("Get email logs error:", error.message);
    return res.status(500).json({ message: "Không thể tải lịch sử email" });
  }
}

module.exports = { getEmailLogs };
