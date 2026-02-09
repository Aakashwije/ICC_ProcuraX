const router = require("express").Router();
const {
  createMeeting,
  getMeetings,
  updateMeeting,
  deleteMeeting
} = require("../controllers/meetingController");

const { protect } = require("../middleware/authMiddleware");

router.use(protect);

router.route("/")
  .post(createMeeting)
  .get(getMeetings);

router.route("/:id")
  .put(updateMeeting)
  .delete(deleteMeeting);

module.exports = router;
