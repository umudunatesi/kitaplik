const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendMessageNotification = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const studentId = message.studentId;
    const studentDoc = await admin.firestore().collection('students').doc(studentId).get();
    const token = studentDoc.data()?.fcmToken;

    if (token) {
      const payload = {
        notification: {
          title: message.title || "Yeni Mesaj",
          body: message.content,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      };
      await admin.messaging().sendToDevice(token, payload);
    }
  });
