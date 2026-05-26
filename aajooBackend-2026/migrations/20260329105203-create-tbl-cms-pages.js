'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_cms_pages', {
      cp_id: {
        type: Sequelize.INTEGER(11),
        primaryKey: true,
        autoIncrement: true,
        allowNull: false
      },
      cp_page_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      cp_section_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      cp_title: {
        type: Sequelize.STRING,
        allowNull: false
      },
      cp_description: {
        type: Sequelize.TEXT,
        allowNull: false
      },
      cp_afile_id: {
        type: Sequelize.INTEGER(11),
        allowNull: true
      },
      cp_bt_title: {
        type: Sequelize.STRING,
        allowNull: true
      },
      cp_btn_url: {
        type: Sequelize.STRING,
        allowNull: true
      },
      cp_btn_opn: {
        type: Sequelize.STRING,
        allowNull: true
      },
      cp_hm_props: {
        type: Sequelize.JSON,
        allowNull: true
      },
      cp_hm_faq: {
        type: Sequelize.JSON,
        allowNull: true
      },
      cp_hm_testimonial: {
        type: Sequelize.JSON,
        allowNull: true
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_cms_pages');
  }
};