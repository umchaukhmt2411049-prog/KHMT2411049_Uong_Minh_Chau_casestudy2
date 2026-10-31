const jwt = require("jsonwebtoken");

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({
      message: "Vui long dang nhap",
    });
  }

  const token = authHeader.slice(7).trim();

  try {
    if (!process.env.JWT_SECRET) {
      return res.status(500).json({
        message: "Server chua cau hinh JWT_SECRET",
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    if (!decoded.sub) {
      return res.status(401).json({
        message: "Token khong hop le",
      });
    }

    req.userId = decoded.sub;
    next();
  } catch (error) {
    return res.status(401).json({
      message: "Token khong hop le hoac da het han",
    });
  }
}

module.exports = authMiddleware;