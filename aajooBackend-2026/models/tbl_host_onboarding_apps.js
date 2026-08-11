'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class tbl_host_onboarding_apps extends Model {
        static associate(models) {
            tbl_host_onboarding_apps.belongsTo(models.tbl_user, {
                foreignKey: 'hoa_user_id',
                targetKey: 'user_id',
                as: 'applicant',
                constraints: false,
            });
        }
    }

    tbl_host_onboarding_apps.init(
        {
            hoa_id: { type: DataTypes.INTEGER(11), allowNull: false, primaryKey: true, autoIncrement: true },
            hoa_user_id: DataTypes.INTEGER(11),
            hoa_property_type: DataTypes.STRING(100),
            hoa_city: DataTypes.STRING(100),
            hoa_state: DataTypes.STRING(100),
            hoa_country: DataTypes.STRING(100),
            hoa_hosting_experience: DataTypes.STRING(255),
            hoa_contact_name: DataTypes.STRING(255),
            hoa_contact_phone: DataTypes.STRING(32),
            hoa_message: DataTypes.TEXT,
            hoa_status: DataTypes.ENUM('RECEIVED', 'IN_REVIEW', 'APPROVED', 'REJECTED'),
            hoa_admin_note: DataTypes.TEXT,
        },
        {
            sequelize,
            freezeTableName: true,
            modelName: 'tbl_host_onboarding_apps',
            timestamps: true,
            createdAt: 'hoa_created_at',
            updatedAt: 'hoa_updated_at',
        }
    );

    return tbl_host_onboarding_apps;
};
