const { Router } = require("express");
const router = Router();

// /webhook/hello-world
router.post("/", (req, res) => {
  console.log(req.body);
  res.sendStatus(200);
});

module.exports = router;
