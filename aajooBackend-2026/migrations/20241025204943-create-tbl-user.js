'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_users', {
      user_id: {
        type: Sequelize.INTEGER(11),
        primaryKey: true,
        allowNull: false,
        autoIncrement: true
      },
      user_fullName: {
        type: Sequelize.STRING(50),
        allowNull: false
      },
      user_pnumber: {
        type: Sequelize.STRING(50),
        allowNull: false,
        comment: "phone number"
      },
      user_dob: {
        type: Sequelize.STRING(20),
        allowNull: false,
        comment: "date of birth"
      },
      user_address: {
        type: Sequelize.STRING(255),
        allowNull: false
      },
      user_city: {
        type: Sequelize.STRING(50),
        allowNull: false
      },
      user_zipcode: {
        type: Sequelize.STRING(20)
      },
      // user_refrel: {
      //   type: Sequelize.INTEGER(11)
      // },
      user_isHost: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
      user_isUser: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
      user_isActive: {
        type: Sequelize.TINYINT(1),
        defaultValue: 1
      },
      user_isVerified: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0   
      },
      user_isDelete: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
      added_at: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updated_at: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_users');
  }
};