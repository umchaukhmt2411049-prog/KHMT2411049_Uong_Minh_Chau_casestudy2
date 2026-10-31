const express = require("express");
const { body } = require("express-validator");
const {
  register,
  login,
} = require("../controllers/authController");

const router = express.Router();

router.post(
  "/register",
  [
    body("fullName")
      .isString()
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage("Ho ten phai co tu 2 den 100 ky tu"),

    body("email")
      .isEmail()
      .normalizeEmail()
      .withMessage("Email khong hop le"),

    body("password")
      .isString()
      .isLength({ min: 8, max: 72 })
      .withMessage("Mat khau phai co tu 8 den 72 ky tu"),
  ],
  register
);

router.post(
  "/login",
  [
    body("email")
      .isEmail()
      .withMessage("Email khong hop le"),

    body("password")
      .isString()
      .notEmpty()
      .withMessage("Mat khau khong duoc de trong"),
  ],
  login
);

module.exports = router;