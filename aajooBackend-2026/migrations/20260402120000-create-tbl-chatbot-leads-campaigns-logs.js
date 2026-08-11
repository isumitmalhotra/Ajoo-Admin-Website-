'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_chatbot_leads', {
      id: {
        type: Sequelize.INTEGER(11),
        autoIncrement: true,
        primaryKey: true,
        allowNull: false,
      },
      lead_session_id: {
        type: Sequelize.STRING(255),
        allowNull: false,
        unique: true,
      },
      lead_phone: {
        type: Sequelize.STRING(20),
        allowNull: true,
      },
      lead_name: {
        type: Sequelize.STRING(255),
        allowNull: true,
      },
      lead_city: {
        type: Sequelize.STRING(255),
        allowNull: true,
      },
      lead_checkin: {
        type: Sequelize.STRING(50),
        allowNull: true,
      },
      lead_checkout: {
        type: Sequelize.STRING(50),
        allowNull: true,
      },
      lead_guests: {
        type: Sequelize.INTEGER(11),
        allowNull: true,
      },
      lead_interest: {
        type: Sequelize.STRING(100),
        allowNull: true,
        defaultValue: 'property_search',
      },
      lead_status: {
        type: Sequelize.STRING(50),
        allowNull: true,
        defaultValue: 'new',
      },
      lead_channel: {
        type: Sequelize.STRING(50),
        allowNull: true,
        defaultValue: 'web',
      },
      lead_booked: {
        type: Sequelize.TINYINT(1),
        allowNull: true,
        defaultValue: 0,
      },
      lead_booked_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'),
      },
    });

    await queryInterface.addIndex('tbl_chatbot_leads', ['lead_phone'], {
      name: 'idx_lead_phone',
    });
    await queryInterface.addIndex('tbl_chatbot_leads', ['lead_status'], {
      name: 'idx_lead_status',
    });
    await queryInterface.addIndex('tbl_chatbot_leads', ['lead_booked'], {
      name: 'idx_lead_booked',
    });

    await queryInterface.createTable('tbl_chatbot_campaigns', {
      id: {
        type: Sequelize.INTEGER(11),
        autoIncrement: true,
        primaryKey: true,
        allowNull: false,
      },
      campaign_session_id: {
        type: Sequelize.STRING(255),
        allowNull: false,
        unique: true,
      },
      campaign_phone: {
        type: Sequelize.STRING(20),
        allowNull: false,
      },
      campaign_city: {
        type: Sequelize.STRING(255),
        allowNull: true,
      },
      campaign_channel: {
        type: Sequelize.STRING(50),
        allowNull: true,
        defaultValue: 'web',
      },
      campaign_status: {
        type: Sequelize.STRING(50),
        allowNull: true,
        defaultValue: 'active',
      },
      reminder_2hr_sent: {
        type: Sequelize.TINYINT(1),
        allowNull: true,
        defaultValue: 0,
      },
      reminder_2hr_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      offer_24hr_sent: {
        type: Sequelize.TINYINT(1),
        allowNull: true,
        defaultValue: 0,
      },
      offer_24hr_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      stopped_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      stop_reason: {
        type: Sequelize.STRING(100),
        allowNull: true,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'),
      },
    });

    await queryInterface.addIndex('tbl_chatbot_campaigns', ['campaign_phone'], {
      name: 'idx_campaign_phone',
    });
    await queryInterface.addIndex('tbl_chatbot_campaigns', ['campaign_status'], {
      name: 'idx_campaign_status',
    });
    await queryInterface.addIndex('tbl_chatbot_campaigns', ['reminder_2hr_sent'], {
      name: 'idx_reminder_2hr',
    });
    await queryInterface.addIndex('tbl_chatbot_campaigns', ['offer_24hr_sent'], {
      name: 'idx_offer_24hr',
    });

    await queryInterface.createTable('tbl_chatbot_logs', {
      id: {
        type: Sequelize.INTEGER(11),
        autoIncrement: true,
        primaryKey: true,
        allowNull: false,
      },
      log_session_id: {
        type: Sequelize.STRING(255),
        allowNull: true,
      },
      log_phone: {
        type: Sequelize.STRING(20),
        allowNull: true,
      },
      log_type: {
        type: Sequelize.STRING(100),
        allowNull: false,
      },
      log_data: {
        type: Sequelize.JSON,
        allowNull: true,
      },
      log_channel: {
        type: Sequelize.STRING(50),
        allowNull: true,
        defaultValue: 'web',
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
    });

    await queryInterface.addIndex('tbl_chatbot_logs', ['log_type'], {
      name: 'idx_log_type',
    });
    await queryInterface.addIndex('tbl_chatbot_logs', ['log_phone'], {
      name: 'idx_log_phone',
    });
    await queryInterface.addIndex('tbl_chatbot_logs', ['log_session_id'], {
      name: 'idx_log_session',
    });
  },

  async down(queryInterface) {
    await queryInterface.dropTable('tbl_chatbot_logs');
    await queryInterface.dropTable('tbl_chatbot_campaigns');
    await queryInterface.dropTable('tbl_chatbot_leads');
  },
};
