import User from "../../models/User.js";
import * as AuthService from "../services/auth.service.js";
import { syncUserToFirestore } from "../../config/firebase.js";

/* ─────────────────────────────────────────────────────────────────────────
   checkUserApproval
   Returns an error response if the user is not approved or active.
   Returns null if the user is allowed to proceed.
────────────────────────────────────────────────────────────────────────── */
function checkUserApproval(user, res) {
  if (!user.isActive) {
    res.status(403).json({ message: "Account is inactive. Contact admin." });
    return false;
  }
  if (!user.isApproved) {
    res.status(403).json({
      approved: false,
      message: "Your account is pending admin approval. Please wait for the admin to approve your account."
    });
    return false;
  }
  return true;
}

/* ─────────────────────────────────────────────────────────────────────────
   register
────────────────────────────────────────────────────────────────────────── */
export const register = async (req, res) => {
  try {
    const { email, password, name } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "Email and password are required" });
    }

    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(400).json({ message: "User already exists" });
    }

    const user = new User({
      name: name?.trim() || email.split("@")[0],
      email,
      password
    });

    await user.save();

    res.json({
      success: true,
      message: "Account created. Await admin approval."
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

/* ─────────────────────────────────────────────────────────────────────────
   login
────────────────────────────────────────────────────────────────────────── */
export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email }).select("+password");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const valid = await AuthService.comparePassword(password, user.password);
    if (!valid) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    /* Approval gate — blocks unapproved / inactive users */
    if (!checkUserApproval(user, res)) return;

    const token = AuthService.generateToken(user);

    /* Update last login timestamp */
    await User.findByIdAndUpdate(user._id, { lastLogin: new Date() });

    /* Sync user profile to Firestore so data is always up-to-date in the cloud */
    await syncUserToFirestore(user._id.toString(), {
      name: user.name,
      email: user.email,
      role: user.role,
      isApproved: user.isApproved,
      googleSheetUrl: user.googleSheetUrl ?? null,
      lastLogin: new Date().toISOString()
    });

    res.json({
      success: true,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        googleSheetUrl: user.googleSheetUrl ?? null
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
