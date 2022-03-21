const { Router } = require("express");
const router = Router();

// /api/hello-world
router.get("/", (_, res) => {
  res.json({ Hello: "world" });
});

module.exports = router;
