const User = require("../models/User");

// GET /api/users/search?q=ten-hoac-email
async function searchUsers(req, res) {
  try {
    const q = typeof req.query.q === "string" ? req.query.q.trim() : "";

    if (q.length < 2) {
      return res.status(200).json({ count: 0, users: [] });
    }

    const escaped = q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const regex = new RegExp(escaped, "i");

    const users = await User.find({
      _id: { $ne: req.userId },
      $or: [{ fullName: regex }, { email: regex }],
    })
      .select("fullName email avatarUrl")
      .sort({ fullName: 1 })
      .limit(20)
      .lean();

    return res.status(200).json({ count: users.length, users });
  } catch (error) {
    console.error("Search users error:", error.message);
    return res.status(500).json({ message: "Khong the tim nguoi dung" });
  }
}

module.exports = { searchUsers };
