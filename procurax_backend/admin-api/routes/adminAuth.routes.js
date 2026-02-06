const router = require("express").Router();
const AdminAuth = require("../controllers/adminAuth.controller");

router.post("/login", AdminAuth.login);

module.exports = router;
