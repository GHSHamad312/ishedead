const notifications = require('./notifications');
const admin = require('firebase-admin');



exports.processInactivity = async () => {
    const db = admin.firestore();
    const now = new Date(); // Use JS Date instead of admin.firestore.Timestamp.now()

    // Get active users
    // Note: In a real app with many users, this query should be paginated or sharded.
    const snapshot = await db.collection('users')
        .where('status', '==', 'Active')
        .get();

    const promises = snapshot.docs.map(async (doc) => {
        const user = doc.data();
        // Check if last_check_in exists
        if (!user.last_check_in) return;

        const lastCheckIn = user.last_check_in.toDate();
        const diffHours = (now - lastCheckIn) / (1000 * 60 * 60);

        // Use user's frequency, default to 24h if missing
        const frequency = user.check_in_frequency || 24;

        // Define tiers relative to frequency
        // Tier 1 (Overdue): Frequency + 2h
        // Tier 2 (Warning): Frequency + 12h
        // Tier 3 (Critical): Frequency + 24h

        const TIER_1_THRESHOLD = frequency + 2;
        const TIER_2_THRESHOLD = frequency + 12;
        const TIER_3_THRESHOLD = frequency + 24;

        if (diffHours < TIER_1_THRESHOLD) return; // Still active

        console.log(`User ${doc.id} inactive for ${diffHours.toFixed(1)} hours (Freq: ${frequency}h).`);

        // Determine Tier
        let tier = 0;
        if (diffHours >= TIER_3_THRESHOLD) tier = 3;
        else if (diffHours >= TIER_2_THRESHOLD) tier = 2;
        else if (diffHours >= TIER_1_THRESHOLD) tier = 1;

        // Check if we already triggered this tier today/for this period
        // For MVP, we simply re-trigger or check a 'last_alert_sent' field.
        // Let's implement a simple check: don't alert if last_alert_tier >= current_tier
        if (user.last_alert_tier && user.last_alert_tier >= tier) {
            // But wait, if time passed and we moved from T1 to T2, we MUST trigger.
            // If we are still in T1 and already sent T1, don't send again?
            // For MVP: We send every check if in threshold. (Logic can be refined).
            // Better: Store 'last_alert_time' and don't spam.
            return;
        }

        // Fetch contacts
        const contactsSnap = await db.collection('users').doc(doc.id).collection('contacts').get();
        if (contactsSnap.empty) {
            console.log(`No contacts for user ${doc.id}`);
            return;
        }

        const contacts = contactsSnap.docs.map(d => d.data());

        // Execute Alerts based on Tier
        for (const contact of contacts) {
            if (tier >= 1) {
                // Tier 1: Email
                await notifications.sendEmail(contact, user, tier);
            }
            if (tier >= 2) {
                // Tier 2: SMS
                // Only send SMS if priority is high or send to all? Let's send to all for MVP.
                await notifications.sendSMS(contact, user);
            }
            if (tier >= 3) {
                // Tier 3: Call
                await notifications.sendCall(contact, user);
            }
        }

        // Update user state
        const updateData = {
            last_alert_tier: tier,
            last_alert_time: now
        };

        // If we just executed Tier 3 (FINAL), mark user as Inactive to stop further checks.
        if (tier >= 3) {
            updateData.status = 'Inactive';
            console.log(`User ${doc.id} reached Tier 3. Marking as Inactive.`);
        }

        await db.collection('users').doc(doc.id).update(updateData);
    });

    await Promise.all(promises);
};
