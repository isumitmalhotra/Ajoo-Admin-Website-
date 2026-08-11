'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class tbl_payouts extends Model {
    static associate(models) {
      this._models = models;
      tbl_payouts.belongsTo(models.tbl_user, {
        foreignKey: 'po_host_id',
        targetKey: 'user_id',
        as: 'host',
        constraints: false,
      });
    }

    static async searchPayouts(whereClause, options = {}) {
      const { page = 1, limit = 20 } = options;
      const offset = (page - 1) * limit;
      try {
        const { rows, count } = await tbl_payouts.findAndCountAll({
          where: whereClause,
          limit,
          offset,
          order: [['po_created_at', 'DESC']],
          raw: true,
        });
        return { items: rows, totalRecords: count };
      } catch (error) {
        return error;
      }
    }

    static async updateStatus(payoutId, status, extras = {}) {
      try {
        const payload = { po_status: status, ...extras };
        if (status === 'COMPLETED') payload.po_completed_at = new Date();
        if (status === 'PROCESSING') payload.po_initiated_at = new Date();
        return await tbl_payouts.update(payload, { where: { po_id: payoutId } });
      } catch (error) {
        return error;
      }
    }
  }

  tbl_payouts.init(
    {
      po_id: {
        type: DataTypes.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true,
      },
      po_host_id: DataTypes.INTEGER(11),
      po_amount: DataTypes.DECIMAL(12, 2),
      po_status: DataTypes.ENUM('QUEUED', 'PROCESSING', 'COMPLETED', 'FAILED'),
      po_payout_method: DataTypes.ENUM('BANK_TRANSFER', 'UPI'),
      po_reference_id: DataTypes.STRING(255),
      po_initiated_by: DataTypes.ENUM('SYSTEM', 'ADMIN'),
      po_initiated_at: DataTypes.DATE,
      po_completed_at: DataTypes.DATE,
      po_failure_reason: DataTypes.TEXT,
      po_period_start: DataTypes.DATEONLY,
      po_period_end: DataTypes.DATEONLY,
      po_on_hold: DataTypes.TINYINT(1),
      po_hold_reason: DataTypes.TEXT,
      po_note: DataTypes.TEXT,
    },
    {
      sequelize,
      freezeTableName: true,
      modelName: 'tbl_payouts',
      timestamps: true,
      createdAt: 'po_created_at',
      updatedAt: 'po_updated_at',
    }
  );

  return tbl_payouts;
};
