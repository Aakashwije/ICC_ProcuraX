import User from "../../models/User.js";
import * as AuthService from "../services/auth.service.js";

export const register = async (req, res) => {
  try {
    const { email, password, name } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        message: "Email and password are required"
      });
    }

    const existing = await User.findOne({ email });

    if (existing) {
      return res.status(400).json({
        message: "User already exists"
      });
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

export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email }).select("+password");

    if (!user) {
      return res.status(404).json({
        message: "User not found"
      });
    }

    const valid = await AuthService.comparePassword(
      password,
      user.password
    );

    if (!valid) {
      return res.status(401).json({
        message: "Invalid credentials"
      });
    }

    if (!user.isActive) {
      return res.status(403).json({
        message: "Account is inactive"
      });
    }

    if (!user.isApproved) {
      return res.status(403).json({
        approved: false,
        message: "Account awaiting approval"
      });
    }

    const token = AuthService.generateToken(user);

    res.json({
      success: true,
      token,
      user: {
        email: user.email,
        projectTitle: user.projectTitle,
        procurementSheetUrl: user.procurementSheetUrl
      }
    });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
