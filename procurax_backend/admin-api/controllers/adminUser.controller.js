import User from "../../models/User.js";

export const getUsers = async (req, res) => {
  try {
    const { approved } = req.query;
    const filter = {};

    if (approved === "true") {
      filter.isApproved = true;
    } else if (approved === "false") {
      filter.isApproved = false;
    }

    const users = await User.find(filter)
      .select("-password")
      .sort({ createdAt: -1 });

    res.json({ success: true, users });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const approveUser = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findByIdAndUpdate(
      id,
      { isApproved: true },
      { new: true }
    ).select("-password");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json({ success: true, user });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const rejectUser = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findByIdAndUpdate(
      id,
      { isApproved: false, isActive: false },
      { new: true }
    ).select("-password");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json({ success: true, user });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
