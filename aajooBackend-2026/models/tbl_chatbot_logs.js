module.exports = (sequelize, DataTypes) => {
    return sequelize.define('tbl_chatbot_logs', {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        log_session_id: { type: DataTypes.STRING(255) },
        log_phone: { type: DataTypes.STRING(20) },
        log_type: { type: DataTypes.STRING(100), allowNull: false },
        log_data: { type: DataTypes.JSON },
        log_channel: { type: DataTypes.STRING(50), defaultValue: 'web' },
    }, {
        tableName: 'tbl_chatbot_logs',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: false,
    });
};