const sgMail = require('@sendgrid/mail');
const twilio = require('twilio');
const functions = require('firebase-functions');
const nodemailer = require('nodemailer');

// Initialize clients with config variables
// Run: firebase functions:config:set sendgrid.key="SG..." twilio.sid="AC..." twilio.token="..." twilio.from="+1..."
const initClients = () => {
    try {
        const config = functions.config();
        if (config.sendgrid && config.sendgrid.key) {
            sgMail.setApiKey(config.sendgrid.key);
        }

        let twilioClient = null;
        if (config.twilio && config.twilio.sid && config.twilio.token) {
            twilioClient = twilio(config.twilio.sid, config.twilio.token);
        }
        return { twilioClient, config };
    } catch (e) {
        console.error("Error initializing clients:", e);
        return { twilioClient: null, config: {} };
    }
};

exports.sendEmail = async (contact, user, tier) => {
    try {
        const { config } = initClients();

        // Check for Nodemailer config
        if (!config.nodemailer || !config.nodemailer.email || !config.nodemailer.password) {
            console.log(`[MOCK EMAIL (Nodemailer not configured)] To: ${contact.email}, Subject: Alert for ${user.email} (Tier ${tier})`);
            return;
        }

        const transporter = nodemailer.createTransport({
            service: config.nodemailer.service || 'gmail',
            auth: {
                user: config.nodemailer.email,
                pass: config.nodemailer.password,
            },
        });

        const isTest = tier === "TEST";
        const isPanic = tier === "EMERGENCY";
        // Critical if tier is 3+ (numeric) OR it is a Panic trigger
        const isCritical = (typeof tier === 'number' && tier >= 3) || isPanic;

        let subject;
        if (isTest) {
            subject = `[TEST] Wellness Check Simulation for ${user.email}`;
        } else if (isPanic) {
            subject = `🚨 EMERGENCY ALERT: ${user.full_name || user.email} Requested Assistance`;
        } else if (isCritical) {
            subject = `FINAL ALERT: Security Protocol Executed for ${user.email}`;
        } else {
            subject = `URGENT: Wellness Check Needed for ${user.email}`;
        }

        const senderName = user.full_name || user.email || "Unknown User";

        // Check permissions AND Tier Level
        // Legacy and Vault are ONLY for Tier 3 (Critical) or Test/Panic
        // Medical Info is allowed for Tier 1+ (Warning) if authorized
        const effectiveIsCritical = isCritical || isTest;
        const isWarningOrHigher = (typeof tier === 'number' && tier >= 1) || isPanic || isTest;

        const showLegacy = effectiveIsCritical && user.legacy_message && contact.accessLegacyMessage;
        const showVault = effectiveIsCritical && user.will_url && contact.accessVault;
        // Allow medical info for Tier 1+ if authorized
        const showMedical = isWarningOrHigher && user.medical_info && contact.accessMedicalInfo;

        const textBody = isTest
            ? `This is a TEST alert initiated by ${senderName}. No action is required.`
            : (isCritical
                ? `FINAL ALERT: Security Protocol Executed for ${senderName}\n\n` +
                `This message confirms that ${senderName} has been inactive for the full duration of the safety protocol. The following information is now being released to you in accordance with their wishes.\n\n` +
                (showLegacy ? `--- LEGACY MESSAGE ---\n"${user.legacy_message}"\n\n` : '') +
                (showVault ? `--- DIGITAL VAULT ---\nAccess critical documents here: ${user.will_url}\n\n` : '') +
                (showMedical ? `--- MEDICAL INFO ---\n` +
                    (user.medical_info && user.medical_info.bloodType ? `Blood Type: ${user.medical_info.bloodType}\n` : '') +
                    (user.medical_info && user.medical_info.notes ? `Medical Notes: ${user.medical_info.notes}\n` : '') +
                    (user.medical_info && user.medical_info.allergies && user.medical_info.allergies.length ? `Allergies: ${user.medical_info.allergies.join(', ')}\n` : '') +
                    (user.medical_info && user.medical_info.medications && user.medical_info.medications.length ? `Medications: ${user.medical_info.medications.join(', ')}\n` : '')
                    : '')
                : `URGENT: Wellness Check Needed for ${senderName}\n\n` +
                `${senderName} has missed a scheduled safety check-in. Please contact them immediately to verify their safety.\n` +
                (showMedical ? `Medical Information is attached below to assist in this emergency.\n` : '') +
                `If they do not check in soon, the rigorous "Dead Man's Switch" protocol will execute and release secure documents (Legacy Message, Digital Vault) to designated contacts.\n\n` +
                (showMedical ? `--- MEDICAL INFO ---\n` +
                    (user.medical_info && user.medical_info.bloodType ? `Blood Type: ${user.medical_info.bloodType}\n` : '') +
                    (user.medical_info && user.medical_info.notes ? `Medical Notes: ${user.medical_info.notes}\n` : '') +
                    (user.medical_info && user.medical_info.allergies && user.medical_info.allergies.length ? `Allergies: ${user.medical_info.allergies.join(', ')}\n` : '') +
                    (user.medical_info && user.medical_info.medications && user.medical_info.medications.length ? `Medications: ${user.medical_info.medications.join(', ')}\n` : '')
                    : ''));

        // Professional HTML Template
        let htmlBody;

        if (tier === "EMERGENCY") {
            // SPECIAL TEMPLATE FOR PANIC BUTTON
            htmlBody = `
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; background-color: #f4f4f4; margin: 0; padding: 0; }
                    .wrapper { padding: 40px 20px; }
                    .container { max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
                    
                    /* Emergency Header */
                    .header { background: linear-gradient(135deg, #d32f2f, #b71c1c); padding: 40px 20px; text-align: center; color: #ffffff; }
                    .header h1 { margin: 0; font-size: 28px; text-transform: uppercase; letter-spacing: 2px; font-weight: 800; }
                    .header p { margin: 10px 0 0; font-size: 16px; opacity: 0.9; }
                    .alert-icon { font-size: 48px; margin-bottom: 10px; display: block; }
                    
                    /* Content */
                    .content { padding: 40px 30px; }
                    .intro { font-size: 18px; color: #2c3e50; margin-bottom: 25px; border-left: 4px solid #d32f2f; padding-left: 15px; }
                    
                    /* Cards */
                    .card { background: #fafafa; border: 1px solid #e0e0e0; border-radius: 8px; padding: 20px; margin-bottom: 20px; }
                    .card-header { display: flex; align-items: center; margin-bottom: 12px; border-bottom: 1px solid #eee; padding-bottom: 10px; }
                    .card-icon { font-size: 20px; margin-right: 10px; }
                    .card-title { font-weight: bold; color: #555; text-transform: uppercase; font-size: 13px; letter-spacing: 0.5px; margin: 0; }
                    
                    /* Button */
                    .action-btn { display: block; width: 100%; text-align: center; background: #d32f2f; color: #ffffff !important; padding: 18px; border-radius: 8px; text-decoration: none; font-weight: bold; margin-top: 30px; font-size: 16px; text-transform: uppercase; }
                    
                    .footer { text-align: center; padding: 20px; background: #f9f9f9; color: #7f8c8d; font-size: 12px; border-top: 1px solid #eee; }
                </style>
            </head>
            <body>
                <div class="wrapper">
                    <div class="container">
                        <div class="header">
                            <span class="alert-icon">🚨</span>
                            <h1>Emergency Alert</h1>
                            <p>Immediate Assist Requested</p>
                        </div>
                        
                        <div class="content">
                            <p class="intro">
                                <strong>${senderName}</strong> has manually triggered their emergency protocol.
                            </p>
                            
                            <p>This is not a drill or an automated check-in failure. The user has explicitly requested help or signalled they are in danger.</p>
                            
                            <p>Please attempt to contact them immediately. If you cannot reach them, consider contacting local emergency services depending on the situation.</p>

                            <!-- Information Release Section -->

                            ${showMedical ? `
                            <div class="card">
                                <div class="card-header">
                                    <span class="card-icon">🏥</span>
                                    <h3 class="card-title">Medical ID</h3>
                                </div>
                                ${user.medical_info && user.medical_info.bloodType ? `<p><strong>Blood Type:</strong> ${user.medical_info.bloodType}</p>` : ''}
                                ${user.medical_info && user.medical_info.notes ? `<p><strong>Medical Notes:</strong> ${user.medical_info.notes}</p>` : ''}
                                ${user.medical_info && user.medical_info.allergies && user.medical_info.allergies.length ? `<p><strong>Allergies:</strong> ${user.medical_info.allergies.join(', ')}</p>` : ''}
                                ${user.medical_info && user.medical_info.medications && user.medical_info.medications.length ? `<p><strong>Medications:</strong> ${user.medical_info.medications.join(', ')}</p>` : ''}
                            </div>` : ''}
                            
                            ${user.phone ? `
                            <a href="tel:${user.phone}" class="action-btn">Call ${senderName} Now</a>
                            ` : ''}
                        </div>
                        
                        <div class="footer">
                            <p>Sent securely via Is He Dead Application • Security Protocol Level 3</p>
                        </div>
                    </div>
                </div>
            </body>
            </html>
            `;
        } else {
            // STANDARD TEMPLATES (TEST, WARNING, FINAL)
            htmlBody = `
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { font-family: 'Helvetica', 'Arial', sans-serif; line-height: 1.6; color: #333; background-color: #f4f4f4; padding: 20px; }
                    .container { max-width: 600px; margin: 0 auto; background: #ffffff; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                    .header { text-align: center; border-bottom: 2px solid #e74c3c; padding-bottom: 20px; margin-bottom: 20px; }
                    .header h1 { color: #c0392b; margin: 0; font-size: 24px; text-transform: uppercase; letter-spacing: 1px; }
                    .test-badge { background: #f1c40f; color: #fff; padding: 5px 10px; border-radius: 4px; font-size: 12px; vertical-align: middle; }
                    .content { font-size: 16px; margin-bottom: 30px; }
                    .card { background: #f9f9f9; border-left: 4px solid #3498db; padding: 15px; margin-bottom: 15px; border-radius: 4px; }
                    .card h3 { margin-top: 0; color: #2980b9; font-size: 14px; text-transform: uppercase; }
                    .card p { margin: 5px 0 0; }
                    .btn { display: inline-block; background: #e74c3c; color: #ffffff; text-decoration: none; padding: 12px 25px; border-radius: 4px; font-weight: bold; margin-top: 10px; }
                    .footer { text-align: center; font-size: 12px; color: #7f8c8d; margin-top: 30px; border-top: 1px solid #eee; padding-top: 20px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        ${isTest ? '<h1>TEST ALERT <span class="test-badge">DEMO</span></h1>' : (isCritical ? '<h1>🚨 PROTOCOL EXECUTED</h1>' : '<h1>⚠️ CHECK-IN MISSED</h1>')}
                    </div>
                    
                    <div class="content">
                        <p>Hello,</p>
                        ${isCritical
                    ? `<p><strong>${senderName}</strong> has remained inactive for the full duration of their safety timer.</p>
                            <p>As per their instructions, the <strong>Dead Man's Switch Protocol</strong> has been executed. The following information is now being securely released to you:</p>`
                    : `<p><strong>${senderName}</strong> has missed a scheduled safety check-in.</p>
                            <p>Please attempt to contact them immediately. If they remain inactive, their secure Digital Vault and Legacy Message will be released to designated contacts.</p>
                            ${showMedical ? `<p><strong>Medical Information</strong> has been attached below to assist in case of an emergency.</p>` : ''}`
                }
                    </div>

                    ${showLegacy ? `
                    <div class="card" style="border-left-color: #9b59b6;">
                        <h3>📜 Legacy Message</h3>
                        <p>"${user.legacy_message}"</p>
                    </div>` : ''}

                    ${showVault ? `
                    <div class="card" style="border-left-color: #2ecc71;">
                        <h3>🔒 Digital Vault</h3>
                        <p>Access critical documents securely.</p>
                        <a href="${user.will_url}" class="btn" style="background:#2ecc71;">Open Vault</a>
                    </div>` : ''}

                    ${showMedical ? `
                    <div class="card" style="border-left-color: #e67e22;">
                        <h3>🏥 Medical Profile</h3>
                        ${user.medical_info && user.medical_info.bloodType ? `<p><strong>Blood Type:</strong> ${user.medical_info.bloodType}</p>` : ''}
                        ${user.medical_info && user.medical_info.notes ? `<p><strong>Medical Notes:</strong> ${user.medical_info.notes}</p>` : ''}
                        ${user.medical_info && user.medical_info.allergies && user.medical_info.allergies.length ? `<p><strong>Allergies:</strong> ${user.medical_info.allergies.join(', ')}</p>` : ''}
                        ${user.medical_info && user.medical_info.medications && user.medical_info.medications.length ? `<p><strong>Medications:</strong> ${user.medical_info.medications.join(', ')}</p>` : ''}
                    </div>` : ''}

                    <div class="footer">
                        <p>This message was sent automatically by the <strong>Is He Dead</strong> application.</p>
                    </div>
                </div>
            </body>
            </html>
            `;
        }

        const mailOptions = {
            from: config.nodemailer.email, // Sender address
            to: contact.email,
            subject: subject,
            text: textBody,
            html: htmlBody,
        };

        if (transporter) {
            await transporter.sendMail(mailOptions);
            console.log(`Email sent to ${contact.email} via Nodemailer`);
        } else {
            console.error("Transporter is undefined!");
        }

    } catch (error) {
        console.error('CRITICAL ERROR in sendEmail:', error);
    }
};

exports.sendSMS = async (contact, user) => {
    try {
        const { twilioClient, config } = initClients();
        if (!twilioClient) {
            console.log(`[MOCK SMS] To: ${contact.phone}, Body: Urgent: ${user.email} is inactive. Check on them.`);
            return;
        }

        await twilioClient.messages.create({
            body: `URGENT: ${user.full_name || user.email} has not checked in. Check your email for details.`,
            from: config.twilio.from,
            to: contact.phone
        });
        console.log(`SMS sent to ${contact.phone}`);
    } catch (error) {
        console.error('CRITICAL ERROR in sendSMS:', error);
    }
};

exports.sendCall = async (contact, user) => {
    try {
        const { twilioClient, config } = initClients();
        if (!twilioClient) {
            console.log(`[MOCK CALL] To: ${contact.phone}`);
            return;
        }

        await twilioClient.calls.create({
            twiml: `<Response><Say>This is an automated emergency alert from the Is He Dead application. User ${user.full_name || user.email} has not checked in for the critical safety duration. Please perform a wellness check immediately.</Say></Response>`,
            to: contact.phone,
            from: config.twilio.from
        });
        console.log(`Call initiated to ${contact.phone}`);
    } catch (error) {
        console.error('CRITICAL ERROR in sendCall:', error);
    }
};
