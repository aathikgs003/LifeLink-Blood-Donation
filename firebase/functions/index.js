const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();
const fcm = admin.messaging();

function toStringData(data = {}) {
  return Object.entries(data).reduce((acc, [key, value]) => {
    if (value === undefined || value === null) {
      return acc;
    }
    acc[key] = typeof value === 'string' ? value : JSON.stringify(value);
    return acc;
  }, {});
}

async function clearRecipientToken(recipientId, token) {
  const userRef = db.collection('users').doc(recipientId);
  const userSnap = await userRef.get();
  if (userSnap.exists && userSnap.get('fcmToken') === token) {
    await userRef.update({
      fcmToken: admin.firestore.FieldValue.delete(),
      updatedAt: new Date().toISOString(),
    });
  }

  const donorSnap = await db.collection('donors')
    .where('userId', '==', recipientId)
    .limit(1)
    .get();
  if (!donorSnap.empty && donorSnap.docs[0].get('fcmToken') === token) {
    await donorSnap.docs[0].ref.update({
      fcmToken: admin.firestore.FieldValue.delete(),
      updatedAt: new Date().toISOString(),
    });
  }
}

/**
 * 1. Auto-Match Donors on Request Creation
 */
exports.onRequestCreated = functions.firestore
  .document('requests/{requestId}')
  .onCreate(async (snap, context) => {
    const requestData = snap.data();
    const requestId = context.params.requestId;

    if (Array.isArray(requestData.matchedDonors) && requestData.matchedDonors.length > 0) {
      console.log(`Request ${requestId} already contains matched donors. Skipping trigger processing.`);
      return null;
    }
    
    // 1. Find compatible donors by blood group and city
    const bloodGroup = requestData.bloodGroupRequired;
    const city = requestData.city;
    
    const donorsSnapshot = await db.collection('donors')
      .where('bloodGroup', '==', bloodGroup)
      .where('city', '==', city)
      .where('isAvailable', '==', true)
      .where('isActive', '==', true)
      .get();
      
    if (donorsSnapshot.empty) {
      console.log('No matching donors found.');
      return null;
    }

    const matchedDonors = [];
    const notifications = [];

    donorsSnapshot.forEach(doc => {
      const donor = doc.data();
      matchedDonors.push({
        donorId: donor.donorId,
        matchedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'invited'
      });

      // Prepare notification if token exists
      if (donor.fcmToken) {
        notifications.push(
          fcm.sendToDevice(donor.fcmToken, {
            notification: {
              title: '🆘 Emergency Blood Request',
              body: `${requestData.unitsRequired} units of ${bloodGroup} needed at ${requestData.hospitalName}`,
              clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            },
            data: {
              requestId: requestId,
              type: 'emergencyAlert'
            }
          })
        );
      }
    });

    // 2. Update request with matched donors list
    await snap.ref.update({
      matchedDonors: matchedDonors,
      notificationBroadcastAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // 3. Send FCM notifications
    return Promise.all(notifications);
  });

/**
 * 1b. Send FCM push when app writes a notification document
 */
exports.onNotificationCreated = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    const notificationId = context.params.notificationId;

    if (!notification) {
      return null;
    }
    if (notification.status === 'deleted') {
      return null;
    }

    const recipientId = notification.recipientId;
    if (!recipientId) {
      console.log(`Notification ${notificationId} has no recipientId.`);
      return null;
    }

    const userSnap = await db.collection('users').doc(recipientId).get();
    let token = userSnap.exists ? userSnap.get('fcmToken') : null;

    if (!token) {
      const donorSnap = await db.collection('donors')
        .where('userId', '==', recipientId)
        .limit(1)
        .get();
      if (!donorSnap.empty) {
        token = donorSnap.docs[0].get('fcmToken');
      }
    }

    if (!token) {
      await snap.ref.set({
        pushStatus: 'skipped_no_token',
        pushAttemptedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      return null;
    }

    const urgency = notification.data && notification.data.urgencyLevel;
    const normalizedUrgency = typeof urgency === 'string' ? urgency.toLowerCase() : '';
    const isHighPriority = notification.priority === 'high' || normalizedUrgency === 'critical';

    const message = {
      token,
      notification: {
        title: notification.title || 'LifeLink Alert',
        body: notification.body || '',
      },
      data: {
        notificationId,
        recipientId,
        requestId: notification.requestId || '',
        type: notification.type || 'system',
        ...toStringData(notification.data || {}),
      },
      android: {
        priority: isHighPriority ? 'high' : 'normal',
        notification: {
          channelId: 'emergency_blood_requests',
        },
      },
      apns: {
        headers: {
          'apns-priority': isHighPriority ? '10' : '5',
        },
      },
    };

    try {
      const messageId = await fcm.send(message);
      await snap.ref.set({
        pushStatus: 'sent',
        pushMessageId: messageId,
        pushAttemptedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      return null;
    } catch (error) {
      const shouldClearToken = error && (
        error.code === 'messaging/registration-token-not-registered' ||
        error.code === 'messaging/invalid-registration-token'
      );

      if (shouldClearToken) {
        await clearRecipientToken(recipientId, token);
      }

      await snap.ref.set({
        pushStatus: shouldClearToken ? 'invalid_token' : 'failed',
        pushErrorCode: error && error.code ? error.code : 'unknown',
        pushErrorMessage: error && error.message ? error.message : String(error),
        pushAttemptedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      return null;
    }
  });

/**
 * 2. Auto-Expire Old Requests
 */
exports.expireOldRequests = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const expiredSnap = await db.collection('requests')
      .where('isActive', '==', true)
      .where('expiresAt', '<=', now)
      .get();
      
    const batch = db.batch();
    expiredSnap.forEach(doc => {
      batch.update(doc.ref, {
        status: 'expired',
        isActive: false,
        updatedAt: now
      });
    });
    
    return batch.commit();
  });

/**
 * 3. Daily Analytics Aggregation
 */
exports.aggregateDailyAnalytics = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const dateStr = yesterday.toISOString().split('T')[0];
    
    // Aggregation logic...
    const stats = {
      date: dateStr,
      totalRequests: 0,
      newDonors: 0,
      completedRequests: 0,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    };
    
    await db.collection('analytics').doc(dateStr).set(stats);
    return null;
  });

/**
 * 4. Razorpay Webhook
 */
exports.razorpayWebhook = functions.https.onRequest(async (req, res) => {
  // Webhook validation and payment processing logic...
  const paymentData = req.body.payload.payment.entity;
  
  await db.collection('payments').add({
    razorpayPaymentId: paymentData.id,
    amount: paymentData.amount / 100,
    status: 'success',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  res.status(200).send('OK');
});

/**
 * 5. Audit Log Creation
 */
exports.createAuditLog = functions.firestore
  .document('{collection}/{documentId}')
  .onWrite(async (change, context) => {
    const collection = context.params.collection;
    if (collection === 'auditLogs') return null;

    const auditData = {
      action: context.eventType,
      resource: collection,
      resourceId: context.params.documentId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      userId: context.auth ? context.auth.uid : 'system'
    };

    return db.collection('auditLogs').add(auditData);
  });
