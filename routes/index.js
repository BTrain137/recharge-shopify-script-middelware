const { Router } = require("express");
const apiRoutes = require("./api");
const webhookRoutes = require("./webhook");

const router = Router();

// /api
router.use("/api", apiRoutes);

// /webhook
router.use("/webhook", webhookRoutes);

module.exports = router;
