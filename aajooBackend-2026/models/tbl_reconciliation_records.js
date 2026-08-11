'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class tbl_reconciliation_records extends Model {
    static associate(models) {
      this._models = models;
      tbl_reconciliation_records.belongsTo(models.tbl_bookings, {
        foreignKey: 'rr_booking_id',
        targetKey: 'book_pri_id',
        as: 'booking',
        constraints: false,
      });
    }

    static async upsertForBooking(bookingId, payload) {
      try {
        const existing = await tbl_reconciliation_records.findOne({ where: { rr_booking_id: bookingId } });
        if (existing) {
          await existing.update(payload);
          return existing.dataValues;
        }
        const row = await tbl_reconciliation_records.create({ rr_booking_id: bookingId, ...payload });
        return row.dataValues;
      } catch (error) {
        return error;
      }
    }

    static async searchRecords(whereClause, options = {}) {
      const { page = 1, limit = 20 } = options;
      const offset = (page - 1) * limit;
      try {
        const { rows, count } = await tbl_reconciliation_records.findAndCountAll({
          where: whereClause,
          limit,
          offset,
          order: [['rr_created_at', 'DESC']],
          raw: true,
        });
        return { items: rows, totalRecords: count };
      } catch (error) {
        return error;
      }
    }

    static async summary(whereClause = {}) {
      try {
        const [matched, variance, pending] = await Promise.all([
          tbl_reconciliation_records.count({ where: { ...whereClause, rr_status: 'MATCHED' } }),
          tbl_reconciliation_records.count({ where: { ...whereClause, rr_status: 'VARIANCE' } }),
          tbl_reconciliation_records.count({ where: { ...whereClause, rr_status: 'PENDING' } }),
        ]);
        return { matched, variance, pending };
      } catch (error) {
        return error;
      }
    }
  }

  tbl_reconciliation_records.init(
    {
      rr_id: {
        type: DataTypes.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true,
      },
      rr_booking_id: DataTypes.INTEGER(11),
      rr_payment_amount: DataTypes.DECIMAL(12, 2),
      rr_expected_amount: DataTypes.DECIMAL(12, 2),
      rr_payout_amount: DataTypes.DECIMAL(12, 2),
      rr_variance: DataTypes.DECIMAL(12, 2),
      rr_status: DataTypes.ENUM('MATCHED', 'VARIANCE', 'PENDING', 'RESOLVED'),
      rr_resolved_by: DataTypes.INTEGER(11),
      rr_resolved_at: DataTypes.DATE,
      rr_action_taken: DataTypes.ENUM('ADJUST', 'WRITE_OFF', 'REFUND'),
      rr_notes: DataTypes.TEXT,
    },
    {
      sequelize,
      freezeTableName: true,
      modelName: 'tbl_reconciliation_records',
      timestamps: true,
      createdAt: 'rr_created_at',
      updatedAt: 'rr_updated_at',
    }
  );

  return tbl_reconciliation_records;
};
