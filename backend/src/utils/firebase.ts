import * as admin from 'firebase-admin';

// Note: To use Firebase Admin, you MUST configure the GOOGLE_APPLICATION_CREDENTIALS 
// environment variable pointing to your Firebase service account JSON key file.
// Alternatively, initialize with credential: admin.credential.cert(...)
if (!admin.apps.length) {
  try {
    admin.initializeApp();
    console.log("Firebase Admin initialized successfully.");
  } catch (error) {
    console.warn("Firebase Admin could not be initialized:", error);
  }
}

export const sendPushNotification = async (
  token: string, 
  title: string, 
  body: string, 
  data?: any
) => {
  if (!token) return;

  const payload = {
    notification: {
      title,
      body,
    },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK'
    },
  };

  try {
    const response = await admin.messaging().send({
      token,
      ...payload,
    });
    console.log('Successfully sent message:', response);
  } catch (error) {
    console.error('Error sending message:', error);
  }
};
