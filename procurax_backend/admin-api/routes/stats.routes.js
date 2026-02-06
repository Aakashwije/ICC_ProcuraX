const router = require("express").Router();

const Stats = require("../controllers/stats.controller");
const adminAuth = require("../middleware/adminAuth.middleware");

router.get("/", adminAuth, Stats.getStats);

module.exports = router;
