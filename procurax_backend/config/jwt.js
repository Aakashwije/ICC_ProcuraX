import jwt from "jsonwebtoken";

export const secret = process.env.JWT_SECRET || "change_me";

export const generateToken = (userId) => {
  return jwt.sign(
    { id: userId },
    secret,
    {
      expiresIn: process.env.JWT_EXPIRE || "7d"
    }
  );
};

export const verifyToken = (token) => {
  return jwt.verify(token, secret);
};
