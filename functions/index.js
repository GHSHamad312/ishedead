const functions = require('firebase-functions');
const admin = require('firebase-admin');
const monitor = require('./monitor_logic');

admin.initializeApp();

// Run every 60 minutes
// For testing, you can change this to 'every 1 minutes'
exports.checkInactivity = functions.pubsub.schedule('every 60 minutes').onRun(async (context) => {
    console.log('Running Inactivity Monitor...');
    await monitor.processInactivity();
    console.log('Inactivity Monitor Finished.');
});

// MANUAL TRIGGER for testing (call this in browser to force a check)
exports.manualRunMonitor = functions.https.onRequest(async (req, res) => {
    console.log('Manually triggered Inactivity Monitor...');
    await monitor.processInactivity();
    res.send("Inactivity Monitor Run Complete. Check logs.");
});

// HTTP Trigger for manual testing
exports.testInactivity = functions.https.onRequest(async (req, res) => {
    await monitor.processInactivity();
    res.send("Inactivity check executed.");
});

console.log("Loading functions/index.js...");

// Callable Function for granular testing (Email/SMS/Call)
exports.debugAlert = functions.https.onCall(async (data, context) => {
    console.log("debugAlert called!");
    // 1. Verify Authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    }

    const { type } = data; // 'email', 'sms', 'call'
    const uid = context.auth.uid;
    const db = admin.firestore();

    // Lazy load specific logic to prevent top-level crashes
    const notifications = require('./notifications');

    try {
        // 2. Fetch User & Contacts
        const userDoc = await db.collection('users').doc(uid).get();
        if (!userDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'User profile not found.');
        }
        const user = userDoc.data();

        const contactsSnap = await db.collection('users').doc(uid).collection('contacts').get();
        if (contactsSnap.empty) {
            return { success: false, message: "No emergency contacts found." };
        }

        const contacts = contactsSnap.docs.map(d => d.data());
        console.log(`Executing Test Alert (${type}) for User ${uid} to ${contacts.length} contacts.`);

        // 3. Dispatch based on type
        const promises = contacts.map(async (contact) => {
            if (type === 'email') {
                await notifications.sendEmail(contact, user, "TEST");
            } else if (type === 'sms') {
                await notifications.sendSMS(contact, user);
            } else if (type === 'call') {
                await notifications.sendCall(contact, user);
            } else if (type === 'panic') {
                // PANIC MODE: Mark Inactive & Send ALL
                console.log(`PANIC MODE TRIGGERED for User ${uid}`);

                // 1. Mark User Inactive Immediately
                await db.collection('users').doc(uid).update({
                    status: 'Inactive',
                    last_alert_time: new Date(),
                    last_alert_tier: 3 // Max tier
                });

                // 2. Send ALL notification types
                try {
                    await notifications.sendEmail(contact, user, "EMERGENCY");
                } catch (e) {
                    console.error("Failed to send Panic Email:", e);
                }

                try {
                    await notifications.sendSMS(contact, user);
                } catch (e) {
                    console.error("Failed to send Panic SMS:", e);
                }
                // await notifications.sendCall(contact, user); // keeping call optional/commented if not configured
            }
        });

        await Promise.all(promises);
        return { success: true, message: `Test ${type} sent to ${contacts.length} contacts.` };

    } catch (error) {
        console.error("Test Alert Error:", error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});

// Simple HTTP function to verify emulator connection
exports.testLocalFunction = functions.https.onRequest((req, res) => {
    res.json({
        message: "Hello from Local Emulator!",
        timestamp: new Date().toISOString()
    });
});
