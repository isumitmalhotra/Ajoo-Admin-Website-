'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class tbl_payout_schedules extends Model {
    static associate(models) {
      tbl_payout_schedules.belongsTo(models.tbl_user, {
        foreignKey: 'ps_host_id',
        targetKey: 'user_id',
        as: 'host',
        constraints: false,
      });
    }

    static async upsertForHost(hostId, payload) {
      try {
        const [row, created] = await tbl_payout_schedules.findOrCreate({
          where: { ps_host_id: hostId },
          defaults: { ps_host_id: hostId, ...payload },
        });
        if (!created) {
          await row.update(payload);
        }
        return row.dataValues;
      } catch (error) {
        return error;
      }
    }

    static async dueSchedules(today) {
      try {
        return await tbl_payout_schedules.findAll({
          where: {
            ps_is_active: 1,
            ps_next_payout_date: { [sequelize.Sequelize.Op.lte]: today },
          },
          raw: true,
        });
      } catch (error) {
        return error;
      }
    }
  }

  tbl_payout_schedules.init(
    {
      ps_id: {
        type: DataTypes.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true,
      },
      ps_host_id: DataTypes.INTEGER(11),
      ps_frequency: DataTypes.ENUM('DAILY', 'WEEKLY', 'BIWEEKLY', 'MONTHLY'),
      ps_next_payout_date: DataTypes.DATEONLY,
      ps_last_payout_date: DataTypes.DATEONLY,
      ps_min_payout_amount: DataTypes.DECIMAL(10, 2),
      ps_is_active: DataTypes.TINYINT(1),
      ps_payout_method: DataTypes.ENUM('BANK_TRANSFER', 'UPI'),
      ps_account_details: DataTypes.TEXT,
    },
    {
      sequelize,
      freezeTableName: true,
      modelName: 'tbl_payout_schedules',
      timestamps: true,
      createdAt: 'ps_created_at',
      updatedAt: 'ps_updated_at',
    }
  );

  return tbl_payout_schedules;
};
