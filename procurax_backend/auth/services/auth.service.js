import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { secret } from "../../config/jwt.js";

export const hashPassword = async (password) => {
  return await bcrypt.hash(password, 10);
};

export const comparePassword = async (password, hash) => {
  return await bcrypt.compare(password, hash);
};

export const generateToken = (user) => {
  return jwt.sign({ id: user._id, role: user.role }, secret);
};
