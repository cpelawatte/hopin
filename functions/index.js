const { onRequest } = require("firebase-functions/v2/https");
const { onValueWritten, onValueCreated } = require("firebase-functions/v2/database");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({ region: "asia-southeast1" });



// Ride request notification
exports.sendRideRequestNotification = onValueWritten("/ride_request_notifications/{requestId}", async (event) => {
  const afterData = event.data.after.val();
  const requestId = event.params.requestId;

  console.log("🔔 Triggered for ride request ID:", requestId);

  if (!afterData) {
    console.log("❌ No data found after write.");
    return;
  }

  const driverPhone = afterData.driver_phone;
  const pickup = afterData.pickup_address_name;
  const destination = afterData.destination_address_name;

  const driverSnapshot = await admin.database().ref("/Users").orderByChild("phone").equalTo(driverPhone).once("value");

  if (driverSnapshot.exists()) {
    const driverData = Object.values(driverSnapshot.val())[0];
    const fcmToken = driverData.fcmToken;
    const username = driverData.username || "User";

    if (!fcmToken) {
      console.log("⚠️ No FCM token found for driver.");
      return;
    }

    const message = {
      token: fcmToken,
      notification: {
        title: "Ride Request Update",
        body: `Hi ${username}, your ride from ${pickup} to ${destination} has a new request!`,
      },
      data: {
        ride_id: afterData.ride_id || "",
        status: afterData.ride_request_notifications || "",
      },
    };

    try {
      await admin.messaging().send(message);
      console.log("✅ Ride request notification sent successfully.");
    } catch (error) {
      console.error("❌ Error sending notification:", error);
    }
  } else {
    console.log("⚠️ No driver data found for phone number:", driverPhone);
  }
});

// Notification updates (passenger <-> driver + rider request status update)
exports.sendNotificationFromNode = onValueCreated("/notifications/{notifId}", async (event) => {
  const notif = event.data.val();
  if (!notif) return;

  const riderPhone = notif.requested_rider_phone;
  const pickup = notif.pickup_address;
  const destination = notif.destination_address;
  const status = notif.status;
  const rideId = notif.ride_id;
  const isRead = notif.isRead ? notif.isRead.toString() : "false";

  const rideSnapshot = await admin.database().ref(`/Rides/${rideId}`).once("value");
  if (!rideSnapshot.exists()) return;

  const rideData = rideSnapshot.val();
  const driverPhone = rideData.phoneNumber;

  // 🚀 Notify all passengers if riderPhone is same as driverPhone
  if (riderPhone === driverPhone) {
    const passengerSnapshot = await admin.database().ref(`/passenger_per_ride/${rideId}`).once("value");
    if (!passengerSnapshot.exists()) return;

    const passengers = passengerSnapshot.val();

    for (const passengerId of Object.keys(passengers)) {
      const passengerPhone = passengers[passengerId].passenger_phone;
      const userSnap = await admin.database().ref("/Users").orderByChild("phone").equalTo(passengerPhone).once("value");

      if (!userSnap.exists()) continue;

      const userData = Object.values(userSnap.val())[0];
      const fcmToken = userData.fcmToken;
      const username = userData.username || "Passenger";

      if (!fcmToken) continue;

      const message = {
        token: fcmToken,
        notification: {
          title: "Ride Update",
          body: `Hi ${username}, your ride from ${pickup} to ${destination} has been ${status}.`,
        },
        data: {
          ride_id: rideId || "",
          isRead: isRead,
        },
      };

      try {
        await admin.messaging().send(message);
        console.log(`✅ Notification sent to passenger: ${passengerPhone}`);
      } catch (error) {
        console.error(`❌ Error sending to passenger: ${passengerPhone}`, error);
      }
    }
  }

  if (status === "accepted" || status === "declined") {
    try {
      const riderSnap = await admin.database().ref("/Users").orderByChild("phone").equalTo(riderPhone).once("value");
      if (!riderSnap.exists()) {
        console.warn(`⚠️ Rider not found for phone: ${riderPhone}`);
        return;
      }

      const riderData = Object.values(riderSnap.val())[0];
      const riderToken = riderData.fcmToken;
      const riderName = riderData.username || "Rider";

      if (riderToken) {
        const riderMessage = {
          token: riderToken,
          notification: {
            title: "Ride Request Status",
            body: `Hi ${riderName}, your request for a ride from ${pickup} to ${destination} was ${status}.`,
          },
          data: {
            ride_id: rideId || "",
            isRead: "false",
          },
        };

        await admin.messaging().send(riderMessage);
        console.log(`✅ Notification sent to requested rider: ${riderPhone}`);
      } else {
        console.warn(`⚠️ No FCM token for requested rider: ${riderPhone}`);
      }
    } catch (err) {
      console.error(`❌ Error sending notification to requested rider ${riderPhone}:`, err);
    }
  }
});

// 🛑 Notify driver when a passenger cancels
exports.notifyDriverOnPassengerCancel = onValueWritten("/passenger_ride_status/{rideId}/{passengerPhone}", async (event) => {
  const afterStatus = event.data.after.val();
  const { rideId, passengerPhone } = event.params;

  console.log(`🚨 Triggered for ride ID: ${rideId}, passenger: ${passengerPhone}, new status: ${afterStatus}`);

  if (afterStatus !== "Cancelled") {
    console.log("ℹ️ Status not 'Cancelled'. No action taken.");
    return;
  }

  const rideSnap = await admin.database().ref(`/Rides/${rideId}`).once("value");
  if (!rideSnap.exists()) {
    console.warn(`❌ No ride found with ID: ${rideId}`);
    return;
  }

  const rideData = rideSnap.val();
  const driverPhone = rideData.phoneNumber;
  const pickup = rideData.pickupAddress || "Unknown pickup";
  const destination = rideData.destinationAddress || "Unknown destination";

  const driverSnap = await admin.database().ref("/Users").orderByChild("phone").equalTo(driverPhone).once("value");

  if (!driverSnap.exists()) {
    console.warn(`⚠️ No driver found for phone number: ${driverPhone}`);
    return;
  }

  const driverData = Object.values(driverSnap.val())[0];
  const fcmToken = driverData.fcmToken;
  const username = driverData.username || "Driver";

  if (!fcmToken) {
    console.warn(`⚠️ No FCM token found for driver ${driverPhone}`);
    return;
  }

  const message = {
    token: fcmToken,
    notification: {
      title: "Passenger Cancelled Ride",
      body: `Hi ${username}, a passenger cancelled their ride from ${pickup} to ${destination}.`,
    },
    data: {
      ride_id: rideId || "",
      passenger_phone: passengerPhone,
      type: "ride_cancelled",
    },
  };

  try {
    await admin.messaging().send(message);
    console.log(`✅ Notification sent to driver: ${driverPhone}`);
  } catch (err) {
    console.error(`❌ Error sending notification to driver ${driverPhone}:`, err);
  }
});

// Chat message notification
exports.sendChatNotification = onValueCreated("chats/{chatId}/messages/{messageId}", async (event) => {
  const messageData = event.data.val();
  if (!messageData) return;

  const senderPhone = messageData.sender;
  const receiverPhone = messageData.receiver;
  const message = messageData.message || "";

  const receiverSnap = await admin.database().ref("/Users").orderByChild("phone").equalTo(receiverPhone).once("value");
  if (!receiverSnap.exists()) return;

  const receiverData = Object.values(receiverSnap.val())[0];
  const receiverFcmToken = receiverData.fcmToken;
  const senderSnap = await admin.database().ref("/Users").orderByChild("phone").equalTo(senderPhone).once("value");
  const senderUsername = senderSnap.exists() ? Object.values(senderSnap.val())[0].username : senderPhone;

  if (!receiverFcmToken) return;

  const notification = {
    token: receiverFcmToken,
    notification: {
      title: "New Message",
      body: `${senderUsername} says: ${message.substring(0, 50)}${message.length > 50 ? "..." : ""}`,
    },
    data: {
      sender: senderPhone,
      type: "chat",
    },
  };

  try {
    await admin.messaging().send(notification);
    console.log("✅ Chat notification sent to", receiverPhone);
  } catch (error) {
    console.error("❌ Failed to send chat notification:", error);
  }
});


