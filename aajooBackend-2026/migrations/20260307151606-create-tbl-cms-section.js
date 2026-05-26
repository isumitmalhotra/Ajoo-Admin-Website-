'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_cms_sections', {
      cs_id: {
        type: Sequelize.INTEGER(11),
        primaryKey: true,
        autoIncrement: true,
        allowNull: false
      },
      cs_title: {
        type: Sequelize.STRING,
        allowNull: false
      },
      cs_slug: {
        type: Sequelize.STRING,
        allowNull: false
      },
      cs_isActive: {
        type: Sequelize.TINYINT(1),
        allowNull: false,
        defaultValue: true
      },
      cs_url: {
        type: Sequelize.STRING,
        allowNull: true
      },
      cs_description: {
        type: Sequelize.TEXT,
        // allowNull: true
      },
      cs_content: {
        type: Sequelize.TEXT('long'),
        // allowNull: true
      },
      cs_image: {
        type: Sequelize.STRING,
        // allowNull: true
      },
      cs_order: {
        type: Sequelize.INTEGER,
        // allowNull: true
      },
      cs_created_at: {
        allowNull: false,
        type: Sequelize.DATE
      },
      cs_updated_at: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_cms_sections');
  }
};