const { v2: cloudinary } = require('cloudinary');
const path = require('path');
const config = require("../config/db.config");
const model = require("../models");

const RAW_FILE_EXTENSIONS = new Set([
    '.pdf',
    '.csv',
    '.txt',
    '.zip',
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
]);

class CloudinaryManager {
    constructor() {
        // Only configured when all three credentials are present. Missing creds
        // (e.g. local dev) must NOT crash uploads — uploadImage degrades below.
        this.isConfigured = Boolean(
            config.cloundinaryCloud &&
            config.cloundinaryKey &&
            config.cloundinarySecrete
        );
        if (this.isConfigured) {
            cloudinary.config({
                cloud_name: config.cloundinaryCloud,
                api_key: config.cloundinaryKey,
                api_secret: config.cloundinarySecrete,
            });
        } else {
            console.warn(
                "[Cloudinary] Credentials not set — image uploads will be " +
                "skipped (files remain on local disk)."
            );
        }
        this.cloudinary = cloudinary;
    };
    async uploadImage(imageUrl, fileType, recordId, options = {}) {
        try {
            // Graceful degradation: no creds → skip cloud upload so callers
            // (e.g. signup) still complete. afileId 0 = "no attachment stored".
            if (!this.isConfigured) {
                console.warn(`[Cloudinary] Skipping upload (not configured): ${imageUrl}`);
                return { afileId: 0, skipped: true };
            }
            const extension = path.extname(imageUrl || '').toLowerCase();
            const inferredResourceType = RAW_FILE_EXTENSIONS.has(extension) ? 'raw' : 'image';
            const {
                resourceType = inferredResourceType,
                attachmentPath = imageUrl,
                originalName = path.basename(imageUrl || ''),
                ...uploadOptions
            } = options;

            const uploadResult = await cloudinary.uploader.upload(imageUrl, {
                resource_type: resourceType,
                ...uploadOptions,
            });
            if (!uploadResult) {
                return false;
            }
            let attachmentPayload = {
                afile_type: fileType,
                afile_record_id: recordId,
                afile_path: attachmentPath,
                afile_cldId: uploadResult["public_id"],
                afile_name: originalName,
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
