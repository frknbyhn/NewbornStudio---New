// Mirrors DECISIONS.md's monetization table. Subscriptions grant a recurring credit allowance;
// consumable packs grant a one-time amount. Keep in sync with the real App Store Connect / RevenueCat products.
const GRANTS = {
  "com.babycollages.weekly": { kind: "subscription", credits: 10 },
  "com.babycollages.monthly": { kind: "subscription", credits: 50 },
  "com.babycollages.yearly": { kind: "subscription", credits: 500 },
  "com.babycollages.small": { kind: "consumable", credits: 5 },
  "com.babycollages.limited": { kind: "consumable", credits: 25 },
  "com.babycollages.medium": { kind: "consumable", credits: 15 },
  "com.babycollages.big": { kind: "consumable", credits: 50 },
};

module.exports = { GRANTS };
