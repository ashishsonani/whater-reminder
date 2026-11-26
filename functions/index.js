const {onSchedule} = require("firebase-functions/v2/scheduler");

// Retain the deployed function name so an update disables legacy push delivery.
exports.sendHydrationReminders = onSchedule("every 1 minutes", () => {});
