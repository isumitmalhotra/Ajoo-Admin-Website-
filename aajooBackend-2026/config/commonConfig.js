Object.defineProperty(exports, "JWT_SECRET", {
    enumerable: true,
    get: () => process.env.JWT_SECRET || null,
});
exports.successStatus = 200;
exports.createdStatus = 201;
exports.badRequestStatus = 400;
exports.notFoundStatus = 404;
exports.conflictStatus = 409;
exports.unprocessableStatus = 422;
exports.serverErrorStatus = 500;
exports.errorStatus = 400;
exports.isYes = 1;
exports.isNo = 0;
exports.listLimit = 10;
exports.listPage = 1;
// T&C
// tc_type
exports.tcTypeHost = 1;
exports.tcTypeGuest = 2;

//status
exports.checkIn = 6;
exports.checkOut = 7;
exports.bookConfirm = 8;
exports.paid = 3;

exports.statusBooked = 5;
exports.statusBookingCancelled = 2;
exports.statusPaymentPending = 1;
exports.statusCheckIn = 6;
exports.statusCheckout = 7;

exports.statusPaymentRecieved = 9;
exports.statusRunning = 10;
exports.statusSuspended = 11;
exports.statusPayoutPending = 12;
exports.statusPayoutSuccessfull = 13;
exports.statusPayoutFailed = 14;

