import mongoose from "mongoose";

const FALLBACK_USER_ID = new mongoose.Types.ObjectId("000000000000000000000001");

const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization || "";
  const [, token] = authHeader.split(" ");

  if (token && mongoose.isValidObjectId(token)) {
    req.userId = token;
    return next();
  }

  req.userId = FALLBACK_USER_ID;
  return next();
};

export default authMiddleware;
