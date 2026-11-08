const mongoose = require("mongoose");

const emailLogSchema = new mongoose.Schema(
  {
    senderId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    recipientId: { type: mongoose.Schema.Types.ObjectId, ref: "User", default: null },
    recipientEmail: { type: String, required: true, trim: true, lowercase: true },
    recipientName: { type: String, default: "" },
    taskId: { type: mongoose.Schema.Types.ObjectId, ref: "Task", default: null },
    eventType: { type: String, enum: ["task_assigned", "task_shared"], required: true },
    subject: { type: String, required: true },
    status: { type: String, enum: ["pending", "sent", "failed"], default: "pending", index: true },
    attempts: { type: Number, default: 0 },
    errorMessage: { type: String, default: "" },
    sentAt: { type: Date, default: null },
  },
  { timestamps: true, collection: "email_logs" }
);

emailLogSchema.index({ senderId: 1, createdAt: -1 });
emailLogSchema.index({ recipientEmail: 1, createdAt: -1 });

module.exports = mongoose.model("EmailLog", emailLogSchema);
