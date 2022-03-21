const axiosRequest = require("../Helpers/axiosRequest");

const { ACCESS_TOKEN, SHOP, API_VERSION } = process.env;

const productTypeMatch = async (productId, productType) => {
  const query = {
    url: `https://${SHOP}.myshopify.com/admin/api/${API_VERSION}/products/${productId}.json`,
    headers: {
      "Content-Type": "application/json",
      "X-Shopify-Access-Token": ACCESS_TOKEN,
    },
    method: "GET",
  };

  try {
    const results = await axiosRequest(query);
    const { product_type } = results.product;
    const compared = product_type == productType;
    return compared;
  } catch (error) {
    throw error;
  }
};

module.exports = {
  productTypeMatch,
};
