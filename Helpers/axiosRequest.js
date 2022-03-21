const axios = require("axios").default;

/********************************
const SHOP = "";
const ACCESS_TOKEN = "";
const exampleQuery = {
  url: `https://${SHOP}.myshopify.com/admin/api/2019-10/graphql.json`,
  headers: {
    'Content-Type': 'application/json',
    'X-Shopify-Access-Token': ACCESS_TOKEN,
  },
  method: 'POST',
  data: {
    query: query,
    variables: variables,
  },
}
*******************************/

/**
 * Post request to shopify
 *
 * @param   {Object}  query Request body
 * @param   {Number}  delay Delay of request for rapid request
 * @returns {Promise}       Promise object represents the post body
 */

 const sleep = (time) => {
	return new Promise((resolve) => {
		setTimeout(() => {
			resolve();
		}, time);
	});
}


const axiosRequest = async (query, delay = 500) => {
  try {
    const result = await axios(query);
		sleep(delay);
    return result.data;
  } catch (error) {
    console.log(error);
    throw error;
  }
};

module.exports = axiosRequest;
