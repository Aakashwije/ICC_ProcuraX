const User = require("../../models/User");

exports.getManagers = async (req, res) => {
  const managers = await User.find({ role: "USER" });
  res.json(managers);
};

exports.addManager = async (req, res) => {
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

exports.deleteManager = async (req, res) => {
  await User.findByIdAndDelete(req.params.id);
  res.json({ success: true });
};

exports.toggleAccess = async (req, res) => {
  const user = await User.findById(req.params.id);

  user.status =
    user.status === "APPROVED" ? "PENDING" : "APPROVED";

  await user.save();

  res.json({ success: true });
};
