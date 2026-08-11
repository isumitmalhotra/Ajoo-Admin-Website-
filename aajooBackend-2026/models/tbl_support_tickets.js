'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class tbl_support_tickets extends Model {
        static associate(models) {
            this._models = models;
            tbl_support_tickets.hasMany(models.tbl_support_ticket_messages, {
                foreignKey: 'stm_ticket_id',
                sourceKey: 'st_id',
                as: 'messages',
                constraints: false,
            });
            tbl_support_tickets.belongsTo(models.tbl_user, {
                foreignKey: 'st_host_id',
                targetKey: 'user_id',
                as: 'host',
                constraints: false,
            });
        }

        static async searchTickets(whereClause, options = {}) {
            const { page = 1, limit = 20 } = options;
            const offset = (page - 1) * limit;
            try {
                const { rows, count } = await tbl_support_tickets.findAndCountAll({
                    where: whereClause,
                    limit,
                    offset,
                    order: [['st_created_at', 'DESC']],
                    raw: true,
                });
                return { items: rows, totalRecords: count };
            } catch (error) {
                return error;
            }
        }
    }

    tbl_support_tickets.init(
        {
            st_id: { type: DataTypes.INTEGER(11), allowNull: false, primaryKey: true, autoIncrement: true },
            st_host_id: DataTypes.INTEGER(11),
            st_subject: DataTypes.STRING(255),
            st_category: DataTypes.ENUM('PAYOUT', 'BOOKING', 'PROFILE', 'GENERAL', 'OTHER'),
            st_status: DataTypes.ENUM('OPEN', 'PENDING', 'RESOLVED', 'CLOSED'),
            st_last_reply_at: DataTypes.DATE,
            st_unread_count: DataTypes.INTEGER(11),
        },
        {
            sequelize,
            freezeTableName: true,
            modelName: 'tbl_support_tickets',
            timestamps: true,
            createdAt: 'st_created_at',
            updatedAt: 'st_updated_at',
        }
    );

    return tbl_support_tickets;
};
