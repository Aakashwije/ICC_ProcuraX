import { Router } from "express";
import { login, register } from "../controllers/auth.controller.js";
import { forgotPassword, verifyOTP, resetPassword } from "../controllers/password.controller.js";
import { registerFcmToken, unregisterFcmToken } from "../controllers/fcm.controller.js";
import { authMiddleware } from "../../core/middleware/auth.middleware.js";

const router = Router();

router.post("/register", register);
router.post("/login", login);
router.post("/forgot-password", forgotPassword);
router.post("/verify-otp", verifyOTP);
router.post("/reset-password", resetPassword);

// FCM token management (requires authentication)
router.post("/fcm-token", authMiddleware, registerFcmToken);
router.delete("/fcm-token", authMiddleware, unregisterFcmToken);

export default router;
