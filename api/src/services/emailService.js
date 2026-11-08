const EmailLog = require("../models/EmailLog");
const { createEmailTransporter } = require("../config/email");

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, (char) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  })[char]);
}

async function sendTaskEventEmail({ sender, recipient, task, eventType }) {
  const isAssignment = eventType === "task_assigned";
  const subject = isAssignment
    ? `Bạn được giao một công việc mới: ${task.title}`
    : `Một công việc đã được chia sẻ với bạn: ${task.title}`;
  const actionText = isAssignment ? "đã giao cho bạn công việc" : "đã chia sẻ với bạn công việc";
  const log = await EmailLog.create({
    senderId: sender._id,
    recipientId: recipient._id,
    recipientEmail: recipient.email,
    recipientName: recipient.fullName,
    taskId: task._id,
    eventType,
    subject,
    status: "pending",
    attempts: 0,
  });

  try {
    const transporter = createEmailTransporter();
    if (!transporter) {
      throw new Error("Chưa cấu hình SMTP_HOST, SMTP_PORT, SMTP_USER và SMTP_PASS trong api/.env");
    }

    const from = process.env.SMTP_FROM || process.env.SMTP_USER;
    const senderName = escapeHtml(sender.fullName || sender.email);
    const recipientName = escapeHtml(recipient.fullName || recipient.email);
    const taskTitle = escapeHtml(task.title);
    const description = escapeHtml(task.description || "Không có mô tả");
    const text = `${sender.fullName} ${actionText} "${task.title}".\nMô tả: ${task.description || "Không có mô tả"}`;
    const html = `<!doctype html><html><body style="font-family:Arial,sans-serif;color:#24352d;line-height:1.6"><h2>Thông báo công việc</h2><p>Xin chào ${recipientName},</p><p><strong>${senderName}</strong> ${actionText}:</p><h3>${taskTitle}</h3><p>${description}</p><p>Hãy đăng nhập ứng dụng Task Manager để xem chi tiết.</p></body></html>`;

    await transporter.sendMail({ from, to: recipient.email, subject, text, html });
    log.status = "sent";
    log.attempts = 1;
    log.errorMessage = "";
    log.sentAt = new Date();
    await log.save();
    return { sent: true, logId: log._id };
  } catch (error) {
    log.status = "failed";
    log.attempts = 1;
    log.errorMessage = String(error.message || "Không gửi được email").slice(0, 1000);
    await log.save();
    console.error("Task email error:", error.message);
    return { sent: false, logId: log._id, error: log.errorMessage };
  }
}

module.exports = { sendTaskEventEmail };
