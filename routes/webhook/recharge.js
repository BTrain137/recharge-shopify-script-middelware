const { Router } = require("express");
const { productTypeMatch } = require("../../Shopify/products");
const router = Router();

// /webhook/recharge/order-created
router.post("/order-created", async (req, res) => {
  const { order } = req.body;
  const { tags, line_items } = order;
  if (tags.includes("Subscription First Order")) {
		const eligibleItems = [];
    for (let i = 0; i < line_items.length; i++) {
      const line_item = line_items[i];
      const { shopify_product_id, subscription_id, quantity, price, sku } =
        line_item;
       const isNewLine = await productTypeMatch(shopify_product_id, "2022");
			 if (isNewLine) {
				eligibleItems.push({ shopify_product_id, subscription_id, quantity, price, sku });
			 }
    }
  } else {
    console.log("Don't Process");
  }
  res.sendStatus(200);
});

module.exports = router;
