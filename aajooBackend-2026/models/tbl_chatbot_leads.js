module.exports = (sequelize, DataTypes) => {
    return sequelize.define('tbl_chatbot_leads', {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        lead_session_id: { type: DataTypes.STRING(255), allowNull: false, unique: true },
        lead_phone: { type: DataTypes.STRING(20) },
        lead_name: { type: DataTypes.STRING(255) },
        lead_city: { type: DataTypes.STRING(255) },
        lead_checkin: { type: DataTypes.STRING(50) },
        lead_checkout: { type: DataTypes.STRING(50) },
        lead_guests: { type: DataTypes.INTEGER },
        lead_interest: { type: DataTypes.STRING(100), defaultValue: 'property_search' },
        lead_status: { type: DataTypes.STRING(50), defaultValue: 'new' },
        lead_channel: { type: DataTypes.STRING(50), defaultValue: 'web' },
        lead_booked: { type: DataTypes.TINYINT, defaultValue: 0 },
        lead_booked_at: { type: DataTypes.DATE },
    }, {
        tableName: 'tbl_chatbot_leads',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at',
    });
};