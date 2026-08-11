'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class tbl_financial_ledger extends Model {
    static associate(models) {
      this._models = models;
      tbl_financial_ledger.belongsTo(models.tbl_bookings, {
        foreignKey: 'fl_booking_id',
        targetKey: 'book_pri_id',
        as: 'booking',
        constraints: false,
      });
      tbl_financial_ledger.belongsTo(models.tbl_user, {
        foreignKey: 'fl_host_id',
        targetKey: 'user_id',
        as: 'host',
        constraints: false,
      });
      tbl_financial_ledger.belongsTo(models.tbl_user, {
        foreignKey: 'fl_user_id',
        targetKey: 'user_id',
        as: 'guest',
        constraints: false,
      });
    }

    static async addEntry(payload) {
      try {
        const row = await tbl_financial_ledger.create(payload);
        return row.dataValues;
      } catch (error) {
        return error;
      }
    }

    static async searchLedger(whereClause, options = {}) {
      const { page = 1, limit = 20, attributes = null } = options;
      const offset = (page - 1) * limit;
      try {
        const { rows, count } = await tbl_financial_ledger.findAndCountAll({
          where: whereClause,
          attributes,
          limit,
          offset,
          order: [['fl_created_at', 'DESC']],
          raw: true,
        });
        return { items: rows, totalRecords: count };
      } catch (error) {
        return error;
      }
    }

    static async sumAmount(whereClause) {
      try {
        return await tbl_financial_ledger.sum('fl_amount', { where: whereClause });
      } catch (error) {
        return error;
      }
    }
  }

  tbl_financial_ledger.init(
    {
      fl_id: {
        type: DataTypes.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true,
      },
      fl_booking_id: DataTypes.INTEGER(11),
      fl_host_id: DataTypes.INTEGER(11),
      fl_user_id: DataTypes.INTEGER(11),
      fl_transaction_type: DataTypes.ENUM(
        'GUEST_PAYMENT',
        'HOST_EARNING',
        'PLATFORM_COMMISSION',
        'TAX_COLLECTED',
        'REFUND',
        'PAYOUT',
        'ADJUSTMENT'
      ),
      fl_entry_type: DataTypes.ENUM('CREDIT', 'DEBIT'),
      fl_amount: DataTypes.DECIMAL(12, 2),
      fl_balance_after: DataTypes.DECIMAL(12, 2),
      fl_reference_id: DataTypes.STRING(255),
      fl_description: DataTypes.TEXT,
      fl_status: DataTypes.ENUM('COMPLETED', 'PENDING', 'FAILED', 'REVERSED'),
    },
    {
      sequelize,
      freezeTableName: true, // table is exactly tbl_financial_ledger (don't pluralize)
      modelName: 'tbl_financial_ledger',
      timestamps: true,
      createdAt: 'fl_created_at',
      updatedAt: 'fl_updated_at',
    }
  );

  return tbl_financial_ledger;
};
