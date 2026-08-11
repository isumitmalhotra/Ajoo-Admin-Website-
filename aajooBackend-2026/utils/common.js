const logger = require("./logger");
const EmailManager = require("./mailer");
const emailManager = new EmailManager();

const response = (req, res, status, success, message, data = []) => {
    return res.status(status).json({ success: success, message: message, data: data });
};

const mergeData = (data, attachments) => {
    const mergedData = data.map((item) => {
        const matchingAttachments = attachments.filter(
            (attachment) => attachment.afile_record_id === item.book_prop_id
        );
        return {
            ...item,
            attachments: matchingAttachments,
        };
    });
    return mergedData;
};

const sendOtpEmail = async (email, name, otp, subject, mailType = 'signup_otp', userId = null) => {
    const contentPayload = { name, otp };
    const parsedUserId = Number(userId);
    const emailUserId = Number.isInteger(parsedUserId) && parsedUserId > 0 ? parsedUserId : 0;

    let content;
    if (mailType === 'chatbot_otp') {
        content = emailManager.chatbotOtp(contentPayload);
    } else {
        content = emailManager.signupOtp(contentPayload);
    }

    const data = emailManager.makeContent(content);
    const option = {
        to: email,
        subject,
        data,
        status: "email sent successfully",
        mailType,
        userId: emailUserId,
    };
    await emailManager.sendEmail(option);
};


module.exports = {
    response,
    mergeData,
    sendOtpEmail
}
