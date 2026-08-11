module.exports = (sequelize, DataTypes) => {
    return sequelize.define('tbl_chatbot_campaigns', {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        campaign_session_id: { type: DataTypes.STRING(255), allowNull: false, unique: true },
        campaign_phone: { type: DataTypes.STRING(20), allowNull: false },
        campaign_city: { type: DataTypes.STRING(255) },
        campaign_channel: { type: DataTypes.STRING(50), defaultValue: 'web' },
        campaign_status: { type: DataTypes.STRING(50), defaultValue: 'active' },
        reminder_2hr_sent: { type: DataTypes.TINYINT, defaultValue: 0 },
        reminder_2hr_at: { type: DataTypes.DATE },
        offer_24hr_sent: { type: DataTypes.TINYINT, defaultValue: 0 },
        offer_24hr_at: { type: DataTypes.DATE },
        stopped_at: { type: DataTypes.DATE },
        stop_reason: { type: DataTypes.STRING(100) },
    }, {
        tableName: 'tbl_chatbot_campaigns',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at',
    });
};