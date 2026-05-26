'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_attachments extends Model {
    static associate(models) {
    }

    static async handleSingle(file, recordId, type) {
      try {
        let payload = {
          afile_type: type,
          afile_record_id: recordId,
          afile_path: file.path,
          afile_name: file.originalname,
        };
        await tbl_attachments.create(payload);
      } catch (error) {
        throw error;
      }
    };
    static async deleteAttachment(recordId, type, findImage) {
      const fs = require('fs');
      const path = require('path');
      console.log("Deleting attachment for recordId:", recordId, "type:", type, "findImage:", findImage);
      try {
        if (findImage == null) {
          throw new Error("no record found");
        }
        const imagePath = path.join(__dirname, '..', findImage.afile_path);
        // Check if file exists first
        if (!fs.existsSync(imagePath)) {
          console.warn("File not found at", imagePath);
        } else {
          fs.unlinkSync(imagePath); // synchronous version is easier here

        }
        const x = await tbl_attachments.destroy({ where: { afile_type: type, afile_record_id: recordId } });
        console.log(x, "Attachment record deleted from database");
        return true;
      } catch (error) {
        return error;
      }
    };
    static async getAllAttachments(whereClause) {
      try {
        const data = await tbl_attachments.findAll({
          raw: true,
          where: whereClause
        });
        return data;
      } catch (error) {
        return error;
      }
    };
    static async handleMultiple(files, recordId, type) {
      let payload = files.map(file => {
        return {
          afile_type: type,
          afile_record_id: recordId,
          afile_path: file.path,
          afile_name: file.originalname,
        };
      });
      await tbl_attachments.bulkCreate(payload);
    };
    static async getSingleAttachment(whereClause) {
      try {
        const data = await tbl_attachments.findOne({
          raw: true,
          where: whereClause
        });
        return data;
      } catch (error) {
        return error
      }
    };
    //with cloudinary
    static async addCloudAttachment(payload) {
      try {
        const data = await tbl_attachments.create(payload);
        return data;
      } catch (error) {
        return error;
      }
    };
    static async createBulkAttachment(payload) {
      try {

        if (!Array.isArray(payload) || payload.length == 0) {
          return false
        }
        const t = await tbl_attachments.bulkCreate(payload);

      } catch (error) {
        console.log(error)
        logger.error(`Error in createBulkAttachment: ${error.message}`, { stack: error.stack });
        return error
      }
    }
  }
  tbl_attachments.init({
    afile_id: {
      type: DataTypes.INTEGER(11),
      primaryKey: true,
      autoIncrement: true,
      allowNull: false
    },
    afile_type: DataTypes.INTEGER(11),
    afile_record_id: DataTypes.INTEGER(11),
    afile_path: DataTypes.TEXT(),
    afile_cldId: DataTypes.TEXT(),
    afile_name: DataTypes.STRING(255),
  }, {
    sequelize,
    modelName: 'tbl_attachments',
    timestamps: false
  });
  return tbl_attachments;
};