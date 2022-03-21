const { Router } = require("express");
const helloWorld = require("./hello-world.js");

const router = Router();

// Test Route
// /webhook/
router.use("/hello-world", helloWorld);

module.exports = router;
