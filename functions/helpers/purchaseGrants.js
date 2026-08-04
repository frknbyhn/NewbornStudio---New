// Mirrors DECISIONS.md's monetization table. Subscriptions grant a recurring credit allowance;
// consumable packs grant a one-time amount. Keep in sync with the real App Store Connect / RevenueCat products.
const GRANTS = {
  "com.newborn.weekly": { kind: "subscription", credits: 10 },
  "com.newborn.monthly": { kind: "subscription", credits: 50 },
  "com.newborn.yearly": { kind: "subscription", credits: 500 },
  "com.newborn.small": { kind: "consumable", credits: 5 },
  "com.newborn.limited": { kind: "consumable", credits: 25 },
  "com.newborn.medium": { kind: "consumable", credits: 15 },
  "com.newborn.big": { kind: "consumable", credits: 50 },
};

module.exports = { GRANTS };
