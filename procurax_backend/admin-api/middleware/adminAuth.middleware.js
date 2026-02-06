const jwt = require("jsonwebtoken");
const config = require("../../config/jwt");

module.exports = function (req, res, next) {
  const token = req.headers["authorization"];

  if (!token) {
    return res.status(401).json({
      message: "No token"
    });
  }

  try {
    const decoded = jwt.verify(token, config.secret);

    if (decoded.role !== "ADMIN") {
      return res.status(403).json({
        message: "Admins only"
      });
    }

    req.admin = decoded;
    next();

  } catch (error) {
    res.status(401).json({
      message: "Invalid token"
    });
  }
};
