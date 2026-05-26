const yup = require("yup");

const pagination = yup.object({
    page: yup.number().integer().min(1),
    limit: yup.number().integer().min(1).max(100),
});

exports.updateHostProfile = yup.object({
    user_fullName: yup.string().min(2).max(100),
    user_pnumber: yup.string().matches(/^\d{10}$/, "Phone number must be exactly 10 digits"),
    user_address: yup.string(),
    user_city: yup.string(),
    user_zipcode: yup.string(),
}).test("atLeastOne", "At least one field is required", (value) => {
    if (!value) return false;
    return Object.values(value).some((v) => v !== undefined);
});

exports.updateHostKyc = yup.object({
    doc_type: yup
        .number()
        .required("Document type is required"),
    doc_number: yup
        .string()
        .required("Document number is required")
        .when("doc_type", {
            is: 1,
            then: (schema) => schema.matches(/^\d{12}$/, "Aadhaar number must be exactly 12 digits"),
        })
        .when("doc_type", {
            is: 2,
            then: (schema) => schema.matches(/^[A-Z]{3}\d{7}$/, "Voter ID must be 3 letters followed by 7 digits (e.g., ABC1234567)"),
        })
        .when("doc_type", {
            is: 3,
            then: (schema) => schema.matches(/^[A-Z]{2}\d{13}$/, "Driving licence must be in format: 2 letters + 13 digits (e.g., DL1420110023456)"),
        }),
});

exports.listPagination = pagination;

exports.supportTicketCreate = yup.object({
    subject: yup.string().required("Subject is required").max(200),
    description: yup.string().required("Description is required"),
    category: yup.string().max(100),
    priority: yup.string().oneOf(["low", "medium", "high", "urgent"]),
});

exports.supportTicketList = yup.object({
    page: yup.number().integer().min(1),
    limit: yup.number().integer().min(1).max(100),
    status: yup.string().oneOf(["open", "in_progress", "resolved", "closed"]),
});

exports.supportTicketStatus = yup.object({
    ticketId: yup.number().required("Ticket id is required"),
    status: yup.string().oneOf(["open", "in_progress", "resolved", "closed"]).required("Status is required"),
    resolutionNote: yup.string().max(1000),
});

exports.supportTicketDetail = yup.object({
    ticketId: yup.number().required("Ticket id is required"),
});

exports.messageUser = yup.object({
    userId: yup.number().required("User id is required"),
});

exports.statementFilter = yup.object({
    page: yup.number().integer().min(1),
    limit: yup.number().integer().min(1).max(100),
    fromDate: yup.string(),
    toDate: yup.string(),
});
