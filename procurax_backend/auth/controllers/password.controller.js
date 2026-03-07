import crypto from "node:crypto";
import User from "../../models/User.js";
import * as AuthService from "../services/auth.service.js";
import { sendMail } from "../../config/mailer.js";

/* ═══════════════════════════════════════════════════════════════════════
   PRODUCTION-LEVEL PASSWORD RESET SYSTEM — ProcuraX
   ─────────────────────────────────────────────────────────────────────
   Security features:
    • OTP hashed with bcrypt before storage
    • Rate limiting — max 3 reset requests per 15 minutes
    • OTP attempt tracking — max 5 wrong attempts → 30-min lockout
    • Account lockout notification email
    • Uniform responses to prevent email enumeration
    • Password strength validation (8 chars, upper, lower, digit, special)
    • Input sanitisation
    • OTP expires in 10 minutes
   ═══════════════════════════════════════════════════════════════════════ */

// ── Constants ──
const OTP_EXPIRY_MINUTES = 10;
const MAX_OTP_ATTEMPTS = 5;
const LOCKOUT_MINUTES = 30;
const MAX_RESET_REQUESTS = 3;
const RATE_LIMIT_WINDOW_MINUTES = 15;
const MIN_PASSWORD_LENGTH = 8;

/* ─────────────────────────────────────────────────────────────────────────
   Helpers
────────────────────────────────────────────────────────────────────────── */
function generateOTP() {
  return crypto.randomInt(100000, 999999).toString();
}

function sanitizeEmail(email) {
  if (typeof email !== "string") return "";
  return email.trim().toLowerCase().slice(0, 254); // RFC 5321 max
}

function validatePasswordStrength(password) {
  const issues = [];
  if (password.length < MIN_PASSWORD_LENGTH)
    issues.push(`at least ${MIN_PASSWORD_LENGTH} characters`);
  if (!/[A-Z]/.test(password)) issues.push("an uppercase letter");
  if (!/[a-z]/.test(password)) issues.push("a lowercase letter");
  if (!/\d/.test(password)) issues.push("a number");
  if (!/[!@#$%^&*(),.?":{}|<>]/.test(password))
    issues.push("a special character");
  return issues;
}

function getOTPEmailHTML(otp, userName) {
  return `
    <div style="font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;max-width:520px;margin:0 auto;padding:0;background:#ffffff;border-radius:16px;overflow:hidden;border:1px solid #e5e7eb">
      <!-- Header -->
      <div style="background:linear-gradient(135deg,#1F4DF0,#1F4CCF);padding:32px 24px;text-align:center">
        <h1 style="color:#ffffff;margin:0;font-size:28px;font-weight:700;letter-spacing:0.5px">ProcuraX</h1>
        <p style="color:rgba(255,255,255,0.85);margin:6px 0 0;font-size:13px;font-weight:500">Secure Password Reset</p>
      </div>

      <!-- Body -->
      <div style="padding:32px 28px">
        <p style="color:#1B1E29;font-size:16px;line-height:1.6;margin:0 0 8px">
          Hi <strong>${userName || "there"}</strong>,
        </p>
        <p style="color:#4B5563;font-size:14px;line-height:1.7;margin:0 0 24px">
          We received a request to reset your ProcuraX account password. Use the verification code below to continue:
        </p>

        <!-- OTP Box -->
        <div style="text-align:center;margin:28px 0">
          <div style="display:inline-block;background:#F0F4FF;border:2px dashed #1F4DF0;border-radius:14px;padding:18px 36px">
            <span style="color:#1F4DF0;font-size:38px;font-weight:800;letter-spacing:12px;font-family:'Courier New',monospace">${otp}</span>
          </div>
        </div>

        <p style="color:#6B7280;font-size:13px;text-align:center;margin:0 0 24px">
          ⏱ This code expires in <strong>${OTP_EXPIRY_MINUTES} minutes</strong>
        </p>

        <!-- Security Notice -->
        <div style="background:#FEF3C7;border-left:4px solid #F59E0B;padding:14px 16px;border-radius:0 8px 8px 0;margin:24px 0">
          <p style="color:#92400E;font-size:13px;margin:0;line-height:1.6">
            🔒 <strong>Security Tip:</strong> Never share this code with anyone. ProcuraX staff will never ask for your verification code.
          </p>
        </div>

        <hr style="border:none;border-top:1px solid #F3F4F6;margin:24px 0"/>
        <p style="color:#9CA3AF;font-size:12px;text-align:center;margin:0;line-height:1.6">
          If you didn't request a password reset, you can safely ignore this email.<br/>
          Your password will remain unchanged.
        </p>
      </div>

      <!-- Footer -->
      <div style="background:#F9FAFB;padding:16px 24px;text-align:center;border-top:1px solid #F3F4F6">
        <p style="color:#9CA3AF;font-size:11px;margin:0">
          © ${new Date().getFullYear()} ProcuraX • Secure Construction Management
        </p>
      </div>
    </div>
  `;
}

function getLockoutEmailHTML(userName, lockoutMinutes) {
  return `
    <div style="font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;max-width:520px;margin:0 auto;padding:0;background:#ffffff;border-radius:16px;overflow:hidden;border:1px solid #e5e7eb">
      <div style="background:linear-gradient(135deg,#DC2626,#B91C1C);padding:32px 24px;text-align:center">
        <h1 style="color:#ffffff;margin:0;font-size:28px;font-weight:700">ProcuraX</h1>
        <p style="color:rgba(255,255,255,0.85);margin:6px 0 0;font-size:13px;font-weight:500">Security Alert</p>
      </div>
      <div style="padding:32px 28px">
        <p style="color:#1B1E29;font-size:16px;line-height:1.6;margin:0 0 8px">
          Hi <strong>${userName || "there"}</strong>,
        </p>
        <p style="color:#4B5563;font-size:14px;line-height:1.7;margin:0 0 16px">
          We detected multiple failed attempts to verify a password reset code on your ProcuraX account. 
          For your security, password reset has been <strong>temporarily locked for ${lockoutMinutes} minutes</strong>.
        </p>
        <div style="background:#FEF2F2;border-left:4px solid #DC2626;padding:14px 16px;border-radius:0 8px 8px 0;margin:20px 0">
          <p style="color:#991B1B;font-size:13px;margin:0;line-height:1.6">
            ⚠️ If this wasn't you, please secure your email account immediately and contact support.
          </p>
        </div>
        <hr style="border:none;border-top:1px solid #F3F4F6;margin:24px 0"/>
        <p style="color:#9CA3AF;font-size:12px;text-align:center;margin:0">
          © ${new Date().getFullYear()} ProcuraX • Secure Construction Management
        </p>
      </div>
    </div>
  `;
}

/* ─────────────────────────────────────────────────────────────────────────
   POST /auth/forgot-password
   Body: { email }
   Sends a 6-digit OTP to the user's email.
   ─ Rate limited: max 3 requests per 15 minutes
────────────────────────────────────────────────────────────────────────── */
export const forgotPassword = async (req, res) => {
  try {
    const email = sanitizeEmail(req.body.email);
    if (!email?.includes("@")) {
      return res.status(400).json({
        success: false,
        code: "INVALID_EMAIL",
        message: "A valid email address is required.",
      });
    }

    // Uniform success response (prevents email enumeration)
    const uniformResponse = {
      success: true,
      code: "OTP_SENT",
      message: "If an account with that email exists, a reset code has been sent.",
      expiresIn: OTP_EXPIRY_MINUTES,
    };

    const user = await User.findOne({ email }).select(
      "+resetPasswordOTP +resetPasswordExpiry +resetPasswordAttempts +resetPasswordLockedUntil +lastResetRequestAt +resetRequestCount"
    );

    if (!user) {
      return res.json(uniformResponse); // don't reveal non-existence
    }

    // ── Check lockout ──
    if (user.resetPasswordLockedUntil && new Date() < user.resetPasswordLockedUntil) {
      const remaining = Math.ceil((user.resetPasswordLockedUntil - Date.now()) / 60000);
      return res.status(429).json({
        success: false,
        code: "ACCOUNT_LOCKED",
        message: `Too many failed attempts. Try again in ${remaining} minute${remaining === 1 ? "" : "s"}.`,
        retryAfter: remaining,
      });
    }

    // ── Rate limiting: max requests per window ──
    const now = new Date();
    const windowStart = new Date(now.getTime() - RATE_LIMIT_WINDOW_MINUTES * 60 * 1000);

    if (user.lastResetRequestAt && user.lastResetRequestAt > windowStart) {
      // Within the rate limit window
      if (user.resetRequestCount >= MAX_RESET_REQUESTS) {
        return res.status(429).json({
          success: false,
          code: "RATE_LIMITED",
          message: `Too many reset requests. Please wait ${RATE_LIMIT_WINDOW_MINUTES} minutes before trying again.`,
          retryAfter: RATE_LIMIT_WINDOW_MINUTES,
        });
      }
      user.resetRequestCount += 1;
    } else {
      // New window
      user.resetRequestCount = 1;
    }

    const otp = generateOTP();
    const expiry = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

    user.resetPasswordOTP = await AuthService.hashPassword(otp);
    user.resetPasswordExpiry = expiry;
    user.resetPasswordAttempts = 0; // reset attempt counter on new OTP
    user.lastResetRequestAt = now;
    await user.save({ validateBeforeSave: false });

    // ── Send email ──
    await sendMail({
      to: user.email,
      subject: "ProcuraX — Your Password Reset Code",
      html: getOTPEmailHTML(otp, user.name),
    });

    res.json(uniformResponse);
  } catch (error) {
    console.error("Forgot password error:", error);
    res.status(500).json({
      success: false,
      code: "SERVER_ERROR",
      message: "Failed to process request. Please try again later.",
    });
  }
};

/* ─────────────────────────────────────────────────────────────────────────
   POST /auth/verify-otp
   Body: { email, otp }
   Verifies OTP — tracks attempts, locks out after max failures.
────────────────────────────────────────────────────────────────────────── */
export const verifyOTP = async (req, res) => {
  try {
    const email = sanitizeEmail(req.body.email);
    const otp = (req.body.otp || "").toString().trim();

    if (!email || !otp) {
      return res.status(400).json({
        success: false,
        code: "MISSING_FIELDS",
        message: "Email and verification code are required.",
      });
    }

    const user = await User.findOne({ email }).select(
      "+resetPasswordOTP +resetPasswordExpiry +resetPasswordAttempts +resetPasswordLockedUntil"
    );

    if (!user || !user.resetPasswordOTP || !user.resetPasswordExpiry) {
      return res.status(400).json({
        success: false,
        code: "NO_RESET_REQUEST",
        message: "No reset request found. Please request a new code.",
      });
    }

    // ── Check lockout ──
    if (user.resetPasswordLockedUntil && new Date() < user.resetPasswordLockedUntil) {
      const remaining = Math.ceil((user.resetPasswordLockedUntil - Date.now()) / 60000);
      return res.status(429).json({
        success: false,
        code: "ACCOUNT_LOCKED",
        message: `Account is temporarily locked. Try again in ${remaining} minute${remaining === 1 ? "" : "s"}.`,
        retryAfter: remaining,
      });
    }

    // ── Check expiry ──
    if (new Date() > user.resetPasswordExpiry) {
      return res.status(400).json({
        success: false,
        code: "OTP_EXPIRED",
        message: "Reset code has expired. Please request a new one.",
      });
    }

    // ── Validate OTP ──
    const valid = await AuthService.comparePassword(otp, user.resetPasswordOTP);
    if (!valid) {
      user.resetPasswordAttempts = (user.resetPasswordAttempts || 0) + 1;
      const remaining = MAX_OTP_ATTEMPTS - user.resetPasswordAttempts;

      // ── Lock account after max attempts ──
      if (user.resetPasswordAttempts >= MAX_OTP_ATTEMPTS) {
        user.resetPasswordLockedUntil = new Date(Date.now() + LOCKOUT_MINUTES * 60 * 1000);
        user.resetPasswordOTP = null;
        user.resetPasswordExpiry = null;
        user.resetPasswordAttempts = 0;
        await user.save({ validateBeforeSave: false });

        // Send lockout notification email (fire & forget)
        sendMail({
          to: user.email,
          subject: "ProcuraX — Security Alert: Account Temporarily Locked",
          html: getLockoutEmailHTML(user.name, LOCKOUT_MINUTES),
        }).catch((err) => console.error("Lockout email failed:", err));

        return res.status(429).json({
          success: false,
          code: "ACCOUNT_LOCKED",
          message: `Too many failed attempts. Reset has been locked for ${LOCKOUT_MINUTES} minutes.`,
          retryAfter: LOCKOUT_MINUTES,
        });
      }

      await user.save({ validateBeforeSave: false });

      return res.status(400).json({
        success: false,
        code: "INVALID_OTP",
        message: `Invalid code. ${remaining} attempt${remaining === 1 ? "" : "s"} remaining.`,
        attemptsRemaining: remaining,
      });
    }

    // OTP is valid — reset attempt counter (don't clear OTP yet, needed for reset-password)
    user.resetPasswordAttempts = 0;
    await user.save({ validateBeforeSave: false });

    res.json({
      success: true,
      code: "OTP_VERIFIED",
      message: "Code verified successfully. You can now set your new password.",
    });
  } catch (error) {
    console.error("Verify OTP error:", error);
    res.status(500).json({
      success: false,
      code: "SERVER_ERROR",
      message: "Verification failed. Please try again.",
    });
  }
};

/* ─────────────────────────────────────────────────────────────────────────
   POST /auth/reset-password
   Body: { email, otp, newPassword }
   Verifies OTP and sets a new password with strength validation.
────────────────────────────────────────────────────────────────────────── */
export const resetPassword = async (req, res) => {
  try {
    const email = sanitizeEmail(req.body.email);
    const otp = (req.body.otp || "").toString().trim();
    const newPassword = req.body.newPassword || "";

    if (!email || !otp || !newPassword) {
      return res.status(400).json({
        success: false,
        code: "MISSING_FIELDS",
        message: "Email, verification code, and new password are required.",
      });
    }

    // ── Password strength validation ──
    const passwordIssues = validatePasswordStrength(newPassword);
    if (passwordIssues.length > 0) {
      return res.status(400).json({
        success: false,
        code: "WEAK_PASSWORD",
        message: `Password must contain ${passwordIssues.join(", ")}.`,
        requirements: passwordIssues,
      });
    }

    const user = await User.findOne({ email }).select(
      "+resetPasswordOTP +resetPasswordExpiry +resetPasswordAttempts +resetPasswordLockedUntil +password"
    );

    if (!user || !user.resetPasswordOTP || !user.resetPasswordExpiry) {
      return res.status(400).json({
        success: false,
        code: "NO_RESET_REQUEST",
        message: "No reset request found. Please request a new code.",
      });
    }

    // ── Check lockout ──
    if (user.resetPasswordLockedUntil && new Date() < user.resetPasswordLockedUntil) {
      const remaining = Math.ceil((user.resetPasswordLockedUntil - Date.now()) / 60000);
      return res.status(429).json({
        success: false,
        code: "ACCOUNT_LOCKED",
        message: `Account is temporarily locked. Try again in ${remaining} minute${remaining === 1 ? "" : "s"}.`,
        retryAfter: remaining,
      });
    }

    // ── Check expiry ──
    if (new Date() > user.resetPasswordExpiry) {
      return res.status(400).json({
        success: false,
        code: "OTP_EXPIRED",
        message: "Reset code has expired. Please request a new one.",
      });
    }

    // ── Validate OTP ──
    const valid = await AuthService.comparePassword(otp, user.resetPasswordOTP);
    if (!valid) {
      user.resetPasswordAttempts = (user.resetPasswordAttempts || 0) + 1;

      if (user.resetPasswordAttempts >= MAX_OTP_ATTEMPTS) {
        user.resetPasswordLockedUntil = new Date(Date.now() + LOCKOUT_MINUTES * 60 * 1000);
        user.resetPasswordOTP = null;
        user.resetPasswordExpiry = null;
        user.resetPasswordAttempts = 0;
        await user.save({ validateBeforeSave: false });

        return res.status(429).json({
          success: false,
          code: "ACCOUNT_LOCKED",
          message: `Too many failed attempts. Reset locked for ${LOCKOUT_MINUTES} minutes.`,
          retryAfter: LOCKOUT_MINUTES,
        });
      }

      await user.save({ validateBeforeSave: false });
      return res.status(400).json({
        success: false,
        code: "INVALID_OTP",
        message: "Invalid verification code.",
      });
    }

    // ── Check if new password is the same as old ──
    const isSamePassword = await AuthService.comparePassword(newPassword, user.password);
    if (isSamePassword) {
      return res.status(400).json({
        success: false,
        code: "SAME_PASSWORD",
        message: "New password cannot be the same as your current password.",
      });
    }

    // ── Set the new password ──
    user.password = newPassword;
    user.resetPasswordOTP = null;
    user.resetPasswordExpiry = null;
    user.resetPasswordAttempts = 0;
    user.resetPasswordLockedUntil = null;
    user.resetRequestCount = 0;
    await user.save();

    res.json({
      success: true,
      code: "PASSWORD_RESET",
      message: "Password reset successfully. You can now log in with your new password.",
    });
  } catch (error) {
    console.error("Reset password error:", error);
    res.status(500).json({
      success: false,
      code: "SERVER_ERROR",
      message: "Password reset failed. Please try again.",
    });
  }
};
