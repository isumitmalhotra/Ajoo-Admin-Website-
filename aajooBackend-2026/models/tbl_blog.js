'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_blog extends Model {
    static associate(models) {
      tbl_blog.belongsTo(sequelize.models.tbl_attachments, { foreignKey: "blog_id", targetKey: "afile_record_id", as: "blogImg" });
    };

    static async blogCreate(payload) {
      try {
        const data = await tbl_blog.create(payload);
        return data.dataValues;
      } catch (error) {
        return error;
      }
    };
    static async getBlogs(whereClause, fileType) {
      try {
        const data = await tbl_blog.findAll({
          raw: true,
          where: whereClause,
          attributes: { exclude: ["blog_isActive", "blog_isDelete"] },
          include: {
            model: sequelize.models.tbl_attachments,
            as: "blogImg",
            where: { afile_type: fileType },
            attributes: ["afile_path"]
          }
        });
        return data;
      } catch (error) {
        return error
      }
    };

    static async blogUpdate(blogId, payload) {
      try {
        await tbl_blog.update(payload, { where: { blog_id: blogId } });
      } catch (error) {
        return error;
      }
    };
  }
  tbl_blog.init({
    blog_id: {
      type: DataTypes.INTEGER(11),
      autoIncrement: true,
      primaryKey: true,
      allowNull: false
    },
    blog_title: DataTypes.STRING(100),
    blog_short_desc: DataTypes.STRING(200),
    blog_long_desc: DataTypes.TEXT(),
    blog_writerId: DataTypes.TEXT(),
    blog_isActive: DataTypes.TINYINT(1),
    blog_isDelete: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_blog',
    timestamps: false,
    createdAt: "blog_addedAt",
    updatedAt: "blog_updatedAt"
  });
  return tbl_blog;
};