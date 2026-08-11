'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class tbl_support_ticket_messages extends Model {
        static associate(models) {
            tbl_support_ticket_messages.belongsTo(models.tbl_support_tickets, {
                foreignKey: 'stm_ticket_id',
                targetKey: 'st_id',
                as: 'ticket',
                constraints: false,
            });
        }
    }

    tbl_support_ticket_messages.init(
        {
            stm_id: { type: DataTypes.INTEGER(11), allowNull: false, primaryKey: true, autoIncrement: true },
            stm_ticket_id: DataTypes.INTEGER(11),
            stm_sender_role: DataTypes.ENUM('HOST', 'SUPPORT', 'ADMIN'),
            stm_sender_id: DataTypes.INTEGER(11),
            stm_message: DataTypes.TEXT,
            stm_is_read: DataTypes.TINYINT(1),
        },
        {
            sequelize,
            freezeTableName: true,
            modelName: 'tbl_support_ticket_messages',
            timestamps: true,
            createdAt: 'stm_created_at',
            updatedAt: 'stm_updated_at',
        }
    );

    return tbl_support_ticket_messages;
};
