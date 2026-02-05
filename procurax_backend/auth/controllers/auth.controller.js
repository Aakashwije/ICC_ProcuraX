const User = require("../../models/User");
const AuthService = require("../services/auth.service");

exports.register = async (req, res) => {
  try {
    const { email, password } = req.body;

    const existing = await User.findOne({ email });

    if (existing) {
      return res.status(400).json({
        message: "User already exists"
      });
    }

    const hashed = await AuthService.hashPassword(password);

    const user = new User({
      email,
      password: hashed
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

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });

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

    if (user.status !== "APPROVED") {
      return res.status(403).json({
        status: user.status,
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
