'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class tbl_invoices extends Model {
    static associate(models) {
      this._models = models;
      tbl_invoices.belongsTo(models.tbl_bookings, {
        foreignKey: 'inv_booking_id',
        targetKey: 'book_pri_id',
        as: 'booking',
        constraints: false,
      });
      tbl_invoices.belongsTo(models.tbl_user, {
        foreignKey: 'inv_host_id',
        targetKey: 'user_id',
        as: 'host',
        constraints: false,
      });
      tbl_invoices.belongsTo(models.tbl_user, {
        foreignKey: 'inv_user_id',
        targetKey: 'user_id',
        as: 'guest',
        constraints: false,
      });
    }

    static buildInvoiceNumber(seq) {
      const now = new Date();
      const yyyymm = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}`;
      const padded = String(seq).padStart(4, '0');
      return `AAJOO-INV-${yyyymm}-${padded}`;
    }

    static async createInvoice(payload) {
      try {
        if (!payload.inv_invoice_number) {
          const count = await tbl_invoices.count();
          payload.inv_invoice_number = tbl_invoices.buildInvoiceNumber(count + 1);
        }
        const row = await tbl_invoices.create(payload);
        return row.dataValues;
      } catch (error) {
        return error;
      }
    }

    static async searchInvoices(whereClause, options = {}) {
      const { page = 1, limit = 20 } = options;
      const offset = (page - 1) * limit;
      try {
        const { rows, count } = await tbl_invoices.findAndCountAll({
          where: whereClause,
          limit,
          offset,
          order: [['inv_created_at', 'DESC']],
          raw: true,
        });
        return { items: rows, totalRecords: count };
      } catch (error) {
        return error;
      }
    }
  }

  tbl_invoices.init(
    {
      inv_id: {
        type: DataTypes.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true,
      },
      inv_invoice_number: DataTypes.STRING(50),
      inv_booking_id: DataTypes.INTEGER(11),
      inv_host_id: DataTypes.INTEGER(11),
      inv_user_id: DataTypes.INTEGER(11),
      inv_invoice_type: DataTypes.ENUM('BOOKING_RECEIPT', 'HOST_COMMISSION', 'PAYOUT_STATEMENT'),
      inv_subtotal: DataTypes.DECIMAL(12, 2),
      inv_tax_amount: DataTypes.DECIMAL(12, 2),
      inv_tax_rate: DataTypes.DECIMAL(5, 2),
      inv_total: DataTypes.DECIMAL(12, 2),
      inv_hsn_sac_code: DataTypes.STRING(32),
      inv_gstin: DataTypes.STRING(32),
      inv_pdf_url: DataTypes.STRING(500),
      inv_line_items: DataTypes.TEXT,
      inv_status: DataTypes.ENUM('GENERATED', 'SENT', 'VOID'),
      inv_void_reason: DataTypes.TEXT,
    },
    {
      sequelize,
      freezeTableName: true,
      modelName: 'tbl_invoices',
      timestamps: true,
      createdAt: 'inv_created_at',
      updatedAt: 'inv_updated_at',
    }
  );

  return tbl_invoices;
};
