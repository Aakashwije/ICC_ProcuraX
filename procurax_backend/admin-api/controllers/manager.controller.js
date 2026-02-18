import User from "../../models/User.js";

const MANAGER_ROLE = "project_manager";

export const getManagers = async (req, res) => {
  const managers = await User.find({ role: MANAGER_ROLE }).select("-password");
  res.json(managers);
};

export const addManager = async (req, res) => {
  const { name, email, phone, isApproved, isActive } = req.body;

  const user = new User({
    email,
    password: "Temp@123",
    role: MANAGER_ROLE,
    isApproved: isApproved ?? true,
    isActive: isActive ?? true,
    phone: phone ?? "",
    name
  });

  await user.save();

  res.json({ success: true, manager: user });
};

export const updateManager = async (req, res) => {
  const { id } = req.params;
  const { name, email, phone, isApproved, isActive } = req.body;

  const manager = await User.findByIdAndUpdate(
    id,
    { name, email, phone, isApproved, isActive },
    { new: true }
  ).select("-password");

  if (!manager) {
    return res.status(404).json({ message: "Manager not found" });
  }

  res.json({ success: true, manager });
};

export const deleteManager = async (req, res) => {
  await User.findByIdAndDelete(req.params.id);
  res.json({ success: true });
};

export const toggleAccess = async (req, res) => {
  const user = await User.findById(req.params.id);

  if (!user) {
    return res.status(404).json({ message: "Manager not found" });
  }

  user.isActive = !user.isActive;

  await user.save();

  res.json({ success: true, manager: user });
};
