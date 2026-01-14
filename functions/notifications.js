const sgMail = require('@sendgrid/mail');
const twilio = require('twilio');
const functions = require('firebase-functions');

// Initialize clients with config variables
// Run: firebase functions:config:set sendgrid.key="SG..." twilio.sid="AC..." twilio.token="..." twilio.from="+1..."
const initClients = () => {
    const config = functions.config();
    if (config.sendgrid && config.sendgrid.key) {
        sgMail.setApiKey(config.sendgrid.key);
    }

    let twilioClient = null;
    if (config.twilio && config.twilio.sid && config.twilio.token) {
        twilioClient = twilio(config.twilio.sid, config.twilio.token);
    }
    return { twilioClient, config };
};

exports.sendEmail = async (contact, user, tier) => {
    const { config } = initClients();
    if (!config.sendgrid) {
        console.log(`[MOCK EMAIL] To: ${contact.email}, Subject: Alert for ${user.email} (Tier ${tier})`);
        return;
    }

    const isTest = tier === "TEST";
    const subject = isTest
        ? `[TEST] Wellness Check Simulation for ${user.email}`
        : `URGENT: Wellness Check Needed for ${user.email}`;

    const textBody = isTest
        ? `This is a TEST alert initiated by ${user.email}. No action is required.`
        : `This is an automated Tier ${tier} alert. ${user.email} has been inactive. Please check on them.`;

    const htmlBody = isTest
        ? `<strong>This is a TEST alert</strong> initiated by ${user.email}.<br>No action is required.`
        : `<strong>This is an automated Tier ${tier} alert.</strong><br>${user.email} has been inactive. Please check on them.`;

    const msg = {
        to: contact.email,
        from: 'no-reply@ishedead-app.com', // Must be verified sender
        subject: subject,
        text: textBody,
        html: htmlBody,
    };

    try {
        await sgMail.send(msg);
        console.log(`Email sent to ${contact.email}`);
    } catch (error) {
        console.error('Error sending email:', error);
    }
};

exports.sendSMS = async (contact, user) => {
    const { twilioClient, config } = initClients();
    if (!twilioClient) {
        console.log(`[MOCK SMS] To: ${contact.phone}, Body: Urgent: ${user.email} is inactive. Check on them.`);
        return;
    }

    try {
        await twilioClient.messages.create({
            body: `URGENT: ${user.email} has not checked in for 72 hours. Please contact them immediately.`,
            from: config.twilio.from,
            to: contact.phone
        });
        console.log(`SMS sent to ${contact.phone}`);
    } catch (error) {
        console.error('Error sending SMS:', error);
    }
};

exports.sendCall = async (contact, user) => {
    const { twilioClient, config } = initClients();
    if (!twilioClient) {
        console.log(`[MOCK CALL] To: ${contact.phone}`);
        return;
    }

    try {
        await twilioClient.calls.create({
            twiml: `<Response><Say>This is an automated emergency alert from the Is He Dead application. User ${user.email} has not checked in for 4 days. Please perform a wellness check immediately.</Say></Response>`,
            to: contact.phone,
            from: config.twilio.from
        });
        console.log(`Call initiated to ${contact.phone}`);
    } catch (error) {
        console.error('Error initiating call:', error);
    }
};
