'use strict';

const { DataTypes } = require('sequelize');

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_properties', {
      property_id: {
        type: Sequelize.INTEGER(11),
        primaryKey: true,
        autoIncrement: true,
        allowNull: false
      },
      property_host_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      property_name: {
        type: Sequelize.STRING(50),
        allowNull: false
      },
      property_address: {
        type: Sequelize.STRING(255),
        allowNull: false
      },
      property_longitude: {
        type: Sequelize.DECIMAL(11, 8),
        allowNull: false
      },
      property_latitude: {
        type: Sequelize.DECIMAL(10, 8),
        allowNull: false
      },
      property_desc: {
        type: Sequelize.TEXT({ length: "long" }),
        allowNull: false
      },
      property_price: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: false
      },
      property_mini_price: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: false
      },
      property_city: {
        type: Sequelize.STRING(50),
        allowNull: false
      },
      property_zip: {
        type: Sequelize.STRING(20),
        // allowNull: 
      },
      property_state: {
        type: Sequelize.STRING(255),
        allowNull: false
      },
      property_contry: {
        type: Sequelize.STRING(20),
        allowNull: false
      },
      property_contact: {
        type: Sequelize.STRING(20)
      },
      property_email: {
        type: Sequelize.STRING(50),
      },
      is_active: {
        type: Sequelize.TINYINT(1),
        defaultValue: 1,
        allowNull: false
      },
      is_deleted: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0,
        allowNull: false
      },
      is_verify: {
        type: Sequelize.TINYINT(1),
        defaultValue: 1,
      },
      is_luxury: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
      created_at: {
        type: Sequelize.DATE(),
        allowNull: false
      },
      updated_at: {
        type: Sequelize.DATE(),
        allowNull: false
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_properties');
  }
};