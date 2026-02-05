const router = require("express").Router();

const Manager = require("../controllers/manager.controller");
const adminAuth = require("../middleware/adminAuth.middleware");

router.get("/", adminAuth, Manager.getManagers);
router.post("/", adminAuth, Manager.addManager);
router.delete("/:id", adminAuth, Manager.deleteManager);
router.post("/toggle/:id", adminAuth, Manager.toggleAccess);

module.exports = router;
