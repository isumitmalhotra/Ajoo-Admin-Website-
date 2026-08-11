'use strict';
/**
 * Migration: composite performance indexes for the new FMS/HMS/notification
 * query paths.
 * Sprint: Full Delivery 2026-06-09..18 (A-15, static half).
 *
 * Why composites (vs the single-column indexes already added in A-02/07/14):
 * the hot controller queries filter on multiple columns at once + order/group
 * by a date. A single-column index only helps the first predicate; a composite
 * lets MySQL satisfy the whole WHERE + the ORDER/GROUP from one index
 * (index-only range scans), which is the win for these dashboards.
 *
 * Each index is wrapped in try/catch so:
 *   - re-running the migration is safe,
 *   - a pre-existing equivalent index (e.g. on tbl_bookings from an earlier
 *     migration) doesn't abort the batch.
 *
 * Runtime EXPLAIN/p95 profiling against live data is the deferred half of A-15
 * (documented as a post-deploy step in DEPLOY_RUNBOOK.md) — these composites
 * are justified by the known query shapes, no profiling required.
 *
 * Query → index mapping:
 *   idx_fl_host_txn_status_date  → host earnings / statements / performance / host-ledger
 *   idx_fl_txn_status_date       → finance dashboard KPIs + revenue/commission/tax/cashflow reports
 *   idx_po_host_status           → payout history summary (host + admin panes)
 *   idx_book_host_status_date    → host bookings search + performance cancellation counts
 *   idx_st_host_status           → host support ticket list
 *   idx_ntf_recipient_read       → notification unread counts + filtered search
 */

const addIndexSafe = async (queryInterface, table, fields, name) => {
    try {
        await queryInterface.addIndex(table, fields, { name });
        // eslint-disable-next-line no-console
        console.log(`  ✓ added index ${name} on ${table}(${fields.join(', ')})`);
    } catch (e) {
        // eslint-disable-next-line no-console
        console.log(`  • skipped ${name} (already exists or table missing): ${e.message}`);
    }
};

const removeIndexSafe = async (queryInterface, table, name) => {
    try {
        await queryInterface.removeIndex(table, name);
    } catch (e) { /* noop */ }
};

module.exports = {
    async up(queryInterface, Sequelize) {
        await addIndexSafe(queryInterface, 'tbl_financial_ledger',
            ['fl_host_id', 'fl_transaction_type', 'fl_status', 'fl_created_at'], 'idx_fl_host_txn_status_date');
        await addIndexSafe(queryInterface, 'tbl_financial_ledger',
            ['fl_transaction_type', 'fl_status', 'fl_created_at'], 'idx_fl_txn_status_date');
        await addIndexSafe(queryInterface, 'tbl_payouts',
            ['po_host_id', 'po_status'], 'idx_po_host_status');
        await addIndexSafe(queryInterface, 'tbl_bookings',
            ['book_host_id', 'book_status', 'book_added_at'], 'idx_book_host_status_date');
        await addIndexSafe(queryInterface, 'tbl_support_tickets',
            ['st_host_id', 'st_status'], 'idx_st_host_status');
        await addIndexSafe(queryInterface, 'tbl_notifications',
            ['ntf_recipient_role', 'ntf_recipient_id', 'ntf_is_read'], 'idx_ntf_recipient_read');
    },

    async down(queryInterface, Sequelize) {
        await removeIndexSafe(queryInterface, 'tbl_financial_ledger', 'idx_fl_host_txn_status_date');
        await removeIndexSafe(queryInterface, 'tbl_financial_ledger', 'idx_fl_txn_status_date');
        await removeIndexSafe(queryInterface, 'tbl_payouts', 'idx_po_host_status');
        await removeIndexSafe(queryInterface, 'tbl_bookings', 'idx_book_host_status_date');
        await removeIndexSafe(queryInterface, 'tbl_support_tickets', 'idx_st_host_status');
        await removeIndexSafe(queryInterface, 'tbl_notifications', 'idx_ntf_recipient_read');
    },
};
