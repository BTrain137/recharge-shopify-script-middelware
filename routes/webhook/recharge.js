const { Router } = require("express");
const { updateSubscriptionPrice } = require("../../Recharge/subscriptions");
const { productTypeMatch } = require("../../Shopify/products");
const router = Router();

const tiers = [
  {
    unit_size: 0,
    discount_amount: 14.95,
  },
  {
    unit_size: 1,
    discount_amount: 14.95,
  },
  {
    unit_size: 2,
    discount_amount: 14.95,
  },
  {
    unit_size: 3,
    discount_amount: 12.65,
  },
  {
    unit_size: 4,
    discount_amount: 12.7,
  },
  {
    unit_size: 5,
    discount_amount: 12.7,
  },
  {
    unit_size: 6,
    discount_amount: 11.16,
  },
  {
    unit_size: 7,
    discount_amount: 11.21,
  },
  {
    unit_size: 8,
    discount_amount: 11.21,
  },
  {
    unit_size: 9,
    discount_amount: 11.21,
  },
  {
    unit_size: 10,
    discount_amount: 10.49,
  },
  {
    unit_size: 11,
    discount_amount: 10.46,
  },
  {
    unit_size: 12,
    discount_amount: 10.41,
  },
];

// /webhook/recharge/order-created
router.post("/order-created", async (req, res) => {
  const { order } = req.body;
  const { tags, line_items, shopify_order_number } = order;
  console.log("+++++++++++++++++++++++++++++++++++");
  console.log("++++++++++++++Start++++++++++++++++");
  console.log("shopify_order_number", shopify_order_number);
  if (tags.includes("Subscription First Order")) {
    const eligibleItems = [];
    for (let i = 0; i < line_items.length; i++) {
      const line_item = line_items[i];
      const { shopify_product_id, subscription_id, quantity, price, sku } =
        line_item;
      const isNewLine = await productTypeMatch(shopify_product_id, "2022");
      if (isNewLine) {
        const [, , bars] = sku.split("/");
        const units = bars / 5;
        eligibleItems.push({
          shopify_product_id,
          subscription_id,
          quantity,
          price,
          sku,
          units,
        });
      }
    }
    if (eligibleItems.length === 0) {
      return;
    }
    const grandTotalBars = eligibleItems.reduce((acc, item) => {
      const { sku, quantity } = item;
      const [, , bars] = sku.split("/");
      const totalBars = +bars * quantity;
      return acc + totalBars;
    }, 0);
    const totalUnits = grandTotalBars / 5;
    const discountTiers = tiers[totalUnits]
      ? tiers[totalUnits]
      : { discount_amount: 10.41 };
    const pricePerUnit = discountTiers.discount_amount;

    console.log("grandTotalBars", grandTotalBars);
    console.log("pricePerUnit", pricePerUnit);

    for (let j = 0; j < eligibleItems.length; j++) {
      const item = eligibleItems[j];
      const { subscription_id, units } = item;
      const totalLineItemPrice = pricePerUnit * units;
      const results = await updateSubscriptionPrice(
        subscription_id,
        totalLineItemPrice
      );
      const { product_title } = results.subscription;
      console.log(`#${j}`, product_title);
    }
  } else {
    console.log("Don't Process");
  }
  console.log("++++++++++++++END++++++++++++++++");
  console.log("+++++++++++++++++++++++++++++++++");
  res.sendStatus(200);
});

module.exports = router;
