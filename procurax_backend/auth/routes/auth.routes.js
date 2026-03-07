import { Router } from "express";
import { login, register } from "../controllers/auth.controller.js";
import { forgotPassword, verifyOTP, resetPassword } from "../controllers/password.controller.js";

const router = Router();

router.post("/register", register);
router.post("/login", login);
router.post("/forgot-password", forgotPassword);
router.post("/verify-otp", verifyOTP);
router.post("/reset-password", resetPassword);

export default router;
