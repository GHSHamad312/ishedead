const functions = require('firebase-functions');
const admin = require('firebase-admin');
const monitor = require('./monitor_logic');

admin.initializeApp();

// Run every 12 hours
// For testing, you can change this to 'every 1 minutes'
exports.checkInactivity = functions.pubsub.schedule('every 12 hours').onRun(async (context) => {
    console.log('Running Inactivity Monitor...');
    await monitor.processInactivity();
    console.log('Inactivity Monitor Finished.');
});

// HTTP Trigger for manual testing
exports.testInactivity = functions.https.onRequest(async (req, res) => {
    await monitor.processInactivity();
    res.send("Inactivity check executed.");
});

// Callable Function for granular testing (Email/SMS/Call)
exports.triggerTestAlert = functions.https.onCall(async (data, context) => {
    // 1. Verify Authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    }

    const { type } = data; // 'email', 'sms', 'call'
    const uid = context.auth.uid;
    const db = admin.firestore();

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
                await notifications.sendSMS(contact, user); // SMS msg might need tweaking to say "TEST"
            } else if (type === 'call') {
                await notifications.sendCall(contact, user);
            }
        });

        await Promise.all(promises);
        return { success: true, message: `Test ${type} sent to ${contacts.length} contacts.` };

    } catch (error) {
        console.error("Test Alert Error:", error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
