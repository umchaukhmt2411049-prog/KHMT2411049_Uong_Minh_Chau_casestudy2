const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { validationResult } = require("express-validator");
const User = require("../models/User");

function getValidationErrors(req) {
  return validationResult(req);
}

// POST /api/auth/register
async function register(req, res) {
  const errors = getValidationErrors(req);

  if (!errors.isEmpty()) {
    return res.status(400).json({
      message: "Du lieu khong hop le",
      errors: errors.array(),
    });
  }

  try {
    const { fullName, email, password } = req.body;
    const normalizedEmail = email.trim().toLowerCase();

    const existingUser = await User.findOne({
      email: normalizedEmail,
    });

    if (existingUser) {
      return res.status(409).json({
        message: "Email da duoc dang ky",
      });
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const user = await User.create({
      fullName: fullName.trim(),
      email: normalizedEmail,
      passwordHash,
    });

    return res.status(201).json({
      message: "Dang ky thanh cong",
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({
        message: "Email da duoc dang ky",
      });
    }

    console.error("Register error:", error.message);

    return res.status(500).json({
      message: "Khong the dang ky tai khoan",
    });
  }
}

// POST /api/auth/login
async function login(req, res) {
  const errors = getValidationErrors(req);

  if (!errors.isEmpty()) {
    return res.status(400).json({
      message: "Du lieu khong hop le",
      errors: errors.array(),
    });
  }

  try {
    const { email, password } = req.body;

    const user = await User.findOne({
      email: email.trim().toLowerCase(),
    }).select("+passwordHash");

    if (!user) {
      return res.status(401).json({
        message: "Email hoac mat khau khong chinh xac",
      });
    }

    const passwordMatches = await bcrypt.compare(
      password,
      user.passwordHash
    );

    if (!passwordMatches) {
      return res.status(401).json({
        message: "Email hoac mat khau khong chinh xac",
      });
    }

    if (!process.env.JWT_SECRET) {
      throw new Error("Thieu JWT_SECRET trong file .env");
    }

    const token = jwt.sign(
      { sub: user._id.toString() },
      process.env.JWT_SECRET,
      { expiresIn: "1d" }
    );

    return res.status(200).json({
      message: "Dang nhap thanh cong",
      token,
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        avatarUrl: user.avatarUrl,
      },
    });
  } catch (error) {
    console.error("Login error:", error.message);

    return res.status(500).json({
      message: "Khong the dang nhap",
    });
  }
}

module.exports = {
  register,
  login,
};