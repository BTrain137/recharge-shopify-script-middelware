const { Router } = require("express");
const helloWorld = require("./hello-world.js");
const recharge = require("./recharge.js");

const router = Router();

// Test Route
// /webhook/
router.use("/hello-world", helloWorld);
router.use("/recharge", recharge);

module.exports = router;
