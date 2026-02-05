const User = require("../../models/User");

exports.getProfile = async (req, res) => {
  const user = await User.findById(req.user.id);

  res.json({
    email: user.email,
    projectTitle: user.projectTitle,
    procurementSheetUrl: user.procurementSheetUrl
  });
};
