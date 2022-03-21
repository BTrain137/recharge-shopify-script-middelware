const { Router } = require("express");
const router = Router();

// /webhook/hello-world
router.post("/", (req, res) => {
  console.log(req.body);
	console.log(`-------------------------------`);
	console.log(JSON.stringify(req.body));
  res.sendStatus(200);
});

module.exports = router;
