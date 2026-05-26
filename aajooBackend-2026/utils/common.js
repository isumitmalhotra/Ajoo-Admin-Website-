const logger = require("./logger");

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


module.exports = {
    response,
    mergeData
}