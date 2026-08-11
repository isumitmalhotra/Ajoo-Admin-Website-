class AdminServiceError extends Error {
    constructor(status, message) {
        super(message);
        this.name = "AdminServiceError";
        this.status = status;
    }
}

const ensureRecord = (record, message, status = 404) => {
    if (!record) {
        throw new AdminServiceError(status, message);
    }

    return record;
};

const buildPagedPayload = ({
    rows = [],
    count = 0,
    page = 1,
    limit = 10,
    offset = 0,
    search = "",
    key = "data",
    extra = {}
}) => ({
    totalRecords: count,
    currentPage: page,
    totalPages: count > 0 ? Math.ceil(count / limit) : 0,
    search,
    page,
    limit,
    offset,
    [key]: rows,
    ...extra,
});

module.exports = {
    AdminServiceError,
    ensureRecord,
    buildPagedPayload,
};
