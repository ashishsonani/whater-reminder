const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {GoogleAuth} = require("google-auth-library");

const packageName = "com.sarang.waterreminder";
const productId = "water_premium";
const basePlans = new Set(["monthly", "three-months", "six-months"]);
const entitled = new Set([
  "SUBSCRIPTION_STATE_ACTIVE",
  "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
  "SUBSCRIPTION_STATE_CANCELED",
]);
const publisher = new GoogleAuth({
  scopes: ["https://www.googleapis.com/auth/androidpublisher"],
});

/**
 * Returns the latest valid expiration for a verified Play subscription.
 * @param {Object} purchase Google Play's SubscriptionPurchaseV2.
 * @param {number} now Current UTC timestamp in milliseconds.
 * @return {number} Expiration in milliseconds, or zero.
 */
function subscriptionExpiry(purchase, now) {
  if (!entitled.has(purchase.subscriptionState)) return 0;
  let expiry = 0;
  for (const item of purchase.lineItems || []) {
    const details = item.offerDetails || {};
    if (item.productId !== productId || !basePlans.has(details.basePlanId)) {
      continue;
    }
    const end = Date.parse(item.expiryTime);
    if (end > now && end > expiry) expiry = end;
  }
  return expiry;
}

const verifyHydrationSubscription = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign-in is required.");
  }
  if (process.env.PLAY_BILLING_ENABLED !== "true") {
    throw new HttpsError("failed-precondition", "Billing is not available.");
  }
  const token = request.data && request.data.purchaseToken;
  if (request.data && request.data.checkOnly === true && token === undefined) {
    return {ready: true};
  }
  if (typeof token !== "string" || token.length < 16 || token.length > 4096) {
    throw new HttpsError("invalid-argument", "Invalid purchase token.");
  }

  const url = "https://androidpublisher.googleapis.com/androidpublisher/v3" +
    `/applications/${packageName}/purchases/subscriptionsv2/tokens/` +
    encodeURIComponent(token);
  try {
    const client = await publisher.getClient();
    const response = await client.request({url, timeout: 10000});
    return {expiresAt: subscriptionExpiry(response.data, Date.now())};
  } catch (error) {
    const status = error.response && error.response.status;
    if (status === 404 || status === 410) return {expiresAt: 0};
    // Publisher exceptions can include the token in their URL.
    throw new HttpsError("unavailable", "Could not verify with Google Play.");
  }
});

module.exports = {verifyHydrationSubscription, subscriptionExpiry};
