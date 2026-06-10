const {onSchedule} = require("firebase-functions/v2/scheduler");
const {setGlobalOptions} = require("firebase-functions");
const admin = require("firebase-admin");
const {FieldValue} = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

admin.initializeApp();

// Configuration for scheduled runs
setGlobalOptions({maxInstances: 20, timeoutSeconds: 60});

const NOTIFICATIONS = [
  {
    en: {
      title: "Good Morning! ✨",
      body: "Wake up your metabolism with a glass before coffee. " +
            "Your body is thirsty after 8 hours! 💧",
    },
    tr: {
      title: "Günaydın! ✨",
      body: "Kahveden önce bir bardakla metabolizmanı uyandır. " +
            "Vücudun 8 saatten sonra susadı! 💧",
    },
  },
  {
    en: {
      title: "Feeling Tired? 😴",
      body: "Before you grab a snack, try a glass of water. " +
            "Fatigue is often the first sign of mild dehydration. ⚡",
    },
    tr: {
      title: "Yorgun mu Hissediyorsun? 😴",
      body: "Atıştırmadan önce bir bardak su dene. " +
            "Yorgunluk genelde hafif susuzluğun ilk işaretidir. ⚡",
    },
  },
  {
    en: {
      title: "Radiant Skin Inside Out ✨",
      body: "Hydration is your cheapest beauty routine. " +
            "Stay on track to keep your skin plump and glowing! 💧👄",
    },
    tr: {
      title: "İçten Dışa Işıldayan Cilt ✨",
      body: "Hidrasyon senin en ucuz güzellik rutinin. " +
            "Cildini nemli ve parlak tutmak için hedefini takibe devam et! 💧👄",
    },
  },
  {
    en: {
      title: "Brain Fog Alert? 🧠",
      body: "Your brain is mostly water! Even mild dehydration " +
            "can hinder concentration. Log your next glass.",
    },
    tr: {
      title: "Beyin Sisi Alarmı mı? 🧠",
      body: "Beyninin çoğu sudur! Hafif susuzluk bile " +
            "konsantrasyonu engelleyebilir. Bir sonraki bardağını kaydet.",
    },
  },
  {
    en: {
      title: "Pre-Meal Trick 🍽️",
      body: "Drink a glass of water 20 mins before lunch. " +
            "It aids digestion and helps recognize true hunger. 💧",
    },
    tr: {
      title: "Yemek Öncesi İpucu 🍽️",
      body: "Öğle yemeğinden 20 dk önce bir bardak su iç. " +
            "Sindirime yardımcı olur ve gerçek açlığı fark etmeni sağlar. 💧",
    },
  },
  {
    en: {
      title: "Workout Warrior? 🏋️‍♂️",
      body: "Replace what you sweat! Hydrate before, during, " +
            "and after exercise to prevent cramps. 💧",
    },
    tr: {
      title: "Antrenman Savaşçısı mısın? 🏋️‍♂️",
      body: "Terlediğin suyu geri kazan! Krampları önlemek için " +
            "egzersiz öncesi, sırası ve sonrasında su iç. 💧",
    },
  },
  {
    en: {
      title: "The Flush Factor 🔄",
      body: "Water helps your kidneys flush out waste. " +
            "Keep your internal system clean with consistent sipping.",
    },
    tr: {
      title: "Arınma Faktörü 🔄",
      body: "Su, böbreklerinin atıkları atmasına yardımcı olur. " +
            "Sürekli yudumlayarak iç sistemini temiz tut.",
    },
  },
  {
    en: {
      title: "Curb Those Cravings 🍩",
      body: "Confusing thirst with hunger is common. " +
            "Craving sweets? Drink water first and wait 15 mins!",
    },
    tr: {
      title: "Aşırı İstekleri Dizginle 🍩",
      body: "Susuzluğu açlıkla karıştırmak yaygındır. " +
            "Canın tatlı mı istiyor? Önce su iç ve 15 dk bekle!",
    },
  },
  {
    en: {
      title: "Keep it Moving! 🚶‍♂️",
      body: "Stay hydrated to keep joints lubricated and " +
            "digestion smooth. Motion needs fluid! 💧",
    },
    tr: {
      title: "Harekete Devam Et! 🚶‍♂️",
      body: "Eklemlerini yağlı ve sindirimini rahat tutmak için " +
            "susuz kalma. Hareket için sıvı gerekir! 💧",
    },
  },
  {
    en: {
      title: "Habit Master 🎉",
      body: "You’ve made it 10 days! Consistency is key. " +
            "Tap to log your first glass and keep your streak alive! 💧🔥",
    },
    tr: {
      title: "Alışkanlık Ustası 🎉",
      body: "10 günü devirdin! İstikrar kilit önemde. " +
            "İlk bardağını kaydetmek için tıkla ve serini devam ettir! 💧🔥",
    },
  },
];

/**
 * Converts a time string (e.g. "5:10 PM") to minutes since midnight.
 * @param {string} timeStr
 * @return {number}
 */
function timeToMinutes(timeStr) {
  if (!timeStr) return -1;
  const cleaned = timeStr.trim().toUpperCase();
  const match = cleaned.match(/(\d+):(\d+)\s*(AM|PM)/);
  if (!match) return -1;

  let hours = parseInt(match[1]);
  const minutes = parseInt(match[2]);
  const ampm = match[3];

  if (ampm === "PM" && hours < 12) hours += 12;
  if (ampm === "AM" && hours === 12) hours = 0;

  return hours * 60 + minutes;
}

/**
 * Scheduled function to send hydration reminders every 1 minute.
 */
exports.sendHydrationReminders = onSchedule(
    "every 1 minutes",
    async (event) => {
      const intendedUtc = event.scheduleTime ?
        new Date(event.scheduleTime) : new Date();

      try {
        const usersSnap = await admin.firestore().collection("users").get();
        const notificationPromises = [];

        for (const userDoc of usersSnap.docs) {
          const userData = userDoc.data();
          const fcmToken = userData.fcmToken;
          const offset = userData.timezoneOffset || 0;
          const uid = userDoc.id;

          // GLOBAL SWITCH CHECK:
          if (userData.isNotificationEnabled === false) {
            continue;
          }

          if (!fcmToken) continue;

          // Local time calculation based on intended run time
          const localTime = new Date(intendedUtc.getTime() + offset * 60000);
          const curH = localTime.getUTCHours();
          const curM = localTime.getUTCMinutes();
          const currentTotalMinutes = curH * 60 + curM;

          let shouldNotify = false;
          let isTip = false;

          // 1. Daily Tip (Exactly 9:00 AM)
          if (curH === 9 && curM === 0) {
            shouldNotify = true;
            isTip = true;
          }

          // 2. Default Reminder (8 AM - 10 PM, Every 2 hours)
          if (!shouldNotify && curH >= 8 && curH <= 22 &&
              (curH - 8) % 2 === 0 && curM === 0) {
            const inactiveDefault = await userDoc.ref
                .collection("reminders")
                .where("isCustom", "==", false)
                .where("isActive", "==", false)
                .limit(1).get();

            if (inactiveDefault.empty) {
              shouldNotify = true;
            }
          }

          // 3. Custom Reminders
          if (!shouldNotify) {
            const customReminders = await userDoc.ref
                .collection("reminders")
                .where("isActive", "==", true)
                .get();

            for (const reminderDoc of customReminders.docs) {
              const reminder = reminderDoc.data();
              const reminderMinutes = timeToMinutes(reminder.timeRange);
              const diff = currentTotalMinutes - reminderMinutes;
              if (diff === 0) {
                shouldNotify = true;
                break;
              }
            }
          }

          if (shouldNotify) {
            const lastSent = userData.lastNotificationSentAt ?
              userData.lastNotificationSentAt.toDate() : new Date(0);
            const minutesSinceLast =
              (intendedUtc.getTime() - lastSent.getTime()) / 60000;

            if (minutesSinceLast < 0.9) {
              logger.info(`Skipping duplicate for ${uid}`);
              continue;
            }

            const isTR = userData.language === "Turkish";
            let title;
            let body;
            let type;

            if (isTip) {
              const dayIndex = (intendedUtc.getUTCDate() - 1) % 10;
              const tip = NOTIFICATIONS[dayIndex];
              title = isTR ? tip.tr.title : tip.en.title;
              body = isTR ? tip.tr.body : tip.en.body;
              type = "tip";
            } else {
              title = isTR ? "Su İçme Vakti!" : "Time to Drink Water!";
              body = isTR ?
                "Gün boyunca susuz kalmayın. Vücudunuzun suya " +
                "ihtiyacı var!" :
                "Stay hydrated! Your body needs water to " +
                "function properly.";
              type = "reminder_with_actions";
            }

            const message = {
              token: fcmToken,
              notification: {
                title: title,
                body: body,
              },
              data: {
                title: title,
                body: body,
                type: type,
                drink_text: isTR ? "250ml İç" : "Drink 250ml",
                snooze_text: isTR ? "10 dk Ertele" : "Snooze 10 min",
                click_action: "FLUTTER_NOTIFICATION_CLICK",
              },
              android: {
                priority: "high",
                ttl: 3600000,
                notification: {
                  channelId: "water_intake_channel",
                  sound: "water",
                  color: "#4B9CFF",
                },
              },
              apns: {
                payload: {
                  aps: {
                    contentAvailable: true,
                  },
                },
              },
            };

            notificationPromises.push(
                admin.messaging().send(message)
                    .then(() => {
                      return userDoc.ref.update({
                        lastNotificationSentAt:
                          FieldValue.serverTimestamp(),
                      });
                    })
                    .catch((err) =>
                      logger.error(`Error sending to ${uid}:`, err)),
            );
          }
        }

        await Promise.allSettled(notificationPromises);
      } catch (error) {
        logger.error("Error in reminder cycle:", error);
      }
    });
