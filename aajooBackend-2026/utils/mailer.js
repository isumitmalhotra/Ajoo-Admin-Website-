const nodemailer = require('nodemailer');
const mailConfig = require("../config/db.config");
const model = require("../models");
const { sequelize } = require('../models');
const logger = require('./logger');

class EmailManager {
    constructor() {
        this.transporter = nodemailer.createTransport({
            // host: mailConfig.etherealHost, // e.g., smtp.gmail.com
            host: 'smtp.gmail.com',
            port: 465,
            secure: true,
            auth: {
                user: mailConfig.mailEmail,
                pass: mailConfig.mailPassword,
            },
            connectionTimeout: 5000, // Increase timeout to 5 seconds
            greetingTimeout: 5000,  // Increase greeting timeout
            socketTimeout: 5000,    // Increase socket timeout
            // logger: true,  // Enable detailed logs
            // debug: true, 
        });
    }

    /**
     * Adds attachments to the email if provided
     * @param {Array} attachments - List of attachments
     * @returns {Array|undefined} - Returns the attachments array or undefined
     */
    addAttachments(attachments) {
        if (attachments && attachments.length > 0) {
            return attachments.map((attachment) => ({
                filename: attachment.filename,
                path: attachment.path,
            }));
        }
        return undefined; // No attachments
    }

    /**
     * Sends an email
     * @param {Object} options - Email options
     * @param {string} options.to - Receiver's email address
     * @param {string} options.subject - Subject of the email
     * @param {string} [options.cc] - CC email addresses
     * @param {string} [options.bcc] - BCC email addresses
     * @param {string} [options.text] - Plain text body
     * @param {string} [options.html] - HTML body
     * @param {Array} [options.attachments] - Attachments for the email
     * @returns {Promise<void>}
     */

    makeContent(content) {
        return `${this.header()}${content}${this.footer()}`;
    };

    async sendEmail(options) {
        const transaction = await sequelize.transaction();
        let sendEmailId
        try {
            const mailOptions = {
                from: mailConfig.mailEmail,
                to: options.to,
                subject: options.subject,
                html: options.data,
                cc: options.cc ?? undefined,
                bcc: options.bcc ?? undefined
            };
            const payload = {
                se_user_id: options.userId,
                se_recipient_email: options.to,
                se_subject: options.subject,
                se_body: options.data,
                se_status: options.status,
                se_cc: options.cc ?? undefined,
                se_bcc: options.bcc ?? undefined,
                se_mail_type: options.mailType,
            }
            const info = await this.transporter.sendMail(mailOptions);

            const sendEmail = await model.tbl_send_email.create(payload, { transaction: transaction });
            sendEmailId = sendEmail.dataValues.se_id;
            await transaction.commit()
            logger.info(`Email sent: ${info.messageId}`);
            return info; // Return the info object on success
        } catch (error) {
            await transaction.rollback();
            logger.error('Error sending email:', error);
            return false;
        }
    }

    header() {
        return (`
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Password Updated</title>
            </head>
            <body style="font-family: Arial, sans-serif; background-color: #f4f4f7; margin: 0; padding: 0;">
                <div style="max-width: 600px; margin: 20px auto; background-color: #ffffff; 
                            border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden; 
                            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);">
                    
                    <!-- Header Section -->
                    <div style="background-color: #AB0241; color: #ffffff; padding: 20px; text-align: center;">
                        <img src="https://yourcompanylogo.com/logo.png" alt="Company Logo" 
                             style="max-width: 150px; margin-bottom: 10px;">
                        <h1 style="margin: 0; font-size: 24px;">Aajoo Homes</h1>
                    </div>
        `);

    };
    footer() {
        return (`
         <!-- Footer Section -->
        <div style="background-color: #f4f4f7; color: #444; padding: 20px; text-align: center; font-size: 13px; border-top: 1px solid #ddd;">
            <p style="margin: 5px 0;">This email was sent to notify you of a change in your account security.</p>
            <p style="margin: 5px 0;">
                If you have any questions, visit our 
                <a href="https://yourwebsite.com/help" style="color: #AB0241; text-decoration: none; font-weight: bold;">Help Center</a>.
            </p>
            <p style="margin: 10px 0; font-weight: bold;">© 2025 Aajoo Homes    . All rights reserved.</p>
        </div>
    </body>
</html>

        `);
    };
    signupOtp(data) {
        return (`
            <main style="padding: 20px; max-width: 600px; margin: 0 auto; background: #ffffff;
                         font-family: Arial, sans-serif;">
                
                <!-- Welcome Message -->
                <h2 style="color: #1E3A8A; text-align: center; font-size: 24px; font-weight: bold; margin-bottom: 10px;">
                    Welcome to Aajoo Homes!
                </h2>
                
                <!-- Greeting -->
                <p style="color: #4B5563; font-size: 16px; line-height: 1.6; text-align: center; margin: 10px 0;">
                    Hi ${data.name},
                </p>
                
                <!-- Info -->
                <p style="color: #4B5563; font-size: 16px; line-height: 1.6; text-align: center; margin: 10px 0;">
                    Thank you for signing up. To complete your registration, please verify your email using the OTP code below.
                </p>
                
                <!-- OTP Code -->
                <div style="text-align: center; margin: 20px 0;">
                    <span style="font-size: 26px; font-weight: bold; color: #AB0241; background: #F3F4F6; 
                                 padding: 12px 24px; border-radius: 8px; display: inline-block;">
                        ${data.otp}
                    </span>
                </div>
                
                <!-- Extra Info -->
                <p style="color: #6B7280; font-size: 14px; text-align: center;">
                    This OTP is valid for 10 minutes. Please do not share it with anyone.
                </p>
                <p style="color: #6B7280; font-size: 14px; text-align: center;">
                    If you didn’t sign up for this account, you can safely ignore this email.
                </p>
            </main>
        `);
    }

    forgetPassword(data) {
        return (`
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#f3f4f6; padding:0px;">
  <tr>
    <td align="center">

      <table width="600" cellpadding="0" cellspacing="0"
        style="background:#ffffff; box-shadow:0px 4px 10px rgba(0,0,0,0.1); font-family:Arial, sans-serif;">

        <!-- Image -->
        <tr>
          <td align="center" style="padding:20px 0;">
            <img src="https://via.placeholder.com/150" alt="Image"
              style="width:120px; height:auto; border-radius:8px; display:block;">
          </td>
        </tr>

        <!-- Heading -->
        <tr>
          <td align="center" style="padding:0 20px;">
            <h2 style="color:#1E3A8A; font-size:24px; font-weight:bold; margin:0 0 10px 0;">
              Reset Your Password
            </h2>
          </td>
        </tr>

        <!-- Message -->
        <tr>
          <td align="center" style="padding:0 30px;">
            <p style="color:#4B5563; font-size:16px; line-height:1.6; margin:10px 0;">
              Hi ${data.user},
            </p>
            <p style="color:#4B5563; font-size:16px; line-height:1.6; margin:10px 0;">
              We received a request to reset your password. Use the OTP code below to proceed.
            </p>
          </td>
        </tr>

        <!-- OTP -->
        <tr>
          <td align="center" style="padding:20px;">
            <div
              style="font-size:24px; font-weight:bold; color:#AB0241; background:#F3F4F6;
                     padding:10px 25px; border-radius:8px; display:inline-block; letter-spacing:3px;">
              ${data.otp}
            </div>
          </td>
        </tr>

        <!-- Footer -->
        <tr>
          <td align="center" style="padding:0 30px 30px;">
            <p style="color:#6B7280; font-size:14px; margin:10px 0;">
              If you didn’t request this, please ignore this email or contact support.
            </p>
            <p style="color:#6B7280; font-size:14px; font-weight:bold; margin:0;">
              This OTP will expire in 10 minutes.
            </p>
          </td>
        </tr>

      </table>

    </td>
  </tr>
</table>
        `);
    };
    confirmUpdatePassword(userName) {
        return (`
            <div style="padding: 20px; color: #333333; line-height: 1.6;">
            <p>Dear ${userName}</p>
            <p>We wanted to let you know that your password has been successfully updated.</p>
            <p>If you did not make this change or if you believe it was unauthorized, please contact our support team immediately.</p>
            <p>Thank you for using our service.</p>
            <p>Best regards,<br>Your Company Name</p>
        </div>
        `)
    };
    bookingMail(data) {
        return (`
          <div style="padding: 20px; color: #444;">
            <p>Dear <strong>${data.username}</strong>,</p>
            <p>We are pleased to confirm your booking. Here are the details:</p>

            <table style="width: 100%; border-collapse: collapse; margin-top: 10px;">
                <tr>
                    <td style="padding: 8px; border-bottom: 1px solid #ddd;"><strong>Booking ID:</strong></td>
                    <td style="padding: 8px; border-bottom: 1px solid #ddd;">${data.bookingId}</td>
                </tr>
                <tr>
                    <td style="padding: 8px; border-bottom: 1px solid #ddd;"><strong>Property Name:</strong></td>
                    <td style="padding: 8px; border-bottom: 1px solid #ddd;">${data.propertyName}</td>
                </tr>
                <tr>
                    <td style="padding: 8px; border-bottom: 1px solid #ddd;"><strong>Check-in Date:</strong></td>
                    <td style="padding: 8px; border-bottom: 1px solid #ddd;">${data.checkinDate}</td>
                </tr>
                <tr>
                    <td style="padding: 8px; border-bottom: 1px solid #ddd;"><strong>Check-out Date:</strong></td>
                    <td style="padding: 8px; border-bottom: 1px solid #ddd;">${data.checkoutDate}</td>
                </tr>
                <tr>
                    <td style="padding: 8px; border-bottom: 1px solid #ddd;"><strong>Total Amount:</strong></td>
                    <td style="padding: 8px; border-bottom: 1px solid #ddd;">${data.totalPrice}</td>
                </tr>
            </table>

            <p style="margin-top: 15px;">If you have any questions, feel free to contact us.</p>
        </div>
        `)
    };
    bookingCancellforUser(data) {
        return (`
           <main style="padding: 20px; background: #ffffff;">
      <h2 style="color: #AB0241; text-align: center; font-size: 22px; margin-bottom: 10px;">
        Your Booking Has Been Cancelled
      </h2>
      <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
        Hi ${data.name},
      </p>
      <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
        We confirm that your booking <strong>(ID: ${data.bookingId})</strong> has been successfully cancelled.
      </p>
      <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
        If this was accidental or you'd like to rebook, you can easily do so anytime from our platform.
      </p>
      <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
        Thank you for choosing Aajoo Homes.
      </p>
    </main>
        `)
    };
    bookingCancellforHost(data) {
        return (`
      <main style="padding: 20px; background: #ffffff;">
      <h2 style="color: #AB0241; text-align: center; font-size: 22px; margin-bottom: 10px;">
        Booking Cancelled by User
      </h2>
      <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
        Hi ${data.hostName},
      </p>
      <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
        The user <strong>${data.userName}</strong> has cancelled their booking (ID: <strong>${data.bookingId}</strong>) for your property: <strong>${data.propertyName}</strong>.
      </p>
      <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
        You may now make this slot available again for other bookings.
      </p>
      <p style="color: #4B5563; font-size: 16px; line-height: 1.6;">
        If you have any questions, feel free to contact our support.
      </p>
    </main>
        `)
    };


};

module.exports = EmailManager;
