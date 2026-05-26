const yup = require("yup");

exports.createHostAccDetails = yup.object({
    accountNumber: yup
        .number()
        .required("account number is required"),
    accountIfsc: yup
        .string()
        .required("account ifsc is required"),
});
exports.createPayoutRequest = yup.object({
    amount: yup
        .number()
        .typeError("Amount must be a number")
        .moreThan(0, "Amount must be greater than 0")
        .required("Amount is required"),
});

exports.payoutHistoryList = yup.object({
    page: yup.number().integer().min(1),
    limit: yup.number().integer().min(1).max(100),
    fromDate: yup.string(),
    toDate: yup.string(),
});
