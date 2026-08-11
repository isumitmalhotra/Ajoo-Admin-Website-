'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class tbl_notifications extends Model {
        static associate(models) { }

        /**
         * Fire-and-forget notification writer. Never throws — notification
         * failures must not break the business flow that triggered them.
         */
        static async notify({ role, recipientId = null, category = 'SYSTEM', title, body = null, linkPath = null }) {
            try {
                const row = await tbl_notifications.create({
                    ntf_recipient_role: role,
                    ntf_recipient_id: recipientId,
                    ntf_category: category,
                    ntf_title: title,
                    ntf_body: body,
                    ntf_link_path: linkPath,
                    ntf_is_read: 0,
                });
                return row.dataValues;
            } catch (error) {
                return null;
            }
        }

        static async search(whereClause, options = {}) {
            const { page = 1, limit = 20 } = options;
            const offset = (page - 1) * limit;
            try {
                const { rows, count } = await tbl_notifications.findAndCountAll({
                    where: whereClause,
                    limit,
                    offset,
                    order: [['ntf_created_at', 'DESC']],
                    raw: true,
                });
                return { items: rows, totalRecords: count };
            } catch (error) {
                return { items: [], totalRecords: 0 };
            }
        }
    }

    tbl_notifications.init(
        {
            ntf_id: { type: DataTypes.INTEGER(11), allowNull: false, primaryKey: true, autoIncrement: true },
            ntf_recipient_role: DataTypes.ENUM('ADMIN', 'HOST', 'GUEST'),
            ntf_recipient_id: DataTypes.INTEGER(11),
            ntf_category: DataTypes.ENUM('BOOKING', 'USER', 'HOST', 'PAYOUT', 'KYC', 'SYSTEM'),
            ntf_title: DataTypes.STRING(255),
            ntf_body: DataTypes.TEXT,
            ntf_link_path: DataTypes.STRING(255),
            ntf_is_read: DataTypes.TINYINT(1),
        },
        {
            sequelize,
            freezeTableName: true,
            modelName: 'tbl_notifications',
            timestamps: true,
            createdAt: 'ntf_created_at',
            updatedAt: 'ntf_updated_at',
        }
    );

    return tbl_notifications;
};
