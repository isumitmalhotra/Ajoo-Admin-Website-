const { v2: cloudinary } = require('cloudinary');
const config = require("../config/db.config");
const model = require("../models");

class CloudinaryManager {
    constructor() {
        cloudinary.config({
            cloud_name: config.cloundinaryCloud,
            api_key: config.cloundinaryKey,
            api_secret: config.cloundinarySecrete,
        });
        this.cloudinary = cloudinary;
    };
    async uploadImage(imageUrl, fileType, recordId) {
        try {
            const uploadResult = await cloudinary.uploader.upload(imageUrl);
            if (!uploadResult) {
                return false;
            }
            let attachmentPayload = {
                afile_type: fileType,
                afile_record_id: recordId,
                afile_path: imageUrl,
                afile_cldId: uploadResult["public_id"],
            };
            const data = await model.tbl_attachments.addCloudAttachment(attachmentPayload);

            return { ...uploadResult, afileId: data.afile_id };
        } catch (error) {
            // logger.error(`Error in uploadImage: ${error.message}`, { stack: error.stack });
            throw error;
        }
    };

    async multipleImages(files, fileType, recordId, folderName = "property_folder") {
        const uploadPromises = files.map(async (f) => {
            const uploadResult = await cloudinary.uploader.upload(f.path, { folder: folderName });
            let payload = {
                afile_type: fileType,
                afile_record_id: recordId,
                afile_path: f.path,
                afile_cldId: uploadResult["public_id"],
            };
            return { payload, url: uploadResult["url"] };
        });
        const uploadResults = await Promise.all(uploadPromises);
        let attachmentPayload = uploadResults.map(result => result.payload)
        await model.tbl_attachments.destroy({ where: { afile_type: fileType, afile_record_id: recordId } });
        await model.tbl_attachments.createBulkAttachment(attachmentPayload)
        const uploadUrls = uploadResults.map(result => result.url);
        return uploadUrls;
    };

    // Method to generate optimized image URL
    async getOptimizedUrl(publicId) {
        return cloudinary.url(publicId, {
            resource_type: 'image',
            fetch_format: 'auto',
            quality: 'auto',
        });
    };

    async getUrlOfmultiIds(publicId) {
        const urls = await Promise.all(
            cldIds.map(async (publicId) => {
                return getOptimizedUrl(publicId);
            })
        );
    }

    // Method to generate auto-cropped image URL
    getAutoCroppedUrl(publicId, width = 500, height = 500) {
        return cloudinary.url(publicId, {
            crop: 'auto',
            gravity: 'auto',
            width,
            height,
        });
    };

    async deleteSingleImage(publicId) {
        try {
            const data = await cloudinary.uploader.destroy(publicId);
            console.log(data, "delete img Cloudinary")
            return
        } catch (error) {
            return error;
        }
    }
};

module.exports = { CloudinaryManager };
