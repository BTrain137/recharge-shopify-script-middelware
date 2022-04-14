var setRechargeCheckoutUrl = function(cart) {

  function checkForSubscriptionItemsInCart(item) {
    return item.properties.shipping_interval_frequency != undefined;
  }
  window.subscription_items_in_cart = cart.items.some(checkForSubscriptionItemsInCart);

  if (!window.subscription_items_in_cart) { return window.recharge_checkout_url = "/checkout"; }

  function get_cookie(name) {
    return (document.cookie.match('(^|; )' + name + '=([^;]*)') || 0)[2]
  }

  var token = get_cookie('cart');

  window.recharge_checkout_url = "https://checkout.rechargeapps.com/r/checkout?myshopify_domain=" + Shopify.shop + "&cart_token=" + token
}

setRechargeCheckoutUrl(cart)
console.log(window.recharge_checkout_url);
window.location = window.recharge_checkout_url;
