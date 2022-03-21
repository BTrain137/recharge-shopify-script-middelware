const axiosRequest = require("../Helpers/axiosRequest");

const { RECHARGE_API_TOKEN } = process.env;

const updateSubscriptionPrice = async (subscriptionId, pricePerUnit) => {
  const query = {
    url: `https://api.rechargeapps.com/subscriptions/${subscriptionId}`,
    headers: {
      "Content-Type": "application/json",
      "X-Recharge-Access-Token": RECHARGE_API_TOKEN,
    },
    method: "PUT",
    data: {
      price: pricePerUnit,
    },
  };

  try {
    const results = await axiosRequest(query);
    return results;
  } catch (error) {
    throw error;
  }
};

module.exports = {
  updateSubscriptionPrice,
};
