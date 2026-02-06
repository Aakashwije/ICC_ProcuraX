const User = require("../../models/User");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const config = require("../../config/jwt");

exports.login = async (req, res) => {
  const { email, password } = req.body;

  const admin = await User.findOne({ email });

  if (!admin || admin.role !== "ADMIN") {
    return res.status(403).json({
      message: "Admin access only"
    });
  }

  const valid = await bcrypt.compare(password, admin.password);

  if (!valid) {
    return res.status(401).json({
      message: "Invalid credentials"
    });
  }

  const token = jwt.sign(
    { id: admin._id, role: "ADMIN" },
    config.secret
  );

  res.json({
    success: true,
    token
  });
};
