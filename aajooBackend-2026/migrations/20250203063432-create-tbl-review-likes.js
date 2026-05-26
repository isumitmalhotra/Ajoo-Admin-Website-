'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_review_likes', {
      rl_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true
      },
      rl_review_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      rl_user_id: {
        type: Sequelize.INTEGER(11),
        // allowNull: false
      },
      rl_like: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
      rl_dislike: {
        type: Sequelize.JSON(),
      },
      rl_list: {
        type: Sequelize.JSON(),
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_review_likes');
  }
};