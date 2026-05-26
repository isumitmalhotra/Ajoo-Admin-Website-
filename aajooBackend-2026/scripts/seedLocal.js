const { sequelize, tbl_doc_list, tbl_book_status } = require("../models");
const moduleConfig = require("../config/moduleConfigs");

const bookStatuses = [
  { bs_id: 1, bs_title: "Payment Pending", bs_code: "PAYMENT_PENDING" },
  { bs_id: 2, bs_title: "Booking Cancelled", bs_code: "BOOKING_CANCELLED" },
  { bs_id: 3, bs_title: "Paid", bs_code: "PAID" },
  { bs_id: 4, bs_title: "Booking Pending", bs_code: "BOOKING_PENDING" },
  { bs_id: 5, bs_title: "Booked", bs_code: "BOOKED" },
  { bs_id: 6, bs_title: "Check In", bs_code: "CHECK_IN" },
  { bs_id: 7, bs_title: "Check Out", bs_code: "CHECK_OUT" },
  { bs_id: 8, bs_title: "Booking Confirmed", bs_code: "BOOKING_CONFIRMED" },
  { bs_id: 9, bs_title: "Payment Received", bs_code: "PAYMENT_RECEIVED" },
  { bs_id: 10, bs_title: "Running", bs_code: "RUNNING" },
  { bs_id: 11, bs_title: "Suspended", bs_code: "SUSPENDED" },
  { bs_id: 12, bs_title: "Payout Pending", bs_code: "PAYOUT_PENDING" },
  { bs_id: 13, bs_title: "Payout Successful", bs_code: "PAYOUT_SUCCESSFUL" },
  { bs_id: 14, bs_title: "Payout Failed", bs_code: "PAYOUT_FAILED" },
];

const seedDocTypes = async () => {
  const docTypes = moduleConfig.documnetTypes ?? [];
  for (const doc of docTypes) {
    const existing = await tbl_doc_list.findOne({ where: { d_id: doc.doc_id } });
    if (!existing) {
      await tbl_doc_list.create({ d_id: doc.doc_id, d_title: doc.doc_name });
    }
  }
};

const seedBookStatuses = async () => {
  for (const status of bookStatuses) {
    const existing = await tbl_book_status.findOne({ where: { bs_id: status.bs_id } });
    if (!existing) {
      await tbl_book_status.create({ ...status, bs_isDelete: 0 });
    }
  }
};

const run = async () => {
  try {
    await sequelize.authenticate();
    await seedDocTypes();
    await seedBookStatuses();
    console.log("✅ Local seed completed.");
  } catch (error) {
    console.error("❌ Local seed failed:", error.message);
    process.exitCode = 1;
  } finally {
    await sequelize.close();
  }
};

run();
