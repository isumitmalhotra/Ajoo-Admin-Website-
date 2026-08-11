'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class tbl_admin_flags extends Model {
        static associate(models) {
            tbl_admin_flags.belongsTo(models.tbl_user, {
                foreignKey: 'af_user_id',
                targetKey: 'user_id',
                as: 'flaggedUser',
                constraints: false,
            });
        }

        static async raiseFlag(payload) {
            try {
                const row = await tbl_admin_flags.create(payload);
                return row.dataValues;
            } catch (error) {
                return error;
            }
        }

        static async searchFlags(whereClause, options = {}) {
            const { page = 1, limit = 20 } = options;
            const offset = (page - 1) * limit;
            try {
                const { rows, count } = await tbl_admin_flags.findAndCountAll({
                    where: whereClause,
                    limit,
                    offset,
                    order: [['af_created_at', 'DESC']],
                    raw: true,
                });
                return { items: rows, totalRecords: count };
            } catch (error) {
                return error;
            }
        }
    }

    tbl_admin_flags.init(
        {
            af_id: { type: DataTypes.INTEGER(11), allowNull: false, primaryKey: true, autoIncrement: true },
            af_user_id: DataTypes.INTEGER(11),
            af_session_id: DataTypes.STRING(64),
            af_flag_type: DataTypes.ENUM('KYC_IN_REVIEW', 'KYC_DECLINED', 'PAYOUT_VARIANCE', 'OTHER'),
            af_subject_role: DataTypes.ENUM('HOST', 'GUEST'),
            af_resolved: DataTypes.TINYINT(1),
            af_resolved_by: DataTypes.INTEGER(11),
            af_notes: DataTypes.TEXT,
        },
        {
            sequelize,
            freezeTableName: true,
            modelName: 'tbl_admin_flags',
            timestamps: true,
            createdAt: 'af_created_at',
            updatedAt: 'af_updated_at',
        }
    );

    return tbl_admin_flags;
};
