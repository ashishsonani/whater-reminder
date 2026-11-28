const assert = require("node:assert/strict");
const {test} = require("node:test");
const {subscriptionExpiry} = require("./play-subscriptions");

const now = Date.parse("2026-11-27T00:00:00Z");
const expiryTime = "2026-12-04T00:00:00Z";
const item = {
  productId: "water_premium",
  offerDetails: {basePlanId: "three-months"},
  expiryTime,
};

test("active, grace and canceled plans keep their verified expiry", () => {
  for (const state of ["ACTIVE", "IN_GRACE_PERIOD", "CANCELED"]) {
    const purchase = {
      subscriptionState: `SUBSCRIPTION_STATE_${state}`,
      lineItems: [item],
    };
    assert.equal(subscriptionExpiry(purchase, now), Date.parse(expiryTime));
  }
});

test("expired, on-hold and foreign plans do not unlock access", () => {
  const purchase = {subscriptionState: "SUBSCRIPTION_STATE_ON_HOLD"};
  assert.equal(subscriptionExpiry({...purchase, lineItems: [item]}, now), 0);

  purchase.subscriptionState = "SUBSCRIPTION_STATE_ACTIVE";
  purchase.lineItems = [
    {...item, productId: "unrelated"},
    {...item, offerDetails: {basePlanId: "other"}},
    {...item, expiryTime: "2026-11-26T00:00:00Z"},
  ];
  assert.equal(subscriptionExpiry(purchase, now), 0);
});
