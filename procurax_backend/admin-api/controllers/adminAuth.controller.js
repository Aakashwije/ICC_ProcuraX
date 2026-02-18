import User from "../../models/User.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { secret } from "../../config/jwt.js";

export const login = async (req, res) => {
  const { email, password } = req.body;

  const admin = await User.findOne({ email }).select("+password");

  if (!admin || admin.role !== "admin") {
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

  const token = jwt.sign({ id: admin._id, role: "admin" }, secret);

  res.json({
    success: true,
    token
  });
};
