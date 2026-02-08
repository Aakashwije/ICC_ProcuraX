import jwt from "jsonwebtoken";

const secret = process.env.JWT_SECRET || "change_me";

export const generateToken = (userId) => {
  return jwt.sign(
    { id: userId },
    secret,
    { expiresIn: process.env.JWT_EXPIRE || "7d" }
  );
};
