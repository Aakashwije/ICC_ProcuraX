import User from "../../models/User.js";

export const getManagers = async (req, res) => {
  const managers = await User.find({ role: "USER" });
  res.json(managers);
};

export const addManager = async (req, res) => {
  const { name, email, phone } = req.body;

  const user = new User({
    email,
    password: "Temp@123",
    role: "USER",
    status: "APPROVED",
    phone,
    name
  });

  await user.save();

  res.json({ success: true });
};

export const deleteManager = async (req, res) => {
  await User.findByIdAndDelete(req.params.id);
  res.json({ success: true });
};

export const toggleAccess = async (req, res) => {
  const user = await User.findById(req.params.id);

  user.status =
    user.status === "APPROVED" ? "PENDING" : "APPROVED";

  await user.save();

  res.json({ success: true });
};
