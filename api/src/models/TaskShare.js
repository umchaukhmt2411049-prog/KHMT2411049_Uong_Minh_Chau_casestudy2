const mongoose = require("mongoose");

const taskShareSchema = new mongoose.Schema(
  {
    taskId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Task",
      required: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    permission: {
      type: String,
      enum: ["viewer", "editor"],
      required: true,
      default: "viewer",
    },
    sharedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  {
    timestamps: true,
    collection: "task_shares",
  }
);

taskShareSchema.index({ taskId: 1, userId: 1 }, { unique: true });
taskShareSchema.index({ userId: 1 });

module.exports = mongoose.model("TaskShare", taskShareSchema);
