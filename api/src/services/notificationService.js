const Notification = require("../models/Notification");
const User = require("../models/User");
const { sendTaskEventEmail } = require("./emailService");

async function notifyTaskRecipients({ task, actorId, recipientIds, eventType }) {
  try {
    const ids = [...new Set((recipientIds || []).map((id) => String(id)))].filter(
      (id) => id !== String(actorId)
    );
    if (ids.length === 0) return;

    const [actor, recipients] = await Promise.all([
      User.findById(actorId).select("fullName email").lean(),
      User.find({ _id: { $in: ids } }).select("fullName email").lean(),
    ]);
    if (!actor) return;

    const isAssignment = eventType === "task_assigned";
    const title = isAssignment
      ? "Bạn được giao công việc mới"
      : "Một công việc được chia sẻ với bạn";
    const message = isAssignment
      ? `${actor.fullName} đã giao cho bạn công việc: ${task.title}`
      : `${actor.fullName} đã chia sẻ với bạn công việc: ${task.title}`;

    await Promise.allSettled(
      recipients.map(async (recipient) => {
        try {
          await Notification.create({
            recipientId: recipient._id,
            actorId: actor._id,
            taskId: task._id,
            type: eventType,
            title,
            message,
          });
        } catch (error) {
          console.error("Create task notification error:", error.message);
        }

        await sendTaskEventEmail({ sender: actor, recipient, task, eventType });
      })
    );
  } catch (error) {
    // Thông báo/email là tác vụ phụ; không làm thất bại việc giao/chia sẻ đã lưu thành công.
    console.error("Task notification workflow error:", error.message);
  }
}

module.exports = { notifyTaskRecipients };
