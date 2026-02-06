const router = require("express").Router();

const Project = require("../controllers/project.controller");
const adminAuth = require("../middleware/adminAuth.middleware");

router.get("/", adminAuth, Project.getProjects);
router.post("/", adminAuth, Project.addProject);
router.post("/assign", adminAuth, Project.assignManager);
router.delete("/:id", adminAuth, Project.deleteProject);

module.exports = router;
