'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_payout_req extends Model {
    static associate(models) {
      this._models = models;
      tbl_payout_req.belongsTo(models.tbl_book_status, { foreignKey: 'pay_req_status', targetKey: 'bs_id', as: 'payoutStatus' });
    }

    static async getPayoutRequest(where, attributes) {
      try {
        return this.findAll({
          where: where,
          attributes: attributes,
          order: [['pay_req_id', 'DESC']],
          raw: true,
          include: [
            {
              model: this._models.tbl_book_status,
              as: "payoutStatus",
              attributes: ["bs_title", "bs_code"]
            }
          ]
        });
      } catch (error) {
        return error;
      }

    }
  };

  tbl_payout_req.init({
    pay_req_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true
    },
    pay_req_host_id: DataTypes.INTEGER(11),
    pay_req_amount: DataTypes.DOUBLE(10, 2),
    pay_req_status: DataTypes.INTEGER(11),
    pay_req_isActive: DataTypes.TINYINT(1),
    pay_req_isDelete: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_payout_req',
  });
  return tbl_payout_req;
};